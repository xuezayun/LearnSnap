import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:path_provider/path_provider.dart';

/// Clears in-memory and on-disk local caches after logout.
Future<void> clearLocalCache() async {
  PaintingBinding.instance.imageCache.clear();
  PaintingBinding.instance.imageCache.clearLiveImages();

  await Future.wait([
    _clearDirectory(() => getTemporaryDirectory()),
    _clearDirectory(() => getApplicationCacheDirectory()),
  ]);
}

Future<void> _clearDirectory(Future<Directory> Function() resolve) async {
  try {
    final dir = await resolve();
    if (!await dir.exists()) return;
    await for (final entity in dir.list(followLinks: false)) {
      try {
        await entity.delete(recursive: true);
      } catch (_) {
        // Best-effort: ignore locked / in-use files.
      }
    }
  } catch (_) {
    // Best-effort on platforms without a cache directory.
  }
}
