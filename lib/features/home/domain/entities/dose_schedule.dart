enum DoseStatus { pending, taken, missed, postponed }

class DoseSchedule {
  const DoseSchedule({
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
}
