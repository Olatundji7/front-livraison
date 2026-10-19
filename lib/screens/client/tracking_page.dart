import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/driver_avatar.dart';

/// Suivi en direct du livreur sur la carte (rafraîchi toutes les 4 secondes).
class TrackingPage extends StatefulWidget {
  final int orderId;

  const TrackingPage({super.key, required this.orderId});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  static const _defaultCenter = LatLng(9.3372, 2.6303);
  static const _finalStatuses = {'livree', 'annulee', 'refusee', 'echec'};

  final MapController _map = MapController();
  Map<String, dynamic>? _tracking;
  Timer? _timer;
  bool _loading = true;
  bool _followDriver = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _map.dispose();
    super.dispose();
  }

  LatLng? _point(Object? lat, Object? lng) {
    final la = lat is num ? lat.toDouble() : double.tryParse('$lat');
    final lo = lng is num ? lng.toDouble() : double.tryParse('$lng');
    return la == null || lo == null ? null : LatLng(la, lo);
  }

  Future<void> _load({bool silent = false}) async {
    try {
      final api = context.read<AuthProvider>().api;
      final data = await api.request('GET', '/orders/${widget.orderId}/tracking', authenticated: true);
      if (!mounted) return;
      final tracking = Map<String, dynamic>.from(data as Map);
      setState(() {
        _tracking = tracking;
        _loading = false;
        _error = null;
      });

      final driverPos = _driverPoint(tracking);
      if (_followDriver && driverPos != null) {
        try {
          _map.move(driverPos, _map.camera.zoom);
        } catch (_) {
          // La carte n'est pas encore prête : le centre initial sera utilisé.
        }
      }

      if (_finalStatuses.contains(tracking['status']?.toString())) _timer?.cancel();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!silent || _tracking == null) _error = 'Suivi indisponible pour le moment.';
      });
    }
  }

  LatLng? _driverPoint(Map<String, dynamic>? t) {
    final loc = t?['driver_location'];
    return loc is Map ? _point(loc['latitude'], loc['longitude']) : null;
  }

  LatLng? _destinationPoint(Map<String, dynamic>? t) {
    final d = t?['destination'];
    return d is Map ? _point(d['latitude'], d['longitude']) : null;
  }

  String _lastSeen(Map<String, dynamic>? t) {
    final raw = t?['driver_location'] is Map ? t!['driver_location']['last_location_at'] : null;
    final date = raw == null ? null : DateTime.tryParse(raw.toString())?.toLocal();
    if (date == null) return 'Position en attente…';
    final seconds = DateTime.now().difference(date).inSeconds;
    if (seconds < 15) return 'Position en direct';
    if (seconds < 90) return 'Mise à jour il y a $seconds s';
    return 'Dernière position il y a ${(seconds / 60).round()} min';
  }

  @override
  Widget build(BuildContext context) {
    final driverPos = _driverPoint(_tracking);
    final destination = _destinationPoint(_tracking);
    final driver = _tracking?['driver'] is Map ? Map<String, dynamic>.from(_tracking!['driver'] as Map) : null;
    final center = driverPos ?? destination ?? _defaultCenter;
    final status = (_tracking?['status'] ?? '-').toString();

    return Scaffold(
      appBar: AppBar(title: Text('Commande #${widget.orderId}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(children: [
                    FlutterMap(
                      mapController: _map,
                      options: MapOptions(
                        initialCenter: center,
                        initialZoom: 15,
                        onPositionChanged: (_, byUser) {
                          if (byUser && _followDriver) setState(() => _followDriver = false);
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.ma3h.ma_livraison',
                        ),
                        if (driverPos != null && destination != null)
                          PolylineLayer(polylines: [
                            Polyline(points: [driverPos, destination], color: AppColors.primary, strokeWidth: 4),
                          ]),
                        MarkerLayer(markers: [
                          if (destination != null)
                            Marker(
                              point: destination,
                              width: 44,
                              height: 44,
                              child: const Icon(Icons.flag, size: 36, color: Colors.red),
                            ),
                          if (driverPos != null)
                            Marker(
                              point: driverPos,
                              width: 56,
                              height: 56,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary, width: 3),
                                  color: Colors.white,
                                ),
                                child: DriverAvatar(photo: driver?['photo_url']?.toString(), radius: 23),
                              ),
                            ),
                        ]),
                      ],
                    ),
                    if (!_followDriver && driverPos != null)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: FloatingActionButton.small(
                          onPressed: () {
                            setState(() => _followDriver = true);
                            _map.move(driverPos, 15);
                          },
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                  ]),
                ),
                Expanded(
                  flex: 2,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_error != null)
                        Card(color: Colors.orange.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!))),
                      Text(
                        'Statut : $status',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 10),
                      if (driver != null)
                        Card(
                          child: ListTile(
                            leading: DriverAvatar(photo: driver['photo_url']?.toString(), radius: 26),
                            title: Text((driver['name'] ?? 'Livreur').toString()),
                            subtitle: Text('${driver['telephone'] ?? driver['phone'] ?? ''}\n${_lastSeen(_tracking)}'),
                            isThreeLine: true,
                          ),
                        )
                      else
                        const Card(child: ListTile(leading: Icon(Icons.hourglass_empty), title: Text('Livreur en cours d’attribution'))),
                      if (driver != null && driverPos == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text('Le livreur n’a pas encore partagé sa position.', style: TextStyle(color: Colors.black54)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
