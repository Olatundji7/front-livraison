import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../providers/auth_provider.dart';

/// Photo de profil ronde d'un livreur, avec icône de secours si l'image est
/// absente ou impossible à charger.
///
/// [photo] accepte `photo_url` (URL complète) ou `photo` (chemin relatif).
class DriverAvatar extends StatelessWidget {
  const DriverAvatar({super.key, required this.photo, this.radius = 24});

  final String? photo;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final url = context.read<AuthProvider>().api.mediaUrl(photo);
    final size = radius * 2;
    final fallback = Icon(Icons.person, size: radius * 1.1, color: AppColors.primary);

    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.blue.shade50,
      child: ClipOval(
        child: url == null
            ? fallback
            : Image.network(
                url,
                key: ValueKey(url),
                width: size,
                height: size,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : SizedBox(
                        width: size,
                        height: size,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                errorBuilder: (_, error, __) {
                  debugPrint('Photo livreur non chargée : $url -> $error');
                  return fallback;
                },
              ),
      ),
    );
  }
}
