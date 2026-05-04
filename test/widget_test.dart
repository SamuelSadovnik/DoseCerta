import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dosecerta/core/providers/app_providers.dart';
import 'package:dosecerta/core/storage/local_cache.dart';
import 'package:dosecerta/main.dart';

void main() {
  testWidgets('shows login screen on startup', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final localCache = await LocalCache.create();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localCacheProvider.overrideWithValue(localCache)],
        child: const DoseCertaApp(),
      ),
    );

    expect(find.text('E-mail ou CPF'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}
