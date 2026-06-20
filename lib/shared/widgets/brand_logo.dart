import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

const _logoAsset = 'assets/images/logoDoseCerta.png';
const _logoIconAsset = 'assets/images/logoDoseCertaIcon.png';
const _logoAspectRatio = 259 / 205;

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
    if (!showWordmark) {
      return _BrandLogoIcon(size: iconSize);
    }

    final logoHeight = iconSize + fontSize + 18;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          _logoAsset,
          height: logoHeight,
          width: logoHeight * _logoAspectRatio,
          fit: BoxFit.contain,
          semanticLabel: 'DoseCerta',
          errorBuilder: (context, error, stackTrace) =>
              _BrandLogoFallback(iconSize: iconSize, fontSize: fontSize),
        ),
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
        const _BrandLogoIcon(size: 32),
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

class _BrandLogoIcon extends StatelessWidget {
  const _BrandLogoIcon({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: FittedBox(
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 130,
            height: 130,
            child: Image.asset(
              _logoIconAsset,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              semanticLabel: 'DoseCerta',
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.primary,
                alignment: Alignment.center,
                child: Icon(
                  Icons.medication,
                  color: Colors.white,
                  size: size * 0.58,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandLogoFallback extends StatelessWidget {
  const _BrandLogoFallback({required this.iconSize, required this.fontSize});

  final double iconSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BrandLogoIcon(size: iconSize),
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
    );
  }
}
