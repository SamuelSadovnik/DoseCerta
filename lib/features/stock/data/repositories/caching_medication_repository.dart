import '../../../../core/storage/local_cache.dart';
import '../../domain/entities/medication.dart';
import '../../domain/repositories/medication_repository.dart';

/// Decorator over [MedicationRepository] that adds an offline cache:
///
///   - On `getAll`: tries remote first; on success persists the snapshot;
///     on failure falls back to the last cached snapshot if any.
///   - On writes (`create`, `delete`, `refill`): forwards to inner and
///     evicts the cache so the next read fetches a fresh snapshot.
///
/// Pure Decorator pattern — same interface as the inner repository, no
/// caller has to change.
class CachingMedicationRepository implements MedicationRepository {
  CachingMedicationRepository(this._inner, this._cache);

  final MedicationRepository _inner;
  final LocalCache _cache;

  static const _cacheKey = 'dosecerta.cache.medications';

  @override
  Future<List<Medication>> getAll({String? dependentId}) async {
    try {
      final fresh = await _inner.getAll(dependentId: dependentId);
      // Cache only the unfiltered global list to keep the contract simple.
      if (dependentId == null) {
        await _cache.writeJson(_cacheKey, fresh.map(_encode).toList());
      }
      return fresh;
    } catch (e) {
      final cached = _cache.readJson<List<Medication>>(_cacheKey, (raw) {
        return (raw as List).cast<Map<String, dynamic>>().map(_decode).toList();
      });
      if (cached != null) return cached;
      rethrow;
    }
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
    final created = await _inner.create(
      name: name,
      dosage: dosage,
      unit: unit,
      initialQuantity: initialQuantity,
      frequency: frequency,
      durationDays: durationDays,
      dependentId: dependentId,
    );
    await _cache.remove(_cacheKey);
    return created;
  }

  @override
  Future<void> delete(String id) async {
    await _inner.delete(id);
    await _cache.remove(_cacheKey);
  }

  @override
  Future<Medication> refill({required String id, required int quantity}) async {
    final result = await _inner.refill(id: id, quantity: quantity);
    await _cache.remove(_cacheKey);
    return result;
  }

  static Map<String, dynamic> _encode(Medication m) => {
    'id': m.id,
    'name': m.name,
    'dosage': m.dosage,
    'unit': m.unit.name,
    'currentQuantity': m.currentQuantity,
    'initialQuantity': m.initialQuantity,
    'frequency': m.frequency,
    'durationDays': m.durationDays,
    'dependentId': m.dependentId,
  };

  static Medication _decode(Map<String, dynamic> json) => Medication(
    id: json['id'] as String,
    name: json['name'] as String,
    dosage: json['dosage'] as String,
    unit: MedicationUnit.values.firstWhere(
      (u) => u.name == json['unit'],
      orElse: () => MedicationUnit.tablet,
    ),
    currentQuantity: json['currentQuantity'] as int,
    initialQuantity: json['initialQuantity'] as int,
    frequency: json['frequency'] as String,
    durationDays: json['durationDays'] as int,
    dependentId: json['dependentId'] as String?,
  );
}
