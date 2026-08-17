import 'dart:io';

import 'package:video_compress/video_compress.dart';

import '../models/checkin_media.dart';

const int _checkinCompressSoftMaxBytes = 3 * 1024 * 1024 ~/ 2; // 1.5 MB
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

/// Compress a local check-in video (LowQuality @ 24fps).
/// Retries once when still above soft max; falls back to original when needed.
Future<CompressedVideo> compressCheckinVideo(String inputPath) async {
  final input = File(inputPath);
  if (!await input.exists()) {
    throw Exception('视频文件不存在');
  }
  final originalBytes = await input.length();
  if (originalBytes <= 0) {
    throw Exception('视频文件为空');
  }

  final first = await _runCompress(inputPath);
  if (first == null || first.bytes >= originalBytes) {
    return _fallbackOrThrow(inputPath, originalBytes);
  }

  var best = first;
  if (best.bytes > _checkinCompressSoftMaxBytes) {
    final second = await _runCompress(best.path);
    if (second != null &&
        second.bytes > 0 &&
        second.bytes < best.bytes) {
      best = second;
    }
  }

  if (best.bytes > checkinMaxVideoBytes) {
    throw Exception('压缩后仍超过 50MB，请缩短录制时长');
  }

  return best;
}
