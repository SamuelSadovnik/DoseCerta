enum MedicationUnit { tablet, capsule, drop, ml }

extension MedicationUnitX on MedicationUnit {
  String get plural => switch (this) {
    MedicationUnit.tablet => 'comprimidos',
    MedicationUnit.capsule => 'cápsulas',
    MedicationUnit.drop => 'gotas',
    MedicationUnit.ml => 'ml',
  };

  String get singular => switch (this) {
    MedicationUnit.tablet => 'comprimido',
    MedicationUnit.capsule => 'cápsula',
    MedicationUnit.drop => 'gota',
    MedicationUnit.ml => 'ml',
  };
}

class Medication {
  const Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.currentQuantity,
    required this.initialQuantity,
    required this.frequency,
    required this.durationDays,
    this.dependentId,
  });

  final String id;
  final String name;
  final String dosage;
  final MedicationUnit unit;
  final int currentQuantity;
  final int initialQuantity;
  final String frequency;
  final int durationDays;
  final String? dependentId;

  double get capacityRatio =>
      initialQuantity == 0 ? 0 : currentQuantity / initialQuantity;

  int get capacityPercent => (capacityRatio * 100).round().clamp(0, 100);

  bool get isCritical => capacityRatio < 0.2;
}
