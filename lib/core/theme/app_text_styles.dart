import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografia DoseCerta — Plus Jakarta Sans, escala discreta mobile-first
/// (SKILL §3). Letter-spacing negativo em headings grandes, positivo em labels
/// ALL CAPS.
class AppTextStyles {
  AppTextStyles._();

  // --- Títulos ---
  static const TextStyle h1 = TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.w800,
    height: 1.25,
    letterSpacing: -0.75,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: -0.45,
    color: AppColors.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // --- Body ---
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = body;

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // --- Labels ---
  /// Labels de seção/form em ALL CAPS, peso 700, 12px.
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelUppercase = label;

  static const TextStyle labelNormal = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // --- Caption ---
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.textSecondary,
  );

  // --- Botões ---
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  // --- Apelidos legados ---
  static const TextStyle sectionTitle = h1;
  static const TextStyle modalTitle = h2;
}
