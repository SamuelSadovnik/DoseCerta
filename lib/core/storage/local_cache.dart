import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight key/value cache for non-sensitive data
/// (e.g. last-seen medications list for offline display).
///
/// Sensitive data (auth tokens, passwords) belongs in [AuthTokenStorage].
class LocalCache {
  LocalCache._(this._prefs);

  /// Async factory — `SharedPreferences.getInstance()` is async, so we expose
  /// a `Future<LocalCache>` rather than a sync constructor.
  static Future<LocalCache> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalCache._(prefs);
  }

  final SharedPreferences _prefs;

  Future<void> writeJson(String key, Object value) async {
    await _prefs.setString(key, jsonEncode(value));
  }

  T? readJson<T>(String key, T Function(Object json) decoder) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return decoder(jsonDecode(raw) as Object);
    } catch (_) {
      return null;
    }
  }

  Future<void> remove(String key) => _prefs.remove(key);

  Future<void> clear() => _prefs.clear();
}
