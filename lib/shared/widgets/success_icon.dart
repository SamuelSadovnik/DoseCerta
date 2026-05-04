import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Ícone de sucesso verde — check teal sobre fundo `--c-success` 10%.
class SuccessIconGreen extends StatelessWidget {
  const SuccessIconGreen({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.successLight,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.check_rounded,
        color: AppColors.success,
        size: size * 0.55,
      ),
    );
  }
}

/// Ícone de sucesso da marca — círculo `--c-brand-tint` (red-200) com check
/// verde de sucesso. SKILL §10.4.
class SuccessIconRed extends StatelessWidget {
  const SuccessIconRed({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryShadow,
            blurRadius: 32,
            spreadRadius: 4,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.check_rounded,
        color: AppColors.success,
        size: size * 0.5,
      ),
    );
  }
}
