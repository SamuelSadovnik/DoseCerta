import 'package:flutter/material.dart';

import 'app_colors.dart';

extension DoseCertaTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get appBackground => Theme.of(this).scaffoldBackgroundColor;

  Color get appSurface => isDark ? const Color(0xFF1B1F1F) : AppColors.surface;

  Color get appSurfaceAlt =>
      isDark ? const Color(0xFF242828) : AppColors.surfaceAlt;

  Color get appTextPrimary =>
      isDark ? const Color(0xFFF7F2F1) : AppColors.textPrimary;

  Color get appTextSecondary =>
      isDark ? const Color(0xFFD8C7C5) : AppColors.textSecondary;

  Color get appTextMuted =>
      isDark ? const Color(0xFFAC9996) : AppColors.textMuted;

  Color get appDivider => isDark ? const Color(0xFF3B3030) : AppColors.divider;

  Color get appTopBar => isDark
      ? const Color(0xFF151818).withValues(alpha: 0.92)
      : Colors.white.withValues(alpha: 0.85);

  Color get appNavBar => isDark
      ? const Color(0xFF151818).withValues(alpha: 0.94)
      : Colors.white.withValues(alpha: 0.85);
}
