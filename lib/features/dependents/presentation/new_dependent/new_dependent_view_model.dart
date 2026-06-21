import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../domain/entities/dependent.dart';
import '../../domain/repositories/dependent_repository.dart';
import '../providers/dependent_providers.dart';
import 'new_dependent_state.dart';

class NewDependentViewModel extends StateNotifier<NewDependentState> {
  NewDependentViewModel(this._repository, this._ref)
    : super(const NewDependentState());

  final DependentRepository _repository;
  final Ref _ref;

  void onNameChanged(String v) =>
      state = state.copyWith(name: v, clearError: true);
  void onBirthDateChanged(DateTime d) =>
      state = state.copyWith(birthDate: d, clearError: true);
  void onBirthDateTextChanged(String value) {
    final parsed = _parseBirthDate(value);
    state = state.copyWith(
      birthDate: parsed,
      clearBirthDate: parsed == null,
      clearError: true,
    );
  }

  void onRelationshipChanged(RelationshipType r) =>
      state = state.copyWith(relationship: r, clearError: true);

  Future<void> submit() async {
    if (state.isLoading) return;
    if (state.name.trim().isEmpty ||
        state.birthDate == null ||
        state.relationship == null) {
      state = state.copyWith(
        errorMessage: state.birthDate == null
            ? 'Informe uma data válida.'
            : 'Preencha todos os campos.',
      );
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final dependent = await _repository.create(
        name: state.name.trim(),
        birthDate: state.birthDate!,
        relationship: state.relationship!,
      );
      _ref.invalidate(dependentsProvider);
      state = state.copyWith(
        isLoading: false,
        success: true,
        createdDependent: dependent,
      );
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

  DateTime? _parseBirthDate(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return null;

    final day = int.tryParse(digits.substring(0, 2));
    final month = int.tryParse(digits.substring(2, 4));
    final year = int.tryParse(digits.substring(4, 8));
    if (day == null || month == null || year == null) return null;

    final date = DateTime(year, month, day);
    final today = DateTime.now();
    final currentDay = DateTime(today.year, today.month, today.day);
    final isSameDate =
        date.year == year && date.month == month && date.day == day;
    if (!isSameDate || year < 1900 || date.isAfter(currentDay)) {
      return null;
    }

    return date;
  }
}

final newDependentViewModelProvider =
    StateNotifierProvider.autoDispose<NewDependentViewModel, NewDependentState>(
      (ref) {
        return NewDependentViewModel(
          ref.watch(dependentRepositoryProvider),
          ref,
        );
      },
    );
