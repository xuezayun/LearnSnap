import 'dart:typed_data';

enum CheckinMediaKind { image, video }

class CheckinMediaItem {
  const CheckinMediaItem({
    required this.kind,
    required this.filename,
    this.bytes,
    this.filePath,
    this.duration,
  });

  final CheckinMediaKind kind;
  final String filename;
  final Uint8List? bytes;
  final String? filePath;
  final Duration? duration;

  bool get isImage => kind == CheckinMediaKind.image;
  bool get isVideo => kind == CheckinMediaKind.video;

  factory CheckinMediaItem.image({
    required Uint8List bytes,
    required String filename,
  }) {
    return CheckinMediaItem(
      kind: CheckinMediaKind.image,
      filename: filename,
      bytes: bytes,
    );
  }

  factory CheckinMediaItem.video({
    required String filePath,
    required String filename,
    Duration? duration,
  }) {
    return CheckinMediaItem(
      kind: CheckinMediaKind.video,
      filename: filename,
      filePath: filePath,
      duration: duration,
    );
  }
}

const checkinMaxVideoDuration = Duration(seconds: 120);
const checkinMaxVideoBytes = 50 * 1024 * 1024;
