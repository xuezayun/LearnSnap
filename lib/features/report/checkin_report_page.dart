import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/device_layout.dart';
import '../../models/checkin_report.dart';
import '../../services/learn_snap_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/kid_style.dart';
import '../../widgets/app_scaffold_bg.dart';
import '../../widgets/child_name_badge.dart';
import '../beans/bean_ledger_page.dart';
import '../home/widgets/meta_pill.dart';

class CheckinReportPage extends StatefulWidget {
  const CheckinReportPage({super.key, this.api});

  final LearnSnapApi? api;

  @override
  State<CheckinReportPage> createState() => _CheckinReportPageState();
}

class _CheckinReportPageState extends State<CheckinReportPage> {
  late final LearnSnapApi _api = widget.api ?? LearnSnapApi();
  CheckinReport? _report;
  int? _childId;
  String _preset = '7d';
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
      final range = _rangeForPreset(_preset);
      final results = await Future.wait([
        _api.fetchCheckinReport(start: range.$1, end: range.$2),
        _api.getChildId(),
      ]);
      if (!mounted) return;
      setState(() {
        _report = results[0] as CheckinReport;
        _childId = results[1] as int?;
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

  (String, String) _rangeForPreset(String preset) {
    final end = DateTime.now();
    final days = preset == '7d' ? 7 : preset == '90d' ? 90 : 30;
    final start = end.subtract(Duration(days: days - 1));
    return (_formatDate(start), _formatDate(end));
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  void _onPresetTap(String preset) {
    if (preset == _preset) return;
    final report = _report;
    if (preset == '90d' && report != null && !report.isPlus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('看 90 天记录请爸爸妈妈开通会员')),
      );
      return;
    }
    setState(() => _preset = preset);
    _load();
  }

  void _openBeanLedger() {
    final report = _report;
    if (report == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BeanLedgerPage(
          api: _api,
          initialBalance: report.energyBeans,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);
    final padding = pagePadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('成长相册')),
      body: AppScaffoldBackground(
        child: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.all(padding),
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
                    padding: EdgeInsets.fromLTRB(padding, padding, padding, 32),
                    children: [
                      Row(
                        children: [
                          ChildNameBadge(
                            nickname: _report!.nickname,
                            childId: _childId,
                            size: tablet
                                ? ChildNameBadgeSize.lg
                                : ChildNameBadgeSize.md,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '的成长相册',
                              style: GoogleFonts.nunito(
                                fontSize: tablet ? 24 : 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_report!.stats.periodStart} ~ ${_report!.stats.periodEnd}',
                        style: GoogleFonts.nunito(
                          color: AppColors.inkMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.local_fire_department, size: 18),
                            label: Text('连续 ${_report!.streak} 天'),
                          ),
                          MetaPill(
                            icon: Icons.savings_rounded,
                            label: '${_report!.energyBeans} 金豆',
                            onTap: _openBeanLedger,
                            emphasize: true,
                            backgroundColor: AppColors.beanGold,
                            foregroundColor: const Color(0xFF5A3A00),
                            iconColor: const Color(0xFF5A3A00),
                            leading: const BeanGlyph(size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _PresetRow(
                        preset: _preset,
                        showNinety: _report!.isPlus,
                        onTap: _onPresetTap,
                      ),
                      const SizedBox(height: 16),
                      _StatsGrid(stats: _report!.stats, tablet: tablet),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: '每天拍了几次',
                        child: _report!.stats.totalCheckins == 0
                            ? const Text('这段时间还没有拍照记录', style: TextStyle(color: Colors.black54))
                            : _DailyBars(daily: _report!.stats.dailyCheckins),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: '习惯排行',
                        child: _report!.stats.topTasks.isEmpty
                            ? const Text('暂无数据', style: TextStyle(color: Colors.black54))
                            : Column(
                                children: _report!.stats.topTasks
                                    .map((task) => _TaskRow(task: task))
                                    .toList(),
                              ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: '爸爸妈妈说',
                        child: _RatingBreakdown(breakdown: _report!.stats.ratingBreakdown),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.preset,
    required this.showNinety,
    required this.onTap,
  });

  final String preset;
  final bool showNinety;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _PresetChip(label: '近7天', value: '7d', active: preset == '7d', onTap: onTap),
        _PresetChip(label: '近30天', value: '30d', active: preset == '30d', onTap: onTap),
        _PresetChip(
          label: '近90天',
          value: '90d',
          active: preset == '90d',
          onTap: onTap,
          locked: !showNinety,
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final String value;
  final bool active;
  final bool locked;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      label: Text(locked ? '$label · 会员' : label),
      selected: active,
      onSelected: (_) => onTap(value),
      selectedColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: active ? color : Colors.black87,
        fontWeight: active ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats, required this.tablet});

  final CheckinReportStats stats;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('拍了几次', '${stats.totalCheckins}'),
      ('获得金豆', '${stats.beansEarned}'),
      ('活跃天数', '${stats.activeDays}'),
      ('完成率', stats.completionRateText),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: tablet ? 2.2 : 1.8,
      children: items
          .map(
            (item) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: tablet ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(item.$1, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _DailyBars extends StatelessWidget {
  const _DailyBars({required this.daily});

  final List<DailyCheckin> daily;

  @override
  Widget build(BuildContext context) {
    final ordered = [...daily]..sort((a, b) => b.date.compareTo(a.date));
    final maxCount = ordered.fold<int>(0, (max, item) => item.count > max ? item.count : max);
    final color = Theme.of(context).colorScheme.primary;
    return Column(
      children: ordered.map((item) {
        final ratio = maxCount == 0 ? 0.0 : item.count / maxCount;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(item.shortLabel, style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio == 0 ? 0.02 : ratio,
                    minHeight: 14,
                    backgroundColor: color.withValues(alpha: 0.12),
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${item.count}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final TopTaskStat task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(task.title)),
          Text('${task.count} 次', style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}

class _RatingBreakdown extends StatelessWidget {
  const _RatingBreakdown({required this.breakdown});

  final Map<String, int> breakdown;

  static const _labels = {
    'excellent': '优秀',
    'pass': '通过',
    'encourage': '加油',
  };

  @override
  Widget build(BuildContext context) {
    final entries = _labels.entries
        .map((e) => MapEntry(e.value, breakdown[e.key] ?? 0))
        .where((e) => e.value > 0)
        .toList();
    if (entries.isEmpty) {
      return const Text('还没有爸爸妈妈的评价', style: TextStyle(color: Colors.black54));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries
          .map(
            (e) => Chip(
              label: Text('${e.key} ${e.value}'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          )
          .toList(),
    );
  }
}
