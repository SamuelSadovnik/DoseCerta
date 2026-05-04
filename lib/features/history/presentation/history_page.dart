import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/enums/account_type.dart';
import '../../../core/providers/account_type_provider.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/theme_extensions.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/dependent_context_selector.dart';
import '../../../shared/widgets/dosecerta_bottom_nav.dart';
import '../domain/entities/history_summary.dart';
import 'providers/history_providers.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountType = ref.watch(currentAccountTypeProvider);
    final month = ref.watch(selectedMonthProvider);
    final async = ref.watch(historySummariesProvider);

    final monthLabel = _capitalize(DateFormat('MMMM y', 'pt_BR').format(month));

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
                    'Histórico',
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
                  async.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, _) =>
                        Center(child: Text('Erro ao carregar: $e')),
                    data: (summaries) {
                      final calendarDays = summaries.isEmpty
                          ? <HistoryDay>[]
                          : summaries.first.days;
                      return Column(
                        children: [
                          _Calendar(month: month, days: calendarDays),
                          const SizedBox(height: AppSpacing.sm),
                          if (accountType == AccountType.personal &&
                              summaries.isNotEmpty)
                            _PersonalStats(summary: summaries.first)
                          else
                            _CaregiverStatsStrip(summaries: summaries),
                          const SizedBox(height: AppSpacing.sm),
                          _MissedSection(summaries: summaries),
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
  const _Calendar({required this.month, required this.days});

  final DateTime month;
  final List<HistoryDay> days;

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
                return _CalendarCell(day: d, isToday: isToday);
              }),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({required this.day, required this.isToday});

  final HistoryDay day;
  final bool isToday;

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

    return Container(
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
    );
  }
}

class _PersonalStats extends StatelessWidget {
  const _PersonalStats({required this.summary});

  final HistorySummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.done_all,
            iconBackground: AppColors.successLight,
            iconColor: AppColors.success,
            value:
                '${summary.dosesTaken.toString().padLeft(2, '0')}/${summary.dosesExpected.toString().padLeft(2, '0')}',
            label: 'Doses tomadas',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatTile(
            icon: Icons.calendar_today_outlined,
            iconBackground: AppColors.primaryLight,
            iconColor: AppColors.error,
            value: summary.dosesMissed.toString().padLeft(2, '0'),
            label: 'Doses perdidas',
          ),
        ),
      ],
    );
  }
}

class _CaregiverStats extends StatelessWidget {
  const _CaregiverStats({required this.summary, this.compactRow = false});

  final HistorySummary summary;
  final bool compactRow;

  @override
  Widget build(BuildContext context) {
    final name = summary.dependentName ?? '—';
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    return Row(
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: compactRow ? 18 : 22,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                initial,
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 60,
              child: Text(
                name.split(' ').first,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatTile(
            compact: true,
            icon: Icons.done_all,
            iconBackground: AppColors.successLight,
            iconColor: AppColors.success,
            value:
                '${summary.dosesTaken.toString().padLeft(2, '0')}/${summary.dosesExpected.toString().padLeft(2, '0')}',
            label: 'Tomadas',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            compact: true,
            icon: Icons.calendar_today_outlined,
            iconBackground: AppColors.primaryLight,
            iconColor: AppColors.error,
            value: summary.dosesMissed.toString().padLeft(2, '0'),
            label: 'Perdidas',
          ),
        ),
      ],
    );
  }
}

class _CaregiverStatsStrip extends StatelessWidget {
  const _CaregiverStatsStrip({required this.summaries});

  final List<HistorySummary> summaries;

  @override
  Widget build(BuildContext context) {
    if (summaries.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 86,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: summaries.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, index) => SizedBox(
          width: 220,
          child: _CaregiverStats(summary: summaries[index], compactRow: true),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
    required this.value,
    required this.label,
    this.compact = false,
  });

  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
  final String value;
  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.xl - 4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 24 : 28,
            height: compact ? 24 : 28,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: compact ? 14 : 16),
          ),
          SizedBox(height: compact ? 4 : 6),
          Text(
            value,
            style: TextStyle(
              fontSize: compact ? 16 : 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissedSection extends StatelessWidget {
  const _MissedSection({required this.summaries});

  final List<HistorySummary> summaries;

  @override
  Widget build(BuildContext context) {
    final missed = summaries.expand((s) => s.missedDoses).toList()
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    final titleStyle = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.45,
      color: Theme.of(context).colorScheme.onSurface,
    );
    if (missed.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Doses não tomadas', style: titleStyle),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Nenhuma dose perdida neste período.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Doses não tomadas', style: titleStyle),
        const SizedBox(height: AppSpacing.sm),
        ...missed.map((m) => _MissedItem(dose: m)),
      ],
    );
  }
}

class _MissedItem extends StatelessWidget {
  const _MissedItem({required this.dose});

  final MissedDose dose;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd/MM \'às\' HH:mm').format(dose.scheduledAt);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: const Border(
          left: BorderSide(color: AppColors.error, width: 4),
        ),
        boxShadow: context.isDark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.medical_services,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${dose.medicationName} • ${dose.dosage}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                if (dose.dependentName != null) ...[
                  Text(
                    dose.dependentName!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
