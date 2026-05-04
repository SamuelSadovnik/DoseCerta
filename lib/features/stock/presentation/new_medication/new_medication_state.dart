import '../../domain/entities/medication.dart';

class NewMedicationState {
  const NewMedicationState({
    this.name = '',
    this.dosage = '',
    this.quantity = '',
    this.duration = '',
    this.frequency,
    this.unit = MedicationUnit.tablet,
    this.dependentId,
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  final String name;
  final String dosage;
  final String quantity;
  final String duration;
  final String? frequency;
  final MedicationUnit unit;
  final String? dependentId;
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  NewMedicationState copyWith({
    String? name,
    String? dosage,
    String? quantity,
    String? duration,
    String? frequency,
    MedicationUnit? unit,
    String? dependentId,
    bool? isLoading,
    String? errorMessage,
    bool? success,
    bool clearError = false,
  }) {
    return NewMedicationState(
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      quantity: quantity ?? this.quantity,
      duration: duration ?? this.duration,
      frequency: frequency ?? this.frequency,
      unit: unit ?? this.unit,
      dependentId: dependentId ?? this.dependentId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      success: success ?? this.success,
    );
  }
}
