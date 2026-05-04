import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/theme_extensions.dart';

/// Variantes do input — SKILL §8.2.
enum LabeledTextFieldVariant {
  /// Pill cinza (`--c-bg-input`) com radius 32 — usado em todos os forms.
  pill,

  /// Card branco com radius 6, sem fundo cinza — usado só na tela de Login.
  rect,
}

enum LabelStyle { normal, uppercase }

class LabeledTextField extends StatelessWidget {
  const LabeledTextField({
    super.key,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.errorText,
    this.labelStyle = LabelStyle.uppercase,
    this.controller,
    this.readOnly = false,
    this.onTap,
    this.initialValue,
    this.variant = LabeledTextFieldVariant.pill,
  });

  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? errorText;
  final LabelStyle labelStyle;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? initialValue;
  final LabeledTextFieldVariant variant;

  @override
  Widget build(BuildContext context) {
    final isUppercase = labelStyle == LabelStyle.uppercase;
    final TextStyle resolvedLabelStyle = isUppercase
        ? TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: context.appTextPrimary,
          )
        : TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.appTextPrimary,
          );

    final String? labelText = label == null
        ? null
        : (isUppercase ? label!.toUpperCase() : label);

    final InputDecoration decoration = variant == LabeledTextFieldVariant.rect
        ? _rectDecoration(context, hint: hint, errorText: errorText)
        : _pillDecoration(context, hint: hint, errorText: errorText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelText != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(labelText, style: resolvedLabelStyle),
          ),
        ],
        TextFormField(
          controller: controller,
          initialValue: controller == null ? initialValue : null,
          onChanged: onChanged,
          obscureText: obscureText,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: context.appTextPrimary,
          ),
          decoration: decoration.copyWith(
            prefixIcon: prefixIcon == null
                ? null
                : Padding(
                    padding: const EdgeInsets.only(left: 16, right: 8),
                    child: Icon(
                      prefixIcon,
                      color: context.appTextSecondary.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 24,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  InputDecoration _pillDecoration(
    BuildContext context, {
    String? hint,
    String? errorText,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: context.appSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: TextStyle(
        color: AppColors.textPlaceholder,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  InputDecoration _rectDecoration(
    BuildContext context, {
    String? hint,
    String? errorText,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      borderSide: BorderSide(color: context.appDivider, width: 1),
    );
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      filled: true,
      fillColor: context.appSurfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: TextStyle(
        color: AppColors.textPlaceholder,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}
