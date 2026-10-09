import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_colors.dart';
import '../../services/location_service.dart';

class PickedLocation {
  final double latitude;
  final double longitude;
  final String label;

  const PickedLocation({required this.latitude, required this.longitude, required this.label});
}

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key, required this.title, this.initialLocation});

  final String title;
  final PickedLocation? initialLocation;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late LatLng selected;
  bool locating = false;

  @override
  void initState() {
    super.initState();
    selected = widget.initialLocation == null
        ? const LatLng(9.3372, 2.6303)
        : LatLng(widget.initialLocation!.latitude, widget.initialLocation!.longitude);
  }

  Future<void> _useMyPosition() async {
    setState(() => locating = true);
    try {
      final p = await LocationService.currentPosition();
      if (!mounted) return;
      setState(() => selected = LatLng(p.latitude, p.longitude));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: selected,
                initialZoom: 15,
                onTap: (_, point) => setState(() => selected = point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ma3h.ma_livraison',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: selected,
                      width: 56,
                      height: 56,
                      child: const Icon(Icons.location_pin, size: 52, color: AppColors.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Position : ${selected.latitude.toStringAsFixed(6)}, ${selected.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Utiliser ma position',
                        onPressed: locating ? null : _useMyPosition,
                        icon: locating
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(
                        context,
                        PickedLocation(
                          latitude: selected.latitude,
                          longitude: selected.longitude,
                          label: 'Position GPS sélectionnée',
                        ),
                      ),
                      icon: const Icon(Icons.check),
                      label: const Text('Utiliser cette position'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
