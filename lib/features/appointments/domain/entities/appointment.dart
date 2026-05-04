enum AppointmentStatus {
  scheduled,
  confirmed,
  completed,
  cancelled,
  rescheduled,
}

extension AppointmentStatusX on AppointmentStatus {
  String get label => switch (this) {
    AppointmentStatus.scheduled => 'AGENDADA',
    AppointmentStatus.confirmed => 'CONFIRMADA',
    AppointmentStatus.completed => 'REALIZADA',
    AppointmentStatus.cancelled => 'CANCELADA',
    AppointmentStatus.rescheduled => 'REAGENDADA',
  };
}

class Appointment {
  const Appointment({
    required this.id,
    required this.doctorName,
    this.specialty,
    required this.scheduledAt,
    this.location,
    required this.status,
    this.doctorAvatarUrl,
    this.dependentId,
    this.dependentName,
    this.dependentAvatarUrl,
  });

  final String id;
  final String doctorName;
  final String? specialty;
  final DateTime scheduledAt;
  final String? location;
  final AppointmentStatus status;
  final String? doctorAvatarUrl;
  final String? dependentId;
  final String? dependentName;
  final String? dependentAvatarUrl;
}
