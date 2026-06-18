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
import '../../dependents/presentation/providers/dependent_providers.dart';
import '../domain/entities/day_dose_detail.dart';
import '../domain/entities/history_summary.dart';
import 'providers/history_providers.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountType = ref.watch(currentAccountTypeProvider);
    final selectedDependentId = ref.watch(selectedCareDependentIdProvider);
    final dependentsAsync = ref.watch(dependentsProvider);
    final month = ref.watch(selectedMonthProvider);
    final async = ref.watch(historySummariesProvider);
    final caregiverDependentsCount = accountType == AccountType.caregiver
        ? dependentsAsync.maybeWhen(
            data: (deps) => deps.length,
            orElse: () => null,
          )
        : null;
    final hasNoCareProfiles =
        accountType == AccountType.caregiver &&
        caregiverDependentsCount != null &&
        caregiverDependentsCount == 0;

    final selectedDependentName = selectedDependentId == null
        ? null
        : dependentsAsync.maybeWhen(
            data: (deps) {
              for (final dependent in deps) {
                if (dependent.id == selectedDependentId) return dependent.name;
              }
              return null;
            },
            orElse: () => null,
          );
    final monthLabel = _capitalize(DateFormat('MMMM y', 'pt_BR').format(month));
    final title = _titleFor(accountType, selectedDependentName);

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
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  AppSpacing.huge + AppSpacing.md,
                ),
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.15,
                    ),
                  ),
                  if (accountType == AccountType.caregiver) ...[
                    const SizedBox(height: AppSpacing.sm),
                    const DependentContextSelector(),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  _MonthSwitcher(
                    label: monthLabel,
                    onPrev: () =>
                        ref.read(selectedMonthProvider.notifier).state =
                            DateTime(month.year, month.month - 1),
                    onNext: () =>
                        ref.read(selectedMonthProvider.notifier).state =
                            DateTime(month.year, month.month + 1),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (hasNoCareProfiles)
                    _EmptyHistoryState(
                      onPressed: () => Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.newDependent),
                    )
                  else
                    async.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (e, _) =>
                          Center(child: Text('Erro ao carregar: $e')),
                      data: (summaries) {
                        final calendarDays = _combinedCalendarDays(
                          month,
                          summaries,
                        );
                        return Column(
                          children: [
                            _Calendar(
                              month: month,
                              days: calendarDays,
                              onDayTap: (day) =>
                                  _showDayDetails(context, ref, day.date),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _TreatmentSummarySection(
                              treatments: _combinedTreatments(summaries),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DoseCertaBottomNav(
        currentIndex: 2,
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
        break;
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.appointments);
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
    }
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _titleFor(AccountType accountType, String? dependentName) {
    if (accountType == AccountType.personal) return 'Meu histórico';
    if (dependentName != null) {
      return 'Histórico de ${dependentName.split(' ').first}';
    }
    return 'Histórico';
  }

  List<HistoryDay> _combinedCalendarDays(
    DateTime month,
    List<HistorySummary> summaries,
  ) {
    if (summaries.isEmpty) {
      final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
      return [
        for (var day = 1; day <= daysInMonth; day++)
          HistoryDay(
            date: DateTime(month.year, month.month, day),
            status: DayStatus.none,
          ),
      ];
    }

    final first = summaries.first.days;
    return [
      for (var i = 0; i < first.length; i++)
        HistoryDay(
          date: first[i].date,
          status: _mergeDayStatus(
            summaries
                .where((summary) => summary.days.length > i)
                .map((summary) => summary.days[i].status)
                .toList(),
          ),
        ),
    ];
  }

  DayStatus _mergeDayStatus(List<DayStatus> statuses) {
    if (statuses.any((status) => status == DayStatus.someMissed)) {
      return DayStatus.someMissed;
    }
    if (statuses.any((status) => status == DayStatus.allTaken)) {
      return DayStatus.allTaken;
    }
    return DayStatus.none;
  }

  List<TreatmentHistory> _combinedTreatments(List<HistorySummary> summaries) {
    final grouped = <String, List<TreatmentHistory>>{};
    for (final summary in summaries) {
      for (final treatment in summary.treatments) {
        final key = treatment.medicationId.isEmpty
            ? '${treatment.medicationName}-${treatment.dosage}'
            : treatment.medicationId;
        grouped.putIfAbsent(key, () => []).add(treatment);
      }
    }

    final combined = grouped.values.map((group) {
      final first = group.first;
      final dosesTaken = group.fold<int>(
        0,
        (total, treatment) => total + treatment.dosesTaken,
      );
      final dosesExpected = group.fold<int>(
        0,
        (total, treatment) => total + treatment.dosesExpected,
      );
      final dosesMissed = group.fold<int>(
        0,
        (total, treatment) => total + treatment.dosesMissed,
      );
      final lastDoseAt = group
          .map((treatment) => treatment.lastDoseAt)
          .whereType<DateTime>()
          .fold<DateTime?>(
            null,
            (latest, current) =>
                latest == null || current.isAfter(latest) ? current : latest,
          );

      return TreatmentHistory(
        medicationId: first.medicationId,
        medicationName: first.medicationName,
        dosage: first.dosage,
        dosesTaken: dosesTaken,
        dosesExpected: dosesExpected,
        dosesMissed: dosesMissed,
        adherencePercent: dosesExpected == 0
            ? 0
            : ((dosesTaken / dosesExpected) * 100).round(),
        lastDoseAt: lastDoseAt,
        lastStatus: group.last.lastStatus,
      );
    }).toList();

    combined.sort((a, b) {
      final byMissed = b.dosesMissed.compareTo(a.dosesMissed);
      if (byMissed != 0) return byMissed;
      return a.medicationName.compareTo(b.medicationName);
    });
    return combined;
  }

  Future<void> _showDayDetails(
    BuildContext context,
    WidgetRef ref,
    DateTime date,
  ) async {
    ref.read(selectedHistoryDayProvider.notifier).state = date;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => const _DayDetailsSheet(),
    );
    ref.read(selectedHistoryDayProvider.notifier).state = null;
  }
}

class _EmptyHistoryState extends StatelessWidget {
  const _EmptyHistoryState({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        children: [
          Icon(Icons.history, color: AppColors.primary, size: 34),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nenhum histórico ainda',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Cadastre uma pessoa cuidada e tratamentos para acompanhar a evolução por dia e por tratamento.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.group_add),
              label: const Text('Adicionar pessoa cuidada'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TreatmentSummarySection extends StatelessWidget {
  const _TreatmentSummarySection({required this.treatments});

  final List<TreatmentHistory> treatments;

  @override
  Widget build(BuildContext context) {
    if (treatments.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text(
          'Nenhum tratamento com doses registradas neste mês.',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Resumo por tratamento',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...treatments
            .take(6)
            .map(
              (treatment) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _TreatmentHistoryTile(treatment: treatment),
              ),
            ),
      ],
    );
  }
}

class _TreatmentHistoryTile extends StatelessWidget {
  const _TreatmentHistoryTile({required this.treatment});

  final TreatmentHistory treatment;

  @override
  Widget build(BuildContext context) {
    final progress = treatment.dosesExpected == 0
        ? 0.0
        : treatment.dosesTaken / treatment.dosesExpected;
    final lastDoseLabel = treatment.lastDoseAt == null
        ? null
        : DateFormat("dd/MM 'às' HH:mm", 'pt_BR').format(treatment.lastDoseAt!);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.medication_liquid,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      treatment.medicationName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      treatment.dosage,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${treatment.adherencePercent}%',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: treatment.dosesMissed > 0
                      ? AppColors.warning
                      : AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 7,
              backgroundColor: context.appDivider,
              valueColor: AlwaysStoppedAnimation<Color>(
                treatment.dosesMissed > 0
                    ? AppColors.warning
                    : AppColors.success,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetricChip(label: '${treatment.dosesTaken} tomadas'),
              _MetricChip(label: '${treatment.dosesExpected} previstas'),
              if (treatment.dosesMissed > 0)
                _MetricChip(
                  label: '${treatment.dosesMissed} perdidas',
                  color: AppColors.error,
                ),
            ],
          ),
          if (lastDoseLabel != null) ...[
            const SizedBox(height: 8),
            Text(
              'Última dose registrada: $lastDoseLabel',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.appTextMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: context.isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: effectiveColor,
        ),
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.label,
    required this.onPrev,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        children: [
          _RoundIcon(icon: Icons.chevron_left, onTap: onPrev),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ),
          _RoundIcon(icon: Icons.chevron_right, onTap: onNext),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  const _RoundIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface,
          size: 20,
        ),
      ),
    );
  }
}

class _Calendar extends StatelessWidget {
  const _Calendar({
    required this.month,
    required this.days,
    required this.onDayTap,
  });

  final DateTime month;
  final List<HistoryDay> days;
  final ValueChanged<HistoryDay> onDayTap;

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(month.year, month.month, 1).weekday % 7;
    final today = DateTime.now();
    final weekdayLabels = ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SÁB'];

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: context.isDark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 32,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: weekdayLabels
                .map(
                  (l) => Expanded(
                    child: Center(
                      child: Text(
                        l,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: context.appTextMuted,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 4),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            childAspectRatio: 1.25,
            mainAxisSpacing: 1,
            crossAxisSpacing: 1,
            children: [
              for (var i = 0; i < firstWeekday; i++) const SizedBox(),
              ...days.map((d) {
                final isToday =
                    d.date.year == today.year &&
                    d.date.month == today.month &&
                    d.date.day == today.day;
                return _CalendarCell(
                  day: d,
                  isToday: isToday,
                  onTap: () => onDayTap(d),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.isToday,
    required this.onTap,
  });

  final HistoryDay day;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    Widget? indicator;
    switch (day.status) {
      case DayStatus.allTaken:
        indicator = Icon(Icons.check, size: 12, color: AppColors.success);
      case DayStatus.someMissed:
        indicator = Icon(Icons.close, size: 12, color: AppColors.error);
      case DayStatus.none:
        indicator = null;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        decoration: BoxDecoration(
          color: isToday
              ? (context.isDark
                    ? AppColors.primary.withValues(alpha: 0.28)
                    : AppColors.primaryLight)
              : null,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.date.day}',
              style: TextStyle(
                fontSize: 12,
                color: day.status == DayStatus.none
                    ? context.appTextMuted
                    : context.appTextPrimary,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (indicator != null) SizedBox(height: 11, child: indicator),
          ],
        ),
      ),
    );
  }
}

class _DayDetailsSheet extends ConsumerWidget {
  const _DayDetailsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedHistoryDayProvider) ?? DateTime.now();
    final async = ref.watch(historyDayDetailsProvider);
    final title = DateFormat("d 'de' MMMM", 'pt_BR').format(date);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.76,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.appDivider,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _capitalize(title),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Doses agendadas para este dia',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: async.when(
                  loading: () => const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  error: (_, _) => Center(
                    child: Text(
                      'Não foi possível carregar as doses deste dia.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  data: (doses) {
                    if (doses.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'Nenhuma dose agendada neste dia.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: doses.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, index) =>
                          _DayDoseTile(dose: doses[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _DayDoseTile extends StatelessWidget {
  const _DayDoseTile({required this.dose});

  final DayDoseDetail dose;

  @override
  Widget build(BuildContext context) {
    final effectiveStatus = _effectiveStatus(dose);
    final status = _statusPresentation(effectiveStatus);
    final time = DateFormat('HH:mm').format(dose.scheduledAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: status.color.withValues(
                alpha: context.isDark ? 0.18 : 0.12,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(status.icon, color: status.color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        dose.medicationName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: context.appTextMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${dose.dosage} • ${status.label}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (dose.dependentName != null) ...[
                  const SizedBox(height: 6),
                  _DependentChip(name: dose.dependentName!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  DayDoseStatus _effectiveStatus(DayDoseDetail dose) {
    if (dose.status == DayDoseStatus.pending &&
        dose.scheduledAt.isBefore(DateTime.now())) {
      return DayDoseStatus.missed;
    }
    return dose.status;
  }

  _DoseStatusPresentation _statusPresentation(DayDoseStatus status) {
    return switch (status) {
      DayDoseStatus.taken => _DoseStatusPresentation(
        icon: Icons.check_circle,
        color: AppColors.success,
        label: 'Tomada',
      ),
      DayDoseStatus.missed => _DoseStatusPresentation(
        icon: Icons.cancel,
        color: AppColors.error,
        label: 'Perdida',
      ),
      DayDoseStatus.postponed => _DoseStatusPresentation(
        icon: Icons.schedule,
        color: AppColors.warning,
        label: 'Adiada',
      ),
      DayDoseStatus.pending => _DoseStatusPresentation(
        icon: Icons.radio_button_unchecked,
        color: AppColors.textMuted,
        label: 'Pendente',
      ),
    };
  }
}

class _DependentChip extends StatelessWidget {
  const _DependentChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: AppColors.primaryLight,
          child: Text(
            initial,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DoseStatusPresentation {
  const _DoseStatusPresentation({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}
