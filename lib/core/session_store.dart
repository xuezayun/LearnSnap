import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _childIdKey = 'child_id';

  Future<String?> get accessToken => _storage.read(key: _accessTokenKey);
  Future<String?> get refreshToken => _storage.read(key: _refreshTokenKey);
  Future<int?> get childId async {
    final value = await _storage.read(key: _childIdKey);
    return value == null ? null : int.tryParse(value);
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required int childId,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _childIdKey, value: childId.toString());
  }

  Future<void> clear() => _storage.deleteAll();
}
