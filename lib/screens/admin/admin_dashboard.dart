import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/ma_api_service.dart';
import '../../widgets/driver_avatar.dart';

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
  List<Map<String, dynamic>> notifications = [];
  int unreadNotifications = 0;
  bool loading = true;
  String? error;
  String orderStatusFilter = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  MaApiService _serviceForContext(BuildContext context) {
    return MaApiService(context.read<AuthProvider>().api);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await _serviceForContext(context).adminNotifications();
      if (!mounted) return;

      setState(() {
        notifications = ((data['notifications'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        unreadNotifications = (data['unread_count'] as num?)?.toInt() ?? 0;
      });
    } catch (e) {
      debugPrint('Chargement des notifications impossible : $e');
    }
  }

  Future<void> _showNotifications() async {
    await _loadNotifications();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
              'Notifications${unreadNotifications > 0 ? ' ($unreadNotifications non lue(s))' : ''}'),
          content: SizedBox(
            width: 450,
            child: notifications.isEmpty
                ? const Text('Aucune notification.')
                : ListView(
                    shrinkWrap: true,
                    children: notifications.map((notification) {
                      final data = notification['data'] is Map
                          ? Map<String, dynamic>.from(
                              notification['data'] as Map)
                          : <String, dynamic>{};
                      final id = notification['id']?.toString() ?? '';
                      final isUnread = notification['read_at'] == null;

                      return ListTile(
                        leading: Icon(
                          isUnread
                              ? Icons.notifications_active
                              : Icons.notifications_none,
                        ),
                        title:
                            Text((data['title'] ?? 'Notification').toString()),
                        subtitle: Text((data['message'] ?? '').toString()),
                        trailing: isUnread
                            ? TextButton(
                                onPressed: () async {
                                  try {
                                    await _serviceForContext(dialogContext)
                                        .markAdminNotificationAsRead(id);
                                    await _loadNotifications();
                                    if (mounted) setDialogState(() {});
                                  } catch (e) {
                                    _toast(
                                        'Impossible de marquer comme lue : $e',
                                        error: true);
                                  }
                                },
                                child: const Text('Marquer lue'),
                              )
                            : const Icon(Icons.check, size: 18),
                        onTap: () {
                          final orderId = data['order_id'];
                          if (orderId != null) {
                            Navigator.pop(dialogContext);
                            _tabs.animateTo(1);
                          }
                        },
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
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
      await _loadNotifications();
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

  Future<void> _approveOrder(OrderModel order) async {
    // Capture le service avant d'ouvrir la boîte de dialogue.
    final service = _serviceForContext(context);

    final productPrice = await showDialog<int>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ApproveOrderDialog(order: order),
    );

    if (!mounted || productPrice == null) return;

    try {
      await service.approveAdminOrder(order.id, productPrice);

      if (!mounted) return;
      _toast(
        'Commande validée : produit $productPrice FCFA, frais calculés automatiquement. '
        'Le client paie après confirmation du paiement.',
      );

      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      _toast('Validation impossible : $e', error: true);
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

    if (yes != true || !mounted) return;

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

  Future<void> _deleteAdvertisement(Map<String, dynamic> advertisement) async {
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

    if (yes != true || !mounted) return;

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
            tooltip: 'Notifications',
            onPressed: _showNotifications,
            icon: Badge(
              isLabelVisible: unreadNotifications > 0,
              label: Text('$unreadNotifications'),
              child: const Icon(Icons.notifications_outlined),
            ),
          ),
          IconButton(
            onPressed: () async {
              await _loadAll();
              await _loadNotifications();
            },
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
      {
        'title': 'Livreurs',
        'value': stats['drivers'],
        'icon': Icons.delivery_dining
      },
      {
        'title': 'Disponibles',
        'value': stats['drivers_available'],
        'icon': Icons.check_circle
      },
      {
        'title': 'Commandes',
        'value': stats['orders_total'],
        'icon': Icons.receipt_long
      },
      {
        'title': 'En cours',
        'value': stats['orders_active'],
        'icon': Icons.route
      },
      {
        'title': 'Terminées',
        'value': stats['orders_completed'],
        'icon': Icons.done_all
      },
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
                      'Les commandes sont reçues par MA Livraison puis attribuées par l’administration à un livreur disponible.',
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
    final pending = orders
        .where((o) => ![
              'livree',
              'annulee',
              'refusee',
              'echec',
            ].contains(o.statut))
        .toList();

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
                  DropdownMenuItem(
                      value: 'en_attente', child: Text('En attente')),
                  DropdownMenuItem(
                      value: 'livreur_reserve', child: Text('Attribuée')),
                  DropdownMenuItem(
                      value: 'livreur_accepte', child: Text('Acceptée')),
                  DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                  DropdownMenuItem(
                      value: 'colis_recupere', child: Text('Colis récupéré')),
                  DropdownMenuItem(
                      value: 'en_livraison', child: Text('En livraison')),
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
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                    'Validez chaque demande et fixez son prix. Les livreurs ne verront la commande qu’après paiement du client.'),
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
            final canApprove =
                order.statut == 'en_attente' && order.paymentStatus != 'paye';
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
                  '${order.paymentStatus == 'paye' ? 'Payée' : ((order.total ?? 0) > 0 ? 'En attente de paiement' : 'Prix à fixer')}\nMontant : ${order.total ?? 0} FCFA'
                  '${order.destAdresse == null ? '' : '\nPosition de livraison : ${order.destAdresse}'}',
                ),
                isThreeLine: true,
                trailing: canApprove
                    ? ElevatedButton.icon(
                        onPressed: () => _approveOrder(order),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Valider'),
                      )
                    : Text(
                        order.paymentStatus == 'paye' ? 'Payée' : order.statut,
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
                      tooltip: 'Réinitialiser le mot de passe',
                      onPressed: () => _resetDriverPassword(driver),
                      icon: const Icon(Icons.lock_reset),
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

  Future<void> _resetDriverPassword(Map<String, dynamic> driver) async {
    final id = _toInt(driver['id']);
    if (id == null) return;
    final controller = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Livreur : ${_driverName(driver)}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Nouveau mot de passe (facultatif)',
                helperText: 'Laissez vide pour en générer un automatiquement (6 caractères minimum).',
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Le livreur sera déconnecté de ses appareils.',
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );

    final typed = controller.text.trim();
    if (confirmed != true || !mounted) return;
    if (typed.isNotEmpty && typed.length < 6) {
      _toast('Le mot de passe doit contenir au moins 6 caractères.', error: true);
      return;
    }

    try {
      final result = await _serviceForContext(context)
          .resetDriverPassword(id, password: typed.isEmpty ? null : typed);
      if (!mounted) return;
      final shown = (result['password'] ?? typed).toString();

      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Mot de passe réinitialisé'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Communiquez ce mot de passe au livreur :'),
              const SizedBox(height: 12),
              SelectableText(
                shown,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              const Text(
                'Il ne sera plus affiché après fermeture de cette fenêtre.',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: shown));
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Mot de passe copié.')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copier'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (e) {
      _toast('Réinitialisation impossible : $e', error: true);
    }
  }

  Widget _driverImage(Map<String, dynamic> driver) {
    return DriverAvatar(
      photo: (driver['photo_url'] ?? driver['photo'])?.toString(),
      radius: 20,
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
                for (final category in categories) Chip(label: Text(category)),
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
    final url = context
        .read<AuthProvider>()
        .api
        .mediaUrl(product['image_url']?.toString());
    if (url != null && url.isNotEmpty) {
      return SizedBox(
        width: 60,
        height: 60,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined)),
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
    final url =
        context.read<AuthProvider>().api.mediaUrl(ad['image_url']?.toString());
    if (url != null && url.isNotEmpty) {
      return SizedBox(
        width: 72,
        height: 52,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image_outlined)),
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

/// Suivi des livreurs en direct : position actuelle de chaque livreur,
/// actualisée toutes les 5 secondes. Le parcours (historique) est optionnel.
class _AdminMapTabState extends State<_AdminMapTab> {
  static const _defaultCenter = LatLng(9.337, 2.630);

  final MapController _map = MapController();
  Timer? _timer;
  late List<Map<String, dynamic>> _drivers;
  int? driverId; // null = tous les livreurs
  bool showPath = false;
  List<LatLng> points = [];
  bool loading = false;
  bool _fitted = false;
  String? error;
  DateTime _updatedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _drivers = List<Map<String, dynamic>>.from(widget.drivers);
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    _refresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _map.dispose();
    super.dispose();
  }

  // ---------- données ----------

  Future<List<LatLng>> _fetchPath(int id) async {
    final data = await widget.service.driverLocations(id, limit: 300);
    final raw = (data['locations'] as List?) ?? [];
    final result = <LatLng>[];
    for (final entry in raw) {
      final row = Map<String, dynamic>.from(entry as Map);
      final lat = _toDouble(row['latitude'] ?? row['lat']);
      final lng = _toDouble(row['longitude'] ?? row['lng']);
      if (lat != null && lng != null) result.add(LatLng(lat, lng));
    }
    return result.reversed.toList(); // du plus ancien au plus récent
  }

  Future<void> _refresh() async {
    try {
      final list = await widget.service.adminDrivers();
      List<LatLng>? path;
      if (showPath && driverId != null) path = await _fetchPath(driverId!);
      if (!mounted) return;
      setState(() {
        _drivers = list;
        if (path != null) points = path;
        _updatedAt = DateTime.now();
        error = null;
      });
      if (!_fitted) _fit();
    } catch (e) {
      if (!mounted) return;
      setState(() => error = 'Actualisation impossible : $e');
    }
  }

  void _select(int? id) {
    setState(() {
      driverId = id;
      points = [];
      _fitted = false;
      if (id == null) showPath = false;
    });
    if (showPath && id != null) {
      setState(() => loading = true);
      _fetchPath(id).then((path) {
        if (!mounted) return;
        setState(() {
          points = path;
          loading = false;
        });
        _fit();
      }).catchError((Object e) {
        if (!mounted) return;
        setState(() {
          loading = false;
          error = 'Parcours indisponible : $e';
        });
      });
    }
    _fit();
  }

  void _togglePath(bool value) {
    setState(() {
      showPath = value;
      if (!value) points = [];
    });
    if (value && driverId != null) _refresh();
  }

  // ---------- aides ----------

  List<Map<String, dynamic>> _visible() => _drivers
      .where((d) => driverId == null || _toInt(d['id']) == driverId)
      .toList();

  LatLng? _pos(Map<String, dynamic> d) {
    final lat = _toDouble(d['latitude']);
    final lng = _toDouble(d['longitude']);
    return lat == null || lng == null ? null : LatLng(lat, lng);
  }

  String _name(Map<String, dynamic> d) {
    final user = d['user'];
    if (user is Map && user['name'] != null) return user['name'].toString();
    return 'Livreur #${d['id'] ?? '-'}';
  }

  int? _age(Map<String, dynamic> d) {
    final t = DateTime.tryParse('${d['last_location_at'] ?? ''}')?.toLocal();
    return t == null ? null : DateTime.now().difference(t).inSeconds;
  }

  Color _color(Map<String, dynamic> d) {
    final status = (d['status'] ?? 'hors_ligne').toString();
    final age = _age(d);
    if (status == 'hors_ligne' || age == null || age > 600) return Colors.grey;
    return age <= 45 ? Colors.green : Colors.orange;
  }

  String _ago(Map<String, dynamic> d) {
    final age = _age(d);
    if (age == null) return 'aucune position';
    if (age < 60) return 'il y a $age s';
    if (age < 3600) return 'il y a ${(age / 60).floor()} min';
    return 'il y a ${(age / 3600).floor()} h';
  }

  void _fit() {
    final pts = <LatLng>[
      ..._visible().map(_pos).whereType<LatLng>(),
      if (showPath) ...points,
    ];
    if (pts.isEmpty) return;
    try {
      if (pts.length == 1) {
        _map.move(pts.first, 15);
      } else {
        _map.fitCamera(CameraFit.coordinates(
          coordinates: pts,
          padding: const EdgeInsets.all(60),
          maxZoom: 16,
        ));
      }
      _fitted = true;
    } catch (_) {
      // La carte n'est pas encore prête : nouvel essai à l'actualisation.
    }
  }

  // ---------- affichage ----------

  Widget _marker(Map<String, dynamic> d) {
    final color = _color(d);
    return GestureDetector(
      onTap: () => _select(_toInt(d['id'])),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: color, width: 3),
            ),
            child: DriverAvatar(
              photo: (d['photo_url'] ?? d['photo'])?.toString(),
              radius: 18,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _name(d),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible();
    final located = visible.where((d) => _pos(d) != null).toList();
    final center = located.isNotEmpty ? _pos(located.first)! : _defaultCenter;
    final t = _updatedAt;
    final clock =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Suivi des livreurs en direct',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(
                width: 240,
                child: DropdownButtonFormField<int?>(
                  key: ValueKey(driverId),
                  initialValue: driverId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Livreur'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Tous les livreurs'),
                    ),
                    ..._drivers
                        .where((d) => _toInt(d['id']) != null)
                        .map(
                          (d) => DropdownMenuItem<int?>(
                            value: _toInt(d['id']),
                            child: Text(_name(d), overflow: TextOverflow.ellipsis),
                          ),
                        ),
                  ],
                  onChanged: _select,
                ),
              ),
              FilterChip(
                label: const Text('Afficher le parcours'),
                selected: showPath,
                onSelected: driverId == null ? null : _togglePath,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.circle, size: 10, color: Colors.green),
              const Text(' en direct   '),
              const Icon(Icons.circle, size: 10, color: Colors.orange),
              const Text(' position récente   '),
              const Icon(Icons.circle, size: 10, color: Colors.grey),
              const Text(' hors ligne'),
              const Spacer(),
              Text('Mis à jour $clock', style: const TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
        ),
        if (loading) const LinearProgressIndicator(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        Expanded(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(initialCenter: center, initialZoom: 13),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ma3h.ma_livraison',
              ),
              if (showPath && points.length >= 2)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: points,
                      color: AppColors.primary.withValues(alpha: .6),
                      strokeWidth: 4,
                    ),
                  ],
                ),
              if (showPath && points.isNotEmpty)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: points.first,
                      width: 36,
                      height: 36,
                      child: const Icon(Icons.flag_circle, color: Colors.green, size: 30),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  for (final d in located)
                    Marker(
                      point: _pos(d)!,
                      width: 96,
                      height: 72,
                      child: _marker(d),
                    ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 92,
          child: visible.isEmpty
              ? const Center(child: Text('Aucun livreur.'))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(10),
                  itemCount: visible.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final d = visible[i];
                    final hasPos = _pos(d) != null;
                    return InkWell(
                      onTap: () {
                        final p = _pos(d);
                        if (p != null) _map.move(p, 16);
                      },
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: _color(d), width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            DriverAvatar(
                              photo: (d['photo_url'] ?? d['photo'])?.toString(),
                              radius: 22,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_name(d),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('${d['status'] ?? 'hors_ligne'}',
                                      style: const TextStyle(fontSize: 12)),
                                  Text(hasPos ? _ago(d) : 'aucune position',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
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

class _ApproveOrderDialog extends StatefulWidget {
  const _ApproveOrderDialog({required this.order});

  final OrderModel order;

  @override
  State<_ApproveOrderDialog> createState() => _ApproveOrderDialogState();
}

class _ApproveOrderDialogState extends State<_ApproveOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    final price = widget.order.productPrice;
    _priceController = TextEditingController(
      text: price != null && price > 0 ? '$price' : '',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final price = int.parse(_priceController.text.trim());
    Navigator.of(context).pop<int>(price);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Valider la commande #${widget.order.id}'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saisissez le prix du produit. La distance routière depuis MA Livraison, les frais de livraison, la réduction éventuelle et le gain du livreur seront calculés automatiquement par le serveur. Le client paiera le prix du produit + les frais de livraison nets.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prix du produit (FCFA)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final amount = int.tryParse((value ?? '').trim());
                  if (amount == null || amount < 1) {
                    return 'Entrez un prix valide supérieur à 0.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop<int>(),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Calculer et valider'),
        ),
      ],
    );
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
      maxWidth: 800,
      maxHeight: 800,
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
    final service = MaApiService(context.read<AuthProvider>().api);

    try {
      Map<String, dynamic> saved;
      if (editing) {
        saved = await service.updateDriver(
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
        saved = await service.createDriver(
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
      if (photoBytes != null && saved['photo_url'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Livreur enregistré, mais la photo n’a pas été reçue par le serveur (fichier trop lourd ?).'),
          ),
        );
      }
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
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Obligatoire'
                      : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phone,
                  decoration: const InputDecoration(labelText: 'Téléphone'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Obligatoire'
                      : null,
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
      title: Text(widget.product == null
          ? 'Ajouter un produit'
          : 'Modifier le produit'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                if (imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(imageBytes!,
                        height: 170, width: double.infinity, fit: BoxFit.cover),
                  )
                else if ((widget.product?['image_url'] ?? '')
                    .toString()
                    .isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      context
                          .read<AuthProvider>()
                          .api
                          .mediaUrl(widget.product!['image_url'].toString())!,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                          height: 120,
                          child: Icon(Icons.broken_image_outlined, size: 50)),
                    ),
                  ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: Text(imageBytes == null
                        ? 'Choisir une image'
                        : 'Image sélectionnée'),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: name,
                  decoration:
                      const InputDecoration(labelText: 'Nom du produit'),
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
                  decoration: const InputDecoration(labelText: 'Description'),
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
                if (imageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(imageBytes!,
                        height: 170, width: double.infinity, fit: BoxFit.cover),
                  )
                else if ((widget.advertisement?['image_url'] ?? '')
                    .toString()
                    .isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      context.read<AuthProvider>().api.mediaUrl(
                          widget.advertisement!['image_url'].toString())!,
                      height: 170,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(
                          height: 120,
                          child: Icon(Icons.broken_image_outlined, size: 50)),
                    ),
                  ),
                const SizedBox(height: 10),
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