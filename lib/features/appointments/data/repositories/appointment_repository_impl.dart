import '../../domain/entities/appointment.dart';
import '../../domain/repositories/appointment_repository.dart';
import '../datasources/appointment_remote_datasource.dart';

class AppointmentRepositoryImpl implements AppointmentRepository {
  AppointmentRepositoryImpl(this._remote);

  final AppointmentRemoteDatasource _remote;

  @override
  Future<List<Appointment>> getAll({String? dependentId}) async {
    final list = await _remote.getAll(dependentId: dependentId);
    return list.map((d) => d.toEntity()).toList();
  }

  @override
  Future<Appointment> create({
    required String doctorName,
    required String specialty,
    required DateTime scheduledAt,
    required String location,
    String? dependentId,
  }) async {
    final dto = await _remote.create(
      doctorName: doctorName,
      specialty: specialty,
      scheduledAt: scheduledAt,
      location: location,
      dependentId: dependentId,
    );
    return dto.toEntity();
  }

  @override
  Future<Appointment> confirm(String id) async {
    final dto = await _remote.confirm(id);
    return dto.toEntity();
  }

  @override
  Future<Appointment> complete(String id) async {
    final dto = await _remote.complete(id);
    return dto.toEntity();
  }

  @override
  Future<Appointment> cancel(String id) async {
    final dto = await _remote.cancel(id);
    return dto.toEntity();
  }

  @override
  Future<Appointment> reschedule({
    required String id,
    required String doctorName,
    required String specialty,
    required DateTime scheduledAt,
    required String location,
    String? dependentId,
  }) async {
    final dto = await _remote.reschedule(
      id: id,
      doctorName: doctorName,
      specialty: specialty,
      scheduledAt: scheduledAt,
      location: location,
      dependentId: dependentId,
    );
    return dto.toEntity();
  }

  @override
  Future<void> delete(String id) => _remote.delete(id);
}
