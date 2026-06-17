import 'package:dio/dio.dart';

import '../../domain/entities/dependent.dart';
import '../models/dependent_dto.dart';

/// Remote datasource for dependents.
///
/// Factory pattern: pick `.http(dio)` or `.mock()`.
abstract class DependentRemoteDatasource {
  factory DependentRemoteDatasource.http(Dio dio) =
      _HttpDependentRemoteDatasource;

  factory DependentRemoteDatasource.mock() = _MockDependentRemoteDatasource;

  Future<List<DependentDto>> getAll();

  Future<DependentDto> create({
    required String name,
    required DateTime birthDate,
    required RelationshipType relationship,
  });

  Future<DependentDto> link({required String code});

  Future<DependentDto> regenerateActivationCode(String id);

  Future<void> unlink();

  Future<void> delete(String id);
}

class _HttpDependentRemoteDatasource implements DependentRemoteDatasource {
  _HttpDependentRemoteDatasource(this._dio);
  final Dio _dio;

  @override
  Future<List<DependentDto>> getAll() async {
    final res = await _dio.get<List<dynamic>>('/dependents');
    return (res.data ?? const [])
        .map((e) => DependentDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DependentDto> create({
    required String name,
    required DateTime birthDate,
    required RelationshipType relationship,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/dependents',
      data: {
        'name': name,
        'birthDate': _formatDate(birthDate),
        'relationship': relationship.name,
      },
    );
    return DependentDto.fromJson(res.data!);
  }

  @override
  Future<DependentDto> link({required String code}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/dependents/link',
      data: {'code': code},
    );
    return DependentDto.fromJson(res.data!);
  }

  @override
  Future<DependentDto> regenerateActivationCode(String id) async {
    final res = await _dio.post<Map<String, dynamic>>('/dependents/$id/code');
    return DependentDto.fromJson(res.data!);
  }

  @override
  Future<void> unlink() async {
    await _dio.post<void>('/dependents/unlink');
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete<void>('/dependents/$id');
  }

  static String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

class _MockDependentRemoteDatasource implements DependentRemoteDatasource {
  @override
  Future<List<DependentDto>> getAll() async {
    await Future<void>.delayed(Duration(milliseconds: 600));
    return [
      DependentDto(
        id: 'dep-1',
        name: 'João Silva',
        birthDate: DateTime(1960, 3, 14),
        relationship: RelationshipType.father,
        status: DependentStatus.active,
        statusMessage: 'Medicamentos em dia',
      ),
      DependentDto(
        id: 'dep-2',
        name: 'Maria Souza',
        birthDate: DateTime(1962, 7, 22),
        relationship: RelationshipType.mother,
        status: DependentStatus.pendingConfirmation,
        statusMessage: 'Aguardando confirmação',
      ),
      DependentDto(
        id: 'dep-3',
        name: 'Ricardo Lima',
        birthDate: DateTime(1958, 1, 5),
        relationship: RelationshipType.other,
        status: DependentStatus.overdue,
        statusMessage: '1 dose em atraso',
      ),
    ];
  }

  @override
  Future<DependentDto> create({
    required String name,
    required DateTime birthDate,
    required RelationshipType relationship,
  }) async {
    await Future<void>.delayed(Duration(milliseconds: 600));
    return DependentDto(
      id: 'dep-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      birthDate: birthDate,
      relationship: relationship,
      status: DependentStatus.pendingConfirmation,
      statusMessage: 'Aguardando confirmação',
    );
  }

  @override
  Future<DependentDto> link({required String code}) async {
    await Future<void>.delayed(Duration(milliseconds: 400));
    return DependentDto(
      id: 'dep-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Dependente Vinculado',
      relationship: RelationshipType.other,
      status: DependentStatus.active,
      activationCode: code,
      linkedUserId: 'mock-user',
      linkedAt: DateTime.now(),
    );
  }

  @override
  Future<DependentDto> regenerateActivationCode(String id) async {
    await Future<void>.delayed(Duration(milliseconds: 400));
    return DependentDto(
      id: id,
      name: 'Pessoa cuidada',
      relationship: RelationshipType.other,
      status: DependentStatus.pendingConfirmation,
      statusMessage: 'Aguardando confirmação',
      activationCode: DateTime.now().millisecondsSinceEpoch
          .toRadixString(36)
          .toUpperCase()
          .padLeft(8, '0')
          .substring(0, 8),
    );
  }

  @override
  Future<void> unlink() async {
    await Future<void>.delayed(Duration(milliseconds: 200));
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(Duration(milliseconds: 200));
  }
}
