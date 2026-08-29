import 'package:shared_preferences/shared_preferences.dart';

/// 隐私政策同意记录。版本号变化后会再次弹出同意框。
class PrivacyConsentStore {
  PrivacyConsentStore({SharedPreferences? prefs}) : _prefsOverride = prefs;

  final SharedPreferences? _prefsOverride;

  /// 政策更新时递增，已同意旧版本的用户会再看一次弹窗。
  static const policyVersion = 1;
  static const agreedVersionKey = 'privacy_consent_version';

  Future<SharedPreferences> _prefs() async {
    return _prefsOverride ?? SharedPreferences.getInstance();
  }

  Future<bool> hasAgreed() async {
    final prefs = await _prefs();
    return prefs.getInt(agreedVersionKey) == policyVersion;
  }

  Future<void> agree() async {
    final prefs = await _prefs();
    await prefs.setInt(agreedVersionKey, policyVersion);
  }
}
