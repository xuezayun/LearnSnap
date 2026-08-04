import 'package:flutter/foundation.dart';

/// 运行环境与 API 地址。
///
/// 切换方式（二选一）：
/// 1. `--dart-define=APP_ENV=dev|prod`（推荐）
/// 2. `--dart-define=API_BASE_URL=https://host/api/v1`（直接覆盖基址）
///
/// 示例：
/// - 测试：`flutter run --dart-define=APP_ENV=dev`
/// - 生产：`flutter build apk --release --dart-define=APP_ENV=prod`
class AppConfig {
  /// `dev` | `prod`
  static const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'prod');

  static const _apiOverride = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const _devApiBaseUrl = 'http://10.0.2.2:8000/api/v1';
  static const _prodApiBaseUrl = 'https://zhiyainfo.com/api/v1';

  static bool _loggedApiBaseUrl = false;

  static bool get isProd => appEnv == 'prod';

  static bool get isDev => !isProd;

  /// API 根路径（含 `/api/v1`）
  static String get apiBaseUrl {
    final url = _apiOverride.isNotEmpty
        ? _apiOverride
        : (isProd ? _prodApiBaseUrl : _devApiBaseUrl);
    if (!_loggedApiBaseUrl) {
      _loggedApiBaseUrl = true;
      debugPrint(
        '[AppConfig] apiBaseUrl=$url '
        '(APP_ENV=$appEnv'
        '${_apiOverride.isNotEmpty ? ', API_BASE_URL override' : ''})',
      );
    }
    return url;
  }

  /// 孩子端 App 正式名（桌面图标 / 商店）
  static const appName = '拍习惯';

  /// 家长端微信小程序名
  static const miniprogramName = '拍习惯家长版';

  /// 品牌 slogan（品类补足「习惯」）
  static const slogan = '拍下好习惯';

  /// 品类短句
  static const tagline = '小学生习惯打卡 · 拍照记录 · 家长审核';
}
