import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';
import '../core/responsive.dart';
import '../providers/auth_provider.dart';
import '../widgets/brand_logo.dart';
import '../widgets/login_dialog.dart';
import 'auth/register_page.dart';
import 'client/product_catalog_page.dart';
import 'home/publicity_page.dart';

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
  final contactKey = GlobalKey();
  final contactFormKey = GlobalKey<FormState>();
  final contactName = TextEditingController();
  final contactPhone = TextEditingController();
  final contactEmail = TextEditingController();
  final contactSubject = TextEditingController();
  final contactMessage = TextEditingController();
  Timer? timer;
  int index = 0;

  // Numéro de contact affiché sur les supports MA Livraison fournis.
  static const String _whatsAppNumber = '2290129300303';
  static const String _mapsQuery = 'MA LIVRAISON Parakou Benin';

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!pages.hasClients || AppAssets.gallery.isEmpty) return;
      index = (index + 1) % AppAssets.gallery.length;
      pages.animateToPage(
        index,
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    pages.dispose();
    contactName.dispose();
    contactPhone.dispose();
    contactEmail.dispose();
    contactSubject.dispose();
    contactMessage.dispose();
    super.dispose();
  }

  void go(GlobalKey key) {
    final target = key.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 550),
      alignment: .04,
    );
  }

  void login() {
    showDialog<void>(
      context: context,
      builder: (_) => const LoginDialog(),
    );
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(_mapsQuery)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.platformDefault) && mounted) {
      _notice('Impossible d’ouvrir Google Maps.');
    }
  }

  Future<void> _sendContact() async {
    if (!(contactFormKey.currentState?.validate() ?? false)) return;
    final message = [
      'Bonjour MA Livraison,',
      '',
      'Nom : ${contactName.text.trim()}',
      'Téléphone : ${contactPhone.text.trim()}',
      if (contactEmail.text.trim().isNotEmpty)
        'E-mail : ${contactEmail.text.trim()}',
      'Objet : ${contactSubject.text.trim()}',
      '',
      contactMessage.text.trim(),
    ].join('\n');
    final uri = Uri.parse(
      'https://wa.me/$_whatsAppNumber?text=${Uri.encodeComponent(message)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      _notice('WhatsApp ne peut pas être ouvert sur cet appareil.');
    }
  }

  void _notice(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated) return const SizedBox.shrink();
    final desktop = Responsive.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 82,
        title: const BrandLogo(size: 58, titleSize: 23),
        actions: [
          if (desktop) ...[
            _nav('Accueil', () => go(homeKey)),
            _nav('Services', () => go(servicesKey)),
            _nav('À propos', () => go(aboutKey)),
            _nav('Contact', () => go(contactKey)),
            _nav('Publicités', () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PublicityPage()),
            )),
          ],
          if (!desktop)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'home') go(homeKey);
                if (value == 'services') go(servicesKey);
                if (value == 'about') go(aboutKey);
                if (value == 'contact') go(contactKey);
                if (value == 'publicity') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const PublicityPage(),
                  ));
                }

                if (value == 'register') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage()));
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'home', child: Text('Accueil')),
                PopupMenuItem(value: 'services', child: Text('Services')),
                PopupMenuItem(value: 'about', child: Text('À propos')),
                PopupMenuItem(value: 'contact', child: Text('Contact')),
                PopupMenuItem(value: 'publicity', child: Text('Publicités')),
                PopupMenuItem(value: 'register', child: Text('Créer un compte')),
              ],
            ),
          OutlinedButton.icon(
            onPressed: login,
            icon: const Icon(Icons.login),
            label: const Text('Connexion'),
          ),
          const SizedBox(width: 8),
          const SizedBox(width: 8),
          if (desktop)
            FilledButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const RegisterPage(),
              )),
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
            Container(key: aboutKey, child: _about(context)),
            _team(),
            _contact(context),
            _location(context),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _nav(String text, VoidCallback action) =>
      TextButton(onPressed: action, child: Text(text));

  Widget _hero(BuildContext context) {
    final desktop = Responsive.isDesktop(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = desktop ? 500.0 : 540.0;
        return SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (AppAssets.gallery.isNotEmpty)
                PageView.builder(
                  controller: pages,
                  itemCount: AppAssets.gallery.length,
                  onPageChanged: (value) => setState(() => index = value),
                  itemBuilder: (_, i) => Stack(
                    fit: StackFit.expand,
                    children: [
                      ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(
                          sigmaX: 18,
                          sigmaY: 18,
                        ),
                        child: Image.asset(
                          AppAssets.gallery[i],
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      ),
                      Container(
                        color: AppColors.primaryDark.withValues(alpha: .42),
                      ),
                      Center(
                        child: Image.asset(
                          AppAssets.gallery[i],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.contain,
                          alignment: Alignment.center,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(color: AppColors.primaryDark),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.primaryDark.withValues(alpha: .88),
                      AppColors.primaryDark.withValues(alpha: .56),
                      AppColors.primaryDark.withValues(alpha: .30),
                    ],
                  ),
                ),
              ),
              // Le cheval en filigrane sera ajouté avec un PNG réellement transparent.
              // On évite d'afficher le fond blanc du logo dans cette version.
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: desktop ? 34 : 22,
                  vertical: 28,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: desktop ? 720 : constraints.maxWidth,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MA LIVRAISON',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: .6,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Vos livraisons,\nsimplement et rapidement.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: desktop ? 48 : 34,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Mon colis, un clin d’œil et c’est livré. Déposez votre demande, MA Livraison organise le traitement et vous suivez la course depuis votre espace.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1.55,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ElevatedButton.icon(
                              onPressed: login,
                              icon: const Icon(Icons.local_shipping),
                              label: const Text('Se faire livrer'),
                            ),
                            OutlinedButton(
                              onPressed: () => Navigator.push(context,
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
              ),
              Positioned(
                bottom: 16,
                right: 20,
                child: Row(
                  children: List.generate(
                    AppAssets.gallery.length,
                    (i) => Container(
                      width: i == index ? 22 : 7,
                      height: 7,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(
                          alpha: i == index ? 1 : .55,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _quick(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.tonalIcon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const RegisterPage(),
            )),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Créer un compte'),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) => Column(
    children: [
      Text(title, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      Text(subtitle, textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.muted, height: 1.5)),
    ],
  );

  Widget _services(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 34),
      child: Column(
        children: [
          _sectionTitle('Nos services',
            'Des solutions simples pour vos déplacements et vos livraisons.'),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _service(Icons.local_shipping, 'Livraison de colis',
                'Déposez votre demande, notre équipe organise la livraison.'),
              _service(Icons.directions_car, 'Course personnelle',
                'Déposez votre demande de course personnelle.'),
              _service(Icons.storefront, 'Produits disponibles',
                'Consultez notre catalogue.',
                () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const ProductCatalogPage(),
                ))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _service(IconData icon, String title, String description,
      [VoidCallback? action]) {
    return SizedBox(
      width: 300,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ListTile(
            onTap: action,
            contentPadding: const EdgeInsets.all(10),
            leading: CircleAvatar(
              backgroundColor: AppColors.primaryLight,
              child: Icon(icon, color: AppColors.primary),
            ),
            title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(description),
            ),
          ),
        ),
      ),
    );
  }

  Widget _about(BuildContext context) {
    final desktop = Responsive.isDesktop(context);
    final values = [
      (Icons.speed, 'Rapidité', 'Une prise en charge organisée pour limiter les délais.'),
      (Icons.verified_user_outlined, 'Fiabilité', 'Un suivi clair de la demande et de son traitement.'),
      (Icons.shield_outlined, 'Sécurité', 'Une attention portée à vos colis et à vos informations.'),
    ];
    return Container(
      width: double.infinity,
      color: AppColors.primaryLight.withValues(alpha: .55),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        children: [
          _sectionTitle('À propos de MA LIVRAISON',
            'Le service de livraison de MA3H SARL, basé à Parakou.'),
          const SizedBox(height: 24),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Text(
              'MA LIVRAISON accompagne les particuliers et les professionnels dans leurs besoins de livraison de colis et de courses personnelles. Depuis votre espace, vous pouvez déposer une demande, renseigner les informations utiles et suivre son évolution. Notre équipe organise le traitement de chaque demande avec une priorité donnée à la rapidité, à la fiabilité et à la sécurité.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.75),
            ),
          ),
          const SizedBox(height: 34),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            alignment: WrapAlignment.center,
            children: values.map((v) => SizedBox(
              width: desktop ? 285 : 320,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      Icon(v.$1, color: AppColors.primary, size: 34),
                      const SizedBox(height: 12),
                      Text(v.$2, style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(v.$3, textAlign: TextAlign.center,
                        style: const TextStyle(height: 1.45)),
                    ],
                  ),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 26),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: const Text(
              'Notre engagement est de proposer un service accessible et pratique : une demande déposée simplement, des informations de suivi consultables depuis votre espace et une équipe mobilisée pour organiser la course.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.65),
            ),
          ),
        ],
      ),
    );
  }

  Widget _team() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 42),
      child: Column(
        children: [
          _sectionTitle('Notre équipe',
            'Des personnes engagées au service de vos livraisons.'),
          const SizedBox(height: 22),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: AppAssets.team.map((path) => ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(path,
                width: 300, height: 210, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 300, height: 210,
                  color: AppColors.primaryLight,
                  child: const Icon(Icons.groups, size: 54,
                    color: AppColors.primary),
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _contact(BuildContext context) {
    return Container(
      key: contactKey,
      width: double.infinity,
      color: AppColors.primaryLight.withValues(alpha: .55),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 44),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: contactFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _sectionTitle('Contactez-nous',
                      'Une question ou un souci ? Écrivez à notre équipe.'),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: contactName,
                      decoration: const InputDecoration(
                        labelText: 'Nom complet',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Veuillez saisir votre nom.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactPhone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Veuillez saisir votre téléphone.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail (facultatif)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactSubject,
                      decoration: const InputDecoration(
                        labelText: 'Objet de votre demande',
                        prefixIcon: Icon(Icons.subject),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Veuillez préciser l’objet.' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contactMessage,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Votre message',
                        alignLabelWithHint: true,
                        prefixIcon: Icon(Icons.message_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Veuillez saisir votre message.' : null,
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _sendContact,
                      icon: const Icon(Icons.chat),
                      label: const Text('Envoyer par WhatsApp'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Votre message sera transmis à MA Livraison dans WhatsApp après votre confirmation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _location(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 42),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.primary, size: 42),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Retrouvez MA LIVRAISON',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            SizedBox(height: 6),
                            Text('Parakou, Bénin',
                              style: TextStyle(color: AppColors.muted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Ouvrez Google Maps pour rechercher notre établissement et préparer votre itinéraire.',
                    style: TextStyle(height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _openMaps,
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Localiser sur Google Maps'),
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

  Widget _footer() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF142451),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      alignment: Alignment.center,
      child: const Text(
        '© 2026 MA LIVRAISON. Tous droits réservés.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color(0xFFDCE5FF),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
