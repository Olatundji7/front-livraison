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
  final destination = TextEditingController();
  final note = TextEditingController();

  PickedLocation? destinationLocation;
  bool loading = false;

  bool get isDelivery => widget.type == 'livraison';

  @override
  void dispose() {
    destination.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _pickDestination() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          title: 'Choisir votre position de livraison',
          initialLocation: destinationLocation,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      destinationLocation = result;
      if (destination.text.trim().isEmpty) {
        destination.text = result.label;
      }
    });
  }

  Future<void> _submit() async {
    if (destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indiquez votre position sur la carte.')),
      );
      return;
    }

    final instruction = note.text.trim();
    if (instruction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L’instruction est obligatoire. Indiquez ce que vous souhaitez commander et toute précision utile.')),
      );
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
          'destination_address': destination.text.trim().isEmpty
              ? destinationLocation!.label
              : destination.text.trim(),
          'destination_latitude': destinationLocation!.latitude,
          'destination_longitude': destinationLocation!.longitude,
          'note': instruction,
        },
      );
      final order = OrderModel.fromJson(
        Map<String, dynamic>.from(data['order'] as Map),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ClientOrderDashboardPage(orderId: order.id),
        ),
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

  Widget _destinationCard() {
    final loc = destinationLocation;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Votre position de livraison',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: _pickDestination,
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Carte'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: destination,
              decoration: const InputDecoration(
                labelText: 'Adresse / repère',
                hintText: 'Ex. maison bleue près du marché...',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            if (loc != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 150,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(loc.latitude, loc.longitude),
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.ma3h.ma_livraison',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(loc.latitude, loc.longitude),
                            width: 45,
                            height: 45,
                            child: const Icon(
                              Icons.location_pin,
                              color: AppColors.primary,
                              size: 42,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            ] else
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Appuyez sur « Carte » puis « Utiliser ma position » ou touchez la carte pour placer votre position exacte.',
                  ),
                ),
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
      appBar: AppBar(
        title: Text(isDelivery ? 'Nouvelle livraison' : 'Course personnelle'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppColors.primaryLight,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Indiquez simplement où vous souhaitez être livré et décrivez votre demande. Le livreur est choisi automatiquement selon les disponibilités.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _destinationCard(),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            minLines: 4,
            maxLines: 7,
            maxLength: 1000,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Instruction *',
              hintText: 'Ex: description de votre commande.',
              helperText: 'Décrivez ce que vous souhaitez commander et toute précision utile pour le livreur.',
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Icons.notes_outlined),
              ),
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppColors.primaryLight,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Les frais de livraison seront calculés à partir de la distance réellement parcourue par le livreur. Les 100 FCFA de service MA Livraison sont ajoutés séparément. Au-delà de 3 km, la réduction prévue s’applique.',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Envoyer ma demande'),
            ),
          ),
        ],
      ),
    );
  }
}
