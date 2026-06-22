import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';

/// Hero banner DoseCerta — fundo `red-500`, raio 48, badge frosted opcional
/// "Segurança e cuidado" (SKILL §8.4).
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.title,
    this.badge,
    this.subtitle,
    this.imageAsset,
    this.height = 160,
  });

  final String title;
  final String? badge;
  final String? subtitle;
  final String? imageAsset;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.hero),
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: height,
            color: AppColors.primaryHero,
          ),
          // Textura sutil — se asset disponível, blend overlay; senão, sobrepõe
          // um degradê radial branco-suave para dar a sensação "de tecido".
          if (imageAsset != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.30,
                child: Image.asset(imageAsset!, fit: BoxFit.cover),
              ),
            )
          else
            const Positioned.fill(child: _SubtleNoiseOverlay()),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (badge != null) _Badge(text: badge!) else const SizedBox(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.75,
                        height: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubtleNoiseOverlay extends StatelessWidget {
  const _SubtleNoiseOverlay();

  @override
  Widget build(BuildContext context) {
    // Simula a textura PNG da SKILL via dois círculos translúcidos —
    // suficiente para tirar a sensação chapada do fundo sólido.
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.7, -0.8),
          radius: 1.4,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.white.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}
