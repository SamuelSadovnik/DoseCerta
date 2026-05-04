import '../../domain/alert_action.dart';

class AppointmentAlertState {
  const AppointmentAlertState({
    this.actionTaken,
    this.isLoading = false,
    this.errorMessage,
  });

  final AlertAction? actionTaken;
  final bool isLoading;
  final String? errorMessage;

  AppointmentAlertState copyWith({
    AlertAction? actionTaken,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppointmentAlertState(
      actionTaken: actionTaken ?? this.actionTaken,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
