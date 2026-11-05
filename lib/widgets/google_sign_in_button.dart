import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Bouton partagé par les écrans de connexion et d'inscription.
/// Un compte Google nouveau doit fournir un numéro de téléphone avant sa
/// création dans Laravel. Le rôle reste exclusivement déterminé par Laravel.
class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  final bool compact;

  const GoogleSignInButton({
    super.key,
    this.onSuccess,
    this.compact = false,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  Future<void> _continueWithGoogle() async {
    final auth = context.read<AuthProvider>();
    var ok = await auth.loginWithGoogle();

    if (!mounted) return;

    if (!ok && auth.googlePhoneRequired) {
      final phone = await _askPhoneNumber();
      if (!mounted || phone == null) return;
      ok = await auth.completeGoogleSignIn(telephone: phone);
    }

    if (!mounted) return;
    if (ok) {
      widget.onSuccess?.call();
      return;
    }

    final message = auth.error;
    if (message != null && message != 'Connexion Google annulée.') {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  Future<String?> _askPhoneNumber() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Votre numéro de téléphone'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Numéro de téléphone',
              hintText: 'Ex. : 01XXXXXXXX',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 8) {
                return 'Saisissez un numéro de téléphone valide.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, controller.text.trim());
              }
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return OutlinedButton.icon(
      onPressed: loading ? null : _continueWithGoogle,
      icon: loading
          ? const SizedBox(
              width: 19,
              height: 19,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.g_mobiledata, size: 28),
      label: Text(widget.compact ? 'Google' : 'Continuer avec Google'),
      style: OutlinedButton.styleFrom(
        minimumSize: Size.fromHeight(widget.compact ? 44 : 48),
        foregroundColor: const Color(0xFF202124),
        side: const BorderSide(color: Color(0xFFDADCE0)),
      ),
    );
  }
}
