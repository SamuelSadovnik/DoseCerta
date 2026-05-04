import 'package:dio/dio.dart';

import '../../domain/entities/medication.dart';
import '../models/medication_dto.dart';

/// Remote datasource for medications.
///
/// Factory pattern: callers don't see the concrete class, they pick a flavor
/// via [MedicationRemoteDatasource.http] or [MedicationRemoteDatasource.mock].
abstract class MedicationRemoteDatasource {
  factory MedicationRemoteDatasource.http(Dio dio) =
      _HttpMedicationRemoteDatasource;

  factory MedicationRemoteDatasource.mock() = _MockMedicationRemoteDatasource;

  Future<List<MedicationDto>> getAll({String? dependentId});

  Future<MedicationDto> create({
    required String name,
    required String dosage,
    required MedicationUnit unit,
    required int initialQuantity,
    required String frequency,
    required int durationDays,
    String? dependentId,
  });

  Future<void> delete(String id);

  Future<MedicationDto> refill({required String id, required int quantity});
}

class _HttpMedicationRemoteDatasource implements MedicationRemoteDatasource {
  _HttpMedicationRemoteDatasource(this._dio);
  final Dio _dio;

  @override
  Future<List<MedicationDto>> getAll({String? dependentId}) async {
    final res = await _dio.get<List<dynamic>>(
      '/medications',
      queryParameters: dependentId != null
          ? {'dependentId': dependentId}
          : null,
    );
    return (res.data ?? const [])
        .map((e) => MedicationDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MedicationDto> create({
    required String name,
    required String dosage,
    required MedicationUnit unit,
    required int initialQuantity,
    required String frequency,
    required int durationDays,
    String? dependentId,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'dosage': dosage,
      'unit': unit.name,
      'initialQuantity': initialQuantity,
      'frequency': frequency,
      'durationDays': durationDays,
    };
    if (dependentId != null) {
      data['dependentId'] = dependentId;
    }
    final res = await _dio.post<Map<String, dynamic>>(
      '/medications',
      data: data,
    );
    return MedicationDto.fromJson(res.data!);
  }

  @override
  Future<void> delete(String id) async {
    await _dio.delete<void>('/medications/$id');
  }

  @override
  Future<MedicationDto> refill({
    required String id,
    required int quantity,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/medications/$id/refill',
      data: {'quantity': quantity},
    );
    return MedicationDto.fromJson(res.data!);
  }
}

class _MockMedicationRemoteDatasource implements MedicationRemoteDatasource {
  @override
  Future<List<MedicationDto>> getAll({String? dependentId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const [
      MedicationDto(
        id: 'm1',
        name: 'Paracetamol',
        dosage: '500mg',
        unit: MedicationUnit.tablet,
        currentQuantity: 12,
        initialQuantity: 20,
        frequency: 'A cada 8 horas',
        durationDays: 7,
      ),
      MedicationDto(
        id: 'm2',
        name: 'Vitamina D',
        dosage: '2000 UI',
        unit: MedicationUnit.drop,
        currentQuantity: 28,
        initialQuantity: 30,
        frequency: '1x ao dia',
        durationDays: 30,
      ),
      MedicationDto(
        id: 'm3',
        name: 'Ibuprofeno',
        dosage: '400mg',
        unit: MedicationUnit.capsule,
        currentQuantity: 3,
        initialQuantity: 20,
        frequency: 'A cada 6 horas',
        durationDays: 5,
      ),
      MedicationDto(
        id: 'm4',
        name: 'Omeprazol',
        dosage: '20mg',
        unit: MedicationUnit.capsule,
        currentQuantity: 10,
        initialQuantity: 30,
        frequency: '1x ao dia',
        durationDays: 30,
      ),
    ];
  }

  @override
  Future<MedicationDto> create({
    required String name,
    required String dosage,
    required MedicationUnit unit,
    required int initialQuantity,
    required String frequency,
    required int durationDays,
    String? dependentId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return MedicationDto(
      id: 'm-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      dosage: dosage,
      unit: unit,
      currentQuantity: initialQuantity,
      initialQuantity: initialQuantity,
      frequency: frequency,
      durationDays: durationDays,
      dependentId: dependentId,
    );
  }

  @override
  Future<void> delete(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<MedicationDto> refill({
    required String id,
    required int quantity,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return MedicationDto(
      id: id,
      name: 'Refilled',
      dosage: '-',
      unit: MedicationUnit.tablet,
      currentQuantity: quantity,
      initialQuantity: quantity,
      frequency: '-',
      durationDays: 0,
    );
  }
}
