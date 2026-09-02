import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../models/checkin_media.dart';
import 'api_client.dart';
import 'checkin_media_cache.dart';
import 'checkin_media_prepare.dart';
import 'harmony_os.dart';
import 'media_url.dart';

class CosPresignItem {
  CosPresignItem({
    required this.objectKey,
    required this.putUrl,
    required this.mediaType,
    required this.contentType,
    this.headers = const {},
  });

  final String objectKey;
  final String putUrl;
  final String mediaType;
  final String contentType;
  final Map<String, String> headers;

  factory CosPresignItem.fromJson(Map<String, dynamic> json) {
    final headersRaw = json['headers'];
    final headers = <String, String>{};
    if (headersRaw is Map) {
      headersRaw.forEach((key, value) {
        if (key != null && value != null) {
          headers[key.toString()] = value.toString();
        }
      });
    }
    return CosPresignItem(
      objectKey: json['object_key'] as String? ?? '',
      putUrl: json['put_url'] as String? ?? '',
      mediaType: json['media_type'] as String? ?? 'image',
      contentType: headers['Content-Type'] ?? 'application/octet-stream',
      headers: headers,
    );
  }
}

class CosUploadedMedia {
  CosUploadedMedia({
    required this.objectKey,
    required this.mediaType,
    required this.sortOrder,
    this.contentType = '',
  });

  final String objectKey;
  final String mediaType;
  final int sortOrder;
  final String contentType;

  Map<String, dynamic> toJson() => {
        'object_key': objectKey,
        'media_type': mediaType,
        'sort_order': sortOrder,
        if (contentType.isNotEmpty) 'content_type': contentType,
      };
}

String guessContentType(CheckinMediaItem item) {
  final ext = p.extension(item.filename).toLowerCase();
  if (item.isVideo) {
    switch (ext) {
      case '.mov':
        return 'video/quicktime';
      case '.webm':
        return 'video/webm';
      case '.m4v':
        return 'video/x-m4v';
      default:
        return 'video/mp4';
    }
  }
  switch (ext) {
    case '.png':
      return 'image/png';
    case '.webp':
      return 'image/webp';
    case '.gif':
      return 'image/gif';
    case '.heic':
      return 'image/heic';
    default:
      return 'image/jpeg';
  }
}

Future<int> mediaByteSize(CheckinMediaItem item) async {
  if (item.bytes != null) return item.bytes!.length;
  if (item.filePath != null) {
    return File(item.filePath!).length();
  }
  return 0;
}

/// Upload only local items; existing remote keys are returned as-is (same order).
Future<List<CosUploadedMedia>?> buildCheckinMediaPayload({
  required ApiClient client,
  required Dio dio,
  required List<CheckinMediaItem> media,
}) async {
  final result = List<CosUploadedMedia?>.filled(media.length, null);
  final localItems = <CheckinMediaItem>[];
  final localIndexes = <int>[];

  for (var i = 0; i < media.length; i++) {
    final item = media[i];
    if (item.isExistingRemote) {
      result[i] = CosUploadedMedia(
        objectKey: item.objectKey!,
        mediaType: item.isVideo ? 'video' : 'image',
        sortOrder: i,
        contentType: item.contentType ?? '',
      );
    } else if (item.needsUpload) {
      localIndexes.add(i);
      localItems.add(item);
    } else {
      throw ApiException('媒体内容不完整，请删除后重新添加');
    }
  }

  if (localItems.isEmpty) {
    return result.cast<CosUploadedMedia>();
  }

  final uploaded = await uploadCheckinMediaViaCos(
    client: client,
    dio: dio,
    media: localItems,
  );
  if (uploaded == null) {
    // COS disabled — caller must use multipart; cannot mix remote keys easily
    if (localItems.length == media.length) return null;
    throw ApiException('当前无法保留已提交媒体，请全部重新添加后提交');
  }
  if (uploaded.length != localItems.length) {
    throw ApiException('云存储上传结果异常');
  }
  for (var j = 0; j < localIndexes.length; j++) {
    final idx = localIndexes[j];
    final u = uploaded[j];
    result[idx] = CosUploadedMedia(
      objectKey: u.objectKey,
      mediaType: u.mediaType,
      sortOrder: idx,
      contentType: u.contentType,
    );
  }
  return result.cast<CosUploadedMedia>();
}

Future<void> putToCos({
  required Dio dio,
  required CosPresignItem presign,
  required CheckinMediaItem item,
}) async {
  final contentType = presign.headers['Content-Type']?.trim().isNotEmpty == true
      ? presign.headers['Content-Type']!.trim()
      : guessContentType(item);

  final Uint8List bytes;
  if (item.isImage) {
    final raw = item.bytes;
    if (raw == null || raw.isEmpty) {
      throw ApiException('照片是空的，请重新拍一张');
    }
    bytes = raw;
  } else {
    final path = item.filePath?.trim() ?? '';
    if (path.isEmpty) {
      throw ApiException('视频文件路径无效');
    }
    final file = File(path);
    if (!await file.exists()) {
      throw ApiException('视频文件不存在，请重新录制或选择');
    }
    bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw ApiException('视频文件为空，请重新录制或选择');
    }
  }

  final headers = <String, dynamic>{
    'Content-Type': contentType,
    Headers.contentLengthHeader: bytes.length.toString(),
  };

  final putUrl = sanitizeMediaUrl(presign.putUrl);
  try {
    final response = await dio.put<dynamic>(
      putUrl,
      data: bytes,
      options: Options(
        headers: headers,
        contentType: contentType,
        sendTimeout: item.isVideo
            ? const Duration(seconds: 180)
            : const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 60),
        followRedirects: false,
        responseType: ResponseType.plain,
        extra: {'skipAuth': true},
        validateStatus: (code) => code != null && code >= 200 && code < 300,
      ),
    );
    if (response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! >= 300) {
      throw ApiException('上传到云存储失败（${response.statusCode}）');
    }
    final body = '${response.data ?? ''}';
    if (cosResponseIndicatesError(body)) {
      throw ApiException('上传到云存储失败，请检查网络后重试');
    }
  } on ApiException {
    rethrow;
  } on DioException catch (e) {
    final code = e.response?.statusCode;
    final kind = item.isVideo ? '视频' : '图片';
    if (code != null) {
      throw ApiException('上传$kind到云存储失败（HTTP $code）');
    }
    if (e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionTimeout) {
      throw ApiException('上传$kind超时，请检查网络后重试');
    }
    throw ApiException('上传$kind到云存储失败，请检查网络后重试');
  }
}

/// HarmonyOS 3/4: upload through the API so the server PUTs to COS.
Future<List<CosUploadedMedia>?> ingestCheckinMediaViaServer({
  required ApiClient client,
  required List<CheckinMediaItem> media,
}) async {
  final formData = FormData();
  for (final item in media) {
    if (item.isImage) {
      final bytes = item.bytes;
      if (bytes == null || bytes.isEmpty) {
        throw ApiException('照片是空的，请重新拍一张');
      }
      formData.files.add(
        MapEntry(
          'files',
          MultipartFile.fromBytes(
            bytes,
            filename: item.filename,
          ),
        ),
      );
    } else {
      final path = item.filePath?.trim() ?? '';
      if (path.isEmpty) {
        throw ApiException('视频文件路径无效');
      }
      formData.files.add(
        MapEntry(
          'files',
          await MultipartFile.fromFile(
            path,
            filename: item.filename.toLowerCase().endsWith('.mp4') ||
                    item.filename.toLowerCase().endsWith('.mov') ||
                    item.filename.toLowerCase().endsWith('.webm')
                ? item.filename
                : '${item.filename}.mp4',
          ),
        ),
      );
    }
  }

  Map<String, dynamic> data;
  try {
    data = await client.postMultipart(
      '/checkins/media/ingest',
      formData,
      sendTimeout: const Duration(seconds: 180),
      receiveTimeout: const Duration(seconds: 60),
    );
  } on ApiException catch (e) {
    if (e.code == 40201) return null;
    rethrow;
  }

  final itemsRaw = data['items'];
  if (itemsRaw is! List || itemsRaw.length != media.length) {
    throw ApiException('云存储上传结果异常');
  }
  final uploaded = <CosUploadedMedia>[];
  for (var i = 0; i < media.length; i++) {
    final raw = itemsRaw[i];
    if (raw is! Map) {
      throw ApiException('云存储上传结果异常');
    }
    final map = Map<String, dynamic>.from(raw);
    final objectKey = map['object_key'] as String? ?? '';
    if (objectKey.isEmpty) {
      throw ApiException('云存储上传结果异常');
    }
    await CheckinMediaCache.putItem(media[i], objectKey: objectKey);
    uploaded.add(
      CosUploadedMedia(
        objectKey: objectKey,
        mediaType: map['media_type'] as String? ??
            (media[i].isVideo ? 'video' : 'image'),
        sortOrder: i,
        contentType: map['content_type'] as String? ?? guessContentType(media[i]),
      ),
    );
  }
  return uploaded;
}

/// Returns null when COS is disabled (caller should fall back to multipart).
Future<List<CosUploadedMedia>?> uploadCheckinMediaViaCos({
  required ApiClient client,
  required Dio dio,
  required List<CheckinMediaItem> media,
}) async {
  if (await HarmonyOs.shouldUploadViaServer()) {
    return ingestCheckinMediaViaServer(client: client, media: media);
  }
  final meta = <Map<String, dynamic>>[];
  for (final item in media) {
    final size = await mediaByteSize(item);
    meta.add({
      'filename': item.isVideo
          ? (item.filename.toLowerCase().endsWith('.mp4') ||
                  item.filename.toLowerCase().endsWith('.mov') ||
                  item.filename.toLowerCase().endsWith('.webm')
              ? item.filename
              : '${item.filename}.mp4')
          : item.filename,
      'content_type': guessContentType(item),
      'byte_size': size,
    });
  }

  Map<String, dynamic> data;
  try {
    data = await client.post('/checkins/media/presign', data: {'items': meta});
  } on ApiException catch (e) {
    if (e.code == 40201) return null;
    rethrow;
  } on DioException catch (e) {
    final raw = e.response?.data;
    if (raw is Map) {
      final code = raw['code'];
      final intCode = code is int
          ? code
          : (code is num ? code.toInt() : int.tryParse('$code'));
      if (intCode == 40201) return null;
      final message = raw['message']?.toString();
      if (message != null && message.isNotEmpty) {
        throw ApiException(message, code: intCode ?? -1, statusCode: e.response?.statusCode);
      }
    }
    rethrow;
  }

  final itemsRaw = data['items'];
  if (itemsRaw is! List || itemsRaw.length != media.length) {
    throw ApiException('云存储预签名返回异常');
  }

  final uploaded = <CosUploadedMedia>[];
  for (var i = 0; i < media.length; i++) {
    final raw = itemsRaw[i];
    if (raw is! Map) {
      throw ApiException('云存储预签名项无效');
    }
    final presign = CosPresignItem.fromJson(Map<String, dynamic>.from(raw));
    if (presign.putUrl.isEmpty || presign.objectKey.isEmpty) {
      throw ApiException('云存储预签名不完整');
    }
    await putToCos(dio: dio, presign: presign, item: media[i]);
    await CheckinMediaCache.putItem(media[i], objectKey: presign.objectKey);
    uploaded.add(
      CosUploadedMedia(
        objectKey: presign.objectKey,
        mediaType: presign.mediaType,
        sortOrder: i,
        contentType: guessContentType(media[i]),
      ),
    );
  }
  return uploaded;
}
