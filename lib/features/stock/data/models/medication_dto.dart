import '../../domain/entities/medication.dart';

class MedicationDto {
  const MedicationDto({
    required this.id,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.currentQuantity,
    required this.initialQuantity,
    required this.frequency,
    required this.durationDays,
    this.status = MedicationStatus.active,
    this.dependentId,
  });

  factory MedicationDto.fromJson(Map<String, dynamic> json) {
    return MedicationDto(
      id: json['id'] as String,
      name: json['name'] as String,
      dosage: json['dosage'] as String,
      unit: MedicationUnit.values.firstWhere(
        (u) => u.name == json['unit'],
        orElse: () => MedicationUnit.tablet,
      ),
      currentQuantity: json['currentQuantity'] as int,
      initialQuantity: json['initialQuantity'] as int,
      frequency: json['frequency'] as String,
      durationDays: json['durationDays'] as int,
      status: MedicationStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MedicationStatus.active,
      ),
      dependentId: json['dependentId'] as String?,
    );
  }

  final String id;
  final String name;
  final String dosage;
  final MedicationUnit unit;
  final int currentQuantity;
  final int initialQuantity;
  final String frequency;
  final int durationDays;
  final MedicationStatus status;
  final String? dependentId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dosage': dosage,
    'unit': unit.name,
    'currentQuantity': currentQuantity,
    'initialQuantity': initialQuantity,
    'frequency': frequency,
    'durationDays': durationDays,
    'status': status.name,
    'dependentId': dependentId,
  };

  Medication toEntity() => Medication(
    id: id,
    name: name,
    dosage: dosage,
    unit: unit,
    currentQuantity: currentQuantity,
    initialQuantity: initialQuantity,
    frequency: frequency,
    durationDays: durationDays,
    status: status,
    dependentId: dependentId,
  );
}
