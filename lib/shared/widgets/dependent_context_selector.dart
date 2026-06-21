import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/enums/account_type.dart';
import '../../core/providers/account_type_provider.dart';
import '../../core/providers/selected_dependent_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_extensions.dart';
import '../../features/dependents/presentation/providers/dependent_providers.dart';

/// Horizontal pill row for the caregiver to switch between the consolidated
/// view and each cared person. Hidden for personal accounts and when the
/// dependents list is empty.
class DependentContextSelector extends ConsumerWidget {
  const DependentContextSelector({super.key, this.showSelf = false});

  final bool showSelf;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountType = ref.watch(currentAccountTypeProvider);
    if (accountType != AccountType.caregiver) {
      return const SizedBox.shrink();
    }
    final depsAsync = ref.watch(dependentsProvider);
    return depsAsync.when(
      loading: () => const SizedBox(height: 44),
      error: (_, _) => const SizedBox.shrink(),
      data: (deps) {
        if (deps.isEmpty) return const SizedBox.shrink();
        final selected = ref.watch(selectedCareContextProvider);
        return SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _ContextPill(
                label: 'Todos',
                isSelected: selected.type == CareContextType.allDependents,
                onTap: () =>
                    ref.read(selectedCareContextProvider.notifier).state =
                        const CareContext.allDependents(),
              ),
              if (showSelf) ...[
                const SizedBox(width: 8),
                _ContextPill(
                  label: 'Eu',
                  isSelected: selected.type == CareContextType.self,
                  onTap: () =>
                      ref.read(selectedCareContextProvider.notifier).state =
                          const CareContext.self(),
                ),
              ],
              for (final d in deps) ...[
                const SizedBox(width: 8),
                _ContextPill(
                  label: d.name.split(' ').first,
                  isSelected:
                      selected.type == CareContextType.dependent &&
                      selected.dependentId == d.id,
                  onTap: () =>
                      ref.read(selectedCareContextProvider.notifier).state =
                          CareContext.dependent(d.id),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ContextPill extends StatelessWidget {
  const _ContextPill({
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
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : context.appSurfaceAlt,
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.appTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
