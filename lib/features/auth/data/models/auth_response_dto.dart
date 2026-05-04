import 'user_dto.dart';

/// Wraps `{accessToken, user}` as returned by `POST /auth/login`
/// and `POST /auth/register`.
class AuthResponseDto {
  const AuthResponseDto({required this.accessToken, required this.user});

  factory AuthResponseDto.fromJson(Map<String, dynamic> json) {
    return AuthResponseDto(
      accessToken: json['accessToken'] as String,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  final String accessToken;
  final UserDto user;
}
