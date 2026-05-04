import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the dependent currently being viewed by a caregiver across Home,
/// History and other contextual screens. `null` means "Eu" (caregiver itself).
final selectedDependentIdProvider = StateProvider<String?>((ref) => null);
