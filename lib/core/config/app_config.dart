import 'package:flutter/foundation.dart';

/// Centralized runtime config. Single source of truth for env-dependent values.
///
/// `useMockData` flips the whole app between live HTTP and offline mocks —
/// useful for demo/dev without backend up. Build with:
///   flutter run --dart-define=USE_MOCK=true
///   flutter run --dart-define=API_BASE_URL=http://localhost:3000/api
class AppConfig {
  const AppConfig._({
    required this.apiBaseUrl,
    required this.notificationBaseUrl,
    required this.notificationApiKey,
    required this.appInstance,
    required this.useMockData,
  });

  /// Factory that reads `--dart-define` flags at compile time.
  factory AppConfig.fromEnv() {
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
    const notificationBaseUrl = String.fromEnvironment('NOTIFICATION_BASE_URL');
    const notificationApiKey = String.fromEnvironment('NOTIFICATION_API_KEY');
    const appInstance = String.fromEnvironment('APP_INSTANCE');
    return AppConfig._(
      apiBaseUrl: apiBaseUrl.isNotEmpty ? apiBaseUrl : _defaultApiBaseUrl,
      notificationBaseUrl: notificationBaseUrl.isNotEmpty
          ? notificationBaseUrl
          : _defaultNotificationBaseUrl,
      notificationApiKey: notificationApiKey.isNotEmpty
          ? notificationApiKey
          : 'dosecerta-internal-key-notification',
      appInstance: appInstance.isNotEmpty ? appInstance : 'default',
      useMockData: const bool.fromEnvironment('USE_MOCK', defaultValue: false),
    );
  }

  final String apiBaseUrl;
  final String notificationBaseUrl;
  final String notificationApiKey;
  final String appInstance;
  final bool useMockData;
}

String get _defaultApiBaseUrl {
  if (kIsWeb) return 'http://localhost:3000/api';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000/api';
  }
  return 'http://localhost:3000/api';
}

String get _defaultNotificationBaseUrl {
  if (kIsWeb) return 'http://localhost:3004/api/v1';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3004/api/v1';
  }
  return 'http://localhost:3004/api/v1';
}
