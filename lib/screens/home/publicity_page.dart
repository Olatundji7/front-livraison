import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Espace vitrine des annonces et entreprises partenaires de MA Livraison.
///
/// Affiche chaque annonce avec les informations de sa structure partenaire.
/// Les données de l'entreprise sont lues dans l'objet JSON `partner` renvoyé
/// par l'API Laravel. Aucun prix n'est affiché.
class PublicityPage extends StatefulWidget {
  const PublicityPage({super.key});

  @override
  State<PublicityPage> createState() => _PublicityPageState();
}

class _PublicityPageState extends State<PublicityPage> {
  late Future<List<Map<String, dynamic>>> _advertisementsFuture;

  @override
  void initState() {
    super.initState();
    _loadAdvertisements();
  }

  void _loadAdvertisements() {
    final api = context.read<AuthProvider>().api;
    _advertisementsFuture = _fetchAdvertisements(api);
  }

  Future<List<Map<String, dynamic>>> _fetchAdvertisements(dynamic api) async {
    final response = await api.request('GET', '/advertisements');
    if (response is! Map) {
      throw const FormatException('Réponse publicitaire invalide.');
    }

    final rawItems = response['advertisements'];
    if (rawItems is! List) return [];

    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> _refresh() async {
    setState(_loadAdvertisements);
    await _advertisementsFuture;
  }

  String _value(Map<String, dynamic> ad, List<String> keys) {
    for (final key in keys) {
      final value = ad[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Nos partenaires'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _advertisementsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _StateMessage(
              icon: Icons.wifi_off_rounded,
              title: 'Chargement impossible',
              message:
                  'Les publicités ne sont pas disponibles pour le moment.',
              actionLabel: 'Réessayer',
              onAction: _refresh,
            );
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: const [
                  _PublicityIntro(),
                  SizedBox(height: 70),
                  _StateMessage(
                    icon: Icons.campaign_outlined,
                    title: 'Les offres arrivent bientôt',
                    message:
                        'Retrouvez ici les entreprises partenaires de MA3H, leurs produits et leurs offres promotionnelles.',
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  children: [
                    const _PublicityIntro(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'À la découverte de nos partenaires',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        Text(
                          '${items.length} annonce${items.length > 1 ? 's' : ''}',
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...items.map(
                      (advertisement) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 780),
                            child: SizedBox(
                              width: double.infinity,
                              child: _AdvertisementCard(
                                advertisement: advertisement,
                                value: _value,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const _BecomePartnerBanner(),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PublicityIntro extends StatelessWidget {
  const _PublicityIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.accent],
          begin: Alignment.centerLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Découvrez nos partenaires',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 9),
                Text(
                  'Des entreprises, des produits et des offres à découvrir près de chez vous.',
                  style: TextStyle(
                    color: Colors.white,
                    height: 1.4,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvertisementCard extends StatelessWidget {
  const _AdvertisementCard({
    required this.advertisement,
    required this.value,
  });

  final Map<String, dynamic> advertisement;
  final String Function(Map<String, dynamic>, List<String>) value;

  @override
  Widget build(BuildContext context) {
    final api = context.read<AuthProvider>().api;
    final imagePath = value(advertisement, ['image_url', 'image']);
    final imageUrl = imagePath.isEmpty ? null : api.mediaUrl(imagePath);
    final partner = advertisement['partner'] is Map
        ? Map<String, dynamic>.from(advertisement['partner'] as Map)
        : <String, dynamic>{};
    final company = value(partner, ['name']).isNotEmpty
        ? value(partner, ['name'])
        : value(advertisement, [
            'company_name',
            'advertiser_name',
            'business_name',
            'company',
          ]);
    final title = value(advertisement, ['title']).isEmpty
        ? 'Découvrez notre offre'
        : value(advertisement, ['title']);
    final description = value(advertisement, ['description']);
    final companyDescription = value(partner, ['description']);
    final phone = value(partner, ['contact_phone']);
    final whatsapp = value(partner, ['contact_whatsapp']);
    final email = value(partner, ['contact_email']);
    final website = value(partner, ['website_url']);
    final product = value(advertisement, ['product_name', 'product']);
    final category = value(partner, ['business_category']).isNotEmpty
        ? value(partner, ['business_category'])
        : value(advertisement, ['category', 'business_category']);
    final logoPath = value(partner, ['logo_url', 'logo']);
    final logoUrl = logoPath.isEmpty ? null : api.mediaUrl(logoPath);
    final sponsoredValue = advertisement['is_sponsored'];
    final isSponsored = sponsoredValue == true ||
        sponsoredValue == 1 ||
        sponsoredValue == '1' ||
        advertisement['is_partner'] == true;

    return Card(
      elevation: 1.5,
      shadowColor: AppColors.primary.withValues(alpha: .08),
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.black.withValues(alpha: .045)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (company.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                children: [
                  if (logoUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        logoUrl,
                        width: 54,
                        height: 54,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _CompanyLogoFallback(),
                      ),
                    )
                  else
                    const _CompanyLogoFallback(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isSponsored)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2F7E9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Partenaire MA Livraison',
                              style: TextStyle(
                                color: Color(0xFF168344),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        if (category.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  const _CompanyLogoFallback(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isSponsored ? 'Partenaire MA Livraison' : 'Publicité',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 8.5,
                child: imageUrl == null
                    ? Container(
                        color: AppColors.primaryLight,
                        child: const Center(
                          child: Icon(
                            Icons.storefront_outlined,
                            size: 54,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.primaryLight,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 42,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _Tag(
                  label: isSponsored ? 'PARTENAIRE' : 'PUBLICITÉ',
                  icon: isSponsored ? Icons.verified_rounded : Icons.campaign,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  const SizedBox(height: 6),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  if (companyDescription.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      companyDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (product.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      product,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                  if (phone.isNotEmpty || whatsapp.isNotEmpty ||
                      email.isNotEmpty || website.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 14,
                      runSpacing: 7,
                      children: [
                        if (phone.isNotEmpty)
                          _ContactItem(icon: Icons.phone_outlined, text: phone),
                        if (whatsapp.isNotEmpty)
                          _ContactItem(
                            icon: Icons.chat_outlined,
                            text: 'WhatsApp : $whatsapp',
                          ),
                        if (email.isNotEmpty)
                          _ContactItem(
                            icon: Icons.email_outlined,
                            text: email,
                          ),
                        if (website.isNotEmpty)
                          _ContactItem(
                            icon: Icons.language_outlined,
                            text: website,
                          ),
                      ],
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompanyLogoFallback extends StatelessWidget {
  const _CompanyLogoFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.business_rounded,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  const _ContactItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 5),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .94),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: .35,
            ),
          ),
        ],
      ),
    );
  }
}

class _BecomePartnerBanner extends StatelessWidget {
  const _BecomePartnerBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: const Row(
        children: [
          Icon(Icons.handshake_outlined, color: AppColors.primary, size: 30),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vous êtes une entreprise ?',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Présentez votre entreprise et vos produits sur MA Livraison. Contactez MA3H pour devenir annonceur.',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 48),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
