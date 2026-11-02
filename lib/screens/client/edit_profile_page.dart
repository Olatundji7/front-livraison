import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Modification des informations du client et de son mot de passe.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _infoKey = GlobalKey<FormState>();
  final _pwdKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  final _currentForInfo = TextEditingController();
  final _currentPwd = TextEditingController();
  final _newPwd = TextEditingController();
  final _confirmPwd = TextEditingController();

  late final String _initialPhone;
  late final String _initialEmail;

  bool _savingInfo = false;
  bool _savingPwd = false;
  bool _hide = true;
  String? _infoError;
  String? _pwdError;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _initialPhone = (user?.telephone ?? '').trim();
    _initialEmail = (user?.email ?? '').trim();
    _name = TextEditingController(text: user?.nom ?? '');
    _phone = TextEditingController(text: _initialPhone);
    _email = TextEditingController(text: _initialEmail);
    _phone.addListener(() => setState(() {}));
    _email.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _currentForInfo, _currentPwd, _newPwd, _confirmPwd]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Le téléphone et l'e-mail servent à se connecter et à récupérer le compte :
  /// les changer demande le mot de passe actuel.
  bool get _sensitiveChanged =>
      _phone.text.trim() != _initialPhone ||
      _email.text.trim().toLowerCase() != _initialEmail.toLowerCase();

  Future<void> _saveInfo() async {
    if (!(_infoKey.currentState?.validate() ?? false)) return;
    if (_sensitiveChanged && _currentForInfo.text.isEmpty) {
      setState(() => _infoError = 'Saisissez votre mot de passe actuel pour changer le téléphone ou l’e-mail.');
      return;
    }
    setState(() {
      _savingInfo = true;
      _infoError = null;
    });
    final error = await context.read<AuthProvider>().updateProfile(
          nom: _name.text,
          telephone: _phone.text,
          email: _email.text,
          currentPassword: _sensitiveChanged ? _currentForInfo.text : null,
        );
    if (!mounted) return;
    setState(() => _savingInfo = false);
    if (error != null) {
      setState(() => _infoError = error);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(const SnackBar(content: Text('Informations mises à jour.')));
  }

  Future<void> _savePassword() async {
    if (!(_pwdKey.currentState?.validate() ?? false)) return;
    setState(() {
      _savingPwd = true;
      _pwdError = null;
    });
    final error = await context.read<AuthProvider>().changePassword(
          currentPassword: _currentPwd.text,
          newPassword: _newPwd.text,
        );
    if (!mounted) return;
    setState(() => _savingPwd = false);
    if (error != null) {
      setState(() => _pwdError = error);
      return;
    }
    _currentPwd.clear();
    _newPwd.clear();
    _confirmPwd.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mot de passe modifié. Vos autres appareils sont déconnectés.')),
    );
  }

  InputDecoration _deco(String label, IconData icon, {String? helper}) => InputDecoration(
        labelText: label,
        helperText: helper,
        helperMaxLines: 3,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      );

  Widget _error(String? text) => text == null
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(text, style: const TextStyle(color: Colors.red)),
        );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Modifier mes informations')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _infoKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mes informations', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _name,
                          textCapitalization: TextCapitalization.words,
                          decoration: _deco('Nom complet', Icons.person_outline),
                          validator: (v) => (v ?? '').trim().isEmpty ? 'Le nom est obligatoire.' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _phone,
                          keyboardType: TextInputType.phone,
                          decoration: _deco('Téléphone', Icons.phone_outlined,
                              helper: 'Ce numéro sert à vous connecter.'),
                          validator: (v) => (v ?? '').trim().length < 8 ? 'Numéro de téléphone invalide.' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _deco('Adresse e-mail', Icons.mail_outline,
                              helper: 'Nécessaire pour récupérer votre mot de passe si vous l’oubliez.'),
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return null;
                            return value.contains('@') && value.contains('.') ? null : 'Adresse e-mail invalide.';
                          },
                        ),
                        if (_sensitiveChanged) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _currentForInfo,
                            obscureText: _hide,
                            decoration: _deco('Mot de passe actuel', Icons.lock_outline,
                                helper: 'Demandé pour changer le téléphone ou l’e-mail.'),
                          ),
                        ],
                        _error(_infoError),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _savingInfo ? null : _saveInfo,
                            icon: _savingInfo
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.save_outlined),
                            label: const Text('Enregistrer'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Form(
                    key: _pwdKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Changer mon mot de passe',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                            IconButton(
                              tooltip: _hide ? 'Afficher' : 'Masquer',
                              onPressed: () => setState(() => _hide = !_hide),
                              icon: Icon(_hide ? Icons.visibility_off : Icons.visibility),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _currentPwd,
                          obscureText: _hide,
                          decoration: _deco('Mot de passe actuel', Icons.lock_outline),
                          validator: (v) => (v ?? '').isEmpty ? 'Saisissez votre mot de passe actuel.' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _newPwd,
                          obscureText: _hide,
                          decoration: _deco('Nouveau mot de passe', Icons.lock_reset),
                          validator: (v) => (v ?? '').length < 6 ? 'Au moins 6 caractères.' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmPwd,
                          obscureText: _hide,
                          decoration: _deco('Confirmer le nouveau mot de passe', Icons.lock_reset),
                          validator: (v) => v != _newPwd.text ? 'Les deux mots de passe ne sont pas identiques.' : null,
                        ),
                        _error(_pwdError),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _savingPwd ? null : _savePassword,
                            icon: _savingPwd
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.key_outlined),
                            label: const Text('Modifier le mot de passe'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
