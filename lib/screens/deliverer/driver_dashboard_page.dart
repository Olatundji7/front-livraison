import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/ma_api_service.dart';

class DriverDashboardPage extends StatefulWidget {
  const DriverDashboardPage({super.key});

  @override
  State<DriverDashboardPage> createState() => _DriverDashboardPageState();
}

class _DriverDashboardPageState extends State<DriverDashboardPage> {
  bool loading = true;
  List<OrderModel> orders = [];
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final data = await MaApiService(context.read<AuthProvider>().api).driverOrders();
      if (!mounted) return;
      setState(() { orders = data; loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { loading = false; error = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mes courses'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!)))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(18),
                    children: [
                      Card(
                        color: AppColors.primaryLight,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(children: [
                            const Icon(Icons.route),
                            const SizedBox(width: 12),
                            Expanded(child: Text('${orders.length} course(s) enregistrée(s).')),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (orders.isEmpty)
                        const Card(child: Padding(padding: EdgeInsets.all(18), child: Text('Aucune course pour le moment.'))),
                      ...orders.map(
                        (o) => Card(
                          child: ListTile(
                            leading: CircleAvatar(child: Icon(o.statut == 'livree' ? Icons.check : Icons.local_shipping)),
                            title: Text('Commande #${o.id}'),
                            subtitle: Text(
                              '${o.statut}\n'
                              '${o.pickupAdresse ?? '-'}'
                              '${o.destAdresse == null ? '' : ' → ${o.destAdresse}'}',
                            ),
                            isThreeLine: true,
                            trailing: o.distanceTravelledKm == null
                                ? null
                                : Text('${o.distanceTravelledKm!.toStringAsFixed(2)} km', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}