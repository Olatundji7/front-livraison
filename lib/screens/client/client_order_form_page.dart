import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import 'client_order_dashboard_page.dart';
import 'map_picker_page.dart';

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

  PickedLocation? pickupLocation;
  PickedLocation? destinationLocation;
  bool loading = false;

  bool get isDelivery => widget.type == 'livraison';

  @override
  void dispose() {
    pickup.dispose();
    destination.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _pickLocation({required bool pickupMode}) async {
    final current = pickupMode ? pickupLocation : destinationLocation;
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          title: pickupMode ? 'Choisir la position de départ' : 'Choisir la position de réception',
          initialLocation: current,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      if (pickupMode) {
        pickupLocation = result;
        if (pickup.text.trim().isEmpty) pickup.text = result.label;
      } else {
        destinationLocation = result;
        if (destination.text.trim().isEmpty) destination.text = result.label;
      }
    });
  }

  Future<void> _submit() async {
    if (pickupLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisissez le point de départ sur la carte.')));
      return;
    }
    if (isDelivery && destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Choisissez le point de réception sur la carte.')));
      return;
    }

    setState(() => loading = true);
    try {
      final api = context.read<AuthProvider>().api;
      final data = await api.request(
        'POST',
        '/orders',
        authenticated: true,
        body: {
          'type': widget.type,
          'pickup_address': pickup.text.trim().isEmpty ? pickupLocation!.label : pickup.text.trim(),
          'pickup_latitude': pickupLocation!.latitude,
          'pickup_longitude': pickupLocation!.longitude,
          if (isDelivery) 'destination_address': destination.text.trim().isEmpty ? destinationLocation!.label : destination.text.trim(),
          if (isDelivery) 'destination_latitude': destinationLocation!.latitude,
          if (isDelivery) 'destination_longitude': destinationLocation!.longitude,
          'note': note.text.trim().isEmpty ? null : note.text.trim(),
        },
      );
      final order = OrderModel.fromJson(Map<String, dynamic>.from(data['order'] as Map));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ClientOrderDashboardPage(orderId: order.id)),
      );
    } catch (e) {
      if (!mounted) return;
      var message = 'Commande impossible.';
      if (e is ApiException && e.body is Map) {
        message = Map<String, dynamic>.from(e.body as Map)['message']?.toString() ?? message;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Widget _locationCard({required bool pickupMode}) {
    final loc = pickupMode ? pickupLocation : destinationLocation;
    final title = pickupMode
        ? (isDelivery ? 'Adresse de départ' : 'Adresse de récupération')
        : 'Adresse de réception';
    final controller = pickupMode ? pickup : destination;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Icon(pickupMode ? Icons.location_on : Icons.flag, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
                FilledButton.tonalIcon(
                  onPressed: () => _pickLocation(pickupMode: pickupMode),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Carte'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Vous pouvez préciser une adresse / repère',
                prefixIcon: const Icon(Icons.place_outlined),
              ),
            ),
            if (loc != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(initialCenter: LatLng(loc.latitude, loc.longitude), initialZoom: 15),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.ma3h.ma_livraison'),
                      MarkerLayer(markers: [Marker(point: LatLng(loc.latitude, loc.longitude), width: 45, height: 45, child: const Icon(Icons.location_pin, color: AppColors.primary, size: 42))]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(alignment: Alignment.centerLeft, child: Text('${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}', style: const TextStyle(color: Colors.black54))),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Align(alignment: Alignment.centerLeft, child: Text('Appuyez sur « Carte » puis « Utiliser ma position » ou touchez la carte pour placer le point exact.')),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(isDelivery ? 'Nouvelle livraison' : 'Course personnelle')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.primaryLight,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(children: [Icon(Icons.near_me_outlined), SizedBox(width: 10), Expanded(child: Text('Vous ne choisissez pas de livreur. La commande est publiée et un livreur disponible peut l’accepter directement.'))]),
            ),
          ),
          const SizedBox(height: 12),
          _locationCard(pickupMode: true),
          if (isDelivery) ...[
            const SizedBox(height: 12),
            _locationCard(pickupMode: false),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: note,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Instruction (facultatif)', prefixIcon: Icon(Icons.notes_outlined), alignLabelWithHint: true),
          ),
          const SizedBox(height: 12),
          Card(
            color: AppColors.primaryLight,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(children: [Icon(Icons.payments_outlined), SizedBox(width: 10), Expanded(child: Text('Le prix de la course est calculé côté serveur selon la distance réellement parcourue. Au-delà de 3 km, une réduction de 20 % s’applique.'))]),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: loading ? null : _submit,
              child: loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Envoyer ma demande'),
            ),
          ),
        ],
      ),
    );
  }
}
