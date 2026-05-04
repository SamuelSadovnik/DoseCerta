import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../network/dio_client.dart';
import '../storage/auth_token_storage.dart';
import '../storage/local_cache.dart';

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnv());

final authTokenStorageProvider = Provider<AuthTokenStorage>(
  (ref) => AuthTokenStorage.secure(),
);

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final tokens = ref.watch(authTokenStorageProvider);
  return DioClient.forBaseUrl(
    baseUrl: config.apiBaseUrl,
    tokenStorage: tokens,
  ).dio;
});

/// Async — initialized once at app startup via `overrideWithValue`.
final localCacheProvider = Provider<LocalCache>(
  (ref) => throw UnimplementedError(
    'localCacheProvider must be overridden in main() with the awaited instance',
  ),
);
