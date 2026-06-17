import '../entities/medication.dart';

abstract class MedicationRepository {
  Future<List<Medication>> getAll({String? dependentId});

  Future<Medication> create({
    required String name,
    required String dosage,
    required MedicationUnit unit,
    required int initialQuantity,
    required String frequency,
    required int durationDays,
    String? dependentId,
  });

  Future<void> delete(String id);

  Future<Medication> refill({required String id, required int quantity});

  Future<Medication> updateStock({required String id, required int quantity});
}
