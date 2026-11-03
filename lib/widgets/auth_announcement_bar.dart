import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// Bande d'annonce défilante commune aux écrans d'authentification.
class AuthAnnouncementBar extends StatefulWidget {
  const AuthAnnouncementBar({super.key});

  @override
  State<AuthAnnouncementBar> createState() => _AuthAnnouncementBarState();
}

class _AuthAnnouncementBarState extends State<AuthAnnouncementBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const String _message =
      'MA LIVRAISON  •  RAPIDITÉ  •  FIABILITÉ  •  SÉCURITÉ  •  MON COLIS, UN CLIN D’ŒIL ET C’EST LIVRÉ';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: double.infinity,
      color: AppColors.primaryDark,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const contentWidth = 1520.0;
            final content = SizedBox(
              width: contentWidth,
              child: Row(
                children: const [
                  SizedBox(width: 760, child: _AnnouncementText(_message)),
                  SizedBox(width: 44),
                  SizedBox(width: 716, child: _AnnouncementText(_message)),
                ],
              ),
            );
            return AnimatedBuilder(
              animation: _controller,
              child: content,
              builder: (context, child) {
                final dx = constraints.maxWidth -
                    (_controller.value * (constraints.maxWidth + contentWidth));
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: SizedBox(
                    width: contentWidth,
                    height: 44,
                    child: Center(child: child),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AnnouncementText extends StatelessWidget {
  final String text;
  const _AnnouncementText(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        maxLines: 1,
        softWrap: false,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: .45,
        ),
      );
}
