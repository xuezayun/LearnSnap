import 'package:flutter/material.dart';

import 'core/device_layout.dart';
import 'features/bind/bind_page.dart';
import 'features/checkin/checkin_page.dart';
import 'features/beans/bean_ledger_page.dart';
import 'features/report/checkin_report_page.dart';
import 'models/home_snapshot.dart';
import 'models/task_list_group.dart';
import 'services/learn_snap_api.dart';

void main() {
  runApp(const LearnSnapApp());
}

class LearnSnapApp extends StatelessWidget {
  const LearnSnapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学拍乐园',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2EC4B6),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
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
    final bound = await _api.hasSession();
    if (!mounted) return;
    setState(() {
      _bound = bound;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.api, required this.onLogout});

  final LearnSnapApi? api;
  final VoidCallback onLogout;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final LearnSnapApi _api = widget.api ?? LearnSnapApi();
  HomeSnapshot? _snapshot;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await _api.fetchHomeSnapshot();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openCheckin(TodayBoxItem box, {bool revise = false}) async {
    final result = await Navigator.of(context).push<CheckinSubmitResult?>(
      MaterialPageRoute(
        builder: (_) => CheckinPage(
          assignmentId: box.assignmentId,
          title: box.title,
          api: _api,
          revise: revise,
          checkinId: box.checkinId,
        ),
      ),
    );
    if (!mounted || result == null) return;
    final message = result.revised
        ? '修订成功'
        : (result.beans > 0
            ? '提交成功，预热能量豆 +${result.beans}'
            : '提交成功');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    _load();
  }

  void _onBoxTap(TodayBoxItem box) {
    if (!box.submitted) {
      _openCheckin(box);
      return;
    }
    if (box.canRevise) {
      _openCheckin(box, revise: true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(box.displaySubtitle)),
    );
  }

  void _openReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckinReportPage(api: _api),
      ),
    );
  }

  void _openBeanLedger(int balance) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BeanLedgerPage(
          api: _api,
          initialBalance: balance,
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重新绑定设备？'),
        content: const Text('退出当前绑定后，需要重新输入家长提供的绑定码才能使用。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout();
            },
            child: const Text('确认退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);
    final buttonHeight = primaryButtonHeight(context);
    final snapshot = _snapshot;
    final boxes = snapshot?.todayBox.boxes ?? [];
    final sections = groupTasksByStatus(boxes);
    final nextBox = boxes.cast<TodayBoxItem?>().firstWhere(
          (b) => b != null && !b.submitted,
          orElse: () => null,
        );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE8FBF8), Color(0xFFFFF8E7)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: AdaptiveBody(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            Center(
                              child: FilledButton(
                                onPressed: _load,
                                child: const Text('重试'),
                              ),
                            ),
                          ],
                        )
                      : ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(bottom: tablet ? 32 : 16),
                          children: [
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(Icons.logout, color: Colors.black38),
                                tooltip: '重新绑定',
                                onPressed: _showLogoutDialog,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '今日宝箱',
                              style: TextStyle(
                                fontSize: tablet ? 32 : 28,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot == null
                                  ? '拍照或录视频打卡'
                                  : '已完成 ${snapshot.todayBox.completed}/${snapshot.todayBox.total} · 连续 ${snapshot.todayBox.streak} 天',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.black54),
                            ),
                            if (snapshot != null) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Chip(
                                    avatar: Icon(
                                      snapshot.entitlements.isPlus
                                          ? Icons.workspace_premium
                                          : Icons.home_outlined,
                                      size: 18,
                                    ),
                                    label: Text(snapshot.entitlements.label),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(Icons.bolt, size: 18),
                                    label: Text('${snapshot.todayBox.energyBeans} 乐豆'),
                                    onPressed: () =>
                                        _openBeanLedger(snapshot.todayBox.energyBeans),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Card(
                                child: ListTile(
                                  leading: Icon(
                                    Icons.insights,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  title: const Text('打卡报告'),
                                  subtitle: const Text('查看近期学习记录与习惯排行'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: _openReport,
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            if (boxes.isEmpty)
                              const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Text(
                                    '今天还没有任务，请家长在小程序分配习惯任务',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            else
                              ...sections.expand(
                                (section) => [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                                    child: Row(
                                      children: [
                                        Text(
                                          section.title,
                                          style: TextStyle(
                                            fontSize: tablet ? 18 : 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Chip(
                                          label: Text('${section.items.length}'),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...section.items.map(
                                    (box) => Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: _TreasureBox(
                                        title: box.title,
                                        subtitle: box.displaySubtitle,
                                        submitted: box.submitted,
                                        canRevise: box.canRevise,
                                        category: section.category,
                                        onTap: () => _onBoxTap(box),
                                        compact: tablet,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 16),
                            if (nextBox != null)
                              FilledButton.icon(
                                onPressed: () => _openCheckin(nextBox),
                                icon: const Icon(Icons.camera_alt),
                                label: Text('开始打卡：${nextBox.title}'),
                                style: FilledButton.styleFrom(
                                  minimumSize: Size(double.infinity, buttonHeight),
                                  textStyle: TextStyle(fontSize: tablet ? 20 : 18),
                                ),
                              ),
                          ],
                        ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TreasureBox extends StatelessWidget {
  const _TreasureBox({
    required this.title,
    required this.subtitle,
    required this.submitted,
    required this.canRevise,
    required this.category,
    required this.onTap,
    this.compact = false,
  });

  final String title;
  final String subtitle;
  final bool submitted;
  final bool canRevise;
  final TaskCategory category;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color iconColor;
    switch (category) {
      case TaskCategory.pending:
        icon = Icons.card_giftcard;
        iconColor = Theme.of(context).colorScheme.primary;
      case TaskCategory.awaitingReview:
        icon = Icons.hourglass_top;
        iconColor = Colors.orange.shade700;
      case TaskCategory.rejected:
        icon = Icons.replay;
        iconColor = Colors.red.shade600;
      case TaskCategory.completed:
        icon = Icons.check_circle;
        iconColor = Colors.green;
    }

    return Card(
      elevation: category == TaskCategory.completed ? 1 : 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 28 : 20),
          child: Row(
            children: [
              Icon(
                icon,
                size: compact ? 48 : 40,
                color: iconColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: compact ? 22 : 18,
                        fontWeight: FontWeight.w600,
                        decoration:
                            category == TaskCategory.completed ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              if (category == TaskCategory.pending || category == TaskCategory.rejected || category == TaskCategory.awaitingReview)
                Icon(
                  category == TaskCategory.pending
                      ? Icons.videocam_outlined
                      : Icons.edit_outlined,
                  size: compact ? 28 : 24,
                  color: Colors.black38,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
