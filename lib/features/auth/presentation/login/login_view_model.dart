import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_error.dart';
import '../../../../core/providers/account_type_provider.dart';
import '../../../../core/providers/selected_dependent_provider.dart';
import '../../domain/repositories/auth_repository.dart';
import '../providers/auth_providers.dart';
import 'login_state.dart';

class LoginViewModel extends StateNotifier<LoginState> {
  LoginViewModel(this._repository, this._ref) : super(const LoginState());

  final AuthRepository _repository;
  final Ref _ref;

  void onIdentifierChanged(String value) {
    state = state.copyWith(identifier: value, clearError: true);
  }

  void onPasswordChanged(String value) {
    state = state.copyWith(password: value, clearError: true);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<void> submit() async {
    if (state.isLoading) return;
    if (state.identifier.trim().isEmpty || state.password.isEmpty) {
      state = state.copyWith(errorMessage: 'Preencha todos os campos.');
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.login(
        identifier: state.identifier.trim(),
        password: state.password,
      );
      _ref.read(currentAccountTypeProvider.notifier).state =
          result.user.accountType;
      _ref.read(selectedDependentIdProvider.notifier).state = null;
      _ref.invalidate(currentUserProvider);
      state = state.copyWith(isLoading: false, loginSuccess: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: describeApiError(
          e,
          fallback: 'Não foi possível entrar. Tente novamente.',
        ),
      );
    }
  }
}

final loginViewModelProvider =
    StateNotifierProvider.autoDispose<LoginViewModel, LoginState>((ref) {
      return LoginViewModel(ref.watch(authRepositoryProvider), ref);
    });
