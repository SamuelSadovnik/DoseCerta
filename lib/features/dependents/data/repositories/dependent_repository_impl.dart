import '../../domain/entities/dependent.dart';
import '../../domain/repositories/dependent_repository.dart';
import '../datasources/dependent_remote_datasource.dart';

class DependentRepositoryImpl implements DependentRepository {
  DependentRepositoryImpl(this._remote);

  final DependentRemoteDatasource _remote;

  @override
  Future<List<Dependent>> getAll() async {
    final list = await _remote.getAll();
    return list.map((d) => d.toEntity()).toList();
  }

  @override
  Future<Dependent> create({
    required String name,
    required DateTime birthDate,
    required RelationshipType relationship,
  }) async {
    final dto = await _remote.create(
      name: name,
      birthDate: birthDate,
      relationship: relationship,
    );
    return dto.toEntity();
  }

  @override
  Future<Dependent> link({required String code}) async {
    final dto = await _remote.link(code: code);
    return dto.toEntity();
  }

  @override
  Future<Dependent> regenerateActivationCode(String id) async {
    final dto = await _remote.regenerateActivationCode(id);
    return dto.toEntity();
  }

  @override
  Future<void> unlink() => _remote.unlink();

  @override
  Future<void> delete(String id) => _remote.delete(id);
}
