import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class ErrorIcon extends StatelessWidget {
  const ErrorIcon({super.key, this.size = 140});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryLight,
            blurRadius: 32,
            spreadRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Container(
        width: size * 0.62,
        height: size * 0.62,
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.close,
          color: AppColors.primaryDark,
          size: size * 0.38,
        ),
      ),
    );
  }
}
