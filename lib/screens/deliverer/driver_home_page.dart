import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import 'driver_dashboard_page.dart';
import 'driver_order_map_page.dart';

class DriverHomePage extends StatefulWidget {
  const DriverHomePage({super.key});

  @override
  State<DriverHomePage> createState() => _DriverHomePageState();
}

class _DriverHomePageState extends State<DriverHomePage> {
  List<Map<String, dynamic>> available = [];
  Map<String, dynamic>? active;
  String status = 'hors_ligne';
  bool loading = true;
  Timer? timer;
  StreamSubscription<Position>? locationSub;

  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    locationSub?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final api = context.read<AuthProvider>().api;
      final me = await api.request('GET', '/auth/me', authenticated: true);
      final user = Map<String, dynamic>.from(me['user'] as Map);
      final deliverer = user['deliverer'] is Map
          ? Map<String, dynamic>.from(user['deliverer'] as Map)
          : <String, dynamic>{};

      final availableResponse = await api.request(
        'GET',
        '/driver/orders/available',
        authenticated: true,
      );
      final activeResponse = await api.request(
        'GET',
        '/driver/orders',
        authenticated: true,
      );

      final list = (availableResponse['orders'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final all = (activeResponse['data'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final activeOrders = all
          .where(
            (o) =>
                !['livree', 'annulee', 'refusee', 'echec']
                    .contains(o['status']),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        status = (deliverer['status'] ?? 'hors_ligne').toString();
        available = list;
        active = activeOrders.isEmpty ? null : activeOrders.first;
        loading = false;
      });
    } catch (e) {
      if (mounted && !silent) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _setOnline(bool online) async {
    try {
      await context.read<AuthProvider>().api.request(
        'PATCH',
        '/driver/status',
        authenticated: true,
        body: {'status': online ? 'disponible' : 'hors_ligne'},
      );

      if (online) {
        await _startLocation();
      } else {
        await locationSub?.cancel();
        locationSub = null;
      }

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de changer le statut : $e')),
      );
    }
  }

  Future<void> _startLocation() async {
    if (locationSub != null) return;

    try {
      locationSub = LocationService.stream().listen((position) async {
        try {
          await context.read<AuthProvider>().api.request(
            'POST',
            '/driver/location',
            authenticated: true,
            body: {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'accuracy': position.accuracy,
              'speed': position.speed,
              'heading': position.heading,
            },
          );
        } catch (_) {}
      });
    } catch (_) {}
  }

  Future<void> _action(int id, String action) async {
    try {
      await context.read<AuthProvider>().api.request(
        'POST',
        '/driver/orders/$id/$action',
        authenticated: true,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action impossible : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(auth.user?.nom ?? 'Livreur'),
        actions: [
          IconButton(
            tooltip: 'Mes courses',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DriverDashboardPage(),
                ),
              );
            },
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: auth.logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: SwitchListTile(
                title: Text(
                  status == 'disponible'
                      ? 'Vous êtes disponible'
                      : status == 'occupe'
                          ? 'Vous êtes en course'
                          : 'Vous êtes hors ligne',
                ),
                subtitle: const Text(
                  'Le serveur contrôle votre statut.',
                ),
                value: status == 'disponible',
                onChanged: status == 'occupe' ? null : _setOnline,
              ),
            ),
            const SizedBox(height: 18),
            if (active != null) ...[
              _orderCard(active!, activeOrder: true),
              const SizedBox(height: 18),
            ],
            const Text(
              'Nouvelles commandes',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (available.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Aucune commande en attente.'),
                ),
              ),
            ...available.map(_orderCard),
          ],
        ),
      ),
    );
  }

  Widget _orderCard(Map<String, dynamic> order, {bool activeOrder = false}) {
    final id = _toInt(order['id']);
    final status = (order['status'] ?? '').toString();

    final action = status == 'en_attente' || status == 'livreur_reserve'
        ? 'accept'
        : status == 'livreur_accepte'
            ? 'start'
            : status == 'en_cours'
                ? 'pickup'
                : status == 'colis_recupere'
                    ? 'deliver'
                    : null;

    final label = action == 'accept'
        ? 'Accepter la commande'
        : action == 'start'
            ? 'Démarrer'
            : action == 'pickup'
                ? 'Colis récupéré'
                : action == 'deliver'
                    ? 'Livrer'
                    : null;

    final hasDetails = status != 'en_attente' && status != 'livreur_reserve';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commande #$id',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 6),
            if (!hasDetails)
              Text(
                status == 'en_attente'
                    ? 'Une nouvelle commande est disponible.'
                    : 'Commande attribuée par MA Livraison.',
              ),
            if (hasDetails)
              Text(
                '${order['pickup_address'] ?? '-'}'
                '${order['destination_address'] == null ? '' : ' → ${order['destination_address']}'}',
              ),
            const SizedBox(height: 10),
            Text('Statut : $status'),
            if (hasDetails && id != null) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  final parsed = OrderModel.fromJson(order);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DriverOrderMapPage(order: parsed),
                    ),
                  );
                },
                icon: const Icon(Icons.map_outlined),
                label: const Text('Voir la carte / position'),
              ),
            ],
            if (action != null && id != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: activeOrder && action == 'accept'
                      ? null
                      : () => _action(id, action),
                  child: Text(label!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }
}
