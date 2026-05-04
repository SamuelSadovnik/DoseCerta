import '../../domain/entities/dependent.dart';

class NewDependentState {
  const NewDependentState({
    this.name = '',
    this.birthDate,
    this.relationship,
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  final String name;
  final DateTime? birthDate;
  final RelationshipType? relationship;
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  NewDependentState copyWith({
    String? name,
    DateTime? birthDate,
    RelationshipType? relationship,
    bool? isLoading,
    String? errorMessage,
    bool? success,
    bool clearError = false,
  }) {
    return NewDependentState(
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      relationship: relationship ?? this.relationship,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      success: success ?? this.success,
    );
  }
}
