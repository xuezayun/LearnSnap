import 'dart:async';

import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

import '../core/api_client.dart';
import '../core/checkin_media_cache.dart';
import '../core/cos_uploader.dart';
import '../core/device_info_collector.dart';
import '../core/local_cache.dart';
import '../core/session_store.dart';
import '../models/bean_ledger.dart';
import '../models/checkin_history.dart';
import '../models/checkin_media.dart';
import '../models/checkin_report.dart';
import '../models/child_checkin_detail.dart';
import '../models/client_version.dart';
import '../models/home_snapshot.dart';
import '../models/honor_badge.dart';
import '../models/review_tools.dart';

String ensureVideoFilename(String name) {
  final ext = p.extension(name).toLowerCase();
  if (ext == '.mp4' || ext == '.mov' || ext == '.webm') {
    return name;
  }
  return '$name.mp4';
}

class LearnSnapApi {
  LearnSnapApi({ApiClient? client, SessionStore? sessionStore})
      : _client = client ?? ApiClient(sessionStore: sessionStore),
        _sessionStore = sessionStore ?? SessionStore();

  final ApiClient _client;
  final SessionStore _sessionStore;

  Future<void> bindChild({
    required String bindCode,
    required DeviceSnapshot device,
  }) async {
    final data = await _client.post(
      '/auth/child-bind',
      data: {
        'code': bindCode.trim().toUpperCase(),
        ...device.toJson(),
      },
      options: Options(extra: {'skipAuth': true}),
    );
    final child = data['child'] as Map<String, dynamic>;
    await _sessionStore.saveSession(
      accessToken: data['access'] as String,
      refreshToken: data['refresh'] as String,
      childId: child['id'] as int,
    );
  }

  Future<void> sendDeviceHeartbeat({DeviceSnapshot? device}) async {
    final snapshot = device ?? await DeviceInfoCollector().collect();
    await _client.post('/devices/heartbeat', data: snapshot.toJson());
  }

  Future<ClientVersionInfo> checkClientVersion({String? current}) async {
    final version = current ?? (await PackageInfo.fromPlatform()).version;
    final data = await _client.get(
      '/client/version',
      queryParameters: {
        'channel': 'child_app',
        'current': version,
      },
      options: Options(extra: {'skipAuth': true}),
    );
    return ClientVersionInfo.fromJson(data);
  }

  Future<bool> hasSession() async {
    final token = await _sessionStore.accessToken;
    final childId = await _sessionStore.childId;
    return token != null && token.isNotEmpty && childId != null;
  }

  Future<void> clearSession() async {
    try {
      await _sessionStore.clear().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Token 清不掉也不能挡住回到暗号页
    }
    // 缓存目录可能很大，不阻塞启动 / 退出
    unawaited(clearLocalCache().catchError((_) {}));
  }

  Future<int?> getChildId() => _sessionStore.childId;

  Future<TodayBox> fetchTodayBox(int childId) async {
    final data = await _client.get('/children/$childId/today-box');
    return TodayBox.fromJson(data);
  }

  Future<FamilyEntitlements> fetchEntitlements(int childId) async {
    final data = await _client.get('/children/$childId/entitlements');
    return FamilyEntitlements.fromJson(data);
  }

  Future<CheckinReport> fetchCheckinReport({
    int? childId,
    String? start,
    String? end,
  }) async {
    final id = childId ?? await _sessionStore.childId;
    if (id == null) {
      throw ApiException('未绑定孩子账号');
    }
    var path = '/children/$id/checkin-report';
    if (start != null && end != null) {
      path += '?start=$start&end=$end';
    }
    final data = await _client.get(path);
    return CheckinReport.fromJson(data);
  }

  Future<CheckinHistoryPageData> fetchCheckinHistory({
    int? childId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final id = childId ?? await _sessionStore.childId;
    if (id == null) {
      throw ApiException('未绑定孩子账号');
    }
    final path = '/children/$id/checkins?page=$page&page_size=$pageSize';
    final data = await _client.get(path);
    return CheckinHistoryPageData.fromJson(data);
  }

  Future<BeanLedgerPage> fetchBeanLedger({
    int? childId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final id = childId ?? await _sessionStore.childId;
    if (id == null) {
      throw ApiException('未绑定孩子账号');
    }
    final path = '/children/$id/bean-ledger?page=$page&page_size=$pageSize';
    final data = await _client.get(path);
    return BeanLedgerPage.fromJson(data);
  }

  Future<HonorBadge> fetchHonorBadge({int? childId}) async {
    final id = childId ?? await _sessionStore.childId;
    if (id == null) {
      throw ApiException('未绑定孩子账号');
    }
    final data = await _client.get('/children/$id/honor-badge');
    return HonorBadge.fromJson(
      data is Map ? Map<String, dynamic>.from(data as Map) : null,
    );
  }

  Future<HonorBadge> redeemHonorStars({int count = 1, int? childId}) async {
    final id = childId ?? await _sessionStore.childId;
    if (id == null) {
      throw ApiException('未绑定孩子账号');
    }
    final data = await _client.post(
      '/children/$id/honor-badge/redeem',
      data: {'count': count},
    );
    return HonorBadge.fromJson(
      data is Map ? Map<String, dynamic>.from(data as Map) : null,
    );
  }

  Future<HomeSnapshot> fetchHomeSnapshot() async {
    final childId = await _sessionStore.childId;
    if (childId == null) {
      throw ApiException('未绑定孩子账号');
    }
    final entitlements = await fetchEntitlements(childId);
    if (!entitlements.usable) {
      throw ApiException(
        '该档案已锁定，请家长开通会员或在小程序切换可用孩子',
        code: 40207,
      );
    }
    final todayBox = await fetchTodayBox(childId);
    return HomeSnapshot(
      todayBox: todayBox,
      entitlements: entitlements,
    );
  }

  Future<ChildCheckinDetail> fetchCheckinDetail(int checkinId) async {
    final data = await _client.get('/checkins/$checkinId/mine');
    return ChildCheckinDetail.fromJson(data);
  }

  Future<List<CheckinMediaItem>> fetchCheckinMedia(int checkinId) async {
    final data = await _client.get('/checkins/$checkinId/mine');
    final raw = data['media'];
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => CheckinMediaItem.fromSubmittedJson(Map<String, dynamic>.from(e)))
        .where((m) =>
            m.hasRemotePreview ||
            m.isExistingRemote ||
            (m.existingMediaId != null && m.existingMediaId! > 0))
        .toList();
  }

  Future<ReviewToolsMeta> fetchReviewToolsMeta() async {
    final data = await _client.get('/child/review-tools');
    return ReviewToolsMeta.fromJson(data);
  }

  Future<ReviewToolsAssignment> assignReviewToolTask({
    int? templateId,
    String? title,
    String taskType = 'study',
    int durationMin = 15,
  }) async {
    final body = <String, dynamic>{
      'task_type': taskType,
      'duration_min': durationMin,
    };
    if (templateId != null) body['template_id'] = templateId;
    if (title != null && title.trim().isNotEmpty) {
      body['title'] = title.trim();
    }
    final data = await _client.post('/child/review-tools/assign', data: body);
    return ReviewToolsAssignment.fromJson(data);
  }

  Future<List<ReviewToolsPendingItem>> fetchReviewToolsPending() async {
    final data = await _client.get('/child/review-tools/pending');
    final items = data['items'] as List<dynamic>? ?? [];
    return items
        .whereType<Map>()
        .map((e) => ReviewToolsPendingItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<ReviewToolsApproveResult> approveReviewToolCheckin({
    required int checkinId,
    required String rating,
    String comment = '',
  }) async {
    final data = await _client.post(
      '/child/review-tools/checkins/$checkinId/approve',
      data: {
        'rating': rating,
        'comment': comment,
      },
    );
    return ReviewToolsApproveResult.fromJson(data);
  }

  Future<CheckinSubmitResult> submitCheckin({
    required int assignmentId,
    required List<CheckinMediaItem> media,
    String note = '',
    String? idempotencyKey,
  }) async {
    final cosMedia = await buildCheckinMediaPayload(
      client: _client,
      dio: _client.dio,
      media: media,
    );
    if (cosMedia != null) {
      final data = await _client.post(
        '/checkins/submit',
        data: {
          'assignment_id': assignmentId,
          'note': note,
          if (idempotencyKey != null && idempotencyKey.isNotEmpty)
            'idempotency_key': idempotencyKey,
          'media': [
            for (var i = 0; i < cosMedia.length; i++)
              {
                ...cosMedia[i].toJson(),
                'sort_order': i,
              },
          ],
        },
        options: Options(
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final result = CheckinSubmitResult(
        beans: _readInt(data['preheat_beans']),
        revised: data['revised'] as bool? ?? false,
        checkinId: _readInt(data['checkin_id']) == 0 ? null : _readInt(data['checkin_id']),
      );
      await _aliasSubmittedCache(media, result.checkinId);
      return result;
    }
    if (media.any((m) => m.isExistingRemote && !m.needsUpload)) {
      throw ApiException('当前环境无法保留已提交媒体，请全部重新添加后提交');
    }
    final formData = FormData.fromMap({
      'assignment_id': assignmentId.toString(),
      'note': note,
      if (idempotencyKey != null && idempotencyKey.isNotEmpty)
        'idempotency_key': idempotencyKey,
    });
    final hasVideo = media.any((item) => item.isVideo);
    for (final item in media) {
      if (item.isImage) {
        formData.files.add(
          MapEntry(
            'files',
            MultipartFile.fromBytes(item.bytes!, filename: item.filename),
          ),
        );
      } else {
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(
              item.filePath!,
              filename: ensureVideoFilename(item.filename),
            ),
          ),
        );
      }
    }
    final data = await _client.postMultipart(
      '/checkins/submit',
      formData,
      sendTimeout: hasVideo ? const Duration(seconds: 180) : const Duration(seconds: 120),
      receiveTimeout:
          hasVideo ? const Duration(seconds: 180) : const Duration(seconds: 120),
    );
    final result = CheckinSubmitResult(
      beans: _readInt(data['preheat_beans']),
      revised: data['revised'] as bool? ?? false,
      checkinId: _readInt(data['checkin_id']) == 0 ? null : _readInt(data['checkin_id']),
    );
    await _aliasSubmittedCache(media, result.checkinId);
    return result;
  }

  Future<void> _aliasSubmittedCache(
    List<CheckinMediaItem> local,
    int? checkinId,
  ) async {
    if (checkinId == null || checkinId <= 0 || local.isEmpty) return;
    try {
      final submitted = await fetchCheckinMedia(checkinId);
      final n = local.length < submitted.length ? local.length : submitted.length;
      for (var i = 0; i < n; i++) {
        final id = submitted[i].existingMediaId ?? 0;
        final key = submitted[i].objectKey ?? '';
        if (local[i].bytes != null && local[i].bytes!.isNotEmpty) {
          await CheckinMediaCache.putBytes(
            local[i].bytes!,
            mediaId: id,
            objectKey: key,
          );
        } else {
          final path = local[i].filePath?.trim() ?? '';
          if (path.isNotEmpty) {
            await CheckinMediaCache.putFile(
              path,
              mediaId: id,
              objectKey: key,
            );
          }
        }
      }
    } catch (_) {
      // cache alias is best-effort
    }
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
