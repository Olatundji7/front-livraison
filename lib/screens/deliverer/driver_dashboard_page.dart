import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Tableau de bord branché sur les données Laravel réelles, pas sur le service mock.
class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _driver = {};
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _orders = [];

  int _int(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  double _double(Object? value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
  String _money(Object? value) => '${_int(value)} FCFA';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final api = context.read<AuthProvider>().api;
      final response = await api.request('GET', '/driver/dashboard', authenticated: true);
      final data = Map<String, dynamic>.from(response as Map);
      if (!mounted) return;
      setState(() {
        _driver = data['driver'] is Map ? Map<String, dynamic>.from(data['driver'] as Map) : {};
        _stats = data['stats'] is Map ? Map<String, dynamic>.from(data['stats'] as Map) : {};
        _orders = ((data['orders'] as List?) ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Impossible de charger votre profil et vos gains. $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<AuthProvider>().api;
    final user = _driver['user'] is Map ? Map<String, dynamic>.from(_driver['user'] as Map) : <String, dynamic>{};
    final name = (user['name'] ?? context.watch<AuthProvider>().user?.nom ?? 'Livreur').toString();
    final phone = (_driver['telephone'] ?? user['phone'] ?? 'Téléphone non renseigné').toString();
    final photoUrl = api.mediaUrl(_driver['photo_url']?.toString() ?? _driver['photo']?.toString());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(title: const Text('Mon profil livreur'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(16), children: [
                if (_error != null) Card(color: Colors.red.shade50, child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!))),
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.blue.shade50,
                        child: ClipOval(
                          child: photoUrl == null
                              ? const Icon(Icons.person, size: 44, color: AppColors.primary)
                              : Image.network(
                                  photoUrl,
                                  key: ValueKey(photoUrl),
                                  width: 84,
                                  height: 84,
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.medium,
                                  loadingBuilder: (context, child, progress) => progress == null
                                      ? child
                                      : const SizedBox(
                                          width: 84,
                                          height: 84,
                                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                        ),
                                  errorBuilder: (_, error, __) => const Icon(
                                    Icons.person,
                                    size: 44,
                                    color: AppColors.primary,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 5),
                        Text(phone, style: const TextStyle(color: Colors.black54)),
                        const SizedBox(height: 5),
                        Text('Statut : ${(_driver['status'] ?? 'hors_ligne').toString()}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ])),
                    ]),
                  ),
                ),
                const SizedBox(height: 14),
                GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width >= 650 ? 4 : 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.35,
                  children: [
                    _stat(Icons.check_circle_outline, 'Courses terminées', '${_int(_stats['completed_count'])}', Colors.green),
                    _stat(Icons.account_balance_wallet_outlined, 'Gains cumulés', _money(_stats['cumulative_earnings']), AppColors.primary),
                    _stat(Icons.payments_outlined, 'Gains des courses livrées', _money(_stats['completed_earnings']), Colors.teal),
                    _stat(Icons.route_outlined, 'Distance livrée', '${_double(_stats['total_distance_km']).toStringAsFixed(2)} km', Colors.deepOrange),
                  ],
                ),
                const SizedBox(height: 22),
                const Text('Historique des livraisons', style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (_orders.isEmpty)
                  const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Aucune livraison terminée pour le moment.')))
                else
                  ..._orders.map(_orderCard),
                const SizedBox(height: 10),
                const Text('Les gains affichés sont enregistrés à la validation de la commande. La réduction accordée au client ne réduit pas le gain brut du livreur.', style: TextStyle(color: Colors.black54)),
              ]),
            ),
    );
  }

  Widget _stat(IconData icon, String label, String value, Color color) => Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
        ])),
      );

  Widget _orderCard(Map<String, dynamic> order) => Card(
        margin: const EdgeInsets.only(bottom: 9),
        child: ListTile(
          leading: const CircleAvatar(child: Icon(Icons.local_shipping_outlined)),
          title: Text('Livraison #${order['id'] ?? '—'}'),
          subtitle: Text('${order['destination_address'] ?? 'Destination non renseignée'}\nDistance : ${_double(order['distance_travelled_km']).toStringAsFixed(2)} km'),
          isThreeLine: true,
          trailing: Text(_money(order['driver_earnings'] ?? order['gross_delivery_fee']), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
        ),
      );
}
