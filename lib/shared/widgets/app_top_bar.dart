import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_controller.dart';
import '../../core/theme/theme_extensions.dart';
import 'brand_logo.dart';

/// Top app bar do DoseCerta — frosted-glass branco translúcido (SKILL §8.5).
class AppTopBar extends ConsumerWidget {
  const AppTopBar({
    super.key,
    this.showBackButton = false,
    this.onBack,
    this.trailing,
    this.showSettings = false,
    this.onSettingsTap,
    this.onNotificationsTap,
    this.title,
  });

  final bool showBackButton;
  final VoidCallback? onBack;
  final Widget? trailing;
  final bool showSettings;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onNotificationsTap;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final platformDark =
        MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && platformDark);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 64,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          color: context.appTopBar,
          child: Row(
            children: [
              if (showBackButton)
                _BackPill(
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                )
              else
                const BrandLogoCompact(),
              if (title != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.45,
                      color: context.appTextPrimary,
                    ),
                  ),
                ),
              ] else
                const Spacer(),
              if (trailing != null)
                trailing!
              else if (showSettings)
                IconButton(
                  onPressed: onSettingsTap,
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.primary,
                  ),
                )
              else
                IconButton(
                  tooltip: isDark ? 'Tema claro' : 'Tema escuro',
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    color: context.appTextSecondary,
                  ),
                  onPressed: () => ref
                      .read(themeModeProvider.notifier)
                      .setMode(isDark ? ThemeMode.light : ThemeMode.dark),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackPill extends StatelessWidget {
  const _BackPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.arrow_back, color: Colors.white, size: 20),
      ),
    );
  }
}
