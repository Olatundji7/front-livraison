import 'dart:async';

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/ma_api_service.dart';
import '../../services/api_client.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  Map<String, dynamic> stats = {};
  List<Map<String, dynamic>> drivers = [];
  List<OrderModel> orders = [];
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> advertisements = [];
  bool loading = true;
  String? error;
  String orderStatusFilter = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadAll());
  }

  MaApiService _serviceForContext(BuildContext context) {
    return MaApiService(context.read<AuthProvider>().api);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final service = _serviceForContext(context);
      final values = await Future.wait<dynamic>([
        service.adminDashboard(),
        service.adminDrivers(),
        service.adminOrders(status: orderStatusFilter),
        service.adminProducts(),
        service.advertisements(admin: true),
      ]);

      if (!mounted) return;
      setState(() {
        stats = Map<String, dynamic>.from(values[0] as Map);
        drivers = (values[1] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        orders = List<OrderModel>.from(values[2] as List);
        products = (values[3] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        advertisements = (values[4] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> get availableDrivers {
    return drivers.where((d) => _driverStatus(d) == 'disponible').toList();
  }

  String _driverName(Map<String, dynamic> driver) {
    final user = driver['user'];
    if (user is Map && user['name'] != null) return user['name'].toString();
    return 'Livreur #${driver['id'] ?? '-'}';
  }

  String _driverStatus(Map<String, dynamic> driver) {
    final value = driver['status'] ?? driver['statut'] ?? 'hors_ligne';
    return value.toString();
  }

  String _orderStatus(OrderModel order) => order.statut;

  Future<void> _assignOrder(OrderModel order) async {
    if (availableDrivers.isEmpty) {
      _toast('Aucun livreur disponible actuellement.');
      return;
    }

    final selected = await showDialog<int>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Attribuer la commande'),
        children: availableDrivers.map((driver) {
          final id = _toInt(driver['id']);
          return SimpleDialogOption(
            onPressed: id == null ? null : () => Navigator.pop(dialogContext, id),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.delivery_dining)),
              title: Text(_driverName(driver)),
              subtitle: Text(_driverStatus(driver)),
            ),
          );
        }).toList(),
      ),
    );

    if (selected == null) return;

    try {
      await _serviceForContext(context).assignAdminOrder(order.id, selected);
      _toast('Commande attribuée. Le livreur doit maintenant l’accepter.');
      await _loadAll();
    } catch (e) {
      _toast('Attribution impossible : $e', error: true);
    }
  }

  Future<void> _openCreateDriver() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const _DriverFormDialog(),
    );
    if (result == true) await _loadAll();
  }

  Future<void> _openEditDriver(Map<String, dynamic> driver) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _DriverFormDialog(driver: driver),
    );
    if (result == true) await _loadAll();
  }

  Future<void> _openCreateProduct() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _ProductFormDialog(),
    );
    if (result == true) await _loadAll();
  }

  Future<void> _openEditProduct(Map<String, dynamic> product) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _ProductFormDialog(product: product),
    );
    if (result == true) await _loadAll();
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final id = _toInt(product['id']);
    if (id == null) return;

    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer le produit ?'),
        content: Text('Le produit "${product['name'] ?? ''}" sera supprimé.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (yes != true) return;

    try {
      await _serviceForContext(context).deleteProduct(id);
      _toast('Produit supprimé.');
      await _loadAll();
    } catch (e) {
      _toast('Suppression impossible : $e', error: true);
    }
  }

  Future<void> _openCreateAdvertisement() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const _AdvertisementFormDialog(),
    );
    if (result == true) await _loadAll();
  }

  Future<void> _openEditAdvertisement(
      Map<String, dynamic> advertisement) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _AdvertisementFormDialog(advertisement: advertisement),
    );
    if (result == true) await _loadAll();
  }

  Future<void> _deleteAdvertisement(
      Map<String, dynamic> advertisement) async {
    final id = _toInt(advertisement['id']);
    if (id == null) return;

    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Supprimer la publicité ?'),
        content: Text(
          'La publicité "${advertisement['title'] ?? ''}" sera supprimée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (yes != true) return;

    try {
      await _serviceForContext(context).deleteAdvertisement(id);
      _toast('Publicité supprimée.');
      await _loadAll();
    } catch (e) {
      _toast('Suppression impossible : $e', error: true);
    }
  }

  void _toast(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    if (loading && stats.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Administration MA Livraison'),
        actions: [
          IconButton(
            onPressed: _loadAll,
            tooltip: 'Actualiser',
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: auth.logout,
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Tableau de bord'),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: 'Commandes'),
            Tab(icon: Icon(Icons.delivery_dining), text: 'Livreurs'),
            Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Produits'),
            Tab(icon: Icon(Icons.campaign_outlined), text: 'Publicités'),
            Tab(icon: Icon(Icons.map_outlined), text: 'Carte GPS'),
          ],
        ),
      ),
      body: error != null
          ? _errorView()
          : TabBarView(
              controller: _tabs,
              children: [
                _buildDashboard(),
                _buildOrders(),
                _buildDrivers(),
                _buildProducts(),
                _buildAdvertisements(),
                _buildMap(),
              ],
            ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 54),
                const SizedBox(height: 12),
                const Text(
                  'Impossible de charger les données administrateur.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(error ?? ''),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _loadAll,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final cards = <Map<String, dynamic>>[
      {'title': 'Clients', 'value': stats['clients'], 'icon': Icons.people},
      {'title': 'Livreurs', 'value': stats['drivers'], 'icon': Icons.delivery_dining},
      {'title': 'Disponibles', 'value': stats['drivers_available'], 'icon': Icons.check_circle},
      {'title': 'Commandes', 'value': stats['orders_total'], 'icon': Icons.receipt_long},
      {'title': 'En cours', 'value': stats['orders_active'], 'icon': Icons.route},
      {'title': 'Terminées', 'value': stats['orders_completed'], 'icon': Icons.done_all},
    ];

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Vue d’ensemble',
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map(
                  (card) => SizedBox(
                    width: 175,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(card['icon'] as IconData,
                                color: AppColors.primary),
                            const SizedBox(height: 12),
                            Text(card['title'] as String),
                            Text(
                              '${card['value'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          Card(
            color: AppColors.primaryLight,
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Les commandes sont visibles par les livreurs disponibles. L’administration suit le traitement, peut attribuer manuellement une commande si nécessaire et supervise les itinéraires.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _tabs.animateTo(1),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Gérer les commandes'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _tabs.animateTo(2),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Créer un livreur'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _tabs.animateTo(3),
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Ajouter un produit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => _tabs.animateTo(4),
                  icon: const Icon(Icons.campaign),
                  label: const Text('Gérer les publicités'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrders() {
    final pending = orders.where((o) => ![
          'livree',
          'annulee',
          'refusee',
          'echec',
        ].contains(o.statut)).toList();

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Commandes',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              DropdownButton<String>(
                value: orderStatusFilter.isEmpty ? null : orderStatusFilter,
                hint: const Text('Filtrer'),
                items: const [
                  DropdownMenuItem(value: 'en_attente', child: Text('En attente')),
                  DropdownMenuItem(value: 'livreur_reserve', child: Text('Attribuée')),
                  DropdownMenuItem(value: 'livreur_accepte', child: Text('Acceptée')),
                  DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                  DropdownMenuItem(value: 'colis_recupere', child: Text('Colis récupéré')),
                  DropdownMenuItem(value: 'en_livraison', child: Text('En livraison')),
                  DropdownMenuItem(value: 'livree', child: Text('Livrée')),
                  DropdownMenuItem(value: 'annulee', child: Text('Annulée')),
                ],
                onChanged: (value) async {
                  setState(() => orderStatusFilter = value ?? '');
                  await _loadAll();
                },
              ),
              IconButton(
                onPressed: () {
                  setState(() => orderStatusFilter = '');
                  _loadAll();
                },
                tooltip: 'Effacer le filtre',
                icon: const Icon(Icons.clear),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (pending.isNotEmpty)
            Card(
              color: AppColors.primaryLight,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  '${pending.length} commande(s) nécessitent un suivi ou une attribution.',
                ),
              ),
            ),
          const SizedBox(height: 10),
          if (orders.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text('Aucune commande.'),
              ),
            ),
          ...orders.map((order) {
            final canAssign = order.statut == 'en_attente';
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Icon(
                    order.statut == 'livree'
                        ? Icons.check
                        : Icons.local_shipping_outlined,
                    color: AppColors.primary,
                  ),
                ),
                title: Text('Commande #${order.id}'),
                subtitle: Text(
                  '${order.statut}\n${order.pickupAdresse ?? 'Départ'}'
                  '${order.destAdresse == null ? '' : ' → ${order.destAdresse}'}'
                  '${order.distanceTravelledKm == null ? '' : '\nDistance parcourue : ${order.distanceTravelledKm!.toStringAsFixed(2)} km'}',
                ),
                isThreeLine: true,
                trailing: canAssign
                    ? ElevatedButton(
                        onPressed: () => _assignOrder(order),
                        child: const Text('Attribuer'),
                      )
                    : Text(
                        order.statut,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDrivers() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Livreurs',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton.icon(
                onPressed: _openCreateDriver,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Créer un livreur'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...drivers.map(
            (driver) => Card(
              child: ListTile(
                leading: _driverImage(driver),
                title: Text(_driverName(driver)),
                subtitle: Text(
                  'Statut : ${_driverStatus(driver)}\n'
                  'Téléphone : ${(driver['user'] is Map ? driver['user']['phone'] : driver['telephone']) ?? '-'}',
                ),
                isThreeLine: true,
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Modifier',
                      onPressed: () => _openEditDriver(driver),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Voir sur la carte',
                      onPressed: () => _tabs.animateTo(5),
                      icon: const Icon(Icons.map_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _driverImage(Map<String, dynamic> driver) {
    final url = ApiClient.resolveMediaUrl(driver['photo_url']?.toString());
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(url),
      );
    }
    return const CircleAvatar(
      child: Icon(Icons.person_outline),
    );
  }

  Widget _buildProducts() {
    final categories = products
        .map((p) => p['category']?.toString().trim() ?? '')
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Produits',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton.icon(
                onPressed: _openCreateProduct,
                icon: const Icon(Icons.add),
                label: const Text('Ajouter un produit'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (categories.isNotEmpty)
            Wrap(
              spacing: 8,
              children: [
                for (final category in categories)
                  Chip(label: Text(category)),
              ],
            ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Aucun produit réel n’est encore enregistré. Ajoutez votre premier produit.',
                ),
              ),
            ),
          ...products.map(
            (product) => Card(
              child: ListTile(
                leading: _productImage(product),
                title: Text((product['name'] ?? 'Produit').toString()),
                subtitle: Text(
                  '${product['category'] ?? 'Sans catégorie'} • '
                  '${product['price'] ?? 0} FCFA • Stock ${product['stock'] ?? 0}',
                ),
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Modifier',
                      onPressed: () => _openEditProduct(product),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: () => _deleteProduct(product),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productImage(Map<String, dynamic> product) {
    final url = ApiClient.resolveMediaUrl(product['image_url']?.toString());
    if (url != null && url.isNotEmpty) {
      return SizedBox(
        width: 60,
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFEAF2FF), child: Icon(Icons.image_not_supported_outlined))),
        ),
      );
    }
    return const CircleAvatar(child: Icon(Icons.inventory_2_outlined));
  }

  Widget _buildAdvertisements() {
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Publicités',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton.icon(
                onPressed: _openCreateAdvertisement,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Ajouter une publicité'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (advertisements.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'Aucune publicité. Ajoutez un visuel pour l’accueil.',
                ),
              ),
            ),
          ...advertisements.map(
            (ad) => Card(
              child: ListTile(
                leading: _adImage(ad),
                title: Text((ad['title'] ?? 'Publicité').toString()),
                subtitle: Text(
                  '${ad['is_active'] == true ? 'Active' : 'Désactivée'}'
                  '${ad['description'] == null || ad['description'].toString().isEmpty ? '' : '\n${ad['description']}'}',
                ),
                isThreeLine: true,
                trailing: Wrap(
                  spacing: 4,
                  children: [
                    IconButton(
                      tooltip: 'Modifier',
                      onPressed: () => _openEditAdvertisement(ad),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Supprimer',
                      onPressed: () => _deleteAdvertisement(ad),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _adImage(Map<String, dynamic> ad) {
    final url = ApiClient.resolveMediaUrl(ad['image_url']?.toString());
    if (url != null && url.isNotEmpty) {
      return SizedBox(
        width: 72,
        height: 52,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFEAF2FF), child: Icon(Icons.image_not_supported_outlined))),
        ),
      );
    }
    return const CircleAvatar(child: Icon(Icons.campaign_outlined));
  }

  Widget _buildMap() {
    return _AdminMapTab(
      drivers: drivers,
      service: _serviceForContext(context),
    );
  }
}

class _AdminMapTab extends StatefulWidget {
  const _AdminMapTab({
    required this.drivers,
    required this.service,
  });

  final List<Map<String, dynamic>> drivers;
  final MaApiService service;

  @override
  State<_AdminMapTab> createState() => _AdminMapTabState();
}

class _AdminMapTabState extends State<_AdminMapTab> {
  int? driverId;
  List<LatLng> points = [];
  bool loading = false;
  String? error;

  Future<void> _loadPath(int id) async {
    setState(() {
      driverId = id;
      loading = true;
      error = null;
      points = [];
    });

    try {
      final data = await widget.service.driverLocations(id, limit: 400);
      final raw = (data['locations'] as List?) ?? [];
      final result = <LatLng>[];
      for (final entry in raw) {
        final row = Map<String, dynamic>.from(entry as Map);
        final lat = _toDouble(row['latitude'] ?? row['lat']);
        final lng = _toDouble(row['longitude'] ?? row['lng']);
        if (lat != null && lng != null) {
          result.add(LatLng(lat, lng));
        }
      }
      if (!mounted) return;
      setState(() {
        points = result.reversed.toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final center =
        points.isNotEmpty ? points.first : const LatLng(9.337, 2.630);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Parcours des livreurs',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                width: 280,
                child: DropdownButtonFormField<int>(
                  initialValue: driverId,
                  decoration: const InputDecoration(
                    labelText: 'Choisir un livreur',
                  ),
                  items: widget.drivers
                      .map(
                        (d) => DropdownMenuItem<int>(
                          value: _toInt(d['id']),
                          child: Text(
                            (d['user'] is Map
                                    ? d['user']['name']
                                    : d['name'] ?? 'Livreur')
                                .toString(),
                          ),
                        ),
                      )
                      .where((item) => item.value != null)
                      .toList(),
                  onChanged: (id) {
                    if (id != null) _loadPath(id);
                  },
                ),
              ),
            ],
          ),
        ),
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              error!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ma3h.ma_livraison',
              ),
              if (points.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      color: AppColors.primary,
                      strokeWidth: 5,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final driver in widget.drivers)
                    if (_toDouble(driver['latitude']) != null && _toDouble(driver['longitude']) != null)
                      Marker(
                        point: LatLng(_toDouble(driver['latitude'])!, _toDouble(driver['longitude'])!),
                        width: 44,
                        height: 44,
                        child: Tooltip(
                          message: (driver['user'] is Map ? driver['user']['name'] : 'Livreur').toString(),
                          child: Icon(
                            Icons.delivery_dining,
                            color: _driverColor(driver),
                            size: 34,
                          ),
                        ),
                      ),
                  if (points.isNotEmpty)
                    Marker(
                      point: points.first,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.my_location, color: Colors.green, size: 34),
                    ),
                  if (points.length > 1)
                    Marker(
                      point: points.last,
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.location_on, color: Colors.red, size: 38),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _driverColor(Map<String, dynamic> driver) {
    final status = (driver['status'] ?? '').toString();
    if (status == 'occupe') return Colors.orange;
    if (status == 'disponible') return Colors.green;
    return Colors.grey;
  }

  double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }
}

class _DriverFormDialog extends StatefulWidget {
  const _DriverFormDialog({this.driver});

  final Map<String, dynamic>? driver;

  @override
  State<_DriverFormDialog> createState() => _DriverFormDialogState();
}

class _DriverFormDialogState extends State<_DriverFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController phone;
  late final TextEditingController email;
  late final TextEditingController password;
  late final TextEditingController vehicle;
  late final TextEditingController plate;
  Uint8List? photoBytes;
  String? photoName;
  String status = 'actif';
  bool active = false;

  bool get editing => widget.driver != null;

  @override
  void initState() {
    super.initState();
    final driver = widget.driver;
    final user = driver?['user'] is Map
        ? Map<String, dynamic>.from(driver!['user'] as Map)
        : <String, dynamic>{};
    name = TextEditingController(text: (user['name'] ?? '').toString());
    phone = TextEditingController(text: (user['phone'] ?? '').toString());
    email = TextEditingController(text: (user['email'] ?? '').toString());
    password = TextEditingController();
    vehicle = TextEditingController(
      text: (driver?['vehicule_type'] ?? 'moto').toString(),
    );
    plate = TextEditingController(
      text: (driver?['immatriculation'] ?? '').toString(),
    );
    status = (user['status'] ?? 'actif').toString();
    active = status == 'actif';
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    vehicle.dispose();
    plate.dispose();
    super.dispose();
  }

  Future<void> pickPhoto() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      photoBytes = bytes;
      photoName = file.name;
    });
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    final service =
        MaApiService(context.read<AuthProvider>().api);

    try {
      if (editing) {
        await service.updateDriver(
          id: _toInt(widget.driver!['id'])!,
          name: name.text.trim(),
          phone: phone.text.trim(),
          email: email.text.trim(),
          status: active ? 'actif' : 'suspendu',
          vehicle: vehicle.text.trim(),
          plate: plate.text.trim(),
          imageBytes: photoBytes,
          imageName: photoName,
        );
      } else {
        await service.createDriver(
          name: name.text.trim(),
          phone: phone.text.trim(),
          password: password.text,
          email: email.text.trim(),
          vehicle: vehicle.text.trim(),
          plate: plate.text.trim(),
          imageBytes: photoBytes,
          imageName: photoName,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enregistrement impossible : $e')),
      );
    }
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return value == null ? null : int.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(editing ? 'Modifier le livreur' : 'Créer un livreur'),
      content: SizedBox(
        width: 540,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                GestureDetector(
                  onTap: pickPhoto,
                  child: CircleAvatar(
                    radius: 38,
                    backgroundImage:
                        photoBytes == null ? null : MemoryImage(photoBytes!),
                    child: photoBytes == null
                        ? const Icon(Icons.add_a_photo_outlined)
                        : null,
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nom complet'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: email,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                ),
                if (!editing) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: password,
                    obscureText: true,
                    decoration:
                        const InputDecoration(labelText: 'Mot de passe'),
                    validator: (value) => value == null || value.length < 6
                        ? '6 caractères minimum'
                        : null,
                  ),
                ],
                const SizedBox(height: 10),
                TextFormField(
                  controller: vehicle,
                  decoration:
                      const InputDecoration(labelText: 'Type de véhicule'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: plate,
                  decoration:
                      const InputDecoration(labelText: 'Immatriculation'),
                ),
                if (editing) ...[
                  const SizedBox(height: 10),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Compte actif'),
                    value: active,
                    onChanged: (v) => setState(() => active = v),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({this.product});

  final Map<String, dynamic>? product;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController name;
  late final TextEditingController category;
  late final TextEditingController price;
  late final TextEditingController stock;
  late final TextEditingController description;
  Uint8List? imageBytes;
  String? imageName;
  bool active = true;

  @override
  void initState() {
    super.initState();
    final p = widget.product ?? {};
    name = TextEditingController(text: (p['name'] ?? '').toString());
    category = TextEditingController(text: (p['category'] ?? '').toString());
    price = TextEditingController(text: (p['price'] ?? '').toString());
    stock = TextEditingController(text: (p['stock'] ?? '').toString());
    description =
        TextEditingController(text: (p['description'] ?? '').toString());
    active = p['is_active'] != false;
  }

  @override
  void dispose() {
    name.dispose();
    category.dispose();
    price.dispose();
    stock.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      imageBytes = bytes;
      imageName = file.name;
    });
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    final p = widget.product;

    try {
      final service = MaApiService(context.read<AuthProvider>().api);
      if (p == null) {
        await service.createProduct(
          name: name.text.trim(),
          category: category.text.trim(),
          price: int.parse(price.text.trim()),
          stock: int.parse(stock.text.trim()),
          description: description.text.trim(),
          imageBytes: imageBytes,
          imageName: imageName,
          active: active,
        );
      } else {
        await service.updateProduct(
          id: _toInt(p['id'])!,
          name: name.text.trim(),
          category: category.text.trim(),
          price: int.parse(price.text.trim()),
          stock: int.parse(stock.text.trim()),
          description: description.text.trim(),
          imageBytes: imageBytes,
          imageName: imageName,
          active: active,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produit non enregistré : $e')),
      );
    }
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return value == null ? null : int.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.product == null ? 'Ajouter un produit' : 'Modifier le produit'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(imageBytes == null ? 'Choisir une image' : 'Image sélectionnée'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nom du produit'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: category,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Prix (FCFA)'),
                  validator: (v) =>
                      int.tryParse(v ?? '') == null ? 'Nombre invalide' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: stock,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stock'),
                  validator: (v) =>
                      int.tryParse(v ?? '') == null ? 'Nombre invalide' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: description,
                  maxLines: 4,
                  decoration:
                      const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Produit disponible'),
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}

class _AdvertisementFormDialog extends StatefulWidget {
  const _AdvertisementFormDialog({this.advertisement});

  final Map<String, dynamic>? advertisement;

  @override
  State<_AdvertisementFormDialog> createState() =>
      _AdvertisementFormDialogState();
}

class _AdvertisementFormDialogState extends State<_AdvertisementFormDialog> {
  final formKey = GlobalKey<FormState>();
  late final TextEditingController title;
  late final TextEditingController description;
  bool active = true;
  Uint8List? imageBytes;
  String? imageName;

  @override
  void initState() {
    super.initState();
    final a = widget.advertisement ?? {};
    title = TextEditingController(text: (a['title'] ?? '').toString());
    description =
        TextEditingController(text: (a['description'] ?? '').toString());
    active = a['is_active'] != false;
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      imageBytes = bytes;
      imageName = file.name;
    });
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    try {
      final service = MaApiService(context.read<AuthProvider>().api);
      if (widget.advertisement == null) {
        await service.createAdvertisement(
          title: title.text.trim(),
          description: description.text.trim(),
          active: active,
          imageBytes: imageBytes,
          imageName: imageName,
        );
      } else {
        await service.updateAdvertisement(
          id: _toInt(widget.advertisement!['id'])!,
          title: title.text.trim(),
          description: description.text.trim(),
          active: active,
          imageBytes: imageBytes,
          imageName: imageName,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Publicité non enregistrée : $e')),
      );
    }
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return value == null ? null : int.tryParse(value.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.advertisement == null
            ? 'Ajouter une publicité'
            : 'Modifier la publicité',
      ),
      content: SizedBox(
        width: 560,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      imageBytes == null
                          ? 'Choisir une image'
                          : 'Image sélectionnée',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: title,
                  decoration: const InputDecoration(
                    labelText: 'Titre de la publicité',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Obligatoire' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: description,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                  ),
                ),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Publicité active'),
                  value: active,
                  onChanged: (v) => setState(() => active = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: submit,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
