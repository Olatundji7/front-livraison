import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import 'client_order_dashboard_page.dart';
import 'location_picker_page.dart';

class ClientOrderFormPage extends StatefulWidget {
  const ClientOrderFormPage({super.key, required this.type});
  final String type;

  @override
  State<ClientOrderFormPage> createState() => _ClientOrderFormPageState();
}

class _ClientOrderFormPageState extends State<ClientOrderFormPage> {
  final pickup = TextEditingController();
  final destination = TextEditingController();
  final note = TextEditingController();
  bool loading = false;
  LatLng? pickupPoint;
  LatLng? destinationPoint;

  bool get isDelivery => widget.type == 'livraison';

  @override
  void dispose() {
    pickup.dispose();
    destination.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _pickPickup() async {
    final point = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          title: isDelivery ? 'Choisir le départ' : 'Choisir la récupération',
          initialPosition: pickupPoint,
        ),
      ),
    );
    if (!mounted || point == null) return;
    setState(() {
      pickupPoint = point;
      if (pickup.text.trim().isEmpty) pickup.text = 'Position GPS sélectionnée';
    });
  }

  Future<void> _pickDestination() async {
    final point = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerPage(
          title: 'Choisir la réception',
          initialPosition: destinationPoint,
        ),
      ),
    );
    if (!mounted || point == null) return;
    setState(() {
      destinationPoint = point;
      if (destination.text.trim().isEmpty) destination.text = 'Position GPS sélectionnée';
    });
  }

  Future<void> submit() async {
    if (pickupPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez la position de départ ou de récupération sur la carte.')),
      );
      return;
    }
    if (pickup.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isDelivery ? 'Renseignez l’adresse de départ.' : 'Renseignez l’adresse de récupération.')),
      );
      return;
    }
    if (isDelivery && (destinationPoint == null || destination.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisissez et renseignez l’adresse de réception.')),
      );
      return;
    }

    setState(() => loading = true);
    try {
      final api = context.read<AuthProvider>().api;
      final body = <String, dynamic>{
        'type': isDelivery ? 'livraison' : 'course_personnelle',
        'pickup_address': pickup.text.trim(),
        'pickup_latitude': pickupPoint!.latitude,
        'pickup_longitude': pickupPoint!.longitude,
        'note': note.text.trim().isEmpty ? null : note.text.trim(),
      };
      if (isDelivery) {
        body.addAll({
          'destination_address': destination.text.trim(),
          'destination_latitude': destinationPoint!.latitude,
          'destination_longitude': destinationPoint!.longitude,
        });
      }

      final data = await api.request(
        'POST', '/orders', authenticated: true, body: body,
      );
      final order = Map<String, dynamic>.from(data['order'] as Map);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ClientOrderDashboardPage(orderId: _toInt(order['id'])),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      var message = 'Commande impossible.';
      if (e is ApiException && e.body is Map) {
        final body = Map<String, dynamic>.from(e.body as Map);
        message = body['message']?.toString() ?? message;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  Widget _locationField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onMap,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 56,
          child: FilledButton.tonalIcon(
            onPressed: onMap,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Carte'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final point = pickupPoint;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isDelivery ? 'Nouvelle livraison' : 'Course personnelle'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            color: AppColors.primaryLight,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.business_center_outlined),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Votre demande est envoyée à MA Livraison. Vous ne choisissez pas le livreur : les livreurs disponibles peuvent prendre la commande.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _locationField(
            controller: pickup,
            label: isDelivery ? 'Adresse de départ' : 'Adresse de récupération',
            icon: Icons.location_on_outlined,
            onMap: _pickPickup,
          ),
          if (isDelivery) ...[
            const SizedBox(height: 12),
            _locationField(
              controller: destination,
              label: 'Adresse de réception',
              icon: Icons.flag_outlined,
              onMap: _pickDestination,
            ),
          ],
          const SizedBox(height: 14),
          if (point != null)
            SizedBox(
              height: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: FlutterMap(
                  options: MapOptions(initialCenter: point, initialZoom: 15),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ma3h.ma_livraison',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 45,
                          height: 45,
                          child: const Icon(Icons.location_on, color: AppColors.primary, size: 42),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Instruction (facultatif)',
              prefixIcon: Icon(Icons.notes_outlined),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            color: AppColors.primaryLight,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.location_history_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isDelivery
                          ? 'Choisissez votre position comme dans une application de messagerie : appuyez sur Carte puis « Utiliser ma position ». Le livreur verra la position exacte après avoir accepté la commande.'
                          : 'Pour une course personnelle, seul le point de récupération est nécessaire.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: loading ? null : submit,
              icon: const Icon(Icons.send),
              label: loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Envoyer ma demande'),
            ),
          ),
        ],
      ),
    );
  }
}
