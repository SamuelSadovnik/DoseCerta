import 'package:dio/dio.dart';

import '../../../../core/enums/account_type.dart';
import '../../domain/entities/day_dose_detail.dart';
import '../../domain/entities/history_summary.dart';

/// Remote datasource for history summaries.
///
/// Factory pattern: pick `.http(dio)` or `.mock()`.
abstract class HistoryRemoteDatasource {
  factory HistoryRemoteDatasource.http(Dio dio) = _HttpHistoryRemoteDatasource;

  factory HistoryRemoteDatasource.mock() = _MockHistoryRemoteDatasource;

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

class _HttpHistoryRemoteDatasource implements HistoryRemoteDatasource {
  _HttpHistoryRemoteDatasource(this._dio);
  final Dio _dio;

  @override
  Future<List<HistorySummary>> getSummaries({
    required DateTime month,
    required AccountType accountType,
    String? dependentId,
  }) async {
    final query = <String, dynamic>{'month': _formatMonth(month)};
    if (dependentId != null) {
      query['dependentId'] = dependentId;
    }
    final res = await _dio.get<List<dynamic>>(
      '/history',
      queryParameters: query,
    );
    return (res.data ?? const [])
        .map((e) => _historySummaryFromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DayDoseDetail>> getDayDetails({
    required DateTime date,
    String? dependentId,
  }) async {
    final query = <String, dynamic>{'date': _formatDate(date)};
    if (dependentId != null) {
      query['dependentId'] = dependentId;
    }
    final res = await _dio.get<List<dynamic>>(
      '/history/day',
      queryParameters: query,
    );
    return (res.data ?? const [])
        .map((e) => _dayDoseDetailFromJson(e as Map<String, dynamic>))
        .toList();
  }

  String _formatMonth(DateTime month) {
    final mm = month.month.toString().padLeft(2, '0');
    return '${month.year}-$mm';
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  HistorySummary _historySummaryFromJson(Map<String, dynamic> json) {
    return HistorySummary(
      dosesTaken: json['dosesTaken'] as int? ?? 0,
      dosesExpected: json['dosesExpected'] as int? ?? 0,
      dosesMissed: json['dosesMissed'] as int? ?? 0,
      days: (json['days'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_historyDayFromJson)
          .toList(),
      missedDoses: (json['missedDoses'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_missedDoseFromJson)
          .toList(),
      dependentId: json['dependentId'] as String?,
      dependentName: json['dependentName'] as String?,
      dependentAvatarUrl: json['dependentAvatarUrl'] as String?,
    );
  }

  HistoryDay _historyDayFromJson(Map<String, dynamic> json) {
    return HistoryDay(
      date: DateTime.parse(json['date'] as String),
      status: DayStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => DayStatus.none,
      ),
    );
  }

  MissedDose _missedDoseFromJson(Map<String, dynamic> json) {
    return MissedDose(
      medicationName: json['medicationName'] as String? ?? 'Medicamento',
      dosage: json['dosage'] as String? ?? '',
      scheduledAt: DateTime.parse(json['scheduledAt'] as String).toLocal(),
      dependentName: json['dependentName'] as String?,
    );
  }

  DayDoseDetail _dayDoseDetailFromJson(Map<String, dynamic> json) {
    return DayDoseDetail(
      id: json['id'] as String,
      medicationName: json['medicationName'] as String? ?? 'Medicamento',
      dosage: json['dosage'] as String? ?? '',
      scheduledAt: DateTime.parse(json['scheduledAt'] as String).toLocal(),
      status: DayDoseStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => DayDoseStatus.pending,
      ),
      takenAt: json['takenAt'] == null
          ? null
          : DateTime.parse(json['takenAt'] as String).toLocal(),
      dependentId: json['dependentId'] as String?,
      dependentName: json['dependentName'] as String?,
    );
  }
}

class _MockHistoryRemoteDatasource implements HistoryRemoteDatasource {
  @override
  Future<List<HistorySummary>> getSummaries({
    required DateTime month,
    required AccountType accountType,
    String? dependentId,
  }) async {
    await Future<void>.delayed(Duration(milliseconds: 600));
    if (accountType == AccountType.caregiver) {
      return [
        _buildSummary(
          month,
          takenBase: 58,
          missed: 1,
          dependentId: 'dep-1',
          dependentName: 'João Silva',
        ),
        _buildSummary(
          month,
          takenBase: 42,
          missed: 0,
          dependentId: 'dep-2',
          dependentName: 'Maria Souza',
        ),
        _buildSummary(
          month,
          takenBase: 24,
          missed: 3,
          dependentId: 'dep-3',
          dependentName: 'Ricardo Lima',
        ),
      ];
    }
    return [_buildSummary(month, takenBase: 124, missed: 2)];
  }

  @override
  Future<List<DayDoseDetail>> getDayDetails({
    required DateTime date,
    String? dependentId,
  }) async {
    await Future<void>.delayed(Duration(milliseconds: 450));
    if (date.day % 7 == 0) return const [];
    return [
      DayDoseDetail(
        id: 'dose-${date.day}-1',
        medicationName: 'Paracetamol',
        dosage: '500mg',
        scheduledAt: DateTime(date.year, date.month, date.day, 8),
        status: DayDoseStatus.taken,
        takenAt: DateTime(date.year, date.month, date.day, 8, 5),
        dependentId: dependentId ?? 'dep-1',
        dependentName: dependentId == null ? 'João Silva' : null,
      ),
      DayDoseDetail(
        id: 'dose-${date.day}-2',
        medicationName: 'Ibuprofeno',
        dosage: '400mg',
        scheduledAt: DateTime(date.year, date.month, date.day, 14),
        status: date.isAfter(DateTime.now())
            ? DayDoseStatus.pending
            : DayDoseStatus.missed,
        dependentId: dependentId ?? 'dep-2',
        dependentName: dependentId == null ? 'Maria Souza' : null,
      ),
    ];
  }

  HistorySummary _buildSummary(
    DateTime month, {
    required int takenBase,
    required int missed,
    String? dependentId,
    String? dependentName,
  }) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final today = DateTime.now();
    final days = <HistoryDay>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final date = DateTime(month.year, month.month, d);
      if (date.isAfter(today)) {
        days.add(HistoryDay(date: date, status: DayStatus.none));
      } else if (d % 11 == 0 && missed > 0) {
        days.add(HistoryDay(date: date, status: DayStatus.someMissed));
      } else {
        days.add(HistoryDay(date: date, status: DayStatus.allTaken));
      }
    }

    final missedDoses = <MissedDose>[];
    if (missed > 0) {
      missedDoses.add(
        MissedDose(
          medicationName: 'Ibuprofeno',
          dosage: '400mg',
          scheduledAt: DateTime(month.year, month.month, 11, 22, 0),
          dependentName: dependentName,
        ),
      );
    }
    if (missed > 1) {
      missedDoses.add(
        MissedDose(
          medicationName: 'Omeprazol',
          dosage: '20mg',
          scheduledAt: DateTime(month.year, month.month, 22, 8, 0),
          dependentName: dependentName,
        ),
      );
    }
    if (missed > 2) {
      missedDoses.add(
        MissedDose(
          medicationName: 'Paracetamol',
          dosage: '500mg',
          scheduledAt: DateTime(month.year, month.month, 5, 14, 0),
        ),
      );
    }

    return HistorySummary(
      dosesTaken: takenBase,
      dosesExpected: takenBase + missed,
      dosesMissed: missed,
      days: days,
      missedDoses: missedDoses,
      dependentId: dependentId,
      dependentName: dependentName,
    );
  }
}
