import '../../domain/entities/appointment.dart';

class AppointmentDto {
  const AppointmentDto({
    required this.id,
    required this.doctorName,
    this.specialty,
    required this.scheduledAt,
    this.location,
    this.status = AppointmentStatus.scheduled,
    this.doctorAvatarUrl,
    this.dependentId,
    this.dependentName,
    this.dependentAvatarUrl,
  });

  factory AppointmentDto.fromJson(Map<String, dynamic> json) {
    return AppointmentDto(
      id: json['id'] as String,
      doctorName: json['doctorName'] as String,
      specialty: json['specialty'] as String?,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String).toLocal(),
      location: json['location'] as String?,
      status: _parseStatus(json['status'] as String?),
      doctorAvatarUrl: json['doctorAvatarUrl'] as String?,
      dependentId: json['dependentId'] as String?,
      dependentName: json['dependentName'] as String?,
      dependentAvatarUrl: json['dependentAvatarUrl'] as String?,
    );
  }

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

  Map<String, dynamic> toJson() => {
    'id': id,
    'doctorName': doctorName,
    'specialty': specialty,
    'scheduledAt': scheduledAt.toIso8601String(),
    'location': location,
    'status': status.name,
    'doctorAvatarUrl': doctorAvatarUrl,
    'dependentId': dependentId,
    'dependentName': dependentName,
    'dependentAvatarUrl': dependentAvatarUrl,
  };

  Appointment toEntity() => Appointment(
    id: id,
    doctorName: doctorName,
    specialty: specialty,
    scheduledAt: scheduledAt,
    location: location,
    status: status,
    doctorAvatarUrl: doctorAvatarUrl,
    dependentId: dependentId,
    dependentName: dependentName,
    dependentAvatarUrl: dependentAvatarUrl,
  );

  static AppointmentStatus _parseStatus(String? value) {
    final normalized = value == 'done' ? 'completed' : value;
    return AppointmentStatus.values.firstWhere(
      (s) => s.name == normalized,
      orElse: () => AppointmentStatus.scheduled,
    );
  }
}
