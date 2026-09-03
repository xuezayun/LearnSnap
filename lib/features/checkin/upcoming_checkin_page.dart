import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/device_layout.dart';
import '../../models/home_snapshot.dart';
import '../../services/learn_snap_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/kid_style.dart';
import '../../widgets/app_scaffold_bg.dart';

class UpcomingCheckinPage extends StatefulWidget {
  const UpcomingCheckinPage({super.key, this.api});

  final LearnSnapApi? api;

  @override
  State<UpcomingCheckinPage> createState() => _UpcomingCheckinPageState();
}

class _UpcomingCheckinPageState extends State<UpcomingCheckinPage> {
  late final LearnSnapApi _api = widget.api ?? LearnSnapApi();
  List<TodayBoxItem> _items = [];
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
        _items = snapshot.todayBox.upcoming;
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

  void _onTap(TodayBoxItem box) {
    final when = box.nextDueLabel.isNotEmpty ? box.nextDueLabel : '那天';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('到$when再来拍吧')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = pagePadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('即将打卡')),
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
                      padding: EdgeInsets.fromLTRB(padding, padding, padding, 32),
                      children: [
                        if (_items.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '最近几天没有要打的卡',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                color: AppColors.inkMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          ..._items.map(
                            (item) => _UpcomingTile(
                              item: item,
                              onTap: () => _onTap(item),
                            ),
                          ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({required this.item, required this.onTap});

  final TodayBoxItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final look = lookForTaskType(item.taskType);
    final when = item.nextDueLabel.isNotEmpty ? '到${item.nextDueLabel}再拍' : '还没到打卡日';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: look.wash,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(look.icon, color: look.color, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title.isNotEmpty ? item.title : '习惯任务',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      when,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: look.wash,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '还没到',
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: look.color,
                            ),
                          ),
                        ),
                        if (item.repeatLabel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: look.wash,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              item.repeatLabel,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: look.color,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
