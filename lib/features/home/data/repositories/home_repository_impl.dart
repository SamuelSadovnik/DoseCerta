import '../../../../core/enums/account_type.dart';
import '../../domain/entities/dose_schedule.dart';
import '../../domain/entities/home_data.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl(this._remote);

  final HomeRemoteDatasource _remote;

  @override
  Future<HomeData> loadHomeData({
    required AccountType accountType,
    String? dependentId,
  }) async {
    final dtos = await _remote.getTodayDoses(
      accountType: accountType,
      dependentId: dependentId,
    );
    final doses = dtos.map((d) => d.toEntity()).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final now = DateTime.now();
    final visibleDoses = doses
        .where(
          (d) => d.status != DoseStatus.missed && !_isExpiredPending(d, now),
        )
        .toList();
    final taken = doses.where((d) => d.status == DoseStatus.taken).length;
    final next = visibleDoses
        .where(
          (d) =>
              d.status == DoseStatus.pending ||
              d.status == DoseStatus.postponed,
        )
        .firstOrNull
        ?.scheduledAt;
    return HomeData(
      dosesTakenToday: taken,
      dosesTotalToday: doses.length,
      nextDoseTime: next,
      todayDoses: visibleDoses,
    );
  }

  bool _isExpiredPending(DoseSchedule dose, DateTime now) {
    return (dose.status == DoseStatus.pending ||
            dose.status == DoseStatus.postponed) &&
        dose.scheduledAt.isBefore(now);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
