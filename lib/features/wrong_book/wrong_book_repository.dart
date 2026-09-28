import 'dart:io';

import '../../services/learn_snap_api.dart';
import 'wrong_book_store.dart';
import 'wrong_item.dart';

class WrongBookRepository {
  WrongBookRepository({LearnSnapApi? api, WrongBookStore? store})
      : _api = api ?? LearnSnapApi(),
        _store = store ?? WrongBookStore();

  final LearnSnapApi _api;
  final WrongBookStore _store;

  Future<List<WrongItem>> loadLocal(int childId) => _store.load(childId);

  Future<List<WrongItem>> saveLocalAndSync(int childId, WrongItem item) async {
    final current = await _store.load(childId);
    final next = [
      item,
      ...current.where((row) => row.clientUuid != item.clientUuid),
    ];
    await _store.save(childId, next);
    return refresh(childId);
  }

  Future<List<WrongItem>> refresh(int childId) async {
    final local = await _store.load(childId);
    final prepared = <WrongItem>[];
    for (final item in local) {
      if (!item.pendingSync ||
          item.deleted ||
          item.imageKey.isNotEmpty ||
          item.localPath.isEmpty) {
        prepared.add(item);
        continue;
      }
      try {
        final key = await _api.uploadWrongImage(childId: childId, path: item.localPath);
        prepared.add(item.copyWith(imageKey: key));
      } catch (_) {
        prepared.add(item);
      }
    }
    final since = await _store.readSince(childId);
    final dirty = prepared.where((item) => item.pendingSync).toList();
    final data = await _api.syncWrongItems(
      childId: childId,
      since: since,
      upserts: dirty.map((item) => item.toSyncJson()).toList(),
    );
    final serverTime = data['server_time'] as String? ?? '';
    final rawItems = data['items'];
    final server = <WrongItem>[];
    if (rawItems is List) {
      for (final raw in rawItems) {
        if (raw is Map) {
          server.add(WrongItem.fromServerJson(Map<String, dynamic>.from(raw)));
        }
      }
    }
    var merged = mergeWrongItems(local: prepared, server: server);
    merged = await _downloadMissing(childId, merged);
    await _store.save(childId, merged);
    if (serverTime.isNotEmpty) {
      await _store.writeSince(childId, serverTime);
    }
    return merged;
  }

  Future<List<WrongItem>> _downloadMissing(int childId, List<WrongItem> items) async {
    final next = <WrongItem>[];
    for (final item in items) {
      if (item.imageKey.isEmpty) {
        next.add(item);
        continue;
      }
      final existing = item.localPath.isNotEmpty ? File(item.localPath) : null;
      if (existing != null && existing.existsSync()) {
        next.add(item);
        continue;
      }
      try {
        final bytes = await _api.downloadWrongImage(
          childId: childId,
          clientUuid: item.clientUuid,
        );
        final file = await _store.imageFile(childId, item.clientUuid);
        await file.writeAsBytes(bytes, flush: true);
        next.add(item.copyWith(localPath: file.path));
      } catch (_) {
        next.add(item);
      }
    }
    return next;
  }
}
