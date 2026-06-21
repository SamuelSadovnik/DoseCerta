import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/account_type.dart';
import '../../../../core/providers/account_type_provider.dart';
import '../../../../core/providers/selected_dependent_provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../../shared/widgets/app_top_bar.dart';
import '../../../../shared/widgets/dependent_context_selector.dart';
import '../../../../shared/widgets/dosecerta_bottom_nav.dart';
import '../../../../shared/widgets/empty_care_profiles_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../dependents/presentation/providers/dependent_providers.dart';
import '../../domain/entities/appointment.dart';
import '../providers/appointment_providers.dart';

class AppointmentsListPage extends ConsumerStatefulWidget {
  const AppointmentsListPage({super.key});

  @override
  ConsumerState<AppointmentsListPage> createState() =>
      _AppointmentsListPageState();
}

class _AppointmentsListPageState extends ConsumerState<AppointmentsListPage> {
  Timer? _refreshTimer;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      ref.invalidate(appointmentsProvider);
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
    final async = ref.watch(appointmentsProvider);
    final accountType = ref.watch(currentAccountTypeProvider);
    final selectedDependentId = ref.watch(selectedCareDependentIdProvider);
    final dependentsAsync = ref.watch(dependentsProvider);
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (accountType == AccountType.caregiver &&
                        !hasNoCareProfiles) ...[
                      const DependentContextSelector(),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    if (hasNoCareProfiles) ...[
                      const SizedBox(height: AppSpacing.lg),
                      EmptyCareProfilesState(
                        message:
                            'Adicione alguém para acompanhar consultas e rotina de cuidado. O convite por código é opcional.',
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.newDependent),
                      ),
                      const Spacer(),
                    ] else ...[
                      _SearchField(
                        onChanged: (v) => setState(() => _query = v),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(
                        child: async.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) =>
                              Center(child: Text('Erro ao carregar: $e')),
                          data: (list) {
                            final filtered = _filter(list);
                            if (filtered.isEmpty) {
                              return Center(
                                child: Text(
                                  'Nenhuma consulta encontrada.',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.sm + 4),
                              itemBuilder: (_, i) => _AppointmentCard(
                                appointment: filtered[i],
                                showDependent:
                                    accountType == AccountType.caregiver &&
                                    selectedDependentId == null,
                                onTap: () => Navigator.of(context).pushNamed(
                                  AppRoutes.alertAppointment,
                                  arguments: filtered[i],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: PrimaryButton(
                          label: 'Nova consulta',
                          trailingIcon: null,
                          leadingIcon: Icons.add,
                          size: PrimaryButtonSize.medium,
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.newAppointment),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.huge + AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: DoseCertaBottomNav(
        currentIndex: 3,
        onTap: (index) => _navigate(context, index),
      ),
    );
  }

  String _titleFor(AccountType accountType, String? dependentName) {
    if (accountType == AccountType.personal) return 'Minhas consultas';
    if (dependentName != null) {
      return 'Consultas de ${dependentName.split(' ').first}';
    }
    return 'Consultas';
  }

  List<Appointment> _filter(List<Appointment> list) {
    if (_query.trim().isEmpty) return list;
    final q = _normalize(_query);
    return list
        .where(
          (a) =>
              _normalize(a.doctorName).contains(q) ||
              _normalize(a.specialty ?? '').contains(q),
        )
        .toList();
  }

  String _normalize(String value) {
    const accents = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'ê': 'e',
      'í': 'i',
      'ó': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ü': 'u',
      'ç': 'c',
    };
    return value
        .trim()
        .toLowerCase()
        .split('')
        .map((char) => accents[char] ?? char)
        .join();
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
        break;
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
    }
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: 'Buscar por médico ou especialidade',
        hintStyle: TextStyle(
          color: AppColors.textPlaceholder,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 8),
          child: Icon(Icons.search, color: context.appTextMuted, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 44,
          minHeight: 24,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({
    required this.appointment,
    required this.showDependent,
    required this.onTap,
  });

  final Appointment appointment;
  final bool showDependent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = DateFormat(
      "d 'de' MMM",
      'pt_BR',
    ).format(appointment.scheduledAt);
    final time = DateFormat('HH:mm').format(appointment.scheduledAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: context.isDark
              ? const []
              : const [
                  BoxShadow(
                    color: Color(0x0D000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.medical_information_outlined,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          appointment.doctorName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      _statusBadge(context, appointment.status),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    appointment.specialty ?? 'Especialidade não informada',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: context.appTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: context.appTextMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        time,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (showDependent && appointment.dependentName != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            appointment.dependentName!.isNotEmpty
                                ? appointment.dependentName![0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          appointment.dependentName!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, AppointmentStatus status) {
    late final Color bg;
    late final Color fg;
    switch (status) {
      case AppointmentStatus.completed:
        bg = AppColors.successLight;
        fg = AppColors.success;
      case AppointmentStatus.cancelled:
        bg = Theme.of(context).cardColor;
        fg = Theme.of(context).colorScheme.onSurfaceVariant;
      case AppointmentStatus.confirmed:
      case AppointmentStatus.scheduled:
        bg = AppColors.primaryLight;
        fg = AppColors.primary;
      case AppointmentStatus.rescheduled:
        bg = AppColors.primaryLight;
        fg = AppColors.primaryDark;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
