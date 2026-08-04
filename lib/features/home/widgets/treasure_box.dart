import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/task_list_group.dart';
import '../../../theme/app_colors.dart';

class TreasureBox extends StatefulWidget {
  const TreasureBox({
    super.key,
    required this.title,
    required this.subtitle,
    required this.submitted,
    required this.canRevise,
    required this.category,
    required this.onTap,
    this.compact = false,
    this.index = 0,
  });

  final String title;
  final String subtitle;
  final bool submitted;
  final bool canRevise;
  final TaskCategory category;
  final VoidCallback onTap;
  final bool compact;
  final int index;

  @override
  State<TreasureBox> createState() => _TreasureBoxState();
}

class _TreasureBoxState extends State<TreasureBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: 380 + widget.index * 40),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void initState() {
    super.initState();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _chipLabel {
    switch (widget.category) {
      case TaskCategory.pending:
        return '待打卡';
      case TaskCategory.awaitingReview:
        return '待家长审核';
      case TaskCategory.rejected:
        return '需修订';
      case TaskCategory.completed:
        return '已完成';
    }
  }

  String get _footerTip {
    switch (widget.category) {
      case TaskCategory.pending:
        return '拍照或录视频上传，完成打卡';
      case TaskCategory.awaitingReview:
        return '家长审核通过后，打卡生效';
      case TaskCategory.rejected:
        return '根据家长意见修订后重新提交';
      case TaskCategory.completed:
        return '点击查看打卡详情';
    }
  }

  IconData get _chipIcon {
    switch (widget.category) {
      case TaskCategory.pending:
        return Icons.photo_camera_outlined;
      case TaskCategory.awaitingReview:
        return Icons.schedule_rounded;
      case TaskCategory.rejected:
        return Icons.replay_rounded;
      case TaskCategory.completed:
        return Icons.check_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color iconColor;
    final Color wash;
    switch (widget.category) {
      case TaskCategory.pending:
        icon = Icons.menu_book_rounded;
        iconColor = AppColors.brandDeep;
        wash = AppColors.brandSoft;
      case TaskCategory.awaitingReview:
        icon = Icons.hourglass_top_rounded;
        iconColor = AppColors.accentSun;
        wash = const Color(0xFFFFF4E8);
      case TaskCategory.rejected:
        icon = Icons.replay_rounded;
        iconColor = AppColors.danger;
        wash = const Color(0xFFFFF0F0);
      case TaskCategory.completed:
        icon = Icons.check_circle_rounded;
        iconColor = AppColors.success;
        wash = const Color(0xFFEEF8EE);
    }

    final chipBg = wash;
    final chipFg = iconColor;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: AppColors.brand.withValues(alpha: 0.1)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: widget.onTap,
            child: Padding(
              padding: EdgeInsets.all(widget.compact ? 20 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: widget.compact ? 58 : 52,
                        height: widget.compact ? 58 : 52,
                        decoration: BoxDecoration(
                          color: wash,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: widget.compact ? 28 : 26,
                          color: iconColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: GoogleFonts.nunito(
                                fontSize: widget.compact ? 20 : 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                                decoration:
                                    widget.category == TaskCategory.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                decorationColor: AppColors.inkFaint,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '建议每天完成',
                              style: GoogleFonts.nunito(
                                color: AppColors.inkMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: chipBg,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: chipFg.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_chipIcon, size: 14, color: chipFg),
                                  const SizedBox(width: 4),
                                  Text(
                                    _chipLabel,
                                    style: GoogleFonts.nunito(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: chipFg,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: widget.compact ? 26 : 22,
                        color: AppColors.inkFaint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _footerTip,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkFaint,
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
