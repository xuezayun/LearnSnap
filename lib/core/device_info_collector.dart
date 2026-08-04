import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'device_identity_store.dart';

class DeviceSnapshot {
  const DeviceSnapshot({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.osVersion,
    required this.deviceModel,
    required this.appVersion,
    required this.appBuild,
    required this.locale,
  });

  final String deviceId;
  final String deviceName;
  final String platform;
  final String osVersion;
  final String deviceModel;
  final String appVersion;
  final String appBuild;
  final String locale;

  Map<String, dynamic> toJson() {
    return {
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
      'os_version': osVersion,
      'device_model': deviceModel,
      'app_version': appVersion,
      'app_build': appBuild,
      'locale': locale,
    };
  }
}

class DeviceInfoCollector {
  DeviceInfoCollector({
    DeviceInfoPlugin? deviceInfo,
    DeviceIdentityStore? identityStore,
  })  : _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        _identityStore = identityStore ?? DeviceIdentityStore();

  final DeviceInfoPlugin _deviceInfo;
  final DeviceIdentityStore _identityStore;

  Future<DeviceSnapshot> collect() async {
    final deviceId = await _identityStore.getOrCreateDeviceId();
    final packageInfo = await PackageInfo.fromPlatform();
    final locale = PlatformDispatcher.instance.locale.toLanguageTag();

    var platform = 'unknown';
    var osVersion = '';
    var deviceModel = '';
    var deviceName = 'LearnSnap Device';

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      platform = 'android';
      osVersion = 'Android ${info.version.release}';
      deviceModel = _compactModel(info.manufacturer, info.model);
      deviceName = deviceModel.isNotEmpty ? deviceModel : 'Android 设备';
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      platform = 'ios';
      osVersion = '${info.systemName} ${info.systemVersion}';
      deviceModel = info.utsname.machine;
      deviceName = info.name.trim().isNotEmpty ? info.name.trim() : 'iOS 设备';
    }

    return DeviceSnapshot(
      deviceId: deviceId,
      deviceName: _truncate(deviceName, 64),
      platform: platform,
      osVersion: _truncate(osVersion, 32),
      deviceModel: _truncate(deviceModel, 64),
      appVersion: _truncate(packageInfo.version, 32),
      appBuild: _truncate(packageInfo.buildNumber, 16),
      locale: _truncate(locale.replaceAll('-', '_'), 16),
    );
  }

  String _compactModel(String manufacturer, String model) {
    final parts = [manufacturer.trim(), model.trim()].where((part) => part.isNotEmpty);
    return parts.join(' ');
  }

  String _truncate(String value, int maxLength) {
    final trimmed = value.trim();
    if (trimmed.length <= maxLength) return trimmed;
    return trimmed.substring(0, maxLength);
  }
}
