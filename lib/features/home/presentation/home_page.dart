import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/enums/account_type.dart';
import '../../../core/providers/account_type_provider.dart';
import '../../../core/providers/selected_dependent_provider.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/dependent_context_selector.dart';
import '../../../shared/widgets/dosecerta_bottom_nav.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../../dependents/presentation/providers/dependent_providers.dart';
import '../domain/entities/dose_schedule.dart';
import '../domain/entities/home_data.dart';
import 'providers/home_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      ref.invalidate(homeDataProvider);
      ref.invalidate(dependentsProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final homeAsync = ref.watch(homeDataProvider);
    final accountType = ref.watch(currentAccountTypeProvider);
    final user = ref.watch(currentUserProvider);
    final selectedDependentId = ref.watch(selectedCareDependentIdProvider);
    final dependentsAsync = ref.watch(dependentsProvider);
    final selectedDependentName = selectedDependentId == null
        ? null
        : dependentsAsync.maybeWhen(
            data: (deps) => deps
                .where((d) => d.id == selectedDependentId)
                .map((d) => d.name)
                .firstOrNull,
            orElse: () => null,
          );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppTopBar(),
            Expanded(
              child: homeAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro ao carregar: $e')),
                data: (data) => _HomeBody(
                  data: data,
                  accountType: accountType,
                  userName: user?.name,
                  selectedDependentName: selectedDependentName,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DoseCertaBottomNav(
        currentIndex: 0,
        onTap: (index) => _navigate(context, index),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.stock);
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.history);
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.appointments);
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
    }
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.data,
    required this.accountType,
    required this.userName,
    required this.selectedDependentName,
  });

  final HomeData data;
  final AccountType accountType;
  final String? userName;
  final String? selectedDependentName;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, d \'de\' MMMM', 'pt_BR');
    final dateText = _capitalize(dateFormat.format(DateTime.now()));
    final nextTime = data.nextDoseTime == null
        ? '--:--'
        : DateFormat('HH:mm').format(data.nextDoseTime!);
    final firstName = (userName ?? '').split(' ').first;
    final greeting = _greetingFor(DateTime.now().hour);
    final isCaregiver = accountType == AccountType.caregiver;
    final viewing = selectedDependentName == null
        ? (isCaregiver ? 'Visualizando todos os dependentes' : null)
        : 'Visualizando ${selectedDependentName!.split(' ').first}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.huge + AppSpacing.lg,
      ),
      children: [
        Text(
          firstName.isEmpty ? '$greeting!' : '$greeting, $firstName',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          viewing ?? dateText,
          style: TextStyle(
            color: viewing != null
                ? AppColors.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
            fontWeight: viewing != null ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        if (isCaregiver) ...[
          const SizedBox(height: AppSpacing.md),
          const DependentContextSelector(),
        ],
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _BentoCard(
                icon: Icons.check_circle_outline,
                iconBackground: AppColors.primaryLight,
                iconColor: AppColors.primary,
                value: '${data.dosesTakenToday}/${data.dosesTotalToday}',
                label: 'Doses tomadas',
              ),
            ),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: _BentoCard(
                icon: Icons.schedule,
                iconBackground: AppColors.successLight,
                iconColor: AppColors.success,
                value: nextTime,
                label: 'Próxima dose',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isCaregiver ? 'Agenda de doses' : 'Medicamentos de hoje',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
            letterSpacing: -0.45,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ..._buildDoseItems(context),
      ],
    );
  }

  static String _greetingFor(int hour) {
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  List<Widget> _buildDoseItems(BuildContext context) {
    if (data.todayDoses.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Text(
              'Nenhuma dose agendada por enquanto.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ];
    }

    final now = DateTime.now();
    final nextActionId = data.todayDoses
        .where(
          (d) =>
              (d.status == DoseStatus.pending ||
                  d.status == DoseStatus.postponed) &&
              !d.scheduledAt.isBefore(now),
        )
        .firstOrNull
        ?.id;
    final items = <Widget>[];
    DateTime? currentDay;
    for (final dose in data.todayDoses) {
      final day = DateTime(
        dose.scheduledAt.year,
        dose.scheduledAt.month,
        dose.scheduledAt.day,
      );
      if (currentDay != day) {
        currentDay = day;
        items.add(_DayHeader(date: day));
      }
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _DoseItem(
            dose: dose,
            isActive: dose.id == nextActionId,
            showDependent: accountType == AccountType.caregiver,
            onTap: dose.id == nextActionId
                ? () => Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.alertMedication, arguments: dose)
                : null,
          ),
        ),
      );
    }
    return items;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final label = date == today
        ? 'Hoje'
        : date == tomorrow
        ? 'Amanhã'
        : DateFormat('EEEE, d \'de\' MMMM', 'pt_BR').format(date);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Text(
        _HomeBody._capitalize(label).toUpperCase(),
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

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl - 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _DoseItem extends StatelessWidget {
  const _DoseItem({
    required this.dose,
    required this.isActive,
    required this.showDependent,
    required this.onTap,
  });

  final DoseSchedule dose;
  final bool isActive;
  final bool showDependent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm').format(dose.scheduledAt);
    final isTaken = dose.status == DoseStatus.taken;
    final isMissed = dose.status == DoseStatus.missed;
    final isFuture = dose.status == DoseStatus.pending && !isActive;

    final Color background;
    final List<BoxShadow> shadows;
    Border? border;
    final double opacity;

    if (isTaken) {
      background = context.appSurface;
      shadows = const [];
      opacity = 0.65;
    } else if (isMissed) {
      background = context.appSurface;
      shadows = const [];
      opacity = 0.65;
    } else if (isActive) {
      background = context.appSurface;
      shadows = context.isDark
          ? const []
          : const [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 6,
                offset: Offset(0, 4),
              ),
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ];
      border = const Border(
        left: BorderSide(color: AppColors.primary, width: 4),
      );
      opacity = 1.0;
    } else if (isFuture) {
      background = context.appSurfaceAlt;
      shadows = const [];
      opacity = 1.0;
    } else {
      background = context.appSurface;
      shadows = const [];
      opacity = 1.0;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.only(topRight: Radius.circular(28)),
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(28),
            ),
            border: border,
            boxShadow: shadows,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  time,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.primary
                        : context.appTextSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: context.appDivider,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dose.medicationName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dose.dosage,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (showDependent && dose.dependentName != null) ...[
                _DependentAvatar(name: dose.dependentName!),
                const SizedBox(width: 8),
              ],
              _statusIndicator(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIndicator(BuildContext context) {
    switch (dose.status) {
      case DoseStatus.taken:
        return Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(Icons.done_all, color: AppColors.success, size: 18),
        );
      case DoseStatus.missed:
        return Icon(Icons.close, color: AppColors.error, size: 24);
      case DoseStatus.postponed:
        return Icon(
          Icons.snooze,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 24,
        );
      case DoseStatus.pending:
        if (isActive) {
          // CTA inline pill com glow vermelho.
          return Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.all(Radius.circular(AppRadius.pill)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryShadow,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              showDependent && dose.dependentId != null ? 'Tomou' : 'Tomar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.iconInactive, width: 2),
          ),
        );
    }
  }
}

class _DependentAvatar extends StatelessWidget {
  const _DependentAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.primaryLight,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.primaryDark,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
