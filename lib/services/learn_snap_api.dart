import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import '../models/home_snapshot.dart';
import '../core/api_client.dart';
import '../core/session_store.dart';
import '../models/checkin_media.dart';
import '../models/checkin_report.dart';
import '../models/bean_ledger.dart';

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
    required String deviceId,
  }) async {
    final data = await _client.post(
      '/auth/child-bind',
      data: {
        'code': bindCode.trim().toUpperCase(),
        'device_id': deviceId,
        'device_name': 'Flutter Device',
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

  Future<bool> hasSession() async {
    final token = await _sessionStore.accessToken;
    final childId = await _sessionStore.childId;
    return token != null && token.isNotEmpty && childId != null;
  }

  Future<void> clearSession() => _sessionStore.clear();

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

  Future<BeanLedgerPage> fetchBeanLedger({
    int? childId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final id = childId ?? await _sessionStore.childId;
    if (id == null) {
      throw ApiException('未绑定孩子账号');
    }
    final path =
        '/children/$id/bean-ledger?page=$page&page_size=$pageSize';
    final data = await _client.get(path);
    return BeanLedgerPage.fromJson(data);
  }

  Future<HomeSnapshot> fetchHomeSnapshot() async {
    final childId = await _sessionStore.childId;
    if (childId == null) {
      throw ApiException('未绑定孩子账号');
    }
    final results = await Future.wait([
      fetchTodayBox(childId),
      fetchEntitlements(childId),
    ]);
    return HomeSnapshot(
      todayBox: results[0] as TodayBox,
      entitlements: results[1] as FamilyEntitlements,
    );
  }

    Future<CheckinSubmitResult> submitCheckin({
    required int assignmentId,
    required List<CheckinMediaItem> media,
    String note = '',
    String? idempotencyKey,
  }) async {
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
      receiveTimeout: hasVideo ? const Duration(seconds: 180) : const Duration(seconds: 120),
    );
    return CheckinSubmitResult(
      beans: _readInt(data['preheat_beans']),
      revised: data['revised'] as bool? ?? false,
    );
  }

  int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
