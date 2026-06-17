import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/page_cache_policy.dart';
import '../../../../core/enums/account_type.dart';
import '../../../../core/providers/account_type_provider.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/selected_dependent_provider.dart';
import '../../data/datasources/home_remote_datasource.dart';
import '../../data/repositories/home_repository_impl.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/repositories/home_repository.dart';

final homeRemoteDatasourceProvider = Provider<HomeRemoteDatasource>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.useMockData
      ? HomeRemoteDatasource.mock()
      : HomeRemoteDatasource.http(ref.watch(dioProvider));
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepositoryImpl(ref.watch(homeRemoteDatasourceProvider));
});

final homeDataProvider = FutureProvider.autoDispose<HomeData>((ref) {
  ref.cacheFor(PageCachePolicy.home);
  final accountType = ref.watch(currentAccountTypeProvider);
  final selectedDependentId = ref.watch(selectedCareDependentIdProvider);
  final dependentId = accountType == AccountType.caregiver
      ? selectedDependentId
      : null;
  return ref
      .watch(homeRepositoryProvider)
      .loadHomeData(accountType: accountType, dependentId: dependentId);
});
