import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/device_layout.dart';
import '../../models/bean_ledger.dart';
import '../../models/honor_badge.dart';
import '../../services/learn_snap_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/kid_style.dart';
import '../../widgets/app_scaffold_bg.dart';
import '../../widgets/child_name_badge.dart';
import '../honor/honor_badge_page.dart';
import '../honor/honor_badge_strip.dart';

class BeanLedgerPage extends StatefulWidget {
  const BeanLedgerPage({super.key, this.api, this.initialBalance});

  final LearnSnapApi? api;
  final int? initialBalance;

  @override
  State<BeanLedgerPage> createState() => _BeanLedgerPageState();
}

class _BeanLedgerPageState extends State<BeanLedgerPage> {
  late final LearnSnapApi _api = widget.api ?? LearnSnapApi();
  final List<BeanLedgerEntry> _items = [];
  int _balance = 0;
  String _nickname = '同学';
  int? _childId;
  HonorBadge _honorBadge = HonorBadge.empty();
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialBalance != null) {
      _balance = widget.initialBalance!;
    }
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
        _page = 1;
        _hasMore = true;
      });
    } else {
      if (_loadingMore || !_hasMore) return;
      setState(() => _loadingMore = true);
    }

    try {
      final result = await _api.fetchBeanLedger(page: _page);
      final childId = reset ? await _api.getChildId() : _childId;
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(result.items);
          _childId = childId;
        } else {
          _items.addAll(result.items);
        }
        _balance = result.balance;
        _nickname = result.nickname;
        _honorBadge = result.honorBadge;
        _hasMore = result.hasMore;
        _page = result.page + 1;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  String _formatTime(String iso) {
    if (iso.length < 16) return iso;
    return iso.substring(0, 16).replaceFirst('T', ' ');
  }

  @override
  Widget build(BuildContext context) {
    final padding = pagePadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('我的金豆')),
      body: AppScaffoldBackground(
        child: RefreshIndicator(
        onRefresh: () => _load(reset: true),
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
                          onPressed: () => _load(reset: true),
                          child: const Text('重试'),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(padding, padding, padding, 32),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.brand.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          children: [
                              ChildNameBadge(
                                nickname: _nickname,
                                childId: _childId,
                                size: ChildNameBadgeSize.md,
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const BeanGlyph(size: 34),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$_balance',
                                    style: GoogleFonts.nunito(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.beanGoldDeep,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '金豆',
                                    style: GoogleFonts.nunito(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ),
                      const SizedBox(height: 12),
                      Material(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => HonorBadgePage(
                                  api: _api,
                                  initial: _honorBadge,
                                ),
                              ),
                            );
                            if (mounted) _load(reset: true);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.accentSun.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '我的奖杯',
                                      style: GoogleFonts.nunito(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '去点亮 ›',
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.brandDeep,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                HonorBadgeStrip(badge: _honorBadge, compact: true),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_items.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                              '还没有金豆记录，去拍照就能赚到哦',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                color: AppColors.inkMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        )
                      else ...[
                        ..._items.map((entry) => _LedgerTile(
                              entry: entry,
                              timeText: _formatTime(entry.createdAt),
                            )),
                        if (_hasMore)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Center(
                              child: _loadingMore
                                  ? const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: CircularProgressIndicator(),
                                    )
                                  : TextButton(
                                      onPressed: () => _load(),
                                      child: const Text('加载更多'),
                                    ),
                            ),
                          ),
                      ],
                    ],
                  ),
        ),
      ),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry, required this.timeText});

  final BeanLedgerEntry entry;
  final String timeText;

  @override
  Widget build(BuildContext context) {
    final income = entry.isIncome;
    final amountColor = income ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(entry.displayTitle),
        subtitle: Text(
          '${entry.entryLabel} · $timeText',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              entry.amountText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: amountColor,
                fontSize: 16,
              ),
            ),
            Text(
              '余额 ${entry.balanceAfter}',
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }
}
