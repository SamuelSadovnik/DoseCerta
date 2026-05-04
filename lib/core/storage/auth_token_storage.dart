import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Securely persists the JWT issued by the backend.
///
/// Uses platform secure storage (Keystore on Android, Keychain on iOS).
/// Single responsibility: read/write/clear the token.
class AuthTokenStorage {
  AuthTokenStorage._(this._storage);

  /// Default factory — production secure storage backed by the platform.
  factory AuthTokenStorage.secure() =>
      AuthTokenStorage._(const FlutterSecureStorage());

  /// Test/in-memory factory — does not touch the platform.
  factory AuthTokenStorage.inMemory() => _InMemoryAuthTokenStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'dosecerta.access_token';

  Future<String?> read() => _storage.read(key: _key);

  Future<void> write(String token) => _storage.write(key: _key, value: token);

  Future<void> clear() => _storage.delete(key: _key);
}

class _InMemoryAuthTokenStorage extends AuthTokenStorage {
  _InMemoryAuthTokenStorage() : super._(const FlutterSecureStorage());
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String token) async => _value = token;

  @override
  Future<void> clear() async => _value = null;
}
