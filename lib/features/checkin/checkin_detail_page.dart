import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api_client.dart';
import '../../core/device_layout.dart';
import '../../core/media_url.dart';
import '../../models/checkin_media.dart';
import '../../models/child_checkin_detail.dart';
import '../../services/learn_snap_api.dart';
import '../../theme/app_colors.dart';
import '../../theme/kid_style.dart';
import '../../widgets/app_scaffold_bg.dart';
import '../../widgets/remote_checkin_image.dart';
import 'image_preview_page.dart';
import 'video_preview_page.dart';

class CheckinDetailPage extends StatefulWidget {
  const CheckinDetailPage({
    super.key,
    required this.checkinId,
    this.fallbackTitle = '打卡详情',
    this.initialParentReview,
    this.api,
  });

  final int checkinId;
  final String fallbackTitle;
  final ParentReviewSummary? initialParentReview;
  final LearnSnapApi? api;

  @override
  State<CheckinDetailPage> createState() => _CheckinDetailPageState();
}

class _CheckinDetailPageState extends State<CheckinDetailPage> {
  late final LearnSnapApi _api = widget.api ?? LearnSnapApi();
  ChildCheckinDetail? _detail;
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
      final detail = await _api.fetchCheckinDetail(widget.checkinId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '加载失败，请稍后重试';
        _loading = false;
      });
    }
  }

  void _openImage(CheckinMediaItem item) {
    final url = item.remoteUrl?.trim() ?? '';
    final mediaId = item.existingMediaId ?? 0;
    if (url.isEmpty && mediaId <= 0) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ImagePreviewPage(
          networkUrl: url.isEmpty ? null : url,
          mediaId: mediaId > 0 ? mediaId : null,
          objectKey: item.objectKey,
        ),
      ),
    );
  }

  void _openVideo(CheckinMediaItem item) {
    final url = item.remoteUrl?.trim() ?? '';
    final mediaId = item.existingMediaId ?? 0;
    if (url.isEmpty && mediaId <= 0) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VideoPreviewPage(
          networkUrl: url.isEmpty ? null : url,
          mediaId: mediaId > 0 ? mediaId : null,
          objectKey: item.objectKey,
          previewOnly: true,
        ),
      ),
    );
  }

  String _formatSubmittedAt(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.year}-$m-$d $h:$min';
  }

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);
    final padding = pagePadding(context);
    final detail = _detail;
    final taskName = () {
      final fromApi = detail?.title.trim() ?? '';
      if (fromApi.isNotEmpty) return fromApi;
      final fallback = widget.fallbackTitle.trim();
      if (fallback.isNotEmpty && fallback != '打卡详情') return fallback;
      return '习惯任务';
    }();
    final review = _resolveParentReview(
      detail?.parentReview,
      widget.initialParentReview,
    );
    final sectionTitleSize = tablet ? 18.0 : 16.0;
    final bodySize = tablet ? 16.0 : 14.0;

    return Scaffold(
      appBar: AppBar(title: const Text('我拍到的')),
      body: AppScaffoldBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? AdaptiveBody(
                    child: _ErrorState(message: _error!, onRetry: _load),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: AdaptiveBody(
                      padding: EdgeInsets.fromLTRB(
                        padding,
                        tablet ? 20 : 12,
                        padding,
                        tablet ? 40 : 28,
                      ),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '这一关',
                                  style: GoogleFonts.nunito(
                                    fontSize: tablet ? 14 : 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.inkMuted,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  taskName,
                                  style: GoogleFonts.nunito(
                                    fontSize: tablet ? 26 : 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                SizedBox(height: tablet ? 14 : 10),
                                _StatusChip(
                                  label: kidStatusLabel(
                                    status: detail!.status,
                                    fallback: detail.statusLabel.isNotEmpty
                                        ? detail.statusLabel
                                        : '过关啦',
                                  ),
                                  tone: _toneForStatus(detail.status),
                                ),
                                if (detail.submittedAt != null &&
                                    detail.submittedAt!.isNotEmpty) ...[
                                  SizedBox(height: tablet ? 12 : 10),
                                  Text(
                                    '拍于 ${_formatSubmittedAt(detail.submittedAt)}',
                                    style: GoogleFonts.nunito(
                                      color: AppColors.inkMuted,
                                      fontWeight: FontWeight.w600,
                                      fontSize: tablet ? 15 : 13,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: tablet ? 18 : 14),
                          _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '爸爸妈妈说',
                                  style: GoogleFonts.nunito(
                                    fontSize: sectionTitleSize,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (review == null) ...[
                                  Text(
                                    '家长还在看，再等一等',
                                    style: GoogleFonts.nunito(
                                      fontSize: bodySize,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    '他们说：${review.displayRatingLabel}',
                                    style: GoogleFonts.nunito(
                                      fontSize: tablet ? 18 : 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brandDeep,
                                    ),
                                  ),
                                  SizedBox(height: tablet ? 14 : 10),
                                  Text(
                                    '鼓励的话',
                                    style: GoogleFonts.nunito(
                                      fontSize: tablet ? 14 : 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.inkMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(tablet ? 16 : 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.brandSoft,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Text(
                                      review.comment.isNotEmpty
                                          ? review.comment
                                          : '这次已经看到你的努力啦',
                                      style: GoogleFonts.nunito(
                                        fontSize: bodySize,
                                        fontWeight: FontWeight.w700,
                                        color: review.comment.isNotEmpty
                                            ? AppColors.ink
                                            : AppColors.inkMuted,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                  if (review.bonusBeans > 0) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      '奖励金豆 +${review.bonusBeans}',
                                      style: GoogleFonts.nunito(
                                        fontSize: bodySize,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.brandDeep,
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                          if (detail.note.trim().isNotEmpty) ...[
                            SizedBox(height: tablet ? 18 : 14),
                            _SectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '我的备注',
                                    style: GoogleFonts.nunito(
                                      fontSize: sectionTitleSize,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    detail.note,
                                    style: GoogleFonts.nunito(
                                      fontSize: bodySize,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.ink,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          SizedBox(height: tablet ? 22 : 18),
                          Text(
                            '我拍的照片',
                            style: GoogleFonts.nunito(
                              fontSize: sectionTitleSize,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          SizedBox(height: tablet ? 14 : 10),
                          if (detail.media.isEmpty)
                            _SectionCard(
                              child: Text(
                                '还没有照片或视频',
                                style: GoogleFonts.nunito(
                                  color: AppColors.inkMuted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: bodySize,
                                ),
                              ),
                            )
                          else
                            _MediaGrid(
                              media: detail.media,
                              onOpenImage: _openImage,
                              onOpenVideo: _openVideo,
                            ),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

/// Prefer the review that actually carries 鼓励的话 (miniprogram comment).
ParentReviewSummary? _resolveParentReview(
  ParentReviewSummary? fromDetail,
  ParentReviewSummary? fromList,
) {
  if (fromDetail != null && fromDetail.comment.isNotEmpty) return fromDetail;
  if (fromList != null && fromList.comment.isNotEmpty) return fromList;
  return fromDetail ?? fromList;
}

enum _ChipTone { success, warn, muted, danger }

_ChipTone _toneForStatus(String status) {
  switch (status) {
    case 'approved':
      return _ChipTone.success;
    case 'encourage':
      return _ChipTone.warn;
    case 'rejected':
      return _ChipTone.danger;
    default:
      return _ChipTone.muted;
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.tone});

  final String label;
  final _ChipTone tone;

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);
    final Color bg;
    final Color fg;
    switch (tone) {
      case _ChipTone.success:
        bg = AppColors.brandSoft;
        fg = AppColors.brandDeep;
      case _ChipTone.warn:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
      case _ChipTone.danger:
        bg = const Color(0xFFFFEBEE);
        fg = AppColors.danger;
      case _ChipTone.muted:
        bg = const Color(0xFFF0F3F5);
        fg = AppColors.inkMuted;
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tablet ? 14 : 12,
        vertical: tablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontSize: tablet ? 15 : 13,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tablet ? 22 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(tablet ? 24 : 20),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.1)),
      ),
      child: child,
    );
  }
}

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({
    required this.media,
    required this.onOpenImage,
    required this.onOpenVideo,
  });

  final List<CheckinMediaItem> media;
  final ValueChanged<CheckinMediaItem> onOpenImage;
  final ValueChanged<CheckinMediaItem> onOpenVideo;

  @override
  Widget build(BuildContext context) {
    final size = mediaThumbSize(context);
    final gap = isTablet(context) ? 16.0 : 10.0;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final item in media)
          _MediaTile(
            item: item,
            size: size,
            onTap: () {
              if (item.isVideo) {
                onOpenVideo(item);
              } else {
                onOpenImage(item);
              }
            },
          ),
      ],
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.item,
    required this.size,
    required this.onTap,
  });

  final CheckinMediaItem item;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = item.remoteUrl?.trim() ?? '';
    final playIconSize = isTablet(context) ? 48.0 : 40.0;
    final radius = isTablet(context) ? 18.0 : 14.0;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: size,
          height: size,
          child: item.isVideo
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    if (url.isNotEmpty)
                      Image.network(
                        resolveMediaUrl(url),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: const Color(0xFF1A1A2E),
                        ),
                      )
                    else
                      Container(color: const Color(0xFF1A1A2E)),
                    Container(color: Colors.black38),
                    Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        color: Colors.white,
                        size: playIconSize,
                      ),
                    ),
                  ],
                )
              : (url.isEmpty && (item.existingMediaId == null || item.existingMediaId! <= 0))
                  ? Container(
                      color: const Color(0xFFE8ECF0),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.image_outlined,
                        size: isTablet(context) ? 36 : 28,
                      ),
                    )
                  : RemoteCheckinImage(
                      mediaId: item.existingMediaId,
                      objectKey: item.objectKey,
                      url: url.isEmpty ? null : url,
                      fit: BoxFit.cover,
                      error: Container(
                        color: const Color(0xFFE8ECF0),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: isTablet(context) ? 36 : 28,
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final tablet = isTablet(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(pagePadding(context)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(
                color: AppColors.inkMuted,
                fontWeight: FontWeight.w600,
                fontSize: tablet ? 17 : 15,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: primaryButtonHeight(context),
              child: FilledButton(
                onPressed: onRetry,
                child: Text(
                  '重试',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w800,
                    fontSize: tablet ? 17 : 15,
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
