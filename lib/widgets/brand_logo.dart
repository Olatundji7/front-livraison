import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            AppAssets.logo,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: size,
              height: size,
              color: AppColors.primaryLight,
              child: const Icon(Icons.delivery_dining, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MA Livraison',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
            ),
            Text(
              'Rapide • Sûre • Partout',
              style: TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ],
    );
  }
}
