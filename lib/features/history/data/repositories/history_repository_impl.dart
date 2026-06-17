import '../../../../core/enums/account_type.dart';
import '../../domain/entities/day_dose_detail.dart';
import '../../domain/entities/history_summary.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl(this._remote);

  final HistoryRemoteDatasource _remote;

  @override
  Future<List<HistorySummary>> getSummaries({
    required DateTime month,
    required AccountType accountType,
    String? dependentId,
  }) {
    return _remote.getSummaries(
      month: month,
      accountType: accountType,
      dependentId: dependentId,
    );
  }

  @override
  Future<List<DayDoseDetail>> getDayDetails({
    required DateTime date,
    String? dependentId,
  }) {
    return _remote.getDayDetails(date: date, dependentId: dependentId);
  }
}
