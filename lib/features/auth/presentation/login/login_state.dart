class LoginState {
  const LoginState({
    this.identifier = '',
    this.password = '',
    this.obscurePassword = true,
    this.isLoading = false,
    this.errorMessage,
    this.loginSuccess = false,
  });

  final String identifier;
  final String password;
  final bool obscurePassword;
  final bool isLoading;
  final String? errorMessage;
  final bool loginSuccess;

  LoginState copyWith({
    String? identifier,
    String? password,
    bool? obscurePassword,
    bool? isLoading,
    String? errorMessage,
    bool? loginSuccess,
    bool clearError = false,
  }) {
    return LoginState(
      identifier: identifier ?? this.identifier,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loginSuccess: loginSuccess ?? this.loginSuccess,
    );
  }
}
