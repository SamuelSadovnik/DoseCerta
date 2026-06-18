import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/account_type.dart';
import '../../../../core/providers/account_type_provider.dart';
import '../../../../core/providers/selected_dependent_provider.dart';
import 'dependent_providers.dart';

final currentCareSubjectDependentIdProvider =
    FutureProvider.autoDispose<String?>((ref) async {
      final accountType = ref.watch(currentAccountTypeProvider);
      if (accountType == AccountType.caregiver) {
        return ref.watch(selectedCareDependentIdProvider);
      }

      final dependents = await ref.watch(dependentsProvider.future);
      for (final dependent in dependents) {
        if (dependent.isLinked) return dependent.id;
      }
      return null;
    });
