import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/auth_provider.dart';

class GoogleAuthButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  const GoogleAuthButton({super.key, this.onSuccess});

  @override
  State<GoogleAuthButton> createState() => _GoogleAuthButtonState();
}

class _GoogleAuthButtonState extends State<GoogleAuthButton> {
  Future<String?> _askPhone() async {
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
              labelText: 'Téléphone',
              hintText: '+229…',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: (value) => value == null || value.trim().length < 8
                ? 'Saisissez un numéro de téléphone valide.'
                : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
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

  Future<void> _continue() async {
    final auth = context.read<AuthProvider>();
    var ok = await auth.loginWithGoogle();
    if (!mounted) return;
    if (!ok && auth.googlePhoneRequired) {
      final phone = await _askPhone();
      if (!mounted || phone == null) return;
      ok = await auth.completeGoogleSignIn(telephone: phone);
    }
    if (!mounted) return;
    if (ok) {
      widget.onSuccess?.call();
    } else if (auth.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error!), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return OutlinedButton.icon(
      onPressed: loading ? null : _continue,
      icon: loading
          ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.g_mobiledata, size: 28),
      label: const Text('Continuer avec Google'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: AppColors.text,
        side: BorderSide(color: AppColors.primary.withValues(alpha: .25)),
      ),
    );
  }
}
