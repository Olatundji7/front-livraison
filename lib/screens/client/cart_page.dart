import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import 'client_order_dashboard_page.dart';
import 'map_picker_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  Map<String, dynamic>? data;
  bool loading = true;
  bool checkoutLoading = false;
  String? error;

  final destination = TextEditingController();
  final note = TextEditingController();
  PickedLocation? destinationLocation;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    destination.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final api = context.read<AuthProvider>().api;
      final result = await api.request('GET', '/cart', authenticated: true);
      if (!mounted) return;
      setState(() { data = Map<String, dynamic>.from(result as Map); loading = false; error = null; });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

  List<Map<String, dynamic>> get items => ((data?['cart'] as Map?)?['items'] as List? ?? [])
      .map((e) => Map<String, dynamic>.from(e as Map)).toList();

  int get subtotal => _toInt((data?['cart'] as Map?)?['subtotal']);
  int _toInt(Object? v) => v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  Future<void> _update(int id, int quantity) async {
    try {
      final api = context.read<AuthProvider>().api;
      if (quantity <= 0) {
        await api.request('DELETE', '/cart/items/$id', authenticated: true);
      } else {
        await api.request('PATCH', '/cart/items/$id', authenticated: true, body: {'quantity': quantity});
      }
      await _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Panier : $e')));
    }
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
      if (destination.text.trim().isEmpty) destination.text = result.label;
    });
  }

  Future<void> _checkout() async {
    if (items.isEmpty) return;
    if (destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Indiquez votre position de livraison sur la carte.')));
      return;
    }
    final instruction = note.text.trim();
    if (instruction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('L’instruction est obligatoire. Décrivez les produits souhaités et toute précision utile.')));
      return;
    }
    setState(() => checkoutLoading = true);
    try {
      final api = context.read<AuthProvider>().api;
      final response = await api.request('POST', '/cart/checkout', authenticated: true, body: {
        'destination_address': destination.text.trim().isEmpty ? destinationLocation!.label : destination.text.trim(),
        'destination_latitude': destinationLocation!.latitude,
        'destination_longitude': destinationLocation!.longitude,
        'note': instruction,
      });
      final order = Map<String, dynamic>.from(response['order'] as Map);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ClientOrderDashboardPage(orderId: _toInt(order['id']))));
    } catch (e) {
      var message = 'Impossible de finaliser le panier.';
      if (e is ApiException && e.body is Map) message = Map<String, dynamic>.from(e.body as Map)['message']?.toString() ?? message;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => checkoutLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon panier')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('Erreur : $error')))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (items.isEmpty)
                        const Card(child: Padding(padding: EdgeInsets.all(24), child: Text('Votre panier est vide.'))),
                      ...items.map((item) => Card(
                        child: ListTile(
                          leading: _productImage(item['product'] as Map?),
                          title: Text(((item['product'] as Map?)?['name'] ?? 'Produit').toString()),
                          subtitle: Text('${_toInt((item['product'] as Map?)?['price'])} FCFA\nSous-total ligne : ${_toInt(item['line_total'])} FCFA'),
                          isThreeLine: true,
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            IconButton(onPressed: () => _update(_toInt(item['id']), _toInt(item['quantity']) - 1), icon: const Icon(Icons.remove_circle_outline)),
                            Text('${_toInt(item['quantity'])}'),
                            IconButton(onPressed: () => _update(_toInt(item['id']), _toInt(item['quantity']) + 1), icon: const Icon(Icons.add_circle_outline)),
                          ]),
                        ),
                      )),
                      if (items.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                          _line('Sous-total produits', subtotal),
                          const Align(alignment: Alignment.centerLeft, child: Padding(padding: EdgeInsets.only(top: 8), child: Text('Les frais de livraison seront calculés à partir de la distance réellement parcourue. Les 100 FCFA de service sont ajoutés séparément.'))),
                        ]))),
                        const SizedBox(height: 12),
                        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [const Expanded(child: Text('Votre position de livraison', style: TextStyle(fontWeight: FontWeight.bold))), FilledButton.tonalIcon(onPressed: _pickDestination, icon: const Icon(Icons.map_outlined), label: const Text('Carte'))]),
                          TextField(controller: destination, decoration: const InputDecoration(labelText: 'Adresse / repère', hintText: 'Ex. maison bleue près du marché...')),
                          const SizedBox(height: 14),
                          TextField(
                            controller: note,
                            minLines: 4,
                            maxLines: 7,
                            maxLength: 1000,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Instruction *',
                              hintText: 'Ex: description de votre commande.',
                              helperText: 'Décrivez les produits souhaités et toute précision utile pour le livreur.',
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(bottom: 48),
                                child: Icon(Icons.notes_outlined),
                              ),
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ]))),
                        const SizedBox(height: 14),
                        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: checkoutLoading ? null : _checkout, icon: checkoutLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.shopping_bag_outlined), label: const Text('Finaliser ma commande'))),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _line(String label, int amount) => Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))), Text('$amount FCFA', style: const TextStyle(fontWeight: FontWeight.bold))]);

  Widget _productImage(Map? product) {
    final raw = product?['image_url']?.toString();
    final url = context.read<AuthProvider>().api.mediaUrl(raw);
    if (url == null) return const CircleAvatar(child: Icon(Icons.inventory_2_outlined));
    return SizedBox(width: 56, height: 56, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined))));
  }
}
