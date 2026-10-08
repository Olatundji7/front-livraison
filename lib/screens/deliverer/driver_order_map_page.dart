import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/ma_api_service.dart';

class DriverOrderMapPage extends StatefulWidget {
  const DriverOrderMapPage({super.key, required this.order});
  final OrderModel order;

  @override
  State<DriverOrderMapPage> createState() => _DriverOrderMapPageState();
}

class _DriverOrderMapPageState extends State<DriverOrderMapPage> {
  Map<String, dynamic>? tracking;
  Timer? timer;

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
      final data = await MaApiService(context.read<AuthProvider>().api).tracking(widget.order.id);
      if (!mounted) return;
      setState(() => tracking = data);
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Suivi indisponible : $e')));
      }
    }
  }

  LatLng? _point(Object? lat, Object? lng) {
    final a = lat is num ? lat.toDouble() : double.tryParse('$lat');
    final b = lng is num ? lng.toDouble() : double.tryParse('$lng');
    return a == null || b == null ? null : LatLng(a, b);
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _point(widget.order.pickupLat, widget.order.pickupLng);
    final destination = _point(widget.order.destinationLat, widget.order.destinationLng);
    final loc = tracking?['driver_location'] is Map
        ? Map<String, dynamic>.from(tracking!['driver_location'] as Map)
        : null;
    final current = _point(loc?['latitude'], loc?['longitude']);

    return Scaffold(
      appBar: AppBar(title: Text('Itinéraire #${widget.order.id}')),
      body: Column(
        children: [
          Expanded(
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
                    polylines: [Polyline(points: [pickup, destination], color: AppColors.primary, strokeWidth: 5)],
                  ),
                MarkerLayer(
                  markers: [
                    if (pickup != null) Marker(point: pickup, width: 44, height: 44, child: const Icon(Icons.trip_origin, color: Colors.green, size: 34)),
                    if (destination != null) Marker(point: destination, width: 44, height: 44, child: const Icon(Icons.flag, color: Colors.red, size: 36)),
                    if (current != null) Marker(point: current, width: 50, height: 50, child: const Icon(Icons.delivery_dining, color: AppColors.primary, size: 42)),
                  ],
                ),
              ],
            ),
          ),
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Statut : ${widget.order.statut}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (widget.order.pickupAdresse != null) Text('Départ : ${widget.order.pickupAdresse}'),
                  if (widget.order.destAdresse != null) Text('Réception : ${widget.order.destAdresse}'),
                  if (widget.order.distanceTravelledKm != null) Text('Distance parcourue : ${widget.order.distanceTravelledKm!.toStringAsFixed(2)} km'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
