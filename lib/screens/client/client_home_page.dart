import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/ma_api_service.dart';
import '../../widgets/brand_logo.dart';
import '../home/publicity_page.dart';
import 'client_order_dashboard_page.dart';
import 'client_order_form_page.dart';
import 'edit_profile_page.dart';
import 'payment_page.dart';
import 'product_catalog_page.dart';

/// Espace client : trois onglets en bas de l'écran (Accueil, Commandes, Profil).
/// Sur grand écran (web / tablette), les onglets sont affichés dans la barre du haut.
class ClientHomePage extends StatefulWidget {
  const ClientHomePage({super.key, required this.clientName});

  final String clientName;

  @override
  State<ClientHomePage> createState() => _ClientHomePageState();
}

class _ClientHomePageState extends State<ClientHomePage> {
  int _index = 0;

  static const _items = [
    (Icons.home_outlined, Icons.home, 'Accueil'),
    (Icons.receipt_long_outlined, Icons.receipt_long, 'Commandes'),
    (Icons.person_outline, Icons.person, 'Profil'),
  ];

  Widget _tab() {
    switch (_index) {
      case 1:
        return const _OrdersTab(key: ValueKey('orders'));
      case 2:
        return const _ProfileTab(key: ValueKey('profile'));
      default:
        return _HomeTab(
          key: const ValueKey('home'),
          name: widget.clientName,
          onStart: () => setState(() => _index = 1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 800;
    final body = _tab();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: const BrandLogo(size: 42),
        actions: wide
            ? [
                for (var i = 0; i < _items.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: TextButton.icon(
                      onPressed: () => setState(() => _index = i),
                      icon: Icon(
                        _index == i ? _items[i].$2 : _items[i].$1,
                        size: 19,
                      ),
                      label: Text(_items[i].$3),
                      style: TextButton.styleFrom(
                        foregroundColor: _index == i ? AppColors.primary : AppColors.text,
                        backgroundColor: _index == i ? AppColors.primaryLight : Colors.transparent,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                  ),
                const SizedBox(width: 18),
              ]
            : null,
      ),
      body: body,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              backgroundColor: Colors.white,
              indicatorColor: AppColors.primaryLight,
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              destinations: [
                for (final item in _items)
                  NavigationDestination(
                    icon: Icon(item.$1),
                    selectedIcon: Icon(item.$2, color: AppColors.primary),
                    label: item.$3,
                  ),
              ],
            ),
    );
  }
}

// ───────────────────────── Accueil ─────────────────────────

/// Écran d'accueil : photo de l'équipe en haut, fondu vers le bleu de la marque,
/// quelques messages et un seul bouton. La liste des actions est dans « Commandes ».
class _HomeTab extends StatelessWidget {
  const _HomeTab({super.key, required this.name, required this.onStart});

  final String name;
  final VoidCallback onStart;

  static const _background = 'assets/images/team/accueil_client.jpg';
  // Numéro principal affiché sur le support officiel MA Livraison (format international).
  // À confirmer si un autre numéro est dédié au WhatsApp de l'assistance.
  static const _whatsAppNumber = '2290129300303';

  Future<void> _contactWhatsApp() async {
    final message = Uri.encodeComponent(
      'Bonjour MA Livraison, j\'ai besoin d\'assistance concernant votre service.',
    );
    final uri = Uri.parse('https://wa.me/$_whatsAppNumber?text=$message');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _highlight(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: .35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      );

  Widget _heroContent(BuildContext context, {required bool desktop}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _background,
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.primaryDark.withValues(alpha: .88),
                    AppColors.primaryDark.withValues(alpha: .64),
                    AppColors.primaryDark.withValues(alpha: .18),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: desktop ? 48 : 24,
                vertical: desktop ? 42 : 30,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - (desktop ? 84 : 60)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bonjour 👋', style: TextStyle(color: Colors.white70, fontSize: 17)),
                    const SizedBox(height: 4),
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    Text(
                      'Vos livraisons,\nsimplement et rapidement.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: desktop ? 42 : 30,
                        fontWeight: FontWeight.w800,
                        height: 1.12,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Text(
                        'Mon colis, un clin d’œil et c’est livré. Déposez votre demande et suivez votre course depuis votre espace.',
                        style: TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _highlight(Icons.inventory_2_outlined, 'Colis sécurisé'),
                        _highlight(Icons.bolt, 'Livraison rapide'),
                        _highlight(Icons.location_on_outlined, 'Suivi en temps réel'),
                        _highlight(Icons.verified_user_outlined, 'Service de confiance'),
                      ],
                    ),
                    const SizedBox(height: 26),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onStart,
                          icon: const Icon(Icons.local_shipping_outlined),
                          label: const Text('Faire une demande'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primary,
                            minimumSize: const Size.fromHeight(54),
                            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _assistanceCard(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF7F5FC),
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 330),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const BrandLogo(size: 76),
              const SizedBox(height: 30),
              const Icon(Icons.support_agent_rounded, size: 42, color: AppColors.primary),
              const SizedBox(height: 14),
              const Text(
                'Besoin d’assistance ?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AppColors.text),
              ),
              const SizedBox(height: 10),
              const Text(
                'Contactez-nous directement sur WhatsApp. Notre équipe est à votre écoute pour vous accompagner.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, height: 1.5, color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _contactWhatsApp,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('Contacter sur WhatsApp'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final desktop = width >= 1000;
    if (desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 7, child: _heroContent(context, desktop: true)),
          Expanded(flex: 3, child: _assistanceCard(context)),
        ],
      );
    }
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: (MediaQuery.sizeOf(context).height * .68).clamp(460.0, 620.0).toDouble(),
            child: _heroContent(context, desktop: false),
          ),
          _assistanceCard(context),
        ],
      ),
    );
  }
}

// ───────────────────────── Commandes ─────────────────────────

class _OrdersTab extends StatefulWidget {
  const _OrdersTab({super.key});

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  List<OrderModel>? _orders;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await MaApiService(context.read<AuthProvider>().api).clientOrders();
      if (!mounted) return;
      setState(() => _orders = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Impossible de charger vos commandes. Tirez vers le bas pour réessayer.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  static const _labels = {
    'en_attente': 'Demande reçue',
    'livreur_reserve': 'Commande attribuée',
    'livreur_accepte': 'Commande acceptée',
    'en_cours': 'En cours',
    'colis_recupere': 'Colis récupéré',
    'en_livraison': 'En livraison',
    'livree': 'Livrée',
    'annulee': 'Annulée',
    'refusee': 'Refusée',
  };

  String _label(String s) => _labels[s] ?? s;

  Color _color(String s) => s == 'livree'
      ? AppColors.success
      : (s == 'annulee' || s == 'refusee' ? AppColors.danger : AppColors.primary);

  String _date(String? raw) {
    final d = DateTime.tryParse(raw ?? '')?.toLocal();
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }

  bool _awaitingPayment(OrderModel o) =>
      o.statut == 'en_attente' && (o.total ?? 0) > 0 && o.paymentStatus != 'paye';

  void _details(OrderModel o) {
    final hasPrice = (o.total ?? 0) > 0;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Commande #${o.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_label(o.statut), style: TextStyle(color: _color(o.statut), fontWeight: FontWeight.w700)),
                if (_date(o.createdAt).isNotEmpty) Text(_date(o.createdAt), style: const TextStyle(color: Colors.black54)),
                if ((o.destAdresse ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text('Position de livraison : ${o.destAdresse}'),
                ],
                if ((o.note ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Votre instruction', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(o.note!.trim()),
                ],
                const SizedBox(height: 14),
                if (hasPrice) ...[
                  Row(children: [
                    const Expanded(child: Text('Frais de livraison')),
                    Text('${o.deliveryFee ?? 0} FCFA'),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Expanded(child: Text('Prix de la commande')),
                    Text('${o.productPrice ?? ((o.total ?? 0) - (o.deliveryFee ?? 0))} FCFA'),
                  ]),
                  const Divider(height: 20),
                  Row(children: [
                    const Expanded(child: Text('Total', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                    Text('${o.total} FCFA', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  ]),
                ] else
                  const Text('Prix en attente de validation par MA Livraison.'),
                if (_awaitingPayment(o)) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PaymentPage(
                              orderId: o.id,
                              initialAmount: o.total,
                              deliveryFee: o.deliveryFee,
                              productPrice: o.productPrice,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.payments_outlined),
                      label: Text('Payer ${o.total} FCFA'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orders;

    final List<Widget> history;
    if (_loading && orders == null) {
      history = const [Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))];
    } else if (orders == null) {
      history = [Text(_error ?? 'Aucune donnée.', textAlign: TextAlign.center)];
    } else if (orders.isEmpty) {
      history = const [
        SizedBox(height: 8),
        Icon(Icons.receipt_long_outlined, size: 44, color: Colors.black38),
        SizedBox(height: 8),
        Text('Aucune commande pour le moment.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
        Text('Vos demandes apparaîtront ici.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
      ];
    } else {
      history = [for (final o in orders) _orderCard(o)];
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Que souhaitez-vous faire ?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _action(context, Icons.local_shipping, 'Se faire livrer', 'Déposer une demande de livraison.',
              const ClientOrderFormPage(type: 'livraison')),
          _action(context, Icons.directions_car, 'Course personnelle', 'Déposer une demande de course personnelle.',
              const ClientOrderFormPage(type: 'course_personnelle')),
          _action(context, Icons.receipt_long, 'Ma commande active', 'Suivre le statut de votre commande.',
              const ClientOrderDashboardPage()),
          _action(context, Icons.storefront, 'Produits disponibles', 'Consulter le catalogue.',
              const ProductCatalogPage()),
          _action(context, Icons.campaign_outlined, 'Publicités', 'Voir les annonces et offres de MA3H.',
              const PublicityPage()),
          const SizedBox(height: 18),
          const Text('Mes commandes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...history,
        ],
      ),
    );
  }

  Widget _action(BuildContext context, IconData icon, String title, String text, Widget page) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(text),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }

  Widget _orderCard(OrderModel o) {
    final hasPrice = (o.total ?? 0) > 0;
    return Card(
      child: ListTile(
        onTap: () => _details(o),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _color(o.statut).withValues(alpha: .12),
          child: Icon(Icons.receipt_long, color: _color(o.statut)),
        ),
        title: Text('Commande #${o.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          '${_label(o.statut)}'
          '${_date(o.createdAt).isEmpty ? '' : ' · ${_date(o.createdAt)}'}\n'
          '${hasPrice ? 'Total : ${o.total} FCFA' : 'Prix en attente de validation'}',
        ),
        isThreeLine: true,
        trailing: _awaitingPayment(o)
            ? const Icon(Icons.payments_outlined, color: AppColors.primary)
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

// ───────────────────────── Profil ─────────────────────────

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez saisir à nouveau votre numéro et votre mot de passe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Se déconnecter')),
        ],
      ),
    );
    if (yes == true && context.mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final name = user?.nom ?? '';
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 8),
        Center(
          child: CircleAvatar(
            radius: 46,
            backgroundColor: AppColors.primaryLight,
            child: Text(
              initial,
              style: const TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(child: Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
        const Center(child: Text('Compte client', style: TextStyle(color: Colors.black54))),
        const SizedBox(height: 20),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.phone_outlined),
                title: const Text('Téléphone'),
                subtitle: Text(user?.telephone ?? '—'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Adresse e-mail'),
                subtitle: Text((user?.email ?? '').isEmpty ? 'Non renseignée' : user!.email!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfilePage()),
          ),
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Modifier mes informations'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('Publicités'),
            subtitle: const Text('Annonces et offres de MA3H'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PublicityPage()),
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => _confirmLogout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: AppColors.danger,
          ),
        ),
      ],
    );
  }
}