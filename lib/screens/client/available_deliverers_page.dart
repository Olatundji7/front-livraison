import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'client_order_form_page.dart';

/// Legacy entry kept for compatibility with older navigation.
/// The client no longer chooses a driver; MA Livraison manages assignment.
class AvailableDeliverersPage extends StatelessWidget {
  const AvailableDeliverersPage({super.key, required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final isDelivery = type == 'livraison';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isDelivery ? 'Nouvelle livraison' : 'Course personnelle'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.business_center_outlined, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Vous n’avez pas à choisir un livreur.',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Votre commande est reçue par MA Livraison. Notre équipe la traite et attribue ensuite la course à un livreur.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ClientOrderFormPage(type: type),
                          ),
                        );
                      },
                      child: const Text('Continuer ma commande'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
