import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';
import '../datasources/medication_remote_datasource.dart';

class MedicationRepositoryImpl implements MedicationRepository {
  MedicationRepositoryImpl(this._remote);

  final MedicationRemoteDatasource _remote;

  @override
  Future<List<Medication>> getAll({String? dependentId}) async {
    final list = await _remote.getAll(dependentId: dependentId);
    return list.map((d) => d.toEntity()).toList();
  }

  @override
  Future<Medication> create({
    required String name,
    required String dosage,
    required MedicationUnit unit,
    required int initialQuantity,
    required String frequency,
    required int durationDays,
    String? dependentId,
  }) async {
    final dto = await _remote.create(
      name: name,
      dosage: dosage,
      unit: unit,
      initialQuantity: initialQuantity,
      frequency: frequency,
      durationDays: durationDays,
      dependentId: dependentId,
    );
    return dto.toEntity();
  }

  @override
  Future<void> delete(String id) => _remote.delete(id);

  @override
  Future<Medication> refill({required String id, required int quantity}) async {
    final dto = await _remote.refill(id: id, quantity: quantity);
    return dto.toEntity();
  }
}
