import 'package:dio/dio.dart';

import '../../../features/auth/data/models/user_dto.dart';
import '../../../features/stock/data/models/medication_dto.dart';

/// Remote datasource for the admin panel.
///
/// Factory pattern (HTTP-only variant — admin has no offline mock since
/// it's gated by network access to the panel anyway).
abstract class AdminRemoteDatasource {
  factory AdminRemoteDatasource.http(Dio dio) = _HttpAdminRemoteDatasource;

  Future<List<UserDto>> listUsers();

  Future<List<MedicationDto>> listMedications();
}

class _HttpAdminRemoteDatasource implements AdminRemoteDatasource {
  _HttpAdminRemoteDatasource(this._dio);
  final Dio _dio;

  @override
  Future<List<UserDto>> listUsers() async {
    final res = await _dio.get<List<dynamic>>('/admin/users');
    return (res.data ?? const [])
        .map((e) => UserDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MedicationDto>> listMedications() async {
    final res = await _dio.get<List<dynamic>>('/admin/medications');
    return (res.data ?? const [])
        .map((e) => MedicationDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
