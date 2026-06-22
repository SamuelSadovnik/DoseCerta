import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/account_type.dart';
import '../../../../core/providers/account_type_provider.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/chip_selector.dart';
import '../../../../shared/widgets/form_app_bar.dart';
import '../../../../shared/widgets/labeled_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../dependents/presentation/providers/dependent_providers.dart';
import 'new_medication_view_model.dart';

const _selfKey = '__self__';

const _frequencies = [
  'A cada 4 horas',
  'A cada 6 horas',
  'A cada 8 horas',
  'A cada 12 horas',
  '1x ao dia',
  '2x ao dia',
  '3x ao dia',
];

class NewMedicationPage extends ConsumerWidget {
  const NewMedicationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(newMedicationViewModelProvider);
    final vm = ref.read(newMedicationViewModelProvider.notifier);
    final accountType = ref.watch(currentAccountTypeProvider);
    final dependentsAsync = ref.watch(dependentsProvider);

    ref.listen(newMedicationViewModelProvider, (prev, next) {
      if (next.success && prev?.success != true) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.medicationSuccess);
      }
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: const FormAppBar(title: 'Novo medicamento'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Novo medicamento',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.75,
                  color: Theme.of(context).colorScheme.onSurface,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Preencha os dados para receber lembretes na hora certa.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              LabeledTextField(
                label: 'Nome do medicamento',
                hint: 'Ex: Paracetamol',
                onChanged: vm.onNameChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Dosagem',
                hint: 'Ex: 500mg',
                onChanged: vm.onDosageChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Quantidade disponível',
                hint: 'Ex: 42 comprimidos',
                keyboardType: TextInputType.number,
                onChanged: vm.onQuantityChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Duração (dias)',
                hint: 'Ex: 7',
                keyboardType: TextInputType.number,
                onChanged: vm.onDurationChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              _PillDropdown(
                label: 'Frequência',
                hint: 'Selecione',
                value: state.frequency,
                items: {for (final f in _frequencies) f: f},
                onChanged: (v) => v != null ? vm.onFrequencyChanged(v) : null,
              ),
              if (accountType == AccountType.caregiver) ...[
                const SizedBox(height: AppSpacing.md),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Para quem é este medicamento?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                dependentsAsync.when(
                  loading: () => const SizedBox(
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (deps) {
                    final options = <ChipOption<String>>[
                      const ChipOption(value: _selfKey, label: 'Eu'),
                      for (final d in deps)
                        ChipOption(value: d.id, label: d.name),
                    ];
                    return ChipSelector<String>(
                      options: options,
                      selected: state.dependentId ?? _selfKey,
                      onChanged: (v) =>
                          vm.onDependentChanged(v == _selfKey ? null : v),
                    );
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Salvar medicamento',
                isLoading: state.isLoading,
                trailingIcon: null,
                onPressed: vm.submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillDropdown extends StatelessWidget {
  const _PillDropdown({
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final String? value;
  final Map<String, String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          icon: Icon(
            Icons.expand_more,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 20,
          ),
          hint: Text(
            hint,
            style: TextStyle(
              color: AppColors.textPlaceholder,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          decoration: InputDecoration(
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
          items: items.entries
              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
