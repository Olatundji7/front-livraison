import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/ma_api_service.dart';

class TrackingPage extends StatefulWidget {
  final int orderId;
  const TrackingPage({super.key, required this.orderId});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  OrderModel? order;
  Map<String, dynamic>? tracking;
  Timer? timer;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final service = MaApiService(context.read<AuthProvider>().api);
      final results = await Future.wait<dynamic>([
        service.getOrder(widget.orderId),
        service.tracking(widget.orderId),
      ]);
      if (!mounted) return;
      setState(() {
        order = results[0] as OrderModel;
        tracking = Map<String, dynamic>.from(results[1] as Map);
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (!silent) setState(() => loading = false);
    }
  }

  LatLng? _point(Object? lat, Object? lng) {
    final a = lat is num ? lat.toDouble() : double.tryParse('$lat');
    final b = lng is num ? lng.toDouble() : double.tryParse('$lng');
    return a == null || b == null ? null : LatLng(a, b);
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _point(order?.pickupLat, order?.pickupLng);
    final destination = _point(order?.destinationLat, order?.destinationLng);
    final driverLocation = tracking?['driver_location'] is Map
        ? Map<String, dynamic>.from(tracking!['driver_location'] as Map)
        : null;
    final current = _point(driverLocation?['latitude'], driverLocation?['longitude']);

    return Scaffold(
      appBar: AppBar(
        title: Text('Suivi de la commande #${widget.orderId}'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: current ?? pickup ?? const LatLng(9.3372, 2.6303),
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.ma3h.ma_livraison',
                      ),
                      if (pickup != null && destination != null)
                        PolylineLayer(
                          polylines: [Polyline(points: [pickup, destination], color: AppColors.primary, strokeWidth: 4)],
                        ),
                      MarkerLayer(
                        markers: [
                          if (pickup != null) Marker(point: pickup, width: 42, height: 42, child: const Icon(Icons.trip_origin, color: Colors.green, size: 34)),
                          if (destination != null) Marker(point: destination, width: 42, height: 42, child: const Icon(Icons.flag, color: Colors.red, size: 34)),
                          if (current != null) Marker(point: current, width: 50, height: 50, child: const Icon(Icons.delivery_dining, color: AppColors.primary, size: 42)),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Text('Statut : ${order?.statut ?? '-'}', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                      const SizedBox(height: 10),
                      if (order?.distanceTravelledKm != null)
                        ListTile(
                          leading: const Icon(Icons.route),
                          title: const Text('Distance réellement parcourue'),
                          trailing: Text('${order!.distanceTravelledKm!.toStringAsFixed(2)} km'),
                        ),
                      if (order?.pickupAdresse != null)
                        ListTile(title: const Text('Départ / récupération'), subtitle: Text(order!.pickupAdresse!)),
                      if (order?.destAdresse != null)
                        ListTile(title: const Text('Réception'), subtitle: Text(order!.destAdresse!)),
                      if (order?.deliverer != null)
                        ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.person)),
                          title: Text('${order!.deliverer!['name'] ?? order!.deliverer!['nom'] ?? 'Livreur'}'),
                          subtitle: Text('${order!.deliverer!['phone'] ?? order!.deliverer!['telephone'] ?? ''}'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
