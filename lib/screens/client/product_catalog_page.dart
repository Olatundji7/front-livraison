
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'cart_page.dart';

class ProductCatalogPage extends StatefulWidget {
  const ProductCatalogPage({super.key});

  @override
  State<ProductCatalogPage> createState() => _ProductCatalogPageState();
}

class _ProductCatalogPageState extends State<ProductCatalogPage> {
  List<Map<String, dynamic>> products = [];
  String query = '';
  String category = 'Toutes';
  bool loading = true;
  String? error;
  final Map<int, int> cart = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await context.read<AuthProvider>().api.request(
            'GET',
            '/products',
          );
      final list = (data['products'] as List?) ?? [];
      if (!mounted) return;
      setState(() {
        products =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  List<Map<String, dynamic>> get filtered {
    final q = query.trim().toLowerCase();
    return products.where((product) {
      final name = (product['name'] ?? '').toString().toLowerCase();
      final cat = (product['category'] ?? '').toString();
      final matchQuery = q.isEmpty || name.contains(q);
      final matchCategory = category == 'Toutes' || cat == category;
      return matchQuery && matchCategory;
    }).toList();
  }

  List<String> get categories {
    final result = <String>{'Toutes'};
    for (final product in products) {
      final value = product['category']?.toString().trim();
      if (value != null && value.isNotEmpty) result.add(value);
    }
    final list = result.toList();
    list.sort();
    return list;
  }

  void _add(Map<String, dynamic> product) {
    final id = _toInt(product['id']);
    if (id == null) return;
    setState(() => cart[id] = (cart[id] ?? 0) + 1);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product['name'] ?? 'Produit'} ajouté au panier.'),
      ),
    );
  }

  void _showDetails(Map<String, dynamic> product) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final image = product['image_url']?.toString();
        return AlertDialog(
          title: Text((product['name'] ?? 'Produit').toString()),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (image != null && image.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        image,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${product['price'] ?? 0} FCFA',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      (product['description'] ?? 'Aucune description.').toString(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Catégorie : ${product['category'] ?? 'Sans catégorie'}',
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Stock : ${product['stock'] ?? 0}'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fermer'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _add(product);
              },
              child: const Text('Ajouter au panier'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = cart.values.fold<int>(0, (sum, value) => sum + value);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Produits disponibles'),
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: 'Panier',
                onPressed: () async {
                  if (cart.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Votre panier est vide.')),
                    );
                    return;
                  }
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CartPage(
                        products: products
                            .where((p) => cart.containsKey(_toInt(p['id'])))
                            .map(
                              (p) => {
                                ...p,
                                'quantity': cart[_toInt(p['id'])] ?? 0,
                              },
                            )
                            .toList(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart_outlined),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6,
                  top: 4,
                  child: CircleAvatar(
                    radius: 9,
                    backgroundColor: Colors.red,
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Erreur : $error'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      TextField(
                        onChanged: (value) => setState(() => query = value),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher un produit',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 44,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 8),
                          itemBuilder: (_, index) {
                            final item = categories[index];
                            final selected = category == item;
                            return ChoiceChip(
                              label: Text(item),
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => category = item),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (filtered.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text('Aucun produit disponible.'),
                          ),
                        ),
                      ...filtered.map(
                        (product) => Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(10),
                            leading: _image(product),
                            title: Text(
                              (product['name'] ?? 'Produit').toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${product['category'] ?? 'Sans catégorie'}\n'
                              '${product['price'] ?? 0} FCFA • Stock ${product['stock'] ?? 0}',
                            ),
                            isThreeLine: true,
                            onTap: () => _showDetails(product),
                            trailing: IconButton(
                              tooltip: 'Ajouter',
                              onPressed: (_toInt(product['stock']) ?? 0) > 0
                                  ? () => _add(product)
                                  : null,
                              icon: const Icon(Icons.add_shopping_cart),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _image(Map<String, dynamic> product) {
    final url = product['image_url']?.toString();
    if (url != null && url.isNotEmpty) {
      return SizedBox(
        width: 74,
        height: 74,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(url, fit: BoxFit.cover),
        ),
      );
    }
    return const CircleAvatar(
      radius: 28,
      child: Icon(Icons.inventory_2_outlined),
    );
  }

  int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }
}
