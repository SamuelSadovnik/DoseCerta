import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.iconSize = 96,
    this.fontSize = 32,
    this.showWordmark = true,
  });

  final double iconSize;
  final double fontSize;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // TODO: trocar por asset PNG quando disponível.
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.logo),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.medication,
            color: Colors.white,
            size: iconSize * 0.58,
          ),
        ),
        if (showWordmark) ...[
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              children: [
                const TextSpan(
                  text: 'Dose',
                  style: TextStyle(color: AppColors.primary),
                ),
                TextSpan(
                  text: 'Certa',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class BrandLogoCompact extends StatelessWidget {
  const BrandLogoCompact({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.medication, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 8),
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            children: [
              const TextSpan(
                text: 'Dose',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(
                text: 'Certa',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
