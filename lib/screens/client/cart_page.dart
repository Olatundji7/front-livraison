
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key, required this.products});

  final List<Map<String, dynamic>> products;

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late final List<Map<String, dynamic>> items;

  @override
  void initState() {
    super.initState();
    items = widget.products.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  int _price(Map<String, dynamic> p) => _toInt(p['price']) ?? 0;
  int _quantity(Map<String, dynamic> p) => _toInt(p['quantity']) ?? 0;

  int get subtotal => items.fold(
        0,
        (sum, item) => sum + (_price(item) * _quantity(item)),
      );

  void _change(int index, int delta) {
    final next = _quantity(items[index]) + delta;
    if (next <= 0) {
      setState(() => items.removeAt(index));
      return;
    }
    setState(() => items[index]['quantity'] = next);
  }

  @override
  Widget build(BuildContext context) {
    const deliveryFee = 100;
    final total = subtotal + (items.isEmpty ? 0 : deliveryFee);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon panier')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (items.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Votre panier est vide.'),
              ),
            ),
          ...List.generate(items.length, (index) {
            final item = items[index];
            final quantity = _quantity(item);
            return Card(
              child: ListTile(
                leading: _image(item),
                title: Text((item['name'] ?? 'Produit').toString()),
                subtitle: Text('${_price(item)} FCFA'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _change(index, -1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$quantity'),
                    IconButton(
                      onPressed: () => _change(index, 1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
            );
          }),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _line('Sous-total', subtotal),
                    _line('Frais de livraison', deliveryFee),
                    const Divider(),
                    _line('Total', total, bold: true),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Panier prêt pour le paiement : $total FCFA.',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.payment_outlined),
                        label: const Text('Passer au paiement'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _line(String label, int amount, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 18 : 15,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('$amount FCFA', style: style),
        ],
      ),
    );
  }

  Widget _image(Map<String, dynamic> p) {
    final url = p['image_url']?.toString();
    if (url != null && url.isNotEmpty) {
      return SizedBox(
        width: 54,
        height: 54,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(url, fit: BoxFit.cover),
        ),
      );
    }
    return const CircleAvatar(child: Icon(Icons.inventory_2_outlined));
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }
}
