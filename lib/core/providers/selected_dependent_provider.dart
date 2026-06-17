import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CareContextType { allDependents, dependent, self }

class CareContext {
  const CareContext._(this.type, [this.dependentId]);

  const CareContext.allDependents() : this._(CareContextType.allDependents);
  const CareContext.self() : this._(CareContextType.self);
  const CareContext.dependent(String id)
    : this._(CareContextType.dependent, id);

  final CareContextType type;
  final String? dependentId;

  bool get isDependent => type == CareContextType.dependent;
}

/// Current care scope selected by the user.
///
/// For caregivers, [CareContext.allDependents] means the consolidated view of
/// cared people. For personal accounts, screens usually ignore this selector
/// and load the user's own data or linked dependent registry when applicable.
final selectedCareContextProvider = StateProvider<CareContext>(
  (ref) => const CareContext.allDependents(),
);

final selectedCareDependentIdProvider = Provider<String?>((ref) {
  final context = ref.watch(selectedCareContextProvider);
  return context.type == CareContextType.dependent ? context.dependentId : null;
});
