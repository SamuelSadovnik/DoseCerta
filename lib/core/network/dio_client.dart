import 'package:dio/dio.dart';

import '../storage/auth_token_storage.dart';

/// Builds and configures the [Dio] HTTP client used across the app.
///
/// Wraps:
///   - base URL pointing at the gateway
///   - auth interceptor that attaches the Bearer token automatically
///   - generous-but-finite timeouts so a dead backend doesn't hang the UI
class DioClient {
  DioClient._(this.dio);

  /// Factory — produces a fully configured [Dio] for the given gateway URL.
  factory DioClient.forBaseUrl({
    required String baseUrl,
    required AuthTokenStorage tokenStorage,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(_AuthInterceptor(tokenStorage));

    return DioClient._(dio);
  }

  final Dio dio;
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokens);
  final AuthTokenStorage _tokens;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokens.read();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
