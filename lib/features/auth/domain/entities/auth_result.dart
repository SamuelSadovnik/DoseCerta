import 'user.dart';

class AuthResult {
  const AuthResult({required this.accessToken, required this.user});

  final String accessToken;
  final User user;
}
