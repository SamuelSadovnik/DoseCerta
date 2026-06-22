import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/enums/account_type.dart';
import '../../../../core/providers/account_type_provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/form_app_bar.dart';
import '../../../../shared/widgets/hero_card.dart';
import '../../../../shared/widgets/labeled_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../dependents/presentation/providers/dependent_providers.dart';
import '../../domain/entities/appointment.dart';
import 'new_appointment_view_model.dart';

class NewAppointmentPage extends ConsumerWidget {
  const NewAppointmentPage({super.key, this.appointment});

  final Appointment? appointment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = newAppointmentViewModelProvider(appointment);
    final state = ref.watch(provider);
    final vm = ref.read(provider.notifier);
    final accountType = ref.watch(currentAccountTypeProvider);
    final dependentsAsync = ref.watch(dependentsProvider);

    ref.listen(provider, (prev, next) {
      if (next.success && prev?.success != true) {
        if (appointment == null) {
          Navigator.of(
            context,
          ).pushReplacementNamed(AppRoutes.appointmentSuccess);
        } else {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.appointments, (_) => false);
        }
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    final dateHint = state.date == null
        ? 'Ex: 25 de outubro de 2026'
        : DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(state.date!);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: FormAppBar(
        title: appointment == null ? 'Nova consulta' : 'Reagendar consulta',
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HeroCard(title: 'Consulta'),
              const SizedBox(height: AppSpacing.lg),
              LabeledTextField(
                label: 'Nome do médico',
                hint: 'Ex: Ana Luiza',
                initialValue: state.doctorName,
                suffixIcon: Icon(
                  Icons.edit_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onChanged: vm.onDoctorChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Especialidade',
                hint: 'Ex: Clínico geral',
                initialValue: state.specialty,
                suffixIcon: Icon(
                  Icons.straighten,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onChanged: vm.onSpecialtyChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Data',
                hint: dateHint,
                readOnly: true,
                suffixIcon: Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onTap: () async {
                  final now = DateTime.now();
                  final today = DateUtils.dateOnly(now);
                  final picked = await showDatePicker(
                    context: context,
                    initialDate:
                        state.date != null && !state.date!.isBefore(today)
                        ? state.date!
                        : today,
                    firstDate: today,
                    lastDate: now.add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) vm.onDateChanged(picked);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Local',
                hint: 'Ex: Hospital Geral Unimed',
                initialValue: state.location,
                suffixIcon: Icon(
                  Icons.place_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onChanged: vm.onLocationChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Horário',
                hint: 'Ex: 14:37',
                initialValue: state.time,
                keyboardType: TextInputType.datetime,
                suffixIcon: Icon(
                  Icons.schedule,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onChanged: vm.onTimeChanged,
              ),
              if (accountType == AccountType.caregiver) ...[
                const SizedBox(height: AppSpacing.md),
                dependentsAsync.when(
                  loading: () => const SizedBox(height: 72),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (deps) => _Dropdown(
                    label: 'Dependente',
                    hint: 'Selecione um dependente',
                    value: state.dependentId,
                    items: deps.map((d) => d.id).toList(),
                    displayMap: {for (final d in deps) d.id: d.name},
                    onChanged: vm.onDependentChanged,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: appointment == null
                    ? 'Salvar consulta'
                    : 'Salvar reagendamento',
                isLoading: state.isLoading,
                trailingIcon: Icons.check_circle,
                onPressed: vm.submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    this.displayMap,
  });

  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final Map<String, String>? displayMap;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          hint: Text(hint),
          borderRadius: BorderRadius.circular(AppRadius.card),
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(displayMap?[e] ?? e),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
