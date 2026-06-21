import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/providers/app_providers.dart';
import 'core/routing/app_routes.dart';
import 'core/storage/local_cache.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/notifications/presentation/notification_listener.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');

  final localCache = await LocalCache.create();

  runApp(
    ProviderScope(
      overrides: [localCacheProvider.overrideWithValue(localCache)],
      child: const DoseCertaApp(),
    ),
  );
}

class DoseCertaApp extends ConsumerWidget {
  const DoseCertaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'DoseCerta',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR')],
      locale: const Locale('pt', 'BR'),
      builder: (context, child) => NotificationListenerShell(
        scaffoldMessengerKey: scaffoldMessengerKey,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
