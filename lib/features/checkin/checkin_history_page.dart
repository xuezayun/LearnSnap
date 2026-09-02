import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/device_layout.dart';
import '../../models/checkin_history.dart';
import '../../services/learn_snap_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/kid_style.dart';
import '../../widgets/app_scaffold_bg.dart';
import '../../widgets/remote_checkin_image.dart';
import 'checkin_detail_page.dart';

class CheckinHistoryPage extends StatefulWidget {
  const CheckinHistoryPage({super.key, this.api});

  final LearnSnapApi? api;

  @override
  State<CheckinHistoryPage> createState() => _CheckinHistoryPageState();
}

class _CheckinHistoryPageState extends State<CheckinHistoryPage> {
  late final LearnSnapApi _api = widget.api ?? LearnSnapApi();
  final List<CheckinHistoryItem> _items = [];
  int _page = 1;
  bool _hasMore = true;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
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
      final result = await _api.fetchCheckinHistory(page: _page);
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items
            ..clear()
            ..addAll(result.items);
        } else {
          _items.addAll(result.items);
        }
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

  void _openDetail(CheckinHistoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckinDetailPage(
          checkinId: item.id,
          fallbackTitle: item.title.isNotEmpty ? item.title : '我拍到的',
          api: _api,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = pagePadding(context);

    return Scaffold(
      appBar: AppBar(title: const Text('打卡记录')),
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
                        if (_items.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '还没有打卡记录，去拍一张吧',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.nunito(
                                color: AppColors.inkMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else ...[
                          ..._items.map(
                            (item) => _HistoryTile(
                              item: item,
                              onTap: () => _openDetail(item),
                            ),
                          ),
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.item, required this.onTap});

  final CheckinHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusText = kidStatusLabel(
      status: item.status,
      fallback: item.statusLabel,
    );
    final look = lookForTaskType(item.taskType);

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
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: item.hasImageCover
                      ? RemoteCheckinImage(
                          mediaId: item.coverMediaId,
                          fit: BoxFit.cover,
                        )
                      : ColoredBox(
                          color: look.wash,
                          child: Icon(
                            item.coverMediaType == 'video'
                                ? Icons.videocam_rounded
                                : look.icon,
                            color: look.color,
                            size: 28,
                          ),
                        ),
                ),
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
                      formatKidCheckinTime(item.submittedAt),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
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
                        statusText,
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: look.color,
                        ),
                      ),
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

String formatKidCheckinTime(String? iso) {
  if (iso == null || iso.isEmpty) return '';
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) {
    if (iso.length < 16) return iso;
    return iso.substring(0, 16).replaceFirst('T', ' ');
  }
  final local = parsed.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final hm =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  if (day == today) return '今天 $hm';
  if (day == today.subtract(const Duration(days: 1))) return '昨天 $hm';
  return '${local.month}月${local.day}日 $hm';
}
