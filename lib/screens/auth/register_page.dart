import 'package:flutter/material.dart';

import '../../widgets/auth_announcement_bar.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/google_auth_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<FormState>();
  final nom = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    nom.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      nom: nom.text.trim(),
      telephone: phone.text.trim(),
      email: email.text.trim(),
      password: password.text,
    );

    if (!mounted) return;
    if (ok) {
      nom.clear();
      phone.clear();
      email.clear();
      password.clear();
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Compte créé avec succès !'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      await Future<void>.delayed(const Duration(milliseconds: 700));
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      bottomNavigationBar: const AuthAnnouncementBar(),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Créer un compte'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Cheval MA Livraison détouré : véritable fond transparent,
          // indépendant du logo complet utilisé dans l'en-tête.
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: .30,
                  child: Image.asset(
                    'assets/branding/ma_livraison_cheval.png',
                    width: 820,
                    height: 560,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -85,
            child: _circle(250),
          ),
          Positioned(
            bottom: -100,
            right: -75,
            child: _circle(230),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 510),
                child: Card(
                  // Transparence légère : le filigrane reste visible derrière
                  // le formulaire sans compromettre le contraste du contenu.
                  color: Colors.white.withValues(alpha: .70),
                  surfaceTintColor: Colors.transparent,
                  elevation: 3,
                  shadowColor: AppColors.primary.withValues(alpha: .10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: .08),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 30,
                    ),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Center(
                              child: BrandLogo(size: 70, titleSize: 25)),
                          const SizedBox(height: 22),
                          const Text(
                            'Rejoignez MA LIVRAISON',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 7),
                          const Text(
                            'Créez votre espace pour déposer et suivre vos demandes.',
                            textAlign: TextAlign.center,
                            style:
                                TextStyle(color: AppColors.muted, height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          TextFormField(
                            controller: nom,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                              labelText: 'Nom complet',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Veuillez saisir votre nom complet.'
                                : null,
                          ),
                          const SizedBox(height: 13),
                          TextFormField(
                            controller: phone,
                            keyboardType: TextInputType.phone,
                            autofillHints: const [
                              AutofillHints.telephoneNumber
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Téléphone',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Veuillez saisir votre téléphone.'
                                : null,
                          ),
                          const SizedBox(height: 13),
                          TextFormField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Adresse e-mail',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Veuillez saisir votre adresse e-mail.';
                              }
                              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                  .hasMatch(v.trim())) {
                                return 'Adresse e-mail invalide.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 13),
                          TextFormField(
                            controller: password,
                            obscureText: obscure,
                            autofillHints: const [AutofillHints.newPassword],
                            decoration: InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () =>
                                    setState(() => obscure = !obscure),
                                icon: Icon(obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                              ),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Le mot de passe doit contenir au moins 6 caractères.'
                                : null,
                          ),
                          if (auth.error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.danger.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(auth.error!,
                                  style:
                                      const TextStyle(color: AppColors.danger)),
                            ),
                          ],
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 52,
                            child: FilledButton(
                              onPressed: auth.loading ? null : submit,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: auth.loading
                                    ? const SizedBox(
                                        key: ValueKey('loading'),
                                        width: 21,
                                        height: 21,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Créer mon compte',
                                        key: ValueKey('register'),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: const [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: Text('OU',
                                    style: TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GoogleAuthButton(onSuccess: () {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('J’ai déjà un compte'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: .045),
        ),
      );
}
