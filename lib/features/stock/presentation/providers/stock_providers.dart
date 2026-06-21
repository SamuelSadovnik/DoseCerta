import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/page_cache_policy.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../dependents/presentation/providers/care_subject_provider.dart';
import '../../data/datasources/medication_remote_datasource.dart';
import '../../data/repositories/caching_medication_repository.dart';
import '../../data/repositories/medication_repository_impl.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';

final medicationRemoteDatasourceProvider = Provider<MedicationRemoteDatasource>(
  (ref) {
    final config = ref.watch(appConfigProvider);
    return config.useMockData
        ? MedicationRemoteDatasource.mock()
        : MedicationRemoteDatasource.http(ref.watch(dioProvider));
  },
);

/// The caller-facing repository is the inner HTTP/mock repo wrapped by a
/// [CachingMedicationRepository] decorator — gives offline-friendly reads
/// and consistent cache eviction on writes.
final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  final inner = MedicationRepositoryImpl(
    ref.watch(medicationRemoteDatasourceProvider),
  );
  return CachingMedicationRepository(
    inner,
    ref.watch(localCacheProvider),
    namespace: config.appInstance,
  );
});

final medicationsProvider = FutureProvider.autoDispose<List<Medication>>((
  ref,
) async {
  ref.cacheFor(PageCachePolicy.mainTabs);
  final dependentId = await ref.watch(
    currentMedicationDependentIdProvider.future,
  );
  return ref
      .watch(medicationRepositoryProvider)
      .getAll(dependentId: dependentId);
});

final medicationsByDependentProvider = FutureProvider.autoDispose
    .family<List<Medication>, String>((ref, dependentId) {
      ref.cacheFor(PageCachePolicy.mainTabs);
      return ref
          .watch(medicationRepositoryProvider)
          .getAll(dependentId: dependentId);
    });

final currentMedicationDependentIdProvider =
    FutureProvider.autoDispose<String?>((ref) async {
      return ref.watch(currentCareSubjectDependentIdProvider.future);
    });
