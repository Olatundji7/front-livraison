import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/brand_logo.dart';

/// Mot de passe oublié (client) : 1) e-mail -> code reçu, 2) code + nouveau mot de passe.
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final email = TextEditingController();
  final code = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  bool codeSent = false;
  bool loading = false;
  bool obscure = true;
  String? message;
  String? error;

  @override
  void dispose() {
    email.dispose();
    code.dispose();
    password.dispose();
    confirm.dispose();
    super.dispose();
  }

  String _text(Object e) {
    if (e is ApiException) {
      final body = e.body;
      if (body is Map) {
        final errors = body['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) return first.first.toString();
        }
        if (body['message'] != null) return body['message'].toString();
      }
      if (e.statusCode == 429) return 'Trop de tentatives. Réessayez dans une minute.';
    }
    return 'Service indisponible. Vérifiez votre connexion et réessayez.';
  }

  Future<void> _send() async {
    final value = email.text.trim();
    if (!value.contains('@') || !value.contains('.')) {
      setState(() => error = 'Saisissez une adresse e-mail valide.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
      message = null;
    });
    try {
      final data = await context.read<AuthProvider>().api.request(
        'POST',
        '/auth/forgot-password',
        body: {'email': value},
      );
      if (!mounted) return;
      setState(() {
        codeSent = true;
        message = (data is Map ? data['message'] : null)?.toString() ??
            'Si un compte existe, un code vient d’être envoyé.';
      });
    } catch (e) {
      if (mounted) setState(() => error = _text(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _reset() async {
    final c = code.text.trim();
    if (c.length != 6 || int.tryParse(c) == null) {
      setState(() => error = 'Saisissez le code à 6 chiffres reçu par e-mail.');
      return;
    }
    if (password.text.length < 6) {
      setState(() => error = 'Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }
    if (password.text != confirm.text) {
      setState(() => error = 'Les deux mots de passe ne sont pas identiques.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await context.read<AuthProvider>().api.request(
        'POST',
        '/auth/reset-password',
        body: {'email': email.text.trim(), 'code': c, 'password': password.text},
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      messenger.showSnackBar(
        const SnackBar(content: Text('Mot de passe modifié. Connectez-vous avec le nouveau.')),
      );
    } catch (e) {
      if (mounted) setState(() => error = _text(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mot de passe oublié')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const BrandLogo(size: 64),
                    const SizedBox(height: 20),
                    Text(
                      codeSent ? 'Nouveau mot de passe' : 'Réinitialiser mon mot de passe',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      codeSent
                          ? 'Saisissez le code reçu par e-mail (valable 15 minutes) et choisissez un nouveau mot de passe.'
                          : 'Saisissez l’adresse e-mail de votre compte : nous vous envoyons un code de confirmation.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: email,
                      enabled: !codeSent,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Adresse e-mail',
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                    ),
                    if (codeSent) ...[
                      const SizedBox(height: 14),
                      TextField(
                        controller: code,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Code à 6 chiffres',
                          prefixIcon: Icon(Icons.pin_outlined),
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: password,
                        obscureText: obscure,
                        decoration: InputDecoration(
                          labelText: 'Nouveau mot de passe',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => obscure = !obscure),
                            icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: confirm,
                        obscureText: obscure,
                        decoration: const InputDecoration(
                          labelText: 'Confirmer le mot de passe',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                    ],
                    if (message != null) ...[
                      const SizedBox(height: 12),
                      Text(message!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.green)),
                    ],
                    if (error != null) ...[
                      const SizedBox(height: 12),
                      Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: loading ? null : (codeSent ? _reset : _send),
                        child: loading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(codeSent ? 'Modifier le mot de passe' : 'Envoyer le code'),
                      ),
                    ),
                    if (codeSent)
                      TextButton(
                        onPressed: loading
                            ? null
                            : () => setState(() {
                                  codeSent = false;
                                  error = null;
                                  message = null;
                                  code.clear();
                                }),
                        child: const Text('Renvoyer un code / changer d’adresse'),
                      ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pas d’adresse e-mail sur votre compte ? Contactez MA Livraison.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black54),
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
}
