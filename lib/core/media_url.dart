import 'app_config.dart';

/// Helpers for remote media URLs (esp. Tencent COS pre-signed GET).

/// Dart [Uri.parse] treats `+` in the query as space (application/x-www-form-urlencoded).
/// COS signatures often contain raw `+`, which breaks auth and returns XML/HTML —
/// ExoPlayer then fails with UnrecognizedInputFormatException.
String sanitizeMediaUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;
  final q = trimmed.indexOf('?');
  if (q < 0) return trimmed;
  final base = trimmed.substring(0, q + 1);
  final query = trimmed.substring(q + 1).replaceAll('+', '%2B');
  return '$base$query';
}

String resolveMediaUrl(String url) {
  var s = sanitizeMediaUrl(url);
  if (s.isEmpty) return s;
  if (s.startsWith('//')) {
    s = 'https:$s';
  } else if (s.startsWith('/media') ||
      s.startsWith('/static') ||
      s.startsWith('/api')) {
    s = '${AppConfig.siteOrigin}$s';
  }
  return s;
}

Uri parseMediaUri(String url) => Uri.parse(resolveMediaUrl(url));
