import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'local_cache.dart';

/// Persists the JWT issued by the backend.
abstract class AuthTokenStorage {
  const AuthTokenStorage();

  /// Production factory backed by platform secure storage.
  factory AuthTokenStorage.secure() = _SecureAuthTokenStorage;

  /// Desktop/dev fallback backed by SharedPreferences through [LocalCache].
  factory AuthTokenStorage.localCache(LocalCache cache, {String namespace}) =
      _LocalAuthTokenStorage;

  /// Test/in-memory factory.
  factory AuthTokenStorage.inMemory() = _InMemoryAuthTokenStorage;

  Future<String?> read();

  Future<void> write(String token);

  Future<void> clear();
}

class _SecureAuthTokenStorage extends AuthTokenStorage {
  _SecureAuthTokenStorage() : _storage = const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _key = 'dosecerta.access_token';

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

class _LocalAuthTokenStorage extends AuthTokenStorage {
  _LocalAuthTokenStorage(this._cache, {String namespace = 'default'})
    : _key = 'dosecerta.$namespace.access_token';

  final LocalCache _cache;
  final String _key;

  @override
  Future<String?> read() async =>
      _cache.readJson<String>(_key, (raw) => raw.toString());

  @override
  Future<void> write(String token) => _cache.writeJson(_key, token);

  @override
  Future<void> clear() => _cache.remove(_key);
}

class _InMemoryAuthTokenStorage extends AuthTokenStorage {
  String? _value;

  @override
  Future<String?> read() async => _value;

  @override
  Future<void> write(String token) async => _value = token;

  @override
  Future<void> clear() async => _value = null;
}
