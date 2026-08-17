import 'dart:typed_data';

enum CheckinMediaKind { image, video }

class CheckinMediaItem {
  const CheckinMediaItem({
    required this.kind,
    required this.filename,
    this.bytes,
    this.filePath,
    this.duration,
    this.fileSizeBytes,
    this.remoteUrl,
    this.objectKey,
    this.contentType,
    this.existingMediaId,
  });

  final CheckinMediaKind kind;
  final String filename;
  final Uint8List? bytes;
  final String? filePath;
  final Duration? duration;

  /// Local file size after compression (videos); optional for remote media.
  final int? fileSizeBytes;

  /// 已提交媒体的展示地址（COS / 服务器 URL）
  final String? remoteUrl;

  /// 已提交媒体的 COS object_key；修订提交时可直接复用
  final String? objectKey;
  final String? contentType;
  final int? existingMediaId;

  bool get isImage => kind == CheckinMediaKind.image;
  bool get isVideo => kind == CheckinMediaKind.video;

  /// 本地新选内容，需要上传
  bool get needsUpload =>
      (objectKey == null || objectKey!.isEmpty) &&
      (bytes != null || (filePath != null && filePath!.isNotEmpty));

  /// 已有云端对象，修订时可保留 key
  bool get isExistingRemote =>
      objectKey != null && objectKey!.trim().isNotEmpty;

  bool get hasRemotePreview =>
      remoteUrl != null && remoteUrl!.trim().isNotEmpty;

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
    int? fileSizeBytes,
  }) {
    return CheckinMediaItem(
      kind: CheckinMediaKind.video,
      filename: filename,
      filePath: filePath,
      duration: duration,
      fileSizeBytes: fileSizeBytes,
    );
  }

  factory CheckinMediaItem.fromSubmittedJson(Map<String, dynamic> json) {
    final mediaType = (json['media_type'] as String? ?? 'image').toLowerCase();
    final isVideo = mediaType == 'video';
    final url = (json['url'] as String? ?? '').trim();
    final thumb = (json['thumbnail_url'] as String? ?? '').trim();
    final key = (json['object_key'] as String? ?? '').trim();
    final id = json['id'];
    final sort = json['sort_order'];
    final name = isVideo
        ? 'submitted_${id ?? sort ?? 0}.mp4'
        : 'submitted_${id ?? sort ?? 0}.jpg';
    return CheckinMediaItem(
      kind: isVideo ? CheckinMediaKind.video : CheckinMediaKind.image,
      filename: name,
      remoteUrl: url.isNotEmpty ? url : (thumb.isNotEmpty ? thumb : null),
      objectKey: key.isNotEmpty ? key : null,
      contentType: json['content_type'] as String?,
      existingMediaId: id is int ? id : int.tryParse('$id'),
    );
  }
}

const checkinMaxVideoDuration = Duration(minutes: 2);
const checkinMaxVideoBytes = 50 * 1024 * 1024;
const checkinMaxImages = 3;
const checkinMaxVideos = 1;
