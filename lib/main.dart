import 'dart:async';

import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/app_config.dart';
import 'core/device_layout.dart';
import 'core/privacy_consent_store.dart';
import 'features/bind/bind_page.dart';
import 'features/home/home_page.dart';
import 'features/privacy/privacy_consent_page.dart';
import 'services/learn_snap_api.dart';
import 'theme/app_theme.dart';
import 'widgets/app_scaffold_bg.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LearnSnapApp());
}

class LearnSnapApp extends StatefulWidget {
  const LearnSnapApp({super.key});

  @override
  State<LearnSnapApp> createState() => _LearnSnapAppState();
}

class _LearnSnapAppState extends State<LearnSnapApp> {
  final _consent = PrivacyConsentStore();
  bool _loading = true;
  bool _agreed = false;

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  Future<void> _loadConsent() async {
    var agreed = false;
    try {
      agreed = await _consent
          .hasAgreed()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
    } catch (_) {
      agreed = false;
    }
    if (!mounted) return;
    setState(() {
      _agreed = agreed;
      _loading = false;
    });
  }

  Future<void> _onAgree() async {
    await _consent.agree();
    if (!mounted) return;
    setState(() => _agreed = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: _agreed ? AppTheme.light() : AppTheme.preConsent(),
      builder: (context, child) {
        var mq = MediaQuery.of(context);
        if (isTablet(context)) {
          final current = mq.textScaler.scale(1);
          final boosted = (current < 1.05 ? 1.05 : current).clamp(1.0, 1.1);
          mq = mq.copyWith(textScaler: TextScaler.linear(boosted));
        }
        return MediaQuery(
          data: mq,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _loading
          ? const _LaunchSplash()
          : _agreed
              ? const AppRoot()
              : PrivacyConsentPage(onAgree: _onAgree),
    );
  }
}

class _LaunchSplash extends StatelessWidget {
  const _LaunchSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: AppScaffoldBackground(
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  final _api = LearnSnapApi();
  bool _loading = true;
  bool _bound = false;
  String? _kickNotice;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    var bound = false;
    try {
      bound = await _api
          .hasSession()
          .timeout(const Duration(seconds: 3), onTimeout: () => false);
      if (bound) {
        try {
          await _api
              .sendDeviceHeartbeat()
              .timeout(const Duration(seconds: 8));
        } on ApiException catch (e) {
          if (e.isSessionInvalid) {
            bound = false;
            _kickNotice = e.message.trim().isNotEmpty
                ? e.message
                : '登录已失效，请重新输入暗号';
            await _api.clearSession();
          }
        } on TimeoutException {
          // 心跳超时不挡启动，进首页后再试
        } catch (_) {
          // 其它失败不阻断启动
        }
      }
    } catch (_) {
      bound = false;
    } finally {
      if (mounted) {
        setState(() {
          _bound = bound;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: AppScaffoldBackground(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }
    if (!_bound) {
      return BindPage(
        notice: _kickNotice,
        onBound: () => setState(() {
          _bound = true;
          _kickNotice = null;
        }),
      );
    }
    return HomePage(
      api: _api,
      onLogout: ({String? notice}) async {
        try {
          await _api.clearSession();
        } catch (_) {}
        if (!mounted) return;
        setState(() {
          _bound = false;
          _kickNotice = notice;
        });
      },
    );
  }
}
