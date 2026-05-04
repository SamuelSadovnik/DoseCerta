import '../entities/appointment.dart';

abstract class AppointmentRepository {
  Future<List<Appointment>> getAll({String? dependentId});

  Future<Appointment> create({
    required String doctorName,
    required String specialty,
    required DateTime scheduledAt,
    required String location,
    String? dependentId,
  });

  Future<Appointment> confirm(String id);

  Future<Appointment> reschedule({
    required String id,
    required String doctorName,
    required String specialty,
    required DateTime scheduledAt,
    required String location,
    String? dependentId,
  });

  Future<void> delete(String id);
}
