import 'package:dio/dio.dart';

import '../../../../core/enums/account_type.dart';
import '../../domain/entities/dose_schedule.dart';
import '../models/dose_schedule_dto.dart';

/// Remote datasource for the home screen (today's dose schedule).
///
/// Factory pattern: pick `.http(dio)` or `.mock()`.
abstract class HomeRemoteDatasource {
  factory HomeRemoteDatasource.http(Dio dio) = _HttpHomeRemoteDatasource;

  factory HomeRemoteDatasource.mock() = _MockHomeRemoteDatasource;

  Future<List<DoseScheduleDto>> getTodayDoses({
    required AccountType accountType,
    String? dependentId,
    bool selfOnly = false,
  });
}

class _HttpHomeRemoteDatasource implements HomeRemoteDatasource {
  _HttpHomeRemoteDatasource(this._dio);
  final Dio _dio;

  @override
  Future<List<DoseScheduleDto>> getTodayDoses({
    required AccountType accountType,
    String? dependentId,
    bool selfOnly = false,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (dependentId != null) {
      queryParameters['dependentId'] = dependentId;
    } else if (selfOnly) {
      queryParameters['scope'] = 'self';
    }
    final res = await _dio.get<List<dynamic>>(
      '/doses',
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );
    return (res.data ?? const [])
        .map((e) => DoseScheduleDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class _MockHomeRemoteDatasource implements HomeRemoteDatasource {
  @override
  Future<List<DoseScheduleDto>> getTodayDoses({
    required AccountType accountType,
    String? dependentId,
    bool selfOnly = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();
    DateTime at(int hour, int minute) =>
        DateTime(now.year, now.month, now.day, hour, minute);
    final isCaregiver = accountType == AccountType.caregiver;

    return [
      DoseScheduleDto(
        id: 'd1',
        medicationId: 'm1',
        medicationName: 'Paracetamol',
        dosage: '1 comprimido',
        note: 'Com comida',
        scheduledAt: at(8, 0),
        status: DoseStatus.taken,
        dependentId: isCaregiver ? 'dep-1' : null,
        dependentName: isCaregiver ? 'João Silva' : null,
      ),
      DoseScheduleDto(
        id: 'd2',
        medicationId: 'm2',
        medicationName: 'Vitamina D',
        dosage: '2 gotas',
        scheduledAt: at(10, 0),
        status: DoseStatus.taken,
        dependentId: isCaregiver ? 'dep-2' : null,
        dependentName: isCaregiver ? 'Maria Souza' : null,
      ),
      DoseScheduleDto(
        id: 'd3',
        medicationId: 'm3',
        medicationName: 'Ibuprofeno',
        dosage: '1 cápsula 400mg',
        note: 'Com água',
        scheduledAt: at(14, 0),
        status: DoseStatus.pending,
        dependentId: isCaregiver ? 'dep-1' : null,
        dependentName: isCaregiver ? 'João Silva' : null,
      ),
      DoseScheduleDto(
        id: 'd4',
        medicationId: 'm1',
        medicationName: 'Paracetamol',
        dosage: '1 comprimido',
        scheduledAt: at(16, 0),
        status: DoseStatus.pending,
        dependentId: isCaregiver ? 'dep-3' : null,
        dependentName: isCaregiver ? 'Ricardo Lima' : null,
      ),
      DoseScheduleDto(
        id: 'd5',
        medicationId: 'm4',
        medicationName: 'Omeprazol',
        dosage: '1 cápsula',
        scheduledAt: at(20, 0),
        status: DoseStatus.pending,
        dependentId: isCaregiver ? 'dep-1' : null,
        dependentName: isCaregiver ? 'João Silva' : null,
      ),
      DoseScheduleDto(
        id: 'd6',
        medicationId: 'm2',
        medicationName: 'Vitamina D',
        dosage: '2 gotas',
        scheduledAt: at(22, 0),
        status: DoseStatus.missed,
        dependentId: isCaregiver ? 'dep-2' : null,
        dependentName: isCaregiver ? 'Maria Souza' : null,
      ),
    ];
  }
}
