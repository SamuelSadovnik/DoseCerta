class RegisterState {
  const RegisterState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.obscurePassword = true,
    this.acceptedTerms = false,
    this.isLoading = false,
    this.errorMessage,
    this.registerSuccess = false,
  });

  final String name;
  final String email;
  final String password;
  final bool obscurePassword;
  final bool acceptedTerms;
  final bool isLoading;
  final String? errorMessage;
  final bool registerSuccess;

  RegisterState copyWith({
    String? name,
    String? email,
    String? password,
    bool? obscurePassword,
    bool? acceptedTerms,
    bool? isLoading,
    String? errorMessage,
    bool? registerSuccess,
    bool clearError = false,
  }) {
    return RegisterState(
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      registerSuccess: registerSuccess ?? this.registerSuccess,
    );
  }
}
