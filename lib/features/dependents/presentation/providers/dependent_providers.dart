import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/page_cache_policy.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/datasources/dependent_remote_datasource.dart';
import '../../data/repositories/dependent_repository_impl.dart';
import '../../domain/entities/dependent.dart';
import '../../domain/repositories/dependent_repository.dart';

final dependentRemoteDatasourceProvider = Provider<DependentRemoteDatasource>((
  ref,
) {
  final config = ref.watch(appConfigProvider);
  return config.useMockData
      ? DependentRemoteDatasource.mock()
      : DependentRemoteDatasource.http(ref.watch(dioProvider));
});

final dependentRepositoryProvider = Provider<DependentRepository>((ref) {
  return DependentRepositoryImpl(ref.watch(dependentRemoteDatasourceProvider));
});

final dependentsProvider = FutureProvider.autoDispose<List<Dependent>>((ref) {
  ref.cacheFor(PageCachePolicy.referenceData);
  return ref.watch(dependentRepositoryProvider).getAll();
});
