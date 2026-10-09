import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';

class TrackingPage extends StatefulWidget {
  final int orderId;

  const TrackingPage({super.key, required this.orderId});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  final api = ApiClient();
  OrderModel? order;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    api.token = context.read<AuthProvider>().apiToken;
    load();
  }

  Future<void> load() async {
    try {
      final data = await api.request(
        'GET',
        '/orders/${widget.orderId}',
        authenticated: true,
      );
      order = OrderModel.fromJson(data['order']);
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final deliverer = order?.deliverer;
    final lat = (deliverer?['position_lat'] as num?)?.toDouble();
    final lng = (deliverer?['position_lng'] as num?)?.toDouble();

    final center = LatLng(lat ?? 9.3372, lng ?? 2.6303);

    return Scaffold(
      appBar: AppBar(title: Text('Commande #${widget.orderId}')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 2,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: 14,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.ma3h.ma_livraison',
                      ),
                      if (lat != null && lng != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(lat, lng),
                              width: 50,
                              height: 50,
                              child: const Icon(
                                Icons.delivery_dining,
                                size: 42,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        'Statut : ${order?.statut ?? '-'}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (deliverer != null)
                        Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(deliverer['nom'] ?? 'Livreur'),
                            subtitle: Text(
                              deliverer['telephone'] ?? '',
                            ),
                          ),
                        ),
                      if (order?.prixEstime != null)
                        ListTile(
                          title: const Text('Prix estimé'),
                          trailing: Text('${order!.prixEstime} FCFA'),
                        ),
                      if (order?.distanceKm != null)
                        ListTile(
                          title: const Text('Distance'),
                          trailing: Text(
                            '${order!.distanceKm!.toStringAsFixed(1)} km',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
