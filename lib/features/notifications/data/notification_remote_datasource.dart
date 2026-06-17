import 'package:dio/dio.dart';

import '../domain/app_notification.dart';

class NotificationRemoteDatasource {
  NotificationRemoteDatasource({
    required String baseUrl,
    required String apiKey,
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 5),
           receiveTimeout: const Duration(seconds: 8),
           headers: {'Content-Type': 'application/json', 'x-api-key': apiKey},
         ),
       );

  final Dio _dio;

  Future<AppNotification?> latestForUser(String userId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/notifications/$userId',
      queryParameters: {'_page': 1, '_size': 1},
    );
    final data = response.data?['data'];
    if (data is! List || data.isEmpty || data.first is! Map) return null;

    final json = Map<String, dynamic>.from(data.first as Map);
    return AppNotification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      sentAt:
          DateTime.tryParse(json['sentAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
