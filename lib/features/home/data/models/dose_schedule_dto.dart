import '../../domain/entities/dose_schedule.dart';

class DoseScheduleDto {
  const DoseScheduleDto({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.scheduledAt,
    required this.status,
    this.note,
    this.dependentId,
    this.dependentName,
    this.dependentAvatarUrl,
  });

  factory DoseScheduleDto.fromJson(Map<String, dynamic> json) {
    return DoseScheduleDto(
      id: json['id'] as String,
      medicationId: json['medicationId'] as String,
      medicationName: json['medicationName'] as String,
      dosage: json['dosage'] as String,
      note: json['note'] as String?,
      scheduledAt: DateTime.parse(json['scheduledAt'] as String).toLocal(),
      status: DoseStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => DoseStatus.pending,
      ),
      dependentId: json['dependentId'] as String?,
      dependentName: json['dependentName'] as String?,
      dependentAvatarUrl: json['dependentAvatarUrl'] as String?,
    );
  }

  final String id;
  final String medicationId;
  final String medicationName;
  final String dosage;
  final String? note;
  final DateTime scheduledAt;
  final DoseStatus status;
  final String? dependentId;
  final String? dependentName;
  final String? dependentAvatarUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'medicationId': medicationId,
    'medicationName': medicationName,
    'dosage': dosage,
    'note': note,
    'scheduledAt': scheduledAt.toIso8601String(),
    'status': status.name,
    'dependentId': dependentId,
    'dependentName': dependentName,
    'dependentAvatarUrl': dependentAvatarUrl,
  };

  DoseSchedule toEntity() => DoseSchedule(
    id: id,
    medicationId: medicationId,
    medicationName: medicationName,
    dosage: dosage,
    note: note,
    scheduledAt: scheduledAt,
    status: status,
    dependentId: dependentId,
    dependentName: dependentName,
    dependentAvatarUrl: dependentAvatarUrl,
  );
}
