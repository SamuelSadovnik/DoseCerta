import 'package:dio/dio.dart';

import '../../domain/entities/appointment.dart';
import '../models/appointment_dto.dart';

/// Remote datasource for appointments.
///
/// Factory pattern: pick `.http(dio)` or `.mock()`.
abstract class AppointmentRemoteDatasource {
  factory AppointmentRemoteDatasource.http(Dio dio) =
      _HttpAppointmentRemoteDatasource;

  factory AppointmentRemoteDatasource.mock() = _MockAppointmentRemoteDatasource;

  Future<List<AppointmentDto>> getAll({String? dependentId});

  Future<AppointmentDto> create({
    required String doctorName,
    required String specialty,
    required DateTime scheduledAt,
    required String location,
    String? dependentId,
  });

  Future<AppointmentDto> confirm(String id);

  Future<AppointmentDto> complete(String id);

  Future<AppointmentDto> cancel(String id);

  Future<AppointmentDto> reschedule({
    required String id,
    required String doctorName,
    required String specialty,
    required DateTime scheduledAt,
    required String location,
    String? dependentId,
  });

  Future<void> delete(String id);
}

class _HttpAppointmentRemoteDatasource implements AppointmentRemoteDatasource {
  _HttpAppointmentRemoteDatasource(this._dio);
  final Dio _dio;

  @override
  Future<List<AppointmentDto>> getAll({String? dependentId}) async {
    final res = await _dio.get<List<dynamic>>(
      '/appointments',
      queryParameters: dependentId != null
          ? {'dependentId': dependentId}
          : null,
    );
    return (res.data ?? const [])
        .map((e) => AppointmentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AppointmentDto> create({
    required String doctorName,
    required String specialty,
    required DateTime scheduledAt,
    required String location,
    String? dependentId,
  }) async {
    final data = <String, dynamic>{
      'doctorName': doctorName,
      'specialty': specialty,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      'location': location,
    };
    if (dependentId != null) {
      data['dependentId'] = dependentId;
    }
    final res = await _dio.post<Map<String, dynamic>>(
      '/appointments',
      data: data,
    );
    return AppointmentDto.fromJson(res.data!);
  }

  @override
  Future<AppointmentDto> confirm(String id) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/appointments/$id/confirm',
    );
    return AppointmentDto.fromJson(res.data!);
  }

  @override
  Future<AppointmentDto> complete(String id) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/appointments/$id/complete',
    );
    return AppointmentDto.fromJson(res.data!);
  }

  @override
  Future<AppointmentDto> cancel(String id) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/appointments/$id/cancel',
    );
    return AppointmentDto.fromJson(res.data!);
  }

  @override
  Future<AppointmentDto> reschedule({
    required String id,
    required String doctorName,
    required String specialty,
    required DateTime scheduledAt,
    required String location,
    String? dependentId,
  }) async {
    final data = <String, dynamic>{
      'doctorName': doctorName,
      'specialty': specialty,
      'scheduledAt': scheduledAt.toUtc().toIso8601String(),
      'location': location,
    };
    if (dependentId != null) {
      data['dependentId'] = dependentId;
    }
    final res = await _dio.post<Map<String, dynamic>>(
      '/appointments/$id/reschedule',
      data: data,
    );
    return AppointmentDto.fromJson(res.data!);
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete<void>('/appointments/$id');
  }
}

class _MockAppointmentRemoteDatasource implements AppointmentRemoteDatasource {
  @override
  Future<List<AppointmentDto>> getAll({String? dependentId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();
    return [
      AppointmentDto(
        id: 'a1',
        doctorName: 'Dra. Ana Silva',
        specialty: 'Cardiologia',
        scheduledAt: DateTime(now.year, now.month, now.day + 2, 14, 30),
        location: 'Hospital Geral Unimed',
        status: AppointmentStatus.confirmed,
      ),
      AppointmentDto(
        id: 'a2',
        doctorName: 'Dr. Lucas Martins',
        specialty: 'Clínico geral',
        scheduledAt: DateTime(now.year, now.month, now.day - 7, 9, 0),
        location: 'Clínica Vida',
        status: AppointmentStatus.completed,
      ),
      AppointmentDto(
        id: 'a3',
        doctorName: 'Dra. Paula Rocha',
        specialty: 'Endocrinologia',
        scheduledAt: DateTime(now.year, now.month, now.day - 14, 16, 0),
        location: 'Hospital São Lucas',
        status: AppointmentStatus.cancelled,
      ),
      AppointmentDto(
        id: 'a4',
        doctorName: 'Dr. Felipe Torres',
        specialty: 'Ortopedia',
        scheduledAt: DateTime(now.year, now.month, now.day + 10, 11, 0),
        location: 'Hospital Geral Unimed',
        status: AppointmentStatus.scheduled,
      ),
    ];
  }

  @override
  Future<AppointmentDto> create({
    required String doctorName,
    required String specialty,
    required DateTime scheduledAt,
    required String location,
    String? dependentId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return AppointmentDto(
      id: 'a-${DateTime.now().millisecondsSinceEpoch}',
      doctorName: doctorName,
      specialty: specialty,
      scheduledAt: scheduledAt,
      location: location,
      status: AppointmentStatus.scheduled,
      dependentId: dependentId,
    );
  }

  @override
  Future<AppointmentDto> confirm(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return AppointmentDto(
      id: id,
      doctorName: '-',
      specialty: '-',
      scheduledAt: DateTime.now(),
      location: '-',
      status: AppointmentStatus.confirmed,
    );
  }

  @override
  Future<AppointmentDto> complete(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return AppointmentDto(
      id: id,
      doctorName: '-',
      specialty: '-',
      scheduledAt: DateTime.now(),
      location: '-',
      status: AppointmentStatus.completed,
    );
  }

  @override
  Future<AppointmentDto> cancel(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return AppointmentDto(
      id: id,
      doctorName: '-',
      specialty: '-',
      scheduledAt: DateTime.now(),
      location: '-',
      status: AppointmentStatus.cancelled,
    );
  }

  @override
  Future<AppointmentDto> reschedule({
    required String id,
    required String doctorName,
    required String specialty,
    required DateTime scheduledAt,
    required String location,
    String? dependentId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return AppointmentDto(
      id: id,
      doctorName: doctorName,
      specialty: specialty,
      scheduledAt: scheduledAt,
      location: location,
      status: AppointmentStatus.rescheduled,
      dependentId: dependentId,
    );
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
}
