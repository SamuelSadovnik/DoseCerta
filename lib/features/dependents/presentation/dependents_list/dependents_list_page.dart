import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/hero_card.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/dependent.dart';
import '../providers/dependent_providers.dart';

class DependentsListPage extends ConsumerWidget {
  const DependentsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dependentsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            AppTopBar(
              showBackButton: true,
              trailing: Row(
                children: [
                  Text(
                    'DoseCerta',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.pagePadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Pessoas cuidadas',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const HeroCard(
                      title: 'Cuidados Compartilhados',
                      subtitle:
                          'Acompanhe medicamentos, consultas e vínculos das pessoas sob seu cuidado.',
                      height: 160,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: async.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) =>
                            Center(child: Text('Erro ao carregar: $e')),
                        data: (deps) {
                          if (deps.isEmpty) {
                            return Center(
                              child: Text(
                                'Você ainda não cadastrou nenhuma pessoa cuidada.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: deps.length,
                            separatorBuilder: (_, _) =>
                                Divider(height: 1, color: context.appDivider),
                            itemBuilder: (_, i) => _DependentTile(
                              dependent: deps[i],
                              onTap: () => Navigator.of(context).pushNamed(
                                AppRoutes.dependentDetail,
                                arguments: deps[i],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    PrimaryButton(
                      label: 'Adicionar pessoa cuidada',
                      trailingIcon: null,
                      leadingIcon: Icons.add,
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.newDependent),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DependentTile extends StatelessWidget {
  const _DependentTile({required this.dependent, required this.onTap});

  final Dependent dependent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = _statusPresentation(dependent);

    final initial = dependent.name.isEmpty
        ? '?'
        : dependent.name[0].toUpperCase();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    initial,
                    style: TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.appBackground,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        dependent.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: context.appSurfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          dependent.relationship.label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(status.icon, size: 12, color: status.color),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 12,
                            color: status.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.appTextMuted, size: 20),
          ],
        ),
      ),
    );
  }

  _DependentStatusPresentation _statusPresentation(Dependent dependent) {
    if (dependent.isLinked) {
      return _DependentStatusPresentation(
        icon: Icons.verified_user,
        color: AppColors.success,
        label: 'Vínculo ativo',
      );
    }

    return switch (dependent.status) {
      DependentStatus.active ||
      DependentStatus.pendingConfirmation => _DependentStatusPresentation(
        icon: Icons.schedule,
        color: AppColors.primary,
        label: dependent.activationCode == null
            ? 'Aguardando código de vínculo'
            : 'Aguardando aceite do código',
      ),
      DependentStatus.overdue => _DependentStatusPresentation(
        icon: Icons.error,
        color: AppColors.error,
        label: 'Código expirado',
      ),
    };
  }
}

class _DependentStatusPresentation {
  const _DependentStatusPresentation({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}
