import 'package:dio/dio.dart';

import '../../../../core/enums/account_type.dart';
import '../models/auth_response_dto.dart';
import '../models/user_dto.dart';

/// Remote datasource for authentication.
///
/// Uses Factory pattern: callers get an instance via [AuthRemoteDatasource.http]
/// or [AuthRemoteDatasource.mock] without knowing the concrete class.
abstract class AuthRemoteDatasource {
  /// Production factory — talks HTTP to the gateway.
  factory AuthRemoteDatasource.http(Dio dio) = _HttpAuthRemoteDatasource;

  /// Offline factory — returns canned responses for dev/demo.
  factory AuthRemoteDatasource.mock() = _MockAuthRemoteDatasource;

  Future<AuthResponseDto> login({
    required String identifier,
    required String password,
  });

  Future<AuthResponseDto> register({
    required String name,
    required String email,
    required String password,
    required AccountType accountType,
    bool acceptedTerms = false,
  });

  Future<AuthResponseDto> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
    String? newPassword,
    Map<String, String>? additionalInfo,
    List<Map<String, String>>? emergencyContacts,
  });

  Future<AuthResponseDto> getProfile();
}

class _HttpAuthRemoteDatasource implements AuthRemoteDatasource {
  _HttpAuthRemoteDatasource(this._dio);
  final Dio _dio;

  @override
  Future<AuthResponseDto> login({
    required String identifier,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'identifier': identifier, 'password': password},
    );
    return AuthResponseDto.fromJson(res.data!);
  }

  @override
  Future<AuthResponseDto> register({
    required String name,
    required String email,
    required String password,
    required AccountType accountType,
    bool acceptedTerms = false,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'name': name,
        'email': email,
        'password': password,
        'accountType': accountType.name,
        'acceptedTerms': acceptedTerms,
      },
    );
    return AuthResponseDto.fromJson(res.data!);
  }

  @override
  Future<AuthResponseDto> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
    String? newPassword,
    Map<String, String>? additionalInfo,
    List<Map<String, String>>? emergencyContacts,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (currentPassword != null) data['currentPassword'] = currentPassword;
    if (newPassword != null) data['newPassword'] = newPassword;
    if (additionalInfo != null) data['additionalInfo'] = additionalInfo;
    if (emergencyContacts != null) {
      data['emergencyContacts'] = emergencyContacts;
    }

    final res = await _dio.patch<Map<String, dynamic>>('/auth/me', data: data);
    return AuthResponseDto.fromJson(res.data!);
  }

  @override
  Future<AuthResponseDto> getProfile() async {
    final res = await _dio.get<Map<String, dynamic>>('/auth/me');
    return AuthResponseDto.fromJson(res.data!);
  }
}

class _MockAuthRemoteDatasource implements AuthRemoteDatasource {
  static Map<String, String>? _additionalInfo;
  static List<Map<String, String>> _emergencyContacts = const [];

  @override
  Future<AuthResponseDto> login({
    required String identifier,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return AuthResponseDto(
      accessToken: 'mock-token',
      user: const UserDto(
        id: 'user-1',
        name: 'João Silva',
        email: 'joao.silva@email.com',
        accountType: AccountType.personal,
      ),
    );
  }

  @override
  Future<AuthResponseDto> register({
    required String name,
    required String email,
    required String password,
    required AccountType accountType,
    bool acceptedTerms = false,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return AuthResponseDto(
      accessToken: 'mock-token',
      user: UserDto(
        id: 'user-${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        email: email,
        accountType: accountType,
      ),
    );
  }

  @override
  Future<AuthResponseDto> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
    String? newPassword,
    Map<String, String>? additionalInfo,
    List<Map<String, String>>? emergencyContacts,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (additionalInfo != null) _additionalInfo = additionalInfo;
    if (emergencyContacts != null) _emergencyContacts = emergencyContacts;
    return AuthResponseDto(
      accessToken: 'mock-token',
      user: UserDto(
        id: 'user-1',
        name: name?.isNotEmpty == true ? name! : 'João Silva',
        email: email?.isNotEmpty == true ? email! : 'joao.silva@email.com',
        accountType: AccountType.personal,
        additionalInfo: additionalInfo ?? _additionalInfo,
        emergencyContacts: emergencyContacts ?? _emergencyContacts,
      ),
    );
  }

  @override
  Future<AuthResponseDto> getProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return AuthResponseDto(
      accessToken: 'mock-token',
      user: UserDto(
        id: 'user-1',
        name: 'João Silva',
        email: 'joao.silva@email.com',
        accountType: AccountType.personal,
        additionalInfo: _additionalInfo,
        emergencyContacts: _emergencyContacts,
      ),
    );
  }
}
