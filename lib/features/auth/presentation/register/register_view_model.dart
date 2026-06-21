import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/account_type.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/providers/account_type_provider.dart';
import '../../../../core/providers/selected_dependent_provider.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_providers.dart';
import 'register_state.dart';

class RegisterViewModel extends StateNotifier<RegisterState> {
  RegisterViewModel(this._repository, this._ref, this._accountType)
    : super(const RegisterState());

  final AuthRepository _repository;
  final Ref _ref;
  final AccountType _accountType;

  void onNameChanged(String value) {
    state = state.copyWith(name: value, clearError: true);
  }

  void onEmailChanged(String value) {
    state = state.copyWith(email: value, clearError: true);
  }

  void onPasswordChanged(String value) {
    state = state.copyWith(password: value, clearError: true);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void toggleTerms(bool value) {
    state = state.copyWith(acceptedTerms: value);
  }

  bool get canSubmit {
    if (state.name.trim().isEmpty) return false;
    if (state.email.trim().isEmpty) return false;
    if (state.password.isEmpty) return false;
    if (_accountType == AccountType.personal && !state.acceptedTerms) {
      return false;
    }
    return true;
  }

  Future<void> submit() async {
    if (state.isLoading) return;
    if (!canSubmit) {
      state = state.copyWith(errorMessage: 'Preencha os dados para continuar.');
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.register(
        name: state.name.trim(),
        email: state.email.trim(),
        password: state.password,
        accountType: _accountType,
        acceptedTerms: state.acceptedTerms,
      );
      _ref.read(currentAccountTypeProvider.notifier).state =
          result.user.accountType;
      _ref
          .read(selectedCareContextProvider.notifier)
          .state = result.user.accountType == AccountType.caregiver
          ? const CareContext.allDependents()
          : const CareContext.self();
      _ref.invalidate(currentUserProvider);
      state = state.copyWith(isLoading: false, registerSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: describeApiError(
          e,
          fallback: 'Não foi possível cadastrar. Tente novamente.',
        ),
      );
    }
  }
}

final registerViewModelProvider = StateNotifierProvider.autoDispose
    .family<RegisterViewModel, RegisterState, AccountType>((ref, accountType) {
      return RegisterViewModel(
        ref.watch(authRepositoryProvider),
        ref,
        accountType,
      );
    });
