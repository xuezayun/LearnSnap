import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/checkin_media.dart';

const _platform = MethodChannel('learnsnap/platform');

/// JPEG SOI.
bool isJpegBytes(Uint8List bytes) {
  return bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF;
}

/// HEIC / HEIF (`ftyp` brand heic / heif / mif1 / msf1).
bool isHeicBytes(Uint8List bytes) {
  if (bytes.length < 12) return false;
  if (bytes[4] != 0x66 || bytes[5] != 0x74 || bytes[6] != 0x79 || bytes[7] != 0x70) {
    return false;
  }
  final brand = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
  return brand == 'heic' ||
      brand == 'heix' ||
      brand == 'heif' ||
      brand == 'heis' ||
      brand == 'mif1' ||
      brand == 'msf1';
}

String safeImageFilename(String original) {
  final ext = p.extension(original).toLowerCase();
  final now = DateTime.now().millisecondsSinceEpoch;
  if (ext == '.png' || ext == '.webp' || ext == '.gif') {
    return 'photo_$now$ext';
  }
  return 'photo_$now.jpg';
}

String safeVideoFilename() =>
    'video_${DateTime.now().millisecondsSinceEpoch}.mp4';

bool cosResponseIndicatesError(String body) {
  final trimmed = body.trim();
  if (trimmed.isEmpty) return false;
  final lower = trimmed.toLowerCase();
  return lower.contains('<error') ||
      lower.contains('<code>nosuchkey</code>') ||
      lower.contains('signaturedoesnotmatch') ||
      lower.contains('accessdenied') ||
      lower.contains('notimplemented');
}

Future<Uint8List> _toJpegNative(Uint8List bytes) async {
  try {
    final raw = await _platform.invokeMethod<dynamic>('toJpeg', {
      'bytes': bytes,
      'quality': 90,
      'maxWidth': 2400,
    });
    if (raw is Uint8List && raw.isNotEmpty) return raw;
    if (raw is List<int> && raw.isNotEmpty) return Uint8List.fromList(raw);
  } catch (_) {
    // Tests / iOS / older APKs without the method.
  }
  return bytes;
}

/// HarmonyOS camera often yields HEIC (named `.jpg`) or a cache file that vanishes.
Future<CheckinMediaItem> prepareCheckinImage({
  required Uint8List bytes,
  required String filename,
}) async {
  if (bytes.isEmpty) {
    throw Exception('照片是空的，请重新拍一张');
  }
  var out = bytes;
  var name = safeImageFilename(filename);
  if (!isJpegBytes(out) || isHeicBytes(out)) {
    out = await _toJpegNative(out);
    name = safeImageFilename(name);
  }
  if (out.isEmpty) {
    throw Exception('照片处理失败，请重新拍一张');
  }
  return CheckinMediaItem.image(bytes: out, filename: name);
}

Future<Directory> _captureDir() async {
  final root = await getApplicationSupportDirectory();
  final dir = Directory(p.join(root.path, 'checkin_capture'));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Copy camera/gallery videos out of HarmonyOS cache / content URIs.
Future<String> persistLocalVideo(String sourcePath) async {
  final src = File(sourcePath);
  if (!await src.exists()) {
    throw Exception('视频文件不存在，请重新录制或选择');
  }
  final length = await src.length();
  if (length <= 0) {
    throw Exception('视频文件为空，请重新录制或选择');
  }
  final dir = await _captureDir();
  final dest = File(p.join(dir.path, safeVideoFilename()));
  if (p.normalize(src.path) == p.normalize(dest.path)) {
    return dest.path;
  }
  await src.copy(dest.path);
  return dest.path;
}
