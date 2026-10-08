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

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (_, auth, __) {
        if (auth.initializing) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
      },
    );
  }
}
