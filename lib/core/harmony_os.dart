import 'package:flutter/services.dart';

/// HarmonyOS 3.x / 4.x run the Flutter APK on an Android-compatible layer.
/// Their HTTP stack often "succeeds" a COS PUT without actually storing the object.
class HarmonyOs {
  HarmonyOs._();

  static const _channel = MethodChannel('learnsnap/platform');
  static bool? _isHarmony;
  static String _version = '';

  static Future<void> _load() async {
    if (_isHarmony != null) return;
    try {
      final raw = await _channel.invokeMethod<dynamic>('harmonyInfo');
      if (raw is Map) {
        _isHarmony = raw['isHarmony'] == true;
        _version = '${raw['version'] ?? ''}'.trim();
        return;
      }
    } catch (_) {
      // Channel missing on iOS / tests.
    }
    _isHarmony = false;
    _version = '';
  }

  static Future<bool> isHarmonyOs() async {
    await _load();
    return _isHarmony ?? false;
  }

  /// Client-side COS PUT is unreliable on HarmonyOS 3.x and 4.x.
  static Future<bool> shouldUploadViaServer() async {
    if (!await isHarmonyOs()) return false;
    final major = _majorVersion(_version);
    if (major == null) return true;
    return major <= 4;
  }

  static int? _majorVersion(String version) {
    final match = RegExp(r'^(\d+)').firstMatch(version.trim());
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }
}
