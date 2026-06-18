import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/providers/selected_dependent_provider.dart';
import '../../../home/presentation/providers/home_providers.dart';
import '../../../history/presentation/providers/history_providers.dart';
import '../../domain/repositories/medication_repository.dart';
import '../providers/stock_providers.dart';
import 'new_medication_state.dart';

class NewMedicationViewModel extends StateNotifier<NewMedicationState> {
  NewMedicationViewModel(this._repository, this._ref)
    : super(
        NewMedicationState(
          dependentId: _ref.read(selectedCareDependentIdProvider),
        ),
      );

  final MedicationRepository _repository;
  final Ref _ref;

  void onNameChanged(String v) =>
      state = state.copyWith(name: v, clearError: true);
  void onDosageChanged(String v) =>
      state = state.copyWith(dosage: v, clearError: true);
  void onQuantityChanged(String v) =>
      state = state.copyWith(quantity: v, clearError: true);
  void onDurationChanged(String v) =>
      state = state.copyWith(duration: v, clearError: true);
  void onFrequencyChanged(String v) =>
      state = state.copyWith(frequency: v, clearError: true);
  void onDependentChanged(String? id) => state = state.copyWith(
    dependentId: id,
    clearDependent: id == null,
    clearError: true,
  );

  Future<void> submit() async {
    if (state.isLoading) return;
    if (state.name.trim().isEmpty ||
        state.dosage.trim().isEmpty ||
        state.quantity.trim().isEmpty ||
        state.duration.trim().isEmpty ||
        state.frequency == null) {
      state = state.copyWith(errorMessage: 'Preencha todos os campos.');
      return;
    }
    final quantity = int.tryParse(
      RegExp(r'\d+').firstMatch(state.quantity)?[0] ?? '',
    );
    if (quantity == null || quantity <= 0) {
      state = state.copyWith(errorMessage: 'Quantidade inválida.');
      return;
    }
    final duration = int.tryParse(
      RegExp(r'\d+').firstMatch(state.duration)?[0] ?? '',
    );
    if (duration == null || duration <= 0) {
      state = state.copyWith(errorMessage: 'Duração inválida.');
      return;
    }
    final requiredQuantity = _requiredQuantity(
      frequency: state.frequency!,
      durationDays: duration,
    );
    if (quantity < requiredQuantity) {
      state = state.copyWith(
        errorMessage:
            'Quantidade insuficiente. Para ${state.frequency} por $duration dias, informe pelo menos $requiredQuantity doses.',
      );
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.create(
        name: state.name.trim(),
        dosage: state.dosage.trim(),
        unit: state.unit,
        initialQuantity: quantity,
        frequency: state.frequency!,
        durationDays: duration,
        dependentId: state.dependentId,
      );
      final createdForDependentId = state.dependentId;
      _ref.invalidate(medicationsProvider);
      if (createdForDependentId != null) {
        _ref.invalidate(medicationsByDependentProvider(createdForDependentId));
        _ref.read(selectedCareContextProvider.notifier).state =
            CareContext.dependent(createdForDependentId);
      }
      _ref.invalidate(homeDataProvider);
      _ref.invalidate(historySummariesProvider);
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: describeApiError(
          e,
          fallback: 'Não foi possível cadastrar.',
        ),
      );
    }
  }

  int _requiredQuantity({
    required String frequency,
    required int durationDays,
  }) {
    final intervalHours = _intervalHours(frequency);
    return (durationDays * 24) ~/ intervalHours;
  }

  int _intervalHours(String frequency) {
    final lower = frequency.toLowerCase().trim();
    final everyHours = RegExp(r'cada\s+(\d+)\s*hora').firstMatch(lower);
    if (everyHours != null) {
      return int.tryParse(everyHours.group(1) ?? '') ?? 24;
    }
    final timesPerDay = RegExp(r'(\d+)\s*x\s*ao\s*dia').firstMatch(lower);
    if (timesPerDay != null) {
      final count = int.tryParse(timesPerDay.group(1) ?? '') ?? 1;
      return count > 0 ? 24 ~/ count : 24;
    }
    return 24;
  }
}

final newMedicationViewModelProvider =
    StateNotifierProvider.autoDispose<
      NewMedicationViewModel,
      NewMedicationState
    >((ref) {
      return NewMedicationViewModel(
        ref.watch(medicationRepositoryProvider),
        ref,
      );
    });
