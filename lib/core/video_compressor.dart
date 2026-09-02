import 'dart:io';
import 'dart:typed_data';

import 'package:video_compress/video_compress.dart';

import '../models/checkin_media.dart';

/// Already small enough for check-in; skip a full re-encode.
const int _checkinCompressSkipMaxBytes = 12 * 1024 * 1024;
const int _checkinCompressFrameRate = 24;

class CompressedVideo {
  const CompressedVideo({required this.path, required this.bytes});

  final String path;
  final int bytes;
}

String formatFileSize(int bytes) {
  if (bytes < 0) bytes = 0;
  if (bytes < 1024) return '$bytes B';
  final kb = bytes / 1024;
  if (kb < 1024) {
    final value = kb >= 100 ? kb.round().toString() : kb.toStringAsFixed(kb >= 10 ? 0 : 1);
    return '$value KB';
  }
  final mb = kb / 1024;
  final value = mb >= 100 ? mb.round().toString() : mb.toStringAsFixed(mb >= 10 ? 1 : 2);
  return '$value MB';
}

Future<CompressedVideo?> _runCompress(
  String inputPath, {
  VideoQuality quality = VideoQuality.LowQuality,
  int frameRate = _checkinCompressFrameRate,
}) async {
  try {
    final info = await VideoCompress.compressVideo(
      inputPath,
      quality: quality,
      deleteOrigin: false,
      includeAudio: true,
      frameRate: frameRate,
    );
    final path = info?.path?.trim();
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.length();
    if (bytes <= 0) return null;
    return CompressedVideo(path: path, bytes: bytes);
  } catch (_) {
    return null;
  }
}

CompressedVideo _fallbackOrThrow(String inputPath, int originalBytes) {
  if (originalBytes > checkinMaxVideoBytes) {
    throw Exception('压缩后仍超过 50MB，请缩短录制时长或降低画质');
  }
  return CompressedVideo(path: inputPath, bytes: originalBytes);
}

/// Compress a local check-in video (one LowQuality @ 24fps pass).
/// Skips re-encode when the source is already under 12MB.
/// Falls back to the original when compress fails or does not shrink.
Future<CompressedVideo> compressCheckinVideo(String inputPath) async {
  final input = File(inputPath);
  if (!await input.exists()) {
    throw Exception('视频文件不存在');
  }
  final originalBytes = await input.length();
  if (originalBytes <= 0) {
    throw Exception('视频文件为空');
  }
  if (originalBytes <= _checkinCompressSkipMaxBytes) {
    return CompressedVideo(path: inputPath, bytes: originalBytes);
  }

  final first = await _runCompress(inputPath);
  if (first == null || first.bytes >= originalBytes) {
    return _fallbackOrThrow(inputPath, originalBytes);
  }
  if (first.bytes > checkinMaxVideoBytes) {
    throw Exception('压缩后仍超过 50MB，请缩短录制时长');
  }
  return first;
}

/// First-frame JPEG for a local video; null if extraction fails.
Future<Uint8List?> extractVideoThumbnail(String path) async {
  final file = File(path);
  if (!await file.exists()) return null;
  try {
    final bytes = await VideoCompress.getByteThumbnail(
      path,
      quality: 60,
      position: 0,
    );
    if (bytes == null || bytes.isEmpty) return null;
    return bytes;
  } catch (_) {
    return null;
  }
}
