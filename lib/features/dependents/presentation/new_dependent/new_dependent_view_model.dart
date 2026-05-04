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
  void onRelationshipChanged(RelationshipType r) =>
      state = state.copyWith(relationship: r, clearError: true);

  Future<void> submit() async {
    if (state.isLoading) return;
    if (state.name.trim().isEmpty ||
        state.birthDate == null ||
        state.relationship == null) {
      state = state.copyWith(errorMessage: 'Preencha todos os campos.');
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.create(
        name: state.name.trim(),
        birthDate: state.birthDate!,
        relationship: state.relationship!,
      );
      _ref.invalidate(dependentsProvider);
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
