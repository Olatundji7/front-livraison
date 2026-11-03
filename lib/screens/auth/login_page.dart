import 'package:flutter/material.dart';

import '../../widgets/auth_announcement_bar.dart';
import 'package:provider/provider.dart';

import '../../core/app_assets.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/google_auth_button.dart';
import 'forgot_password_page.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    phone.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final auth = context.read<AuthProvider>();
    if (phone.text.trim().isEmpty || password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez renseigner votre téléphone et votre mot de passe.')),
      );
      return;
    }
    final ok = await auth.login(
      telephone: phone.text.trim(),
      password: password.text,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(auth.error ?? 'Connexion impossible.'),
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      bottomNavigationBar: const AuthAnnouncementBar(),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Connexion'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Opacity(
                  opacity: .055,
                  child: Image.asset(
                    AppAssets.logo,
                    width: 360,
                    height: 280,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -80,
            child: _decorativeCircle(260),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _decorativeCircle(230),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 470),
                child: Card(
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
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(child: BrandLogo(size: 72, titleSize: 25)),
                        const SizedBox(height: 26),
                        const Text(
                          'Heureux de vous revoir !',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Connectez-vous à votre espace MA LIVRAISON.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.muted),
                        ),
                        const SizedBox(height: 28),
                        TextField(
                          controller: phone,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.telephoneNumber],
                          decoration: const InputDecoration(
                            labelText: 'Téléphone',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: password,
                          obscureText: obscure,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) { if (!auth.loading) submit(); },
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: obscure ? 'Afficher le mot de passe' : 'Masquer le mot de passe',
                              onPressed: () => setState(() => obscure = !obscure),
                              icon: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: Icon(
                                  obscure ? Icons.visibility_off : Icons.visibility,
                                  key: ValueKey(obscure),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => Navigator.push(context,
                              MaterialPageRoute(
                                builder: (_) => const ForgotPasswordPage(),
                              ),
                            ),
                            child: const Text('Mot de passe oublié ?'),
                          ),
                        ),
                        if (auth.error != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              auth.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.danger),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 8),
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
                                    'Se connecter',
                                    key: ValueKey('login'),
                                    style: TextStyle(fontWeight: FontWeight.bold),
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
                              child: Text('OU', style: TextStyle(
                                color: AppColors.muted, fontSize: 12,
                                fontWeight: FontWeight.w700)),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GoogleAuthButton(onSuccess: () {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }),
                        const SizedBox(height: 12),
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              const Text('Vous n’avez pas de compte ? ', style: TextStyle(color: AppColors.muted)),
                              TextButton(
                                onPressed: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const RegisterPage()),
                                ),
                                child: const Text('Créer un compte'),
                              ),
                            ],
                          ),
                        ),
                      ],
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

  Widget _decorativeCircle(double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.primary.withValues(alpha: .045),
    ),
  );
}
