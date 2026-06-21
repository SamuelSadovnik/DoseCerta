enum DayStatus { allTaken, someMissed, none }

class HistoryDay {
  const HistoryDay({required this.date, required this.status});

  final DateTime date;
  final DayStatus status;
}

class MissedDose {
  const MissedDose({
    required this.medicationName,
    required this.dosage,
    required this.scheduledAt,
    this.dependentName,
  });

  final String medicationName;
  final String dosage;
  final DateTime scheduledAt;
  final String? dependentName;
}

class HistorySummary {
  const HistorySummary({
    required this.dosesTaken,
    required this.dosesExpected,
    required this.dosesMissed,
    required this.days,
    required this.missedDoses,
    required this.treatments,
    this.dependentId,
    this.dependentName,
    this.dependentAvatarUrl,
  });

  final int dosesTaken;
  final int dosesExpected;
  final int dosesMissed;
  final List<HistoryDay> days;
  final List<MissedDose> missedDoses;
  final List<TreatmentHistory> treatments;
  final String? dependentId;
  final String? dependentName;
  final String? dependentAvatarUrl;
}

class TreatmentHistory {
  const TreatmentHistory({
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.dosesTaken,
    required this.dosesExpected,
    required this.dosesMissed,
    required this.adherencePercent,
    this.lastDoseAt,
    this.lastStatus,
  });

  final String medicationId;
  final String medicationName;
  final String dosage;
  final int dosesTaken;
  final int dosesExpected;
  final int dosesMissed;
  final int adherencePercent;
  final DateTime? lastDoseAt;
  final String? lastStatus;
}
