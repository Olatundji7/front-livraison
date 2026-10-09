import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_colors.dart';
import '../../models/order_model.dart';

class DriverOrderMapPage extends StatelessWidget {
  const DriverOrderMapPage({super.key, required this.order});
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final pickup = order.pickupLat != null && order.pickupLng != null ? LatLng(order.pickupLat!, order.pickupLng!) : null;
    final destination = order.destLat != null && order.destLng != null ? LatLng(order.destLat!, order.destLng!) : null;
    final center = pickup ?? destination ?? const LatLng(9.3372, 2.6303);
    final markers = <Marker>[];
    if (pickup != null) markers.add(Marker(point: pickup, width: 48, height: 48, child: const Icon(Icons.location_pin, size: 44, color: AppColors.primary)));
    if (destination != null) markers.add(Marker(point: destination, width: 48, height: 48, child: const Icon(Icons.flag, size: 36, color: Colors.red)));
    final line = [if (pickup != null) pickup, if (destination != null) destination];

    return Scaffold(
      appBar: AppBar(title: Text('Commande #${order.id}')),
      body: Column(children: [
        Expanded(child: FlutterMap(options: MapOptions(initialCenter: center, initialZoom: 14), children: [
          TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.ma3h.ma_livraison'),
          if (line.length >= 2) PolylineLayer(polylines: [Polyline(points: line, color: AppColors.primary, strokeWidth: 4)]),
          if (markers.isNotEmpty) MarkerLayer(markers: markers),
        ])),
        SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Point de départ : ${order.pickupAdresse ?? '-'}'),
          if (order.destAdresse != null && order.destAdresse!.trim().isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Réception : ${order.destAdresse}')),
          const SizedBox(height: 8),
          const Text('Suivez le repère exact indiqué par le client sur la carte.', style: TextStyle(color: Colors.black54)),
        ]))),
      ]),
    );
  }
}
