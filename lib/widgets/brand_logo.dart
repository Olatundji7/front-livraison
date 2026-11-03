import 'package:flutter/material.dart';

import '../core/app_assets.dart';
import '../core/app_colors.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final double titleSize;

  const BrandLogo({super.key, this.size = 48, this.titleSize = 22});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            AppAssets.logo,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: size,
              height: size,
              color: AppColors.primaryLight,
              alignment: Alignment.center,
              child: const Icon(Icons.delivery_dining, color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MA LIVRAISON',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: titleSize,
                  height: 1.05,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.35,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Rapidité • Fiabilité • Sécurité',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
