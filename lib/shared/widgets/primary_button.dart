import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/theme_extensions.dart';

/// Botão primário do DoseCerta — pill 9999, fundo `--c-brand`, glow vermelho
/// vindo de SKILL §6 (`--shadow-btn`). Variante `large` aumenta o glow para
/// telas-de-sucesso (`--shadow-btn-lg`).
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.trailingIcon = Icons.arrow_forward,
    this.leadingIcon,
    this.size = PrimaryButtonSize.large,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? trailingIcon;
  final IconData? leadingIcon;
  final PrimaryButtonSize size;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    final double height;
    final double fontSize;
    final EdgeInsetsGeometry padding;
    switch (size) {
      case PrimaryButtonSize.large:
        height = 56;
        fontSize = 18;
        padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
      case PrimaryButtonSize.medium:
        height = 52;
        fontSize = 16;
        padding = const EdgeInsets.symmetric(horizontal: 28, vertical: 14);
      case PrimaryButtonSize.small:
        height = 40;
        fontSize = 14;
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 8);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        boxShadow: disabled
            ? null
            : const [
                BoxShadow(
                  color: AppColors.primaryShadow,
                  blurRadius: 24,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: context.appSurfaceAlt,
            foregroundColor: Colors.white,
            disabledForegroundColor: context.appTextMuted,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            elevation: 0,
            padding: padding,
          ),
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(leadingIcon, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 8),
                      Icon(trailingIcon, size: 20),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

enum PrimaryButtonSize { small, medium, large }
