class AppNotification {
  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    required this.sentAt,
  });

  final String id;
  final String userId;
  final String type;
  final String title;
  final String body;
  final DateTime sentAt;
}
