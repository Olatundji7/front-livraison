import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_colors.dart';

/// Écran de démarrage plein écran : logo, slogan et barre de chargement.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    // Plein écran : barres du système masquées pendant l'écran de démarrage.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    // Retour à l'affichage normal avec les barres du système.
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    _controller.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/ma_livraison_background.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFE6EEFF),
                child: Center(
                  child: Icon(Icons.delivery_dining, size: 100, color: AppColors.primary),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.transparent, Colors.black54],
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: const Text(
                        'Préparation de votre livraison...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 150,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: const LinearProgressIndicator(
                        minHeight: 5,
                        color: Colors.white,
                        backgroundColor: Colors.white38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 35),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
