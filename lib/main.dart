import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'core/app_config.dart';
import 'core/device_layout.dart';
import 'features/bind/bind_page.dart';
import 'features/home/home_page.dart';
import 'services/learn_snap_api.dart';
import 'theme/app_theme.dart';
import 'widgets/app_scaffold_bg.dart';

void main() {
  runApp(const LearnSnapApp());
}

class LearnSnapApp extends StatelessWidget {
  const LearnSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
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
      home: const AppRoot(),
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

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    var bound = await _api.hasSession();
    if (bound) {
      try {
        await _api.sendDeviceHeartbeat();
      } on ApiException catch (e) {
        if (e.isSessionInvalid) {
          await _api.clearSession();
          bound = false;
        }
        // 其它心跳失败（网络等）不阻断启动，进首页后再试
      } catch (_) {
        // ignore
      }
    }
    if (!mounted) return;
    setState(() {
      _bound = bound;
      _loading = false;
    });
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
      return BindPage(onBound: () => setState(() => _bound = true));
    }
    return HomePage(
      api: _api,
      onLogout: () async {
        await _api.clearSession();
        setState(() => _bound = false);
      },
    );
  }
}
