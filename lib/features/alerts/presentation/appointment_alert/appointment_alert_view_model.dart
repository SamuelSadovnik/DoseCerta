import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../appointments/presentation/providers/appointment_providers.dart';
import '../../domain/alert_action.dart';
import 'appointment_alert_state.dart';

class AppointmentAlertViewModel extends StateNotifier<AppointmentAlertState> {
  AppointmentAlertViewModel(this._ref, this._appointmentId)
    : super(const AppointmentAlertState());

  final Ref _ref;
  final String? _appointmentId;

  Future<void> confirm() async {
    if (_appointmentId == null || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      await _ref.read(appointmentRepositoryProvider).confirm(_appointmentId);
      _ref.invalidate(appointmentsProvider);
      state = state.copyWith(
        actionTaken: AlertAction.confirmed,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: describeApiError(
          e,
          fallback: 'Não foi possível confirmar a consulta.',
        ),
      );
    }
  }

  Future<void> complete() async {
    if (_appointmentId == null || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      await _ref.read(appointmentRepositoryProvider).complete(_appointmentId);
      _ref.invalidate(appointmentsProvider);
      state = state.copyWith(
        actionTaken: AlertAction.completed,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: describeApiError(
          e,
          fallback: 'Não foi possível concluir a consulta.',
        ),
      );
    }
  }

  Future<void> cancel() async {
    if (_appointmentId == null || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      await _ref.read(appointmentRepositoryProvider).cancel(_appointmentId);
      _ref.invalidate(appointmentsProvider);
      state = state.copyWith(
        actionTaken: AlertAction.cancelled,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: describeApiError(
          e,
          fallback: 'Não foi possível cancelar a consulta.',
        ),
      );
    }
  }
}

final appointmentAlertViewModelProvider = StateNotifierProvider.autoDispose
    .family<AppointmentAlertViewModel, AppointmentAlertState, String?>(
      (ref, appointmentId) => AppointmentAlertViewModel(ref, appointmentId),
    );
