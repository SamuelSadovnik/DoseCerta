import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/page_cache_policy.dart';
import '../../../../core/providers/account_type_provider.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../dependents/presentation/providers/care_subject_provider.dart';
import '../../data/datasources/history_remote_datasource.dart';
import '../../data/repositories/history_repository_impl.dart';
import '../../domain/entities/day_dose_detail.dart';
import '../../domain/entities/history_summary.dart';
import '../../domain/repositories/history_repository.dart';

final historyRemoteDatasourceProvider = Provider<HistoryRemoteDatasource>((
  ref,
) {
  final config = ref.watch(appConfigProvider);
  return config.useMockData
      ? HistoryRemoteDatasource.mock()
      : HistoryRemoteDatasource.http(ref.watch(dioProvider));
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepositoryImpl(ref.watch(historyRemoteDatasourceProvider));
});

final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final selectedHistoryDayProvider = StateProvider<DateTime?>((ref) => null);

final historySummariesProvider =
    FutureProvider.autoDispose<List<HistorySummary>>((ref) async {
      ref.cacheFor(PageCachePolicy.mainTabs);
      final month = ref.watch(selectedMonthProvider);
      final accountType = ref.watch(currentAccountTypeProvider);
      final dependentId = await ref.watch(
        currentCareSubjectDependentIdProvider.future,
      );
      return ref
          .watch(historyRepositoryProvider)
          .getSummaries(
            month: month,
            accountType: accountType,
            dependentId: dependentId,
          );
    });

final historyDayDetailsProvider =
    FutureProvider.autoDispose<List<DayDoseDetail>>((ref) async {
      final date = ref.watch(selectedHistoryDayProvider);
      if (date == null) return Future.value(const []);

      final dependentId = await ref.watch(
        currentCareSubjectDependentIdProvider.future,
      );

      return ref
          .watch(historyRepositoryProvider)
          .getDayDetails(date: date, dependentId: dependentId);
    });
