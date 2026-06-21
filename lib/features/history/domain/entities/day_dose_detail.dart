enum DayDoseStatus { pending, taken, missed, postponed }

class DayDoseDetail {
  const DayDoseDetail({
    required this.id,
    required this.medicationName,
    required this.dosage,
    required this.scheduledAt,
    required this.status,
    this.takenAt,
    this.dependentId,
    this.dependentName,
  });

  final String id;
  final String medicationName;
  final String dosage;
  final DateTime scheduledAt;
  final DayDoseStatus status;
  final DateTime? takenAt;
  final String? dependentId;
  final String? dependentName;
}
