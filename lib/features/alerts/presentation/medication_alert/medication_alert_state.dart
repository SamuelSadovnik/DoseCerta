import '../../domain/alert_action.dart';

class MedicationAlertState {
  const MedicationAlertState({
    this.actionTaken,
    this.isLoading = false,
    this.errorMessage,
  });

  final AlertAction? actionTaken;
  final bool isLoading;
  final String? errorMessage;

  MedicationAlertState copyWith({
    AlertAction? actionTaken,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MedicationAlertState(
      actionTaken: actionTaken ?? this.actionTaken,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
