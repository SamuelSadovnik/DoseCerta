import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/account_type.dart';
import '../../../core/providers/account_type_provider.dart';
import '../../../core/providers/selected_dependent_provider.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/dosecerta_bottom_nav.dart';
import '../../appointments/presentation/providers/appointment_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../dependents/presentation/providers/dependent_providers.dart';
import '../../history/presentation/providers/history_providers.dart';
import '../../home/presentation/providers/home_providers.dart';
import '../../stock/presentation/providers/stock_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountType = ref.watch(currentAccountTypeProvider);
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final dependentsAsync = ref.watch(dependentsProvider);
    final linkedDependent = accountType == AccountType.personal
        ? dependentsAsync.maybeWhen(
            data: (deps) => deps.where((d) => d.isLinked).firstOrNull,
            orElse: () => null,
          )
        : null;
    final responsibleText = accountType == AccountType.personal
        ? dependentsAsync.when(
            data: (_) => linkedDependent?.caregiverName ?? 'Vincular',
            loading: () => 'Verificando...',
            error: (_, _) => 'Atualizar',
          )
        : null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.huge + AppSpacing.huge + AppSpacing.md,
                ),
                children: [
                  const Center(child: _Avatar()),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      user?.name ?? 'Usuário',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      user?.email ?? 'email não disponível',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionLabel('Conta'),
                  const SizedBox(height: AppSpacing.md),
                  _ProfileGroup(
                    children: [
                      _ProfileItem(
                        icon: Icons.medical_services_outlined,
                        label: 'Cartão de saúde',
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.profileAdditionalInfo),
                      ),
                      _ProfileItem(
                        icon: Icons.contact_emergency_outlined,
                        label: 'Rede de emergência',
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.profileEmergencyContacts),
                      ),
                      _ProfileItem(
                        icon: Icons.emergency_share_outlined,
                        label: 'Botão de emergência',
                        trailingText: 'SOS',
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.emergency),
                      ),
                      if (accountType == AccountType.caregiver)
                        _ProfileItem(
                          icon: Icons.family_restroom,
                          label: 'Pessoas cuidadas',
                          badge: dependentsAsync.maybeWhen(
                            data: (deps) => deps.isEmpty
                                ? null
                                : '${deps.length} ${deps.length == 1 ? 'ativo' : 'ativos'}',
                            orElse: () => null,
                          ),
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.dependents),
                        ),
                      if (accountType == AccountType.personal)
                        _ProfileItem(
                          icon: linkedDependent == null
                              ? Icons.link
                              : Icons.verified_user_outlined,
                          label: 'Responsável',
                          trailingText: responsibleText,
                          onTap: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.linkDependent),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _SectionLabel('Preferências'),
                  const SizedBox(height: AppSpacing.sm),
                  _ProfileGroup(
                    children: [
                      _ProfileItem(
                        icon: Icons.notifications_outlined,
                        label: 'Notificações',
                        trailingText: 'Ativadas',
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.profileNotifications),
                      ),
                      _ProfileItem(
                        icon: Icons.shield_outlined,
                        label: 'Privacidade e segurança',
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.profilePrivacySecurity),
                      ),
                      _ProfileItem(
                        icon: Icons.dark_mode_outlined,
                        label: 'Tema',
                        trailingText: _themeLabel(themeMode),
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.profileTheme),
                      ),
                      _ProfileItem(
                        icon: Icons.info_outline,
                        label: 'Sobre o DoseCerta',
                        onTap: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.profileAbout),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _LogoutButton(
                    onTap: () async {
                      await ref.read(authRepositoryProvider).logout();
                      ref.read(selectedCareContextProvider.notifier).state =
                          const CareContext.allDependents();
                      ref.read(currentAccountTypeProvider.notifier).state =
                          AccountType.personal;
                      ref.invalidate(currentUserProvider);
                      ref.invalidate(homeDataProvider);
                      ref.invalidate(medicationsProvider);
                      ref.invalidate(historySummariesProvider);
                      ref.invalidate(appointmentsProvider);
                      ref.invalidate(dependentsProvider);
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          AppRoutes.login,
                          (_) => false,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DoseCertaBottomNav(
        currentIndex: 4,
        onTap: (index) => _navigate(context, index),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.stock);
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.history);
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.appointments);
      case 4:
        break;
    }
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Escuro';
      case ThemeMode.system:
        return 'Sistema';
      case ThemeMode.light:
        return 'Claro';
    }
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

class _Avatar extends StatelessWidget {
  const _Avatar();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 88,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.person, size: 48, color: AppColors.primary),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ProfileGroup extends StatelessWidget {
  const _ProfileGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 56,
                endIndent: 16,
                color: Theme.of(context).dividerColor,
              ),
          ],
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingText,
    this.badge,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailingText;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ] else if (trailingText != null) ...[
              Text(
                trailingText!,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right, color: context.appTextMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: AppColors.error, size: 18),
            const SizedBox(width: 8),
            Text(
              'Sair da conta',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
