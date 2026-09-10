import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/checkin_media.dart';

/// Local copies of submitted check-in photos/videos, keyed by media id or COS object key.
///
/// Files are stored with a real extension (`.jpg` / `.mp4`) so iOS AVPlayer and
/// image decoders can sniff the container. Legacy extension-less names are still read.
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

  static String normalizeExt(String raw) {
    var ext = raw.trim().toLowerCase();
    if (ext.isEmpty) return '';
    if (!ext.startsWith('.')) ext = '.$ext';
    if (ext == '.jpeg') return '.jpg';
    if (ext == '.quicktime') return '.mov';
    return ext;
  }

  /// Infer a file extension for cache storage / playback.
  static String inferExt({
    CheckinMediaKind? kind,
    String contentType = '',
    String filename = '',
    String objectKey = '',
    String sourcePath = '',
  }) {
    for (final candidate in [filename, objectKey, sourcePath]) {
      final ext = normalizeExt(p.extension(candidate));
      if (ext.isNotEmpty) return ext;
    }
    final ct = contentType.trim().toLowerCase();
    if (ct.contains('jpeg') || ct.contains('jpg')) return '.jpg';
    if (ct.contains('png')) return '.png';
    if (ct.contains('webp')) return '.webp';
    if (ct.contains('heic') || ct.contains('heif')) return '.jpg';
    if (ct.contains('mp4') || ct.contains('mpeg')) return '.mp4';
    if (ct.contains('quicktime') || ct.contains('mov')) return '.mov';
    if (ct.startsWith('video/')) return '.mp4';
    if (ct.startsWith('image/')) return '.jpg';
    if (kind == CheckinMediaKind.video) return '.mp4';
    if (kind == CheckinMediaKind.image) return '.jpg';
    return '';
  }

  static bool _baseHasExt(String base, String ext) {
    if (ext.isEmpty) return false;
    return base.toLowerCase().endsWith(ext.toLowerCase());
  }

  static List<String> _names({
    int mediaId = 0,
    String objectKey = '',
    String ext = '',
  }) {
    final normalizedExt = normalizeExt(ext);
    final bases = <String>[];
    if (mediaId > 0) {
      bases.add('i_$mediaId');
    }
    final key = objectKey.trim();
    if (key.isNotEmpty) {
      bases.add(_sanitizeKey(key));
    }
    final names = <String>[];
    for (final base in bases) {
      if (normalizedExt.isNotEmpty && !_baseHasExt(base, normalizedExt)) {
        names.add('$base$normalizedExt');
      }
      names.add(base); // legacy or already includes extension
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
      names.add('t_i_$mediaId.jpg');
      names.add('t_i_$mediaId');
    }
    final key = objectKey.trim();
    if (key.isNotEmpty) {
      final sk = _sanitizeKey(key);
      if (!_baseHasExt(sk, '.jpg')) {
        names.add('t_$sk.jpg');
      }
      names.add('t_$sk');
    }
    final path = localPath.trim();
    if (path.isNotEmpty) {
      final sk = _sanitizeKey(path);
      if (!_baseHasExt(sk, '.jpg')) {
        names.add('t_$sk.jpg');
      }
      names.add('t_$sk');
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

  static Future<File?> _existingFile({
    int mediaId = 0,
    String objectKey = '',
    String ext = '',
  }) async {
    final dir = await _root();
    for (final name in _names(mediaId: mediaId, objectKey: objectKey, ext: ext)) {
      final file = File(p.join(dir.path, name));
      if (await file.exists() && await file.length() > 0) {
        return file;
      }
    }
    // Also probe common media extensions when caller did not specify.
    if (ext.isEmpty && mediaId > 0) {
      for (final probe in ['.mp4', '.mov', '.jpg', '.png', '.webp']) {
        final file = File(p.join(dir.path, 'i_$mediaId$probe'));
        if (await file.exists() && await file.length() > 0) {
          return file;
        }
      }
    }
    return null;
  }

  static Future<String?> pathFor({
    int mediaId = 0,
    String objectKey = '',
    CheckinMediaKind? kind,
    String contentType = '',
    String filename = '',
  }) async {
    final ext = inferExt(
      kind: kind,
      contentType: contentType,
      filename: filename,
      objectKey: objectKey,
    );
    final file = await _existingFile(
      mediaId: mediaId,
      objectKey: objectKey,
      ext: ext,
    );
    return file?.path;
  }

  /// Ensure [path] has a playable extension for iOS AVPlayer (copy if needed).
  static Future<String> ensurePlayablePath(
    String path, {
    required CheckinMediaKind kind,
  }) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return trimmed;
    if (normalizeExt(p.extension(trimmed)).isNotEmpty) return trimmed;
    final ext = kind == CheckinMediaKind.video ? '.mp4' : '.jpg';
    final targetPath = '$trimmed$ext';
    final src = File(trimmed);
    final dst = File(targetPath);
    if (!await src.exists()) return trimmed;
    if (!await dst.exists() || await dst.length() == 0) {
      try {
        await src.copy(targetPath);
      } catch (e) {
        debugPrint('CheckinMediaCache.ensurePlayablePath copy failed: $e');
        return trimmed;
      }
    }
    return targetPath;
  }

  static Future<Uint8List?> readBytes({
    int mediaId = 0,
    String objectKey = '',
    CheckinMediaKind? kind,
  }) async {
    final filePath = await pathFor(
      mediaId: mediaId,
      objectKey: objectKey,
      kind: kind,
    );
    if (filePath == null) return null;
    try {
      return await File(filePath).readAsBytes();
    } catch (_) {
      return null;
    }
  }

  static Future<void> putBytes(
    Uint8List bytes, {
    int mediaId = 0,
    String objectKey = '',
    CheckinMediaKind? kind,
    String contentType = '',
    String filename = '',
  }) async {
    if (bytes.isEmpty) return;
    final ext = inferExt(
      kind: kind,
      contentType: contentType,
      filename: filename,
      objectKey: objectKey,
    );
    final names = _names(mediaId: mediaId, objectKey: objectKey, ext: ext);
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
    CheckinMediaKind? kind,
    String contentType = '',
    String filename = '',
  }) async {
    final src = File(sourcePath);
    if (!await src.exists()) return;
    final ext = inferExt(
      kind: kind,
      contentType: contentType,
      filename: filename.isNotEmpty ? filename : sourcePath,
      objectKey: objectKey,
      sourcePath: sourcePath,
    );
    final names = _names(mediaId: mediaId, objectKey: objectKey, ext: ext);
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
      await putBytes(
        item.bytes!,
        mediaId: id,
        objectKey: key,
        kind: item.kind,
        contentType: item.contentType ?? '',
        filename: item.filename,
      );
      return;
    }
    final path = item.filePath?.trim() ?? '';
    if (path.isNotEmpty) {
      await putFile(
        path,
        mediaId: id,
        objectKey: key,
        kind: item.kind,
        contentType: item.contentType ?? '',
        filename: item.filename,
      );
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
        kind: item.kind,
        contentType: item.contentType ?? '',
        filename: item.filename,
      );
      if (path == null) {
        out.add(item);
        continue;
      }
      final playable = item.isVideo
          ? await ensurePlayablePath(path, kind: CheckinMediaKind.video)
          : path;
      out.add(
        CheckinMediaItem(
          kind: item.kind,
          filename: item.filename,
          bytes: item.bytes,
          filePath: playable,
          duration: item.duration,
          fileSizeBytes: item.fileSizeBytes ?? await File(playable).length(),
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
