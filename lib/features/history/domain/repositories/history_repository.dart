import '../../../../core/enums/account_type.dart';
import '../entities/day_dose_detail.dart';
import '../entities/history_summary.dart';

abstract class HistoryRepository {
  Future<List<HistorySummary>> getSummaries({
    required DateTime month,
    required AccountType accountType,
    String? dependentId,
  });

  Future<List<DayDoseDetail>> getDayDetails({
    required DateTime date,
    String? dependentId,
  });
}
