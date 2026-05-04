import 'package:dio/dio.dart';

/// Extracts a user-friendly Portuguese message from any error thrown by
/// the data layer (Dio failures, validation errors from NestJS, etc).
String describeApiError(Object error, {String fallback = 'Erro inesperado.'}) {
  if (error is DioException) {
    final response = error.response;
    if (response != null) {
      final data = response.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (data is Map && data['message'] is List) {
        final list = (data['message'] as List).whereType<String>().toList();
        if (list.isNotEmpty) return list.first;
      }
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'O servidor demorou para responder.';
      case DioExceptionType.connectionError:
        return 'Sem conexão com o servidor.';
      default:
        return fallback;
    }
  }
  return fallback;
}
