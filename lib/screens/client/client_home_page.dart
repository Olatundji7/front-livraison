import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'client_order_form_page.dart';
import 'client_order_dashboard_page.dart';
import 'product_catalog_page.dart';

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key, required this.clientName});
  final String clientName;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('MA Livraison'), actions: [IconButton(onPressed: () => context.read<AuthProvider>().logout(), icon: const Icon(Icons.logout))]),
    backgroundColor: AppColors.background,
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Card(color: AppColors.primary, child: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Bonjour 👋', style: TextStyle(color: Colors.white70)), const SizedBox(height: 5), Text(clientName, style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.bold)), const SizedBox(height: 8), const Text('Que souhaitez-vous faire ?', style: TextStyle(color: Colors.white))]))),
      const SizedBox(height: 24),
      _action(context, Icons.local_shipping, 'Se faire livrer', 'Déposer une demande de livraison.', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientOrderFormPage(type: 'livraison')))),
      _action(context, Icons.directions_car, 'Course personnelle', 'Déposer une demande de course personnelle.', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientOrderFormPage(type: 'course_personnelle')))),
      _action(context, Icons.receipt_long, 'Ma commande active', 'Suivre le statut de votre commande.', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientOrderDashboardPage()))),
      _action(context, Icons.storefront, 'Produits disponibles', 'Consulter le catalogue.', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductCatalogPage()))),
    ]),
  );
  Widget _action(BuildContext context, IconData icon, String title, String text, VoidCallback onTap) => Card(child: ListTile(contentPadding: const EdgeInsets.all(16), leading: CircleAvatar(backgroundColor: AppColors.primaryLight, child: Icon(icon, color: AppColors.primary)), title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(text), trailing: const Icon(Icons.chevron_right), onTap: onTap));
}
