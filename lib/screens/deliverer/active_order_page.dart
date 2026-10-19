import 'package:flutter/material.dart';

import '../../services/mock_driver_service.dart';

/// Détail et suivi d'une course du livreur.
/// Le suivi cartographique réel nécessite d'ajouter/configurer un plugin de carte
/// (Google Maps ou OpenStreetMap) et une source GPS active.
class ActiveOrderPage extends StatelessWidget {
  const ActiveOrderPage({super.key, required this.order});

  final Map<String, dynamic> order;
  static const Color _blue = Color(0xFF1565C0);

  int _asInt(dynamic value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
  double _asDouble(dynamic value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  String _money(dynamic value) => '${_asInt(value).toString()} F CFA';

  @override
  Widget build(BuildContext context) {
    final service = MockDriverService.instance;
    final orderId = _asInt(order['id']);

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        final liveOrder = service.activeOrder;
        final current = liveOrder != null && _asInt(liveOrder['id']) == orderId
            ? liveOrder
            : order;
        final status = (current['statut'] ?? 'en_attente').toString();
        final canStart = status == 'traitee';
        final canFinish = status == 'en_cours';
        final distance = _asDouble(current['distance_km']);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Suivi de la course'),
            backgroundColor: _blue,
            foregroundColor: Colors.white,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _statusBanner(status),
              const SizedBox(height: 16),
              _sectionCard(
                title: 'Informations du client',
                icon: Icons.person_outline,
                children: [
                  _detailRow('Nom', '${current['client'] ?? 'Client'}'),
                  _detailRow('Téléphone', '${current['telephone_client'] ?? 'Non renseigné'}'),
                  _detailRow('Type', '${current['type'] ?? 'Livraison'}'),
                ],
              ),
              const SizedBox(height: 12),
              _sectionCard(
                title: 'Itinéraire',
                icon: Icons.route_outlined,
                children: [
                  _addressRow(Icons.radio_button_checked, 'Point de retrait', '${current['pickup_adresse'] ?? 'Non renseigné'}'),
                  const Divider(height: 22),
                  _addressRow(Icons.location_on, 'Destination', '${current['dest_adresse'] ?? 'Non renseignée'}'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.straighten, color: _blue),
                      const SizedBox(width: 8),
                      Text('${distance.toStringAsFixed(2)} km'),
                      const Spacer(),
                      Text(_money(current['prix_estime']), style: const TextStyle(fontWeight: FontWeight.bold, color: _blue)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.map_outlined, color: _blue),
                        SizedBox(width: 8),
                        Expanded(child: Text('Carte : les adresses et coordonnées sont disponibles. Pour afficher la position GPS du client en direct, il faut connecter le widget de carte et actualiser sa position depuis l’API.')),
                      ],
                    ),
                  ),
                ],
              ),
              if ((current['note'] ?? '').toString().trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _sectionCard(
                  title: 'Note du client',
                  icon: Icons.notes,
                  children: [Text('${current['note']}')],
                ),
              ],
              const SizedBox(height: 20),
              if (canStart)
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: _blue, foregroundColor: Colors.white),
                    onPressed: () {
                      final ok = service.startOrder(orderId);
                      _showMessage(context, ok ? 'Course démarrée.' : 'Impossible de démarrer cette course.');
                    },
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Démarrer la course'),
                  ),
                ),
              if (canFinish)
                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700, foregroundColor: Colors.white),
                    onPressed: () => _confirmFinish(context, service, orderId),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmer la livraison'),
                  ),
                ),
              if (status == 'livree')
                const Center(child: Chip(avatar: Icon(Icons.check_circle, color: Colors.green), label: Text('Course terminée'))),
            ],
          ),
        );
      },
    );
  }

  Widget _statusBanner(String status) {
    final labels = <String, String>{
      'en_attente': 'En attente d’acceptation',
      'traitee': 'Commande acceptée — prête à démarrer',
      'en_cours': 'Course en cours',
      'livree': 'Livraison terminée',
    };
    final color = status == 'livree' ? Colors.green : status == 'en_cours' ? Colors.orange.shade800 : _blue;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(14)),
      child: Row(children: [Icon(Icons.local_shipping_outlined, color: color, size: 30), const SizedBox(width: 12), Expanded(child: Text(labels[status] ?? status, style: TextStyle(color: color, fontWeight: FontWeight.bold))) ]),
    );
  }

  Widget _sectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Icon(icon, color: _blue), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))]),
          const SizedBox(height: 14),
          ...children,
        ]),
      ),
    );
  }

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.black54))), Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)))]),
  );

  Widget _addressRow(IconData icon, String label, String address) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [Icon(icon, color: _blue), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)), const SizedBox(height: 3), Text(address, style: const TextStyle(fontWeight: FontWeight.w500))]))],
  );

  Future<void> _confirmFinish(BuildContext context, MockDriverService service, int orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la livraison'),
        content: const Text('Confirmez-vous que le colis a été remis au client ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmer')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = service.finishOrder(orderId);
    _showMessage(context, ok ? 'Livraison enregistrée.' : 'Impossible de terminer cette course.');
    if (ok && context.mounted) Navigator.pop(context);
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
