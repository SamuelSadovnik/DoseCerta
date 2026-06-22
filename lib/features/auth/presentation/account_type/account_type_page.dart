import 'package:flutter/material.dart';

import '../../../../core/enums/account_type.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/form_app_bar.dart';

class AccountTypePage extends StatelessWidget {
  const AccountTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const FormAppBar(title: 'Criar conta'),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              Text(
                'Criar conta',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.75,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Como você vai usar o DoseCerta?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _ChoiceCard(
                icon: Icons.person_outline,
                title: 'Minha saúde',
                description:
                    'Controle seus remédios, consultas, estoque e lembretes. Se receber um código, você pode vincular um responsável depois.',
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.register,
                  arguments: AccountType.personal,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _ChoiceCard(
                icon: Icons.family_restroom,
                title: 'Cuidar de alguém',
                description:
                    'Acompanhe medicamentos, consultas e histórico de uma pessoa cuidada. Ela não precisa ter conta própria.',
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.register,
                  arguments: AccountType.caregiver,
                ),
              ),
              const Spacer(),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: Icon(
                    Icons.arrow_back,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  label: Text(
                    'Voltar para login',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: Colors.transparent, width: 2),
          ),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward, color: AppColors.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
