import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class PageCachePolicy {
  PageCachePolicy._();

  static const Duration home = Duration(seconds: 45);
  static const Duration mainTabs = Duration(minutes: 5);
  static const Duration referenceData = Duration(minutes: 10);
}

extension CacheFor on Ref {
  void cacheFor(Duration duration) {
    final link = keepAlive();
    final timer = Timer(duration, link.close);
    onDispose(timer.cancel);
  }
}
