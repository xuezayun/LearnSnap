import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'wrong_item.dart';

class WrongBookStore {
  Future<Directory> _dir(int childId) async {
    final root = await getApplicationSupportDirectory();
    final dir = Directory(p.join(root.path, 'wrong_book', '$childId'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<File> _file(int childId) async {
    final dir = await _dir(childId);
    return File(p.join(dir.path, 'items.json'));
  }

  Future<List<WrongItem>> load(int childId) async {
    final file = await _file(childId);
    if (!file.existsSync()) return [];
    try {
      final raw = jsonDecode(await file.readAsString());
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((item) => WrongItem.fromLocalJson(Map<String, dynamic>.from(item)))
          .where((item) => item.clientUuid.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> save(int childId, List<WrongItem> items) async {
    final file = await _file(childId);
    final visible = items.where((item) => !item.deleted || item.pendingSync).toList();
    await file.writeAsString(
      jsonEncode(visible.map((item) => item.toLocalJson()).toList()),
    );
  }

  Future<String?> readSince(int childId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('wrong_book_since_$childId');
  }

  Future<void> writeSince(int childId, String serverTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wrong_book_since_$childId', serverTime);
  }

  Future<File> imageFile(int childId, String clientUuid) async {
    final dir = await _dir(childId);
    final images = Directory(p.join(dir.path, 'images'));
    if (!images.existsSync()) {
      await images.create(recursive: true);
    }
    return File(p.join(images.path, '$clientUuid.jpg'));
  }
}
