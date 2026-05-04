import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../domain/alert_action.dart';
import 'medication_alert_state.dart';

class MedicationAlertViewModel extends StateNotifier<MedicationAlertState> {
  MedicationAlertViewModel(this._ref, this._doseId)
    : super(const MedicationAlertState());

  final Ref _ref;
  final String? _doseId;

  Future<void> takeNow() async {
    if (_doseId == null || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      await _ref.read(dioProvider).post<void>('/doses/$_doseId/take');
      _ref.invalidate(homeDataProvider);
      state = state.copyWith(
        actionTaken: AlertAction.taken,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: describeApiError(
          e,
          fallback: 'Não foi possível registrar a dose.',
        ),
      );
    }
  }

  Future<void> postpone() async {
    if (_doseId == null || state.isLoading) return;
    state = state.copyWith(isLoading: true);
    try {
      await _ref
          .read(dioProvider)
          .post<void>('/doses/$_doseId/postpone', data: {'minutes': 10});
      _ref.invalidate(homeDataProvider);
      state = state.copyWith(
        actionTaken: AlertAction.postponed,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: describeApiError(
          e,
          fallback: 'Não foi possível adiar a dose.',
        ),
      );
    }
  }
}

final medicationAlertViewModelProvider = StateNotifierProvider.autoDispose
    .family<MedicationAlertViewModel, MedicationAlertState, String?>(
      (ref, doseId) => MedicationAlertViewModel(ref, doseId),
    );
