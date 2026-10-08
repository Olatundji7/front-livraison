import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/app_colors.dart';
import '../../services/location_service.dart';

class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.initialPosition, required this.title});

  final LatLng? initialPosition;
  final String title;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  late LatLng selected;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    selected = widget.initialPosition ?? const LatLng(9.3372, 2.6303);
  }

  Future<void> _useMyLocation() async {
    setState(() => loading = true);
    try {
      final position = await LocationService.currentPosition();
      if (!mounted) return;
      setState(() => selected = LatLng(position.latitude, position.longitude));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          FlutterMap(
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
                    width: 48,
                    height: 48,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_outlined),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text('Touchez la carte pour choisir la position exacte.'),
                    ),
                    IconButton(
                      tooltip: 'Partager ma position',
                      onPressed: loading ? null : _useMyLocation,
                      icon: loading
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: FilledButton.icon(
              onPressed: () => Navigator.pop(context, selected),
              icon: const Icon(Icons.check),
              label: Text(
                'Utiliser cette position (${selected.latitude.toStringAsFixed(5)}, ${selected.longitude.toStringAsFixed(5)})',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
