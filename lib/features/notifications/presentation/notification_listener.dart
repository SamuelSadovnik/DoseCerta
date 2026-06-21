import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../data/notification_remote_datasource.dart';
import '../domain/app_notification.dart';

final notificationRemoteDatasourceProvider =
    Provider<NotificationRemoteDatasource>((ref) {
      final config = ref.watch(appConfigProvider);
      return NotificationRemoteDatasource(
        baseUrl: config.notificationBaseUrl,
        apiKey: config.notificationApiKey,
      );
    });

class NotificationListenerShell extends ConsumerStatefulWidget {
  const NotificationListenerShell({
    super.key,
    required this.scaffoldMessengerKey,
    required this.child,
  });

  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey;
  final Widget child;

  @override
  ConsumerState<NotificationListenerShell> createState() =>
      _NotificationListenerShellState();
}

class _NotificationListenerShellState
    extends ConsumerState<NotificationListenerShell> {
  Timer? _timer;
  String? _currentUserId;
  bool _initializedForUser = false;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollLatestNotification(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pollLatestNotification();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;

  Future<void> _pollLatestNotification() async {
    if (!mounted || _polling) return;

    final user = ref.read(currentUserProvider);
    if (user == null) {
      _currentUserId = null;
      _initializedForUser = false;
      return;
    }

    if (_currentUserId != user.id) {
      _currentUserId = user.id;
      _initializedForUser = false;
    }

    _polling = true;
    try {
      final latest = await ref
          .read(notificationRemoteDatasourceProvider)
          .latestForUser(user.id);
      if (!mounted || latest == null) return;

      final config = ref.read(appConfigProvider);
      final cache = ref.read(localCacheProvider);
      final cacheKey =
          'dosecerta.${config.appInstance}.last_notification.${user.id}';
      final lastSeenId = cache.readJson<String>(
        cacheKey,
        (raw) => raw.toString(),
      );

      if (!_initializedForUser) {
        _initializedForUser = true;
        if (lastSeenId == null) {
          await cache.writeJson(cacheKey, latest.id);
          return;
        }
      }

      if (lastSeenId == latest.id) return;

      await cache.writeJson(cacheKey, latest.id);
      _showNotification(latest);
    } catch (_) {
      // Polling is best-effort. Connectivity errors should not interrupt the app.
    } finally {
      _polling = false;
    }
  }

  void _showNotification(AppNotification notification) {
    final messenger = widget.scaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          content: Row(
            children: [
              const Icon(Icons.notifications_active, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(notification.body),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
  }
}
