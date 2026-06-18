import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/entities/medication.dart';
import '../providers/stock_providers.dart';
import 'stock_list_state.dart';
import 'stock_list_view_model.dart';

class StockListPage extends ConsumerWidget {
  const StockListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsProvider);
    final accountType = ref.watch(currentAccountTypeProvider);
    final selectedDependentId = ref.watch(selectedCareDependentIdProvider);
    final dependentsAsync = ref.watch(dependentsProvider);
    final state = ref.watch(stockListViewModelProvider);
    final vm = ref.read(stockListViewModelProvider.notifier);
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
                            'Adicione alguém para acompanhar tratamentos, estoque e doses. O convite por código é opcional.',
                        onPressed: () => Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.newDependent),
                      ),
                      const Spacer(),
                    ] else ...[
                      _SearchField(onChanged: vm.onQueryChanged),
                      const SizedBox(height: AppSpacing.sm),
                      _TreatmentFilterSelector(
                        value: state.filter,
                        onChanged: vm.onFilterChanged,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(
                        child: medsAsync.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) =>
                              Center(child: Text('Erro ao carregar: $e')),
                          data: (meds) {
                            final filtered = _filter(meds, state.query)
                                .where(
                                  (medication) => switch (state.filter) {
                                    TreatmentFilter.active =>
                                      !medication.isEnded,
                                    TreatmentFilter.ended => medication.isEnded,
                                  },
                                )
                                .toList();
                            if (filtered.isEmpty) {
                              return Center(
                                child: Text(
                                  state.query.trim().isEmpty
                                      ? _emptyTextFor(state.filter)
                                      : 'Nenhum medicamento encontrado.',
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
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              itemCount: filtered.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: AppSpacing.sm + 4),
                              itemBuilder: (_, i) => _InventoryCard(
                                medication: filtered[i],
                                onTap: () => _showStockActions(
                                  context,
                                  ref,
                                  filtered[i],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: PrimaryButton(
                          label: 'Cadastrar tratamento',
                          trailingIcon: null,
                          leadingIcon: Icons.add,
                          size: PrimaryButtonSize.medium,
                          onPressed: () => Navigator.of(
                            context,
                          ).pushNamed(AppRoutes.newMedication),
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
        currentIndex: 1,
        onTap: (index) => _navigate(context, index),
      ),
    );
  }

  String _emptyTextFor(TreatmentFilter filter) {
    return switch (filter) {
      TreatmentFilter.active => 'Nenhum tratamento ativo por enquanto.',
      TreatmentFilter.ended => 'Nenhum tratamento encerrado por enquanto.',
    };
  }

  String _titleFor(AccountType accountType, String? dependentName) {
    if (accountType == AccountType.personal) return 'Meus tratamentos';
    if (dependentName != null) {
      return 'Tratamentos de ${dependentName.split(' ').first}';
    }
    return 'Tratamentos';
  }

  List<Medication> _filter(List<Medication> list, String query) {
    if (query.trim().isEmpty) return list;
    final q = query.toLowerCase();
    return list
        .where(
          (m) =>
              m.name.toLowerCase().contains(q) ||
              m.dosage.toLowerCase().contains(q),
        )
        .toList();
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      case 1:
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.history);
      case 3:
        Navigator.of(context).pushReplacementNamed(AppRoutes.appointments);
      case 4:
        Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
    }
  }

  Future<void> _showStockActions(
    BuildContext context,
    WidgetRef ref,
    Medication medication,
  ) async {
    final controller = TextEditingController(
      text: medication.currentQuantity == 0
          ? ''
          : medication.currentQuantity.toString(),
    );

    final result = await showModalBottomSheet<_StockAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                medication.name,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(sheetContext).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                medication.currentQuantity == 0
                    ? 'Este tratamento foi encerrado e não possui próximas doses.'
                    : 'Atualize a quantidade restante desse tratamento.',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              if (medication.currentQuantity == 0) ...[
                Text(
                  'Para retomar o uso, cadastre um novo tratamento com a nova frequência e duração.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(sheetContext).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Entendi',
                  trailingIcon: null,
                  leadingIcon: Icons.check,
                  size: PrimaryButtonSize.medium,
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(_StockAction.close),
                ),
              ] else ...[
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Quantidade restante',
                    suffixText: medication.unit.plural,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Salvar estoque',
                  trailingIcon: null,
                  leadingIcon: Icons.check,
                  size: PrimaryButtonSize.medium,
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(_StockAction.save),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(_StockAction.refill),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('Adicionar esta quantidade ao estoque'),
                ),
                const SizedBox(height: 4),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.of(sheetContext).pop(_StockAction.end),
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Encerrar tratamento'),
                ),
              ],
            ],
          ),
        );
      },
    );

    if (!context.mounted || result == null) {
      controller.dispose();
      return;
    }

    final repository = ref.read(medicationRepositoryProvider);
    try {
      if (result == _StockAction.close) {
        return;
      } else if (result == _StockAction.save) {
        final quantity = int.tryParse(controller.text.trim());
        if (quantity == null || quantity < 0) {
          throw const FormatException('Quantidade inválida');
        }
        await repository.updateStock(id: medication.id, quantity: quantity);
      } else if (result == _StockAction.refill) {
        final quantity = int.tryParse(controller.text.trim());
        if (quantity == null || quantity <= 0) {
          throw const FormatException('Quantidade inválida');
        }
        await repository.refill(id: medication.id, quantity: quantity);
      } else {
        await repository.endTreatment(medication.id);
      }

      ref.invalidate(medicationsProvider);
      ref.invalidate(homeDataProvider);
      if (medication.dependentId != null) {
        ref.invalidate(medicationsByDependentProvider(medication.dependentId!));
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result == _StockAction.save
                  ? 'Estoque atualizado.'
                  : result == _StockAction.refill
                  ? 'Tratamento reabastecido.'
                  : 'Tratamento encerrado.',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível atualizar o estoque.'),
          ),
        );
      }
    } finally {
      controller.dispose();
    }
  }
}

enum _StockAction { save, refill, end, close }

class _TreatmentFilterSelector extends StatelessWidget {
  const _TreatmentFilterSelector({
    required this.value,
    required this.onChanged,
  });

  final TreatmentFilter value;
  final ValueChanged<TreatmentFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final filter in TreatmentFilter.values) ...[
          Expanded(
            child: _TreatmentFilterPill(
              label: filter.label,
              isSelected: value == filter,
              onTap: () => onChanged(filter),
            ),
          ),
          if (filter != TreatmentFilter.values.last)
            const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _TreatmentFilterPill extends StatelessWidget {
  const _TreatmentFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.appSurfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.appTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
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
        hintText: 'Buscar medicamentos...',
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

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.medication, required this.onTap});

  final Medication medication;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = medication.capacityRatio.clamp(0.0, 1.0);
    final isCritical = medication.isCritical;
    final barColor = isCritical ? AppColors.error : AppColors.primary;

    final icon = switch (medication.unit) {
      MedicationUnit.tablet || MedicationUnit.capsule => Icons.medical_services,
      MedicationUnit.drop || MedicationUnit.ml => Icons.water_drop,
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.45,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${medication.currentQuantity} ${medication.unit.plural} restantes • ${medication.dosage}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCritical)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      'BAIXO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.edit_outlined,
                  color: context.appTextMuted,
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: context.appSurfaceAlt,
                valueColor: AlwaysStoppedAnimation(barColor),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Capacidade ${medication.capacityPercent}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: context.appTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
