import 'package:flutter/foundation.dart';

/// Centralized runtime config. Single source of truth for env-dependent values.
///
/// `useMockData` flips the whole app between live HTTP and offline mocks —
/// useful for demo/dev without backend up. Build with:
///   flutter run --dart-define=USE_MOCK=true
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
class AppConfig {
  const AppConfig._({required this.apiBaseUrl, required this.useMockData});

  /// Factory that reads `--dart-define` flags at compile time.
  factory AppConfig.fromEnv() {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    return AppConfig._(
      apiBaseUrl: apiBaseUrl.isNotEmpty ? apiBaseUrl : _defaultApiBaseUrl,
      useMockData: const bool.fromEnvironment('USE_MOCK', defaultValue: false),
    );
  }

  final String apiBaseUrl;
  final bool useMockData;
}

const String _defaultApiBaseUrl = kIsWeb
    ? 'http://localhost:3000/api'
    : 'http://10.0.2.2:3000/api';
