import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../providers/auth_provider.dart';
import '../widgets/brand_logo.dart';
import '../widgets/login_dialog.dart';
import '../services/ma_api_service.dart';
import '../services/api_client.dart';
import 'auth/admin_login_page.dart';
import 'auth/driver_login_page.dart';
import 'auth/register_page.dart';
import 'client/product_catalog_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController pages = PageController();
  final homeKey = GlobalKey();
  final servicesKey = GlobalKey();
  final aboutKey = GlobalKey();
  Timer? timer;
  int index = 0;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!pages.hasClients || AppAssets.gallery.isEmpty) return;
      index = (index + 1) % AppAssets.gallery.length;
      pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    pages.dispose();
    super.dispose();
  }

  void go(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 500),
      alignment: .05,
    );
  }

  void login() {
    showDialog<void>(
      context: context,
      builder: (_) => const LoginDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated) return const SizedBox.shrink();

    final desktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: const BrandLogo(),
        actions: [
          if (desktop) ...[
            _nav('Accueil', () => go(homeKey)),
            _nav('Services', () => go(servicesKey)),
            _nav('À propos', () => go(aboutKey)),
          ],
          if (!desktop)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'home') go(homeKey);
                if (value == 'services') go(servicesKey);
                if (value == 'about') go(aboutKey);
                if (value == 'admin') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminLoginPage(),
                    ),
                  );
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'home', child: Text('Accueil')),
                PopupMenuItem(value: 'services', child: Text('Services')),
                PopupMenuItem(value: 'about', child: Text('À propos')),
                PopupMenuItem(
                  value: 'admin',
                  child: Text('Administration'),
                ),
              ],
            ),
          OutlinedButton.icon(
            onPressed: login,
            icon: const Icon(Icons.login),
            label: const Text('Connexion'),
          ),
          const SizedBox(width: 8),
          if (desktop)
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminLoginPage(),
                ),
              ),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Admin'),
            ),
          const SizedBox(width: 8),
          if (desktop)
            FilledButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RegisterPage(),
                ),
              ),
              child: const Text('Créer un compte'),
            ),
          const SizedBox(width: 14),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(key: homeKey, child: _hero(context)),
            _quick(context),
            Container(key: servicesKey, child: _services(context)),
            _advertisements(context),
            Container(key: aboutKey, child: _about()),
            _team(),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _nav(String text, VoidCallback action) {
    return TextButton(onPressed: action, child: Text(text));
  }

  Widget _hero(BuildContext context) {
    return SizedBox(
      height: Responsive.isDesktop(context) ? 500 : 560,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: pages,
            itemCount: AppAssets.gallery.length,
            itemBuilder: (_, i) => Image.asset(
              AppAssets.gallery[i],
              fit: BoxFit.cover,
            ),
          ),
          Container(
            color: AppColors.primaryDark.withValues(alpha: .70),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'MA3H SARL • MA Livraison',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vos livraisons,\nsimplement et rapidement.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: Responsive.isDesktop(context) ? 50 : 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 700,
                    child: Text(
                      'Mon colis, un clin d’œil et c’est livré. Déposez votre demande, MA Livraison organise le traitement et vous suivez la course depuis votre espace.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 17,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: login,
                        icon: const Icon(Icons.local_shipping),
                        label: const Text('Se faire livrer'),
                      ),
                      OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterPage(),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                        ),
                        child: const Text('Créer un compte'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quick(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.tonalIcon(
            onPressed: login,
            icon: const Icon(Icons.person),
            label: const Text('Espace client'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DriverLoginPage(),
              ),
            ),
            icon: const Icon(Icons.two_wheeler),
            label: const Text('Espace livreur'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminLoginPage(),
              ),
            ),
            icon: const Icon(Icons.admin_panel_settings),
            label: const Text('Administration'),
          ),
        ],
      ),
    );
  }

  Widget _services(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'Nos services',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _service(
                Icons.local_shipping,
                'Livraison de colis',
                'Déposez votre demande, notre équipe organise la livraison.',
              ),
              _service(
                Icons.directions_car,
                'Course personnelle',
                'Déposez votre demande de course personnelle.',
              ),
              _service(
                Icons.storefront,
                'Produits disponibles',
                'Consultez notre catalogue.',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProductCatalogPage(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _service(
    IconData icon,
    String title,
    String description, [
    VoidCallback? action,
  ]) {
    return SizedBox(
      width: 280,
      child: Card(
        child: ListTile(
          onTap: action,
          leading: Icon(icon, color: AppColors.primary),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(description),
        ),
      ),
    );
  }

  Widget _advertisements(BuildContext context) {
    final api = context.read<AuthProvider>().api;
    return FutureBuilder<dynamic>(
      future: api.request('GET', '/advertisements'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data is! Map) {
          return const SizedBox.shrink();
        }

        final data = Map<String, dynamic>.from(snapshot.data as Map);
        final items = (data['advertisements'] as List?) ?? [];
        if (items.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            children: [
              const Text(
                'Publicités',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 260,
                child: PageView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, index) {
                    final ad = Map<String, dynamic>.from(items[index] as Map);
                    final imageUrl = ApiClient.resolveMediaUrl(ad['image_url']?.toString());
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFEAF2FF), child: Icon(Icons.campaign_outlined, size: 64)))
                          else
                            const ColoredBox(
                              color: Color(0xFFEAF2FF),
                              child: Icon(Icons.campaign_outlined, size: 64),
                            ),
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              width: double.infinity,
                              color: Colors.black54,
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (ad['title'] ?? 'Publicité').toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (ad['description'] != null &&
                                      ad['description']
                                          .toString()
                                          .trim()
                                          .isNotEmpty)
                                    Text(
                                      ad['description'].toString(),
                                      style: const TextStyle(
                                        color: Colors.white70,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _about() {
    return const Padding(
      padding: EdgeInsets.all(30),
      child: Column(
        children: [
          Text(
            'À propos',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text(
            'MA Livraison est le service de livraison de MA3H SARL, basé à Parakou.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _team() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Notre équipe',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: AppAssets.team
                .map(
                  (path) => ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      path,
                      width: 300,
                      height: 210,
                      fit: BoxFit.cover,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      color: AppColors.primaryDark,
      child: const Column(
        children: [
          Text(
            'MA Livraison — MA3H Sarl',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Parakou • Service de livraison et courses',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
