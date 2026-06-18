import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'emergency_button.dart';
import 'error_icon.dart';
import 'primary_button.dart';
import 'secondary_button.dart';
import 'success_icon.dart';

enum FeedbackIconType { successGreen, successRed, error }

enum FeedbackButtonStyle { primary, secondary }

class FeedbackButton {
  const FeedbackButton({
    required this.label,
    required this.onPressed,
    this.style = FeedbackButtonStyle.primary,
    this.trailingIcon,
  });

  final String label;
  final VoidCallback onPressed;
  final FeedbackButtonStyle style;
  final IconData? trailingIcon;
}

class FeedbackPageConfig {
  const FeedbackPageConfig({
    required this.iconType,
    required this.title,
    this.subtitle,
    this.buttons = const [],
    this.showBackButton = false,
    this.onBack,
    this.showEmergencyButton = false,
    this.onEmergency,
    this.emergencyTitle = 'Emergência',
    this.emergencySubtitle = 'Abrir ações de ajuda',
    this.headerOverride,
  });

  final FeedbackIconType iconType;
  final String title;
  final String? subtitle;
  final List<FeedbackButton> buttons;
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showEmergencyButton;
  final VoidCallback? onEmergency;
  final String emergencyTitle;
  final String emergencySubtitle;
  final Widget? headerOverride;
}

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key, required this.config});

  final FeedbackPageConfig config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            children: [
              if (config.showBackButton)
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: config.onBack ?? () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (config.headerOverride != null)
                      config.headerOverride!
                    else
                      _buildIcon(),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      config.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.75,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.25,
                      ),
                    ),
                    if (config.subtitle != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          config.subtitle!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              for (var i = 0; i < config.buttons.length; i++) ...[
                _buildButton(config.buttons[i]),
                if (i < config.buttons.length - 1)
                  const SizedBox(height: AppSpacing.md),
              ],
              if (config.showEmergencyButton) ...[
                const SizedBox(height: AppSpacing.md),
                EmergencyButton(
                  title: config.emergencyTitle,
                  subtitle: config.emergencySubtitle,
                  onPressed: config.onEmergency ?? () {},
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    switch (config.iconType) {
      case FeedbackIconType.successGreen:
        return const SuccessIconGreen();
      case FeedbackIconType.successRed:
        return const SuccessIconRed();
      case FeedbackIconType.error:
        return const ErrorIcon();
    }
  }

  Widget _buildButton(FeedbackButton button) {
    return switch (button.style) {
      FeedbackButtonStyle.primary => PrimaryButton(
        label: button.label,
        onPressed: button.onPressed,
        trailingIcon: button.trailingIcon,
      ),
      FeedbackButtonStyle.secondary => SecondaryButton(
        label: button.label,
        onPressed: button.onPressed,
        trailingIcon: button.trailingIcon,
      ),
    };
  }
}
