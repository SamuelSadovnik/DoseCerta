import '../entities/dependent.dart';

abstract class DependentRepository {
  Future<List<Dependent>> getAll();

  Future<Dependent> create({
    required String name,
    required DateTime birthDate,
    required RelationshipType relationship,
  });

  Future<Dependent> link({required String code});

  Future<void> unlink();

  Future<void> delete(String id);
}
