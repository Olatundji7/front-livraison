import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_logo.dart';
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
  void dispose() { phone.dispose(); password.dispose(); super.dispose(); }

  Future<void> submit() async {
    final auth = context.read<AuthProvider>();
    if (phone.text.trim().isEmpty || password.text.isEmpty) return;
    final ok = await auth.login(telephone: phone.text.trim(), password: password.text);
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.error ?? 'Connexion impossible.')));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Connexion')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(children: [
                  const BrandLogo(size: 64),
                  const SizedBox(height: 22),
                  const Text('Se connecter', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 24),
                  TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone', prefixIcon: Icon(Icons.phone_outlined))),
                  const SizedBox(height: 14),
                  TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Mot de passe', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_off : Icons.visibility)))),
                  if (auth.error != null) ...[
                    const SizedBox(height: 12),
                    Text(auth.error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(width: double.infinity, child: ElevatedButton(onPressed: auth.loading ? null : submit, child: auth.loading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Se connecter'))),
                  TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterPage())), child: const Text('Créer un compte client')),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
