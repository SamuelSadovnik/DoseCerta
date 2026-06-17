import '../../../../core/enums/account_type.dart';
import '../../../../core/storage/auth_token_storage.dart';
import '../../../../core/storage/local_cache.dart';
import '../../domain/entities/auth_result.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/auth_response_dto.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remote,
    this._tokens,
    this._cache, {
    this.namespace = 'default',
  });

  final AuthRemoteDatasource _remote;
  final AuthTokenStorage _tokens;
  final LocalCache _cache;
  final String namespace;

  static String currentUserCacheKey(String namespace) =>
      'dosecerta.$namespace.current_user';

  @override
  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    final dto = await _remote.login(identifier: identifier, password: password);
    return _persistAndMap(dto);
  }

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    required AccountType accountType,
    bool acceptedTerms = false,
  }) async {
    final dto = await _remote.register(
      name: name,
      email: email,
      password: password,
      accountType: accountType,
      acceptedTerms: acceptedTerms,
    );
    return _persistAndMap(dto);
  }

  @override
  Future<AuthResult> updateProfile({
    String? name,
    String? email,
    String? currentPassword,
    String? newPassword,
    Map<String, String>? additionalInfo,
    List<Map<String, String>>? emergencyContacts,
  }) async {
    final dto = await _remote.updateProfile(
      name: name,
      email: email,
      currentPassword: currentPassword,
      newPassword: newPassword,
      additionalInfo: additionalInfo,
      emergencyContacts: emergencyContacts,
    );
    return _persistAndMap(dto);
  }

  @override
  Future<AuthResult> getProfile() async {
    final dto = await _remote.getProfile();
    return _persistAndMap(dto);
  }

  @override
  Future<void> logout() async {
    await _tokens.clear();
    await _cache.remove(currentUserCacheKey(namespace));
  }

  Future<AuthResult> _persistAndMap(AuthResponseDto dto) async {
    await _tokens.write(dto.accessToken);
    await _cache.writeJson(currentUserCacheKey(namespace), {
      'id': dto.user.id,
      'name': dto.user.name,
      'email': dto.user.email,
      'accountType': dto.user.accountType.name,
      'additionalInfo': dto.user.additionalInfo,
      'emergencyContacts': dto.user.emergencyContacts,
    });
    return AuthResult(accessToken: dto.accessToken, user: dto.user.toEntity());
  }

  static User? readCurrentUser(
    LocalCache cache, {
    String namespace = 'default',
  }) {
    return cache.readJson<User>(currentUserCacheKey(namespace), (raw) {
      final json = raw as Map<String, dynamic>;
      return User(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        additionalInfo: (json['additionalInfo'] as Map?)?.map(
          (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
        ),
        emergencyContacts:
            (json['emergencyContacts'] as List?)
                ?.whereType<Map>()
                .map(
                  (item) => item.map(
                    (key, value) =>
                        MapEntry(key.toString(), value?.toString() ?? ''),
                  ),
                )
                .toList() ??
            const [],
        accountType: AccountType.values.firstWhere(
          (type) => type.name == json['accountType'],
          orElse: () => AccountType.personal,
        ),
      );
    });
  }
}
