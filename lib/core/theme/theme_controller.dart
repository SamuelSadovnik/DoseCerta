import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../storage/local_cache.dart';

const _themeModeCacheKey = 'dosecerta.theme_mode';

final themeModeProvider = StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    return ThemeModeController(ref.watch(localCacheProvider));
  },
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._cache) : super(_readMode(_cache));

  final LocalCache _cache;

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _cache.writeJson(_themeModeCacheKey, mode.name);
  }

  static ThemeMode _readMode(LocalCache cache) {
    final stored = cache.readJson<String>(
      _themeModeCacheKey,
      (json) => json as String,
    );
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.light,
    );
  }
}
