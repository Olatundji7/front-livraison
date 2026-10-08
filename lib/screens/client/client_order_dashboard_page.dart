import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';

class ClientOrderDashboardPage extends StatefulWidget {
  const ClientOrderDashboardPage({super.key, this.orderId});
  final int? orderId;
  @override
  State<ClientOrderDashboardPage> createState() => _ClientOrderDashboardPageState();
}
class _ClientOrderDashboardPageState extends State<ClientOrderDashboardPage> {
  Map<String, dynamic>? order;
  Map<String, dynamic>? tracking;
  Timer? timer;
  bool loading = true;
  @override
  void initState() { super.initState(); _load(); timer = Timer.periodic(const Duration(seconds: 5), (_) => _load(silent: true)); }
  @override
  void dispose() { timer?.cancel(); super.dispose(); }
  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => loading = true);
    try {
      final api = context.read<AuthProvider>().api;
      Map<String, dynamic>? current;
      if (widget.orderId != null) {
        final data = await api.request('GET', '/orders/${widget.orderId}', authenticated: true);
        current = data['order'] == null ? null : Map<String, dynamic>.from(data['order'] as Map);
      } else {
        final data = await api.request('GET', '/orders/active', authenticated: true);
        current = data['order'] == null ? null : Map<String, dynamic>.from(data['order'] as Map);
      }
      if (current != null) {
        final t = await api.request('GET', '/orders/${current['id']}/tracking', authenticated: true);
        if (mounted) setState(() { order = current; tracking = Map<String, dynamic>.from(t as Map); loading = false; });
      } else if (mounted) setState(() { order = null; loading = false; });
    } catch (e) { if (mounted && !silent) setState(() => loading = false); }
  }
  String label(String s) { const m = {'en_attente':'Demande reçue', 'livreur_reserve':'Commande attribuée','livreur_accepte':'Commande acceptée','en_cours':'En cours','colis_recupere':'Colis récupéré','en_livraison':'En livraison','livree':'Livrée','annulee':'Annulée','refusee':'Refusée'}; return m[s] ?? s; }
  Color color(String s) => s == 'livree' ? AppColors.success : s == 'annulee' || s == 'refusee' ? AppColors.danger : AppColors.primary;
  Future<void> cancel() async { final id = order?['id']; if (id == null) return; try { await context.read<AuthProvider>().api.request('POST', '/orders/$id/cancel', authenticated: true); await _load(); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Annulation impossible: $e'))); } }
  @override
  Widget build(BuildContext context) {
    if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final o = order;
    if (o == null) return Scaffold(appBar: AppBar(title: const Text('Ma commande')), body: const Center(child: Text('Aucune commande active.')));
    final status = (o['status'] ?? 'en_attente').toString();
    final loc = tracking?['driver_location'];
    return Scaffold(backgroundColor: AppColors.background, appBar: AppBar(title: Text('Commande #${o['id']}')), body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.all(20), children: [
      Card(color: color(status), child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Statut', style: TextStyle(color: Colors.white70)), const SizedBox(height: 6), Text(label(status), style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold))]))),
      const SizedBox(height: 16),
      Card(child: ListTile(leading: const Icon(Icons.location_on), title: const Text('Départ'), subtitle: Text((o['pickup_address'] ?? '-').toString()))),
      if ((o['destination_address'] ?? '').toString().trim().isNotEmpty) Card(child: ListTile(leading: const Icon(Icons.flag), title: const Text('Réception'), subtitle: Text((o['destination_address']).toString()))),
      if (o['driver'] is Map) Card(child: ListTile(leading: const Icon(Icons.delivery_dining), title: const Text('Livreur'), subtitle: Text((o['driver']['name'] ?? 'En cours d’attribution').toString()))) else Card(child: ListTile(leading: const Icon(Icons.business_center_outlined), title: const Text('Traitement'), subtitle: const Text('MA Livraison traite votre demande.'))),
      Card(child: ListTile(leading: const Icon(Icons.payments), title: const Text('Montant'), subtitle: Text(o['type'] == 'course_personnelle' && ((o['total'] ?? 0) == 0) ? 'Tarif à confirmer par MA Livraison' : '${o['total'] ?? 0} FCFA'))),
      if (loc is Map && loc['latitude'] != null) Card(child: ListTile(leading: const Icon(Icons.gps_fixed), title: const Text('Position du livreur'), subtitle: Text('${loc['latitude']}, ${loc['longitude']}'))),
      const SizedBox(height: 12),
      if (!['livree','annulee','refusee'].contains(status)) OutlinedButton.icon(onPressed: cancel, icon: const Icon(Icons.cancel_outlined), label: const Text('Annuler la commande')),
    ])));
  }
}
