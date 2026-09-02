import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/checkin_media.dart';

/// Local copies of submitted check-in photos/videos, keyed by media id or COS object key.
class CheckinMediaCache {
  CheckinMediaCache._();

  static const _folder = 'checkin_media';
  static const _maxFiles = 80;

  static Future<Directory> _root() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, _folder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static String _sanitizeKey(String objectKey) {
    final buf = StringBuffer('k_');
    for (final rune in objectKey.runes) {
      final c = String.fromCharCode(rune);
      final ok = (c.compareTo('a') >= 0 && c.compareTo('z') <= 0) ||
          (c.compareTo('A') >= 0 && c.compareTo('Z') <= 0) ||
          (c.compareTo('0') >= 0 && c.compareTo('9') <= 0) ||
          c == '.' ||
          c == '-' ||
          c == '_';
      buf.write(ok ? c : '_');
    }
    var name = buf.toString();
    if (name.length > 120) {
      name = 'k_${name.substring(name.length - 116)}';
    }
    return name;
  }

  static List<String> _names({int mediaId = 0, String objectKey = ''}) {
    final names = <String>[];
    if (mediaId > 0) {
      names.add('i_$mediaId');
    }
    final key = objectKey.trim();
    if (key.isNotEmpty) {
      names.add(_sanitizeKey(key));
    }
    return names;
  }

  static List<String> _thumbNames({
    int mediaId = 0,
    String objectKey = '',
    String localPath = '',
  }) {
    final names = <String>[];
    if (mediaId > 0) {
      names.add('t_i_$mediaId');
    }
    final key = objectKey.trim();
    if (key.isNotEmpty) {
      names.add('t_${_sanitizeKey(key)}');
    }
    final path = localPath.trim();
    if (path.isNotEmpty) {
      names.add('t_${_sanitizeKey(path)}');
    }
    return names;
  }

  static Future<File?> _existingThumbFile({
    int mediaId = 0,
    String objectKey = '',
    String localPath = '',
  }) async {
    final dir = await _root();
    for (final name in _thumbNames(
      mediaId: mediaId,
      objectKey: objectKey,
      localPath: localPath,
    )) {
      final file = File(p.join(dir.path, name));
      if (await file.exists() && await file.length() > 0) {
        return file;
      }
    }
    return null;
  }

  static Future<String?> thumbPathFor({
    int mediaId = 0,
    String objectKey = '',
    String localPath = '',
  }) async {
    final file = await _existingThumbFile(
      mediaId: mediaId,
      objectKey: objectKey,
      localPath: localPath,
    );
    return file?.path;
  }

  static Future<void> putThumbBytes(
    Uint8List bytes, {
    int mediaId = 0,
    String objectKey = '',
    String localPath = '',
  }) async {
    if (bytes.isEmpty) return;
    final names = _thumbNames(
      mediaId: mediaId,
      objectKey: objectKey,
      localPath: localPath,
    );
    if (names.isEmpty) return;
    final dir = await _root();
    await _prune(dir);
    final primary = File(p.join(dir.path, names.first));
    await primary.writeAsBytes(bytes, flush: true);
    for (var i = 1; i < names.length; i++) {
      final alias = File(p.join(dir.path, names[i]));
      if (alias.path == primary.path) continue;
      try {
        await primary.copy(alias.path);
      } catch (_) {
        // alias optional
      }
    }
  }

  static Future<File?> _existingFile({int mediaId = 0, String objectKey = ''}) async {
    final dir = await _root();
    for (final name in _names(mediaId: mediaId, objectKey: objectKey)) {
      final file = File(p.join(dir.path, name));
      if (await file.exists() && await file.length() > 0) {
        return file;
      }
    }
    return null;
  }

  static Future<String?> pathFor({int mediaId = 0, String objectKey = ''}) async {
    final file = await _existingFile(mediaId: mediaId, objectKey: objectKey);
    return file?.path;
  }

  static Future<Uint8List?> readBytes({int mediaId = 0, String objectKey = ''}) async {
    final file = await _existingFile(mediaId: mediaId, objectKey: objectKey);
    if (file == null) return null;
    try {
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  static Future<void> putBytes(
    Uint8List bytes, {
    int mediaId = 0,
    String objectKey = '',
  }) async {
    if (bytes.isEmpty) return;
    final names = _names(mediaId: mediaId, objectKey: objectKey);
    if (names.isEmpty) return;
    final dir = await _root();
    await _prune(dir);
    final primary = File(p.join(dir.path, names.first));
    await primary.writeAsBytes(bytes, flush: true);
    for (var i = 1; i < names.length; i++) {
      final alias = File(p.join(dir.path, names[i]));
      if (alias.path == primary.path) continue;
      try {
        if (await alias.exists()) {
          await alias.delete();
        }
        await primary.copy(alias.path);
      } catch (_) {
        // alias is optional
      }
    }
  }

  static Future<void> putFile(
    String sourcePath, {
    int mediaId = 0,
    String objectKey = '',
  }) async {
    final src = File(sourcePath);
    if (!await src.exists()) return;
    final names = _names(mediaId: mediaId, objectKey: objectKey);
    if (names.isEmpty) return;
    final dir = await _root();
    await _prune(dir);
    final primary = File(p.join(dir.path, names.first));
    if (p.normalize(src.path) != p.normalize(primary.path)) {
      await src.copy(primary.path);
    }
    for (var i = 1; i < names.length; i++) {
      final alias = File(p.join(dir.path, names[i]));
      if (alias.path == primary.path) continue;
      try {
        await primary.copy(alias.path);
      } catch (_) {
        // alias is optional
      }
    }
  }

  static Future<void> putItem(CheckinMediaItem item, {String objectKey = ''}) async {
    final key = objectKey.trim().isNotEmpty
        ? objectKey
        : (item.objectKey ?? '');
    final id = item.existingMediaId ?? 0;
    if (item.bytes != null && item.bytes!.isNotEmpty) {
      await putBytes(item.bytes!, mediaId: id, objectKey: key);
      return;
    }
    final path = item.filePath?.trim() ?? '';
    if (path.isNotEmpty) {
      await putFile(path, mediaId: id, objectKey: key);
    }
  }

  static Future<List<CheckinMediaItem>> hydrate(List<CheckinMediaItem> items) async {
    final out = <CheckinMediaItem>[];
    for (final item in items) {
      if ((item.filePath != null && item.filePath!.trim().isNotEmpty) ||
          (item.bytes != null && item.bytes!.isNotEmpty)) {
        out.add(item);
        continue;
      }
      final path = await pathFor(
        mediaId: item.existingMediaId ?? 0,
        objectKey: item.objectKey ?? '',
      );
      if (path == null) {
        out.add(item);
        continue;
      }
      out.add(
        CheckinMediaItem(
          kind: item.kind,
          filename: item.filename,
          bytes: item.bytes,
          filePath: path,
          duration: item.duration,
          fileSizeBytes: item.fileSizeBytes ?? await File(path).length(),
          remoteUrl: item.remoteUrl,
          objectKey: item.objectKey,
          contentType: item.contentType,
          existingMediaId: item.existingMediaId,
        ),
      );
    }
    return out;
  }

  static Future<void> clear() async {
    try {
      final support = await getApplicationSupportDirectory();
      final dir = Directory(p.join(support.path, _folder));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // best-effort
    }
  }

  static Future<void> _prune(Directory dir) async {
    try {
      final files = await dir
          .list()
          .where((e) => e is File)
          .cast<File>()
          .toList();
      if (files.length < _maxFiles) return;
      files.sort((a, b) {
        final am = a.statSync().modified;
        final bm = b.statSync().modified;
        return am.compareTo(bm);
      });
      final extra = files.length - (_maxFiles - 4);
      for (var i = 0; i < extra && i < files.length; i++) {
        try {
          await files[i].delete();
        } catch (_) {
          // ignore locked files
        }
      }
    } catch (_) {
      // ignore
    }
  }
}
