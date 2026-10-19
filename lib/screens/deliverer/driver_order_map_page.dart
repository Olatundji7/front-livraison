import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../models/order_model.dart';
import '../../services/location_service.dart';

/// Carte de la course côté livreur : sa position en direct, le point du client
/// et la distance restante.
class DriverOrderMapPage extends StatefulWidget {
  const DriverOrderMapPage({super.key, required this.order});
  final OrderModel order;

  @override
  State<DriverOrderMapPage> createState() => _DriverOrderMapPageState();
}

class _DriverOrderMapPageState extends State<DriverOrderMapPage> {
  static const _fallbackCenter = LatLng(9.3372, 2.6303);

  final MapController _map = MapController();
  StreamSubscription<Position>? _sub;
  LatLng? _me;
  bool _follow = true;
  String? _gpsError;

  // Itinéraire routier (serveur public OSRM). Pour la production, prévoir un
  // service dédié (OSRM hébergé, OpenRouteService, Mapbox...) : le serveur de
  // démonstration n'a aucune garantie de disponibilité.
  static const _routingBase = 'https://router.project-osrm.org/route/v1/driving';
  List<LatLng> _route = [];
  double? _routeKm;
  double? _routeMin;
  LatLng? _routeFrom;
  DateTime _routeAt = DateTime.fromMillisecondsSinceEpoch(0);
  bool _fetchingRoute = false;
  bool _routeFailed = false;

  OrderModel get order => widget.order;

  LatLng? get _pickup => order.pickupLat != null && order.pickupLng != null
      ? LatLng(order.pickupLat!, order.pickupLng!)
      : null;
  LatLng? get _destination => order.destLat != null && order.destLng != null
      ? LatLng(order.destLat!, order.destLng!)
      : null;

  @override
  void initState() {
    super.initState();
    _startGps();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _map.dispose();
    super.dispose();
  }

  Future<void> _startGps() async {
    try {
      final first = await LocationService.currentPosition();
      _onPosition(first);
      _sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen(_onPosition, onError: (Object e) {
        if (mounted) setState(() => _gpsError = '$e');
      });
    } catch (e) {
      if (mounted) setState(() => _gpsError = '$e');
    }
  }

  void _onPosition(Position p) {
    if (!mounted) return;
    final point = LatLng(p.latitude, p.longitude);
    setState(() {
      _me = point;
      _gpsError = null;
    });
    _refreshRoute(point);
    if (_follow) {
      try {
        _map.move(point, _map.camera.zoom);
      } catch (_) {
        // Carte pas encore prête : le centre initial sera utilisé.
      }
    }
  }

  /// Recalcule l'itinéraire au premier fix, puis quand le livreur s'est
  /// déplacé de plus de 80 m (il a pu quitter le chemin) ou toutes les 60 s.
  Future<void> _refreshRoute(LatLng from) async {
    final dest = _destination;
    if (dest == null || _fetchingRoute) return;
    final moved = _routeFrom == null
        ? double.infinity
        : const Distance().as(LengthUnit.Meter, _routeFrom!, from);
    final age = DateTime.now().difference(_routeAt).inSeconds;
    if (_route.isNotEmpty && moved < 80 && age < 60) return;
    if (age < 8) return; // limite le nombre d'appels

    _fetchingRoute = true;
    _routeAt = DateTime.now();
    try {
      final uri = Uri.parse(
        '$_routingBase/${from.longitude},${from.latitude};${dest.longitude},${dest.latitude}'
        '?overview=full&geometries=geojson',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final r = routes.first as Map<String, dynamic>;
          final coords = (r['geometry']['coordinates'] as List)
              .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
              .toList();
          if (mounted) {
            setState(() {
              _route = coords;
              _routeKm = (r['distance'] as num).toDouble() / 1000;
              _routeMin = (r['duration'] as num).toDouble() / 60;
              _routeFrom = from;
              _routeFailed = false;
            });
          }
        } else if (mounted) {
          setState(() => _routeFailed = true);
        }
      } else if (mounted) {
        setState(() => _routeFailed = true);
      }
    } catch (e) {
      debugPrint('Itinéraire indisponible : $e');
      if (mounted) setState(() => _routeFailed = true);
    } finally {
      _fetchingRoute = false;
    }
  }

  String? _remaining() {
    final me = _me;
    final dest = _destination;
    if (me == null || dest == null) return null;
    final km = _routeKm ?? const Distance().as(LengthUnit.Kilometer, me, dest);
    final dist = km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
    if (_routeKm == null || _routeMin == null) return '$dist (à vol d’oiseau)';
    return '$dist · environ ${_routeMin!.ceil()} min';
  }

  Future<void> _openNavigation() async {
    final dest = _destination;
    if (dest == null) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}&travelmode=driving',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir l’application de navigation.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pickup = _pickup;
    final destination = _destination;
    final me = _me;
    final center = me ?? destination ?? pickup ?? _fallbackCenter;
    final remaining = _remaining();

    return Scaffold(
      appBar: AppBar(title: Text('Commande #${order.id}')),
      body: Column(children: [
        Expanded(
          child: Stack(children: [
            FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                onPositionChanged: (_, byUser) {
                  if (byUser && _follow) setState(() => _follow = false);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ma3h.ma_livraison',
                ),
                if (me != null && destination != null)
                  PolylineLayer(polylines: [
                    Polyline(
                      points: _route.length >= 2 ? _route : [me, destination],
                      color: AppColors.primary,
                      strokeWidth: 5,
                    ),
                  ]),
                MarkerLayer(markers: [
                  if (pickup != null)
                    Marker(point: pickup, width: 44, height: 44, child: const Icon(Icons.location_pin, size: 40, color: AppColors.primary)),
                  if (destination != null)
                    Marker(point: destination, width: 44, height: 44, child: const Icon(Icons.flag, size: 36, color: Colors.red)),
                  if (me != null)
                    Marker(
                      point: me,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: AppColors.primary, width: 3),
                        ),
                        child: const Icon(Icons.delivery_dining, color: AppColors.primary),
                      ),
                    ),
                ]),
              ],
            ),
            if (!_follow && me != null)
              Positioned(
                right: 12,
                bottom: 12,
                child: FloatingActionButton.small(
                  onPressed: () {
                    setState(() => _follow = true);
                    _map.move(me, 15);
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),
          ]),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_gpsError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('GPS indisponible : $_gpsError', style: const TextStyle(color: Colors.red)),
                )
              else if (me == null)
                const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Recherche de votre position…')),
              if (_routeFailed && _route.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6),
                  child: Text('Itinéraire routier indisponible (internet ou service) : ligne droite affichée.', style: TextStyle(color: Colors.orange)),
                ),
              if (remaining != null)
                Text('Reste à parcourir : $remaining', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (order.destAdresse != null && order.destAdresse!.trim().isNotEmpty)
                Padding(padding: const EdgeInsets.only(top: 6), child: Text('Destination : ${order.destAdresse}')),
              const SizedBox(height: 6),
              const Text('Le drapeau rouge est la position GPS indiquée par le client.', style: TextStyle(color: Colors.black54)),
              if (destination != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openNavigation,
                    icon: const Icon(Icons.navigation_outlined),
                    label: const Text('Lancer la navigation'),
                  ),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}
