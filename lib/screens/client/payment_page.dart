import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.orderId, this.initialAmount});

  final int orderId;
  final int? initialAmount;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool loading = false;
  bool checking = false;
  String? reference;
  String? paymentUrl;
  String status = 'non_paye';
  int amount = 0;
  String? message;

  @override
  void initState() {
    super.initState();
    amount = widget.initialAmount ?? 0;
    _initiate();
  }

  Future<void> _initiate() async {
    setState(() { loading = true; message = null; });
    try {
      final api = context.read<AuthProvider>().api;
      final data = await api.request(
        'POST',
        '/orders/${widget.orderId}/payment',
        authenticated: true,
      );
      final payment = Map<String, dynamic>.from(data['payment'] as Map);
      if (!mounted) return;
      setState(() {
        reference = payment['reference']?.toString();
        paymentUrl = payment['payment_url']?.toString();
        status = payment['status']?.toString() ?? 'pending';
        amount = (payment['amount'] is num) ? (payment['amount'] as num).toInt() : amount;
      });
    } catch (e) {
      if (mounted) setState(() => message = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openPayment() async {
    final url = paymentUrl;
    if (url == null || url.isEmpty) return;
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d’ouvrir la page de paiement.')),
      );
    }
  }

  Future<void> _refresh() async {
    final ref = reference;
    if (ref == null) return;
    setState(() => checking = true);
    try {
      final api = context.read<AuthProvider>().api;
      final data = await api.request(
        'GET',
        '/payments/$ref',
        authenticated: true,
      );
      final payment = Map<String, dynamic>.from(data['payment'] as Map);
      if (!mounted) return;
      setState(() => status = payment['status']?.toString() ?? status);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vérification impossible : $e')));
      }
    } finally {
      if (mounted) setState(() => checking = false);
    }
  }

  String _statusLabel() {
    switch (status) {
      case 'paid': return 'Paiement confirmé';
      case 'failed': return 'Paiement échoué';
      case 'cancelled': return 'Paiement annulé';
      default: return 'Paiement en attente';
    }
  }

  @override
  Widget build(BuildContext context) {
    final paid = status == 'paid';
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Paiement')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Récapitulatif du paiement', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text('Commande #${widget.orderId}'),
                  const SizedBox(height: 6),
                  Text('Montant : $amount FCFA', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(_statusLabel()),
                  if (reference != null) ...[
                    const SizedBox(height: 6),
                    Text('Référence : $reference', style: const TextStyle(color: Colors.black54)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (message != null)
            Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(16), child: Text(message!))),
          if (loading)
            const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
          else if (!paid) ...[
            FilledButton.icon(
              onPressed: paymentUrl == null ? null : _openPayment,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Payer maintenant'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: checking ? null : _refresh,
              icon: checking ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.refresh),
              label: const Text('Vérifier le paiement'),
            ),
          ] else
            const Card(
              color: Color(0xFFE8F5E9),
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 10), Expanded(child: Text('Votre paiement a été confirmé.'))]),
              ),
            ),
          const SizedBox(height: 18),
          const Text('Le paiement est traité par FedaPay. Les méthodes de paiement disponibles dépendent de votre compte marchand.', style: TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
