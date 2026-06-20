import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/formatters/birth_date_input_formatter.dart';
import '../../../../shared/widgets/chip_selector.dart';
import '../../../../shared/widgets/form_app_bar.dart';
import '../../../../shared/widgets/hero_card.dart';
import '../../../../shared/widgets/labeled_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../domain/entities/dependent.dart';
import 'new_dependent_state.dart';
import 'new_dependent_view_model.dart';

class NewDependentPage extends ConsumerStatefulWidget {
  const NewDependentPage({super.key});

  @override
  ConsumerState<NewDependentPage> createState() => _NewDependentPageState();
}

class _NewDependentPageState extends ConsumerState<NewDependentPage> {
  late final TextEditingController _birthDateController;

  @override
  void initState() {
    super.initState();
    _birthDateController = TextEditingController();
  }

  @override
  void dispose() {
    _birthDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newDependentViewModelProvider);
    final vm = ref.read(newDependentViewModelProvider.notifier);

    ref.listen(newDependentViewModelProvider, (prev, next) {
      if (next.success && prev?.success != true) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.dependentSuccess,
          arguments: next.createdDependent,
        );
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
      appBar: const FormAppBar(title: 'Nova pessoa cuidada'),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.pagePadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const HeroCard(title: 'Pessoa cuidada'),
              const SizedBox(height: AppSpacing.lg),
              LabeledTextField(
                label: 'Nome Completo',
                labelStyle: LabelStyle.uppercase,
                hint: 'Ex: João',
                suffixIcon: Icon(
                  Icons.person_outline,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onChanged: vm.onNameChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              LabeledTextField(
                label: 'Data de Nascimento',
                labelStyle: LabelStyle.uppercase,
                hint: '00/00/0000',
                controller: _birthDateController,
                keyboardType: TextInputType.number,
                inputFormatters: [BirthDateInputFormatter()],
                suffixIcon: IconButton(
                  icon: Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => _pickBirthDate(context, state, vm),
                ),
                onChanged: vm.onBirthDateTextChanged,
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'GRAU DE PARENTESCO',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              ChipSelector<RelationshipType>(
                options: RelationshipType.values
                    .map((r) => ChipOption(value: r, label: r.label))
                    .toList(),
                selected: state.relationship,
                onChanged: vm.onRelationshipChanged,
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                label: 'Salvar pessoa',
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

  Future<void> _pickBirthDate(
    BuildContext context,
    NewDependentState state,
    NewDependentViewModel vm,
  ) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: state.birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null) return;

    _birthDateController.text = DateFormat('dd/MM/yyyy').format(picked);
    vm.onBirthDateChanged(picked);
  }
}
