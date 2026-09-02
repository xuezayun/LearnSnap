import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/device_layout.dart';
import '../../models/client_version.dart';
import '../../models/home_snapshot.dart';
import '../../models/task_list_group.dart';
import '../../services/learn_snap_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/kid_style.dart';
import '../../widgets/app_scaffold_bg.dart';
import '../beans/bean_ledger_page.dart';
import '../checkin/checkin_detail_page.dart';
import '../checkin/checkin_history_page.dart';
import '../checkin/checkin_page.dart';
import '../honor/honor_badge_page.dart';
import '../report/checkin_report_page.dart';
import 'widgets/all_done_card.dart';
import 'widgets/empty_tasks_hint.dart';
import 'widgets/home_greeting.dart';
import 'widgets/home_top_bar.dart';
import 'widgets/section_header.dart';
import 'widgets/today_progress_panel.dart';
import 'widgets/treasure_box.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.api, required this.onLogout});

  final LearnSnapApi? api;
  final Future<void> Function({String? notice}) onLogout;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final LearnSnapApi _api = widget.api ?? LearnSnapApi();
  HomeSnapshot? _snapshot;
  int? _childId;
  bool _loading = true;
  String? _error;
  ClientVersionInfo? _updateInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    _checkUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _load(silent: true);
      _api.sendDeviceHeartbeat().catchError((_) {});
    }
  }

  Future<void> _checkUpdate() async {
    try {
      final info = await _api.checkClientVersion();
      if (!mounted) return;
      setState(() => _updateInfo = info);
    } catch (_) {
      // 版本检查失败不影响首页
    }
  }

  Future<void> _onUpdateTap() async {
    final info = _updateInfo;
    if (info == null || !info.updateAvailable) return;
    final url = info.downloadUrl.trim();
    if (url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (ok || !mounted) return;
      }
    }
    if (!mounted) return;
    final notes = info.releaseNotes.trim();
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(info.title.isNotEmpty ? info.title : '发现新版本'),
        content: Text(
          notes.isNotEmpty
              ? notes
              : '已有新版本 ${info.latestVersion}，请前往官网下载安装。',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  String _friendlyError(Object e) {
    if (e is ApiException) {
      if (e.code == 40207) {
        return '这个档案暂时不能用，请爸爸妈妈在小程序里换一个孩子';
      }
      return e.message;
    }
    final raw = e.toString();
    if (raw.startsWith('ApiException: ')) {
      return raw.substring('ApiException: '.length);
    }
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return '加载失败，请检查网络后重试';
  }

  Future<void> _handleSessionInvalid([ApiException? err]) async {
    final msg = (err != null && err.message.trim().isNotEmpty)
        ? err.message
        : '登录已失效，请重新输入暗号';
    await widget.onLogout(notice: msg);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        _api.fetchHomeSnapshot(),
        _api.getChildId(),
      ]);
      if (!mounted) return;
      setState(() {
        _snapshot = results[0] as HomeSnapshot;
        _childId = results[1] as int?;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is ApiException && e.isSessionInvalid) {
        setState(() => _loading = false);
        await _handleSessionInvalid(e);
        return;
      }
      setState(() {
        if (!silent || _snapshot == null) {
          _error = _friendlyError(e);
        }
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
          nickname: _snapshot?.todayBox.nickname,
          childId: _childId,
          durationMin: box.durationMin,
          initialMedia: revise ? box.media : const [],
        ),
      ),
    );
    if (!mounted || result == null) return;
    final message = result.revised
        ? '重新交出去啦'
        : (result.beans > 0
            ? '交出去啦，金豆 +${result.beans}'
            : '交出去啦，等家长看一看');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    _load();
  }

  void _onBoxTap(TodayBoxItem box) {
    if (!box.submitted) {
      if (box.quotaBlocked) {
        final tier = _snapshot?.todayBox.membershipTier ?? 'free';
        final limit = _snapshot?.todayBox.dailyCheckinTaskLimit ?? 3;
        final tip = kidQuotaBlockedTip(tier: tier, limit: limit);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tip)));
        return;
      }
      _openCheckin(box);
      return;
    }
    if (box.canRevise) {
      _openCheckin(box, revise: true);
      return;
    }
    final checkinId = box.checkinId;
    if (checkinId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('找不到这次拍照记录')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckinDetailPage(
          checkinId: checkinId,
          fallbackTitle: box.title,
          initialParentReview: box.parentReview,
          api: _api,
        ),
      ),
    );
  }

  void _openReport() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckinReportPage(api: _api),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckinHistoryPage(api: _api),
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
    ).then((_) {
      if (mounted) _load(silent: true);
    });
  }

  void _openHonorBadge() {
    final badge = _snapshot?.todayBox.honorBadge;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HonorBadgePage(
          api: _api,
          initial: badge,
        ),
      ),
    ).then((_) {
      if (mounted) _load(silent: true);
    });
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('要换一台设备吗？'),
        content: Text(
          '退出后要重新输入家长给的暗号。请让爸爸妈妈帮忙。',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.onLogout();
            },
            child: const Text(
              '换设备',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);
    final snapshot = _snapshot;
    final boxes = snapshot?.todayBox.boxes ?? [];
    final sections = groupTasksByStatus(boxes);
    final hasActionable =
        boxes.any((b) => !b.submitted || (b.canRevise && b.checkinStatus == 'rejected'));
    final total = snapshot?.todayBox.total ?? 0;
    final completed = snapshot?.todayBox.completed ?? 0;
    final progress = total == 0 ? 0.0 : completed / total;
    final allDone = total > 0 && !hasActionable;

    return Scaffold(
      body: AppScaffoldBackground(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.brand,
                onRefresh: _load,
                child: SafeArea(
                  child: AdaptiveBody(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 120),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.nunito(
                                      color: AppColors.inkMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
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
                                padding: EdgeInsets.only(
                                  bottom: tablet ? 24 : 12,
                                ),
                                children: [
                                  HomeTopBar(
                                    onLogout: _showLogoutDialog,
                                    updateInfo: _updateInfo,
                                    onUpdateTap: _onUpdateTap,
                                  ),
                                  const SizedBox(height: 18),
                                  if (snapshot != null) ...[
                                    HomeGreeting(
                                      nickname: snapshot.todayBox.nickname,
                                      tablet: tablet,
                                      honorBadge: snapshot.todayBox.honorBadge,
                                      onHonorTap: _openHonorBadge,
                                    ),
                                    const SizedBox(height: 18),
                                    TodayProgressPanel(
                                      progress: progress,
                                      completed: completed,
                                      total: total,
                                      streak: snapshot.todayBox.streak,
                                      beans: snapshot.todayBox.energyBeans,
                                      tablet: tablet,
                                      allDone: allDone,
                                      onBeansTap: () => _openBeanLedger(
                                        snapshot.todayBox.energyBeans,
                                      ),
                                      onHistoryTap: _openHistory,
                                      onReportTap: _openReport,
                                    ),
                                  ],
                                  if (allDone) ...[
                                    const SizedBox(height: 16),
                                    AllDoneCard(
                                      streak: snapshot?.todayBox.streak ?? 0,
                                    ),
                                  ],
                                  const SizedBox(height: 20),
                                  if (boxes.isEmpty)
                                    const EmptyTasksHint()
                                  else
                                    ...sections.expand(
                                      (section) => [
                                        SectionHeader(
                                          title: section.title,
                                          count: section.items.length,
                                          category: section.category,
                                        ),
                                        ...section.items.asMap().entries.map(
                                              (entry) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 12,
                                                ),
                                                child: TreasureBox(
                                                  title: entry.value.title,
                                                  taskType: entry.value.taskType,
                                                  category: section.category,
                                                  onTap: () =>
                                                      _onBoxTap(entry.value),
                                                  compact: tablet,
                                                  index: entry.key,
                                                ),
                                              ),
                                            ),
                                      ],
                                    ),
                                ],
                              ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
