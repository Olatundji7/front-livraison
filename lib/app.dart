import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/register_page.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/deliverer/driver_home_page.dart';
import 'screens/client/client_home_page.dart';
import 'screens/home/home_page.dart';
import 'screens/splash_page.dart';

class MaLivraisonApp extends StatelessWidget {
  const MaLivraisonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MA Livraison',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _AppGate(),
      routes: {
        '/login': (_) => const LoginPage(),
        '/register': (_) => const RegisterPage(),
      },
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  /// Écran de démarrage sur le web : désactivé (le site d'accueil s'affiche
  /// directement). Mettre `true` pour l'afficher aussi sur le web.
  static const bool _splashOnWeb = true;

  /// Durée minimale d'affichage de l'écran de démarrage (mobile).
  static const Duration _splashDuration = Duration(milliseconds: 2200);

  bool _splashDone = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (kIsWeb && !_splashOnWeb) {
      _splashDone = true;
    } else {
      _timer = Timer(_splashDuration, () {
        if (mounted) setState(() => _splashDone = true);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _page(AuthProvider auth) {
    if (!_splashDone) return const SplashPage();
    if (auth.initializing) {
      return kIsWeb
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : const SplashPage();
    }
    if (!auth.isAuthenticated) return const HomePage();
    switch (auth.user!.role) {
      case 'admin':
        return const AdminDashboard();
      case 'driver':
        return const DriverHomePage();
      default:
        return ClientHomePage(clientName: auth.user!.nom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        child: _page(auth),
      ),
    );
  }
}
