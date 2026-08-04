import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import 'meta_pill.dart';

class TodayProgressPanel extends StatelessWidget {
  const TodayProgressPanel({
    super.key,
    required this.progress,
    required this.completed,
    required this.total,
    required this.streak,
    required this.beans,
    required this.membershipLabel,
    required this.isPlus,
    required this.tablet,
    required this.allDone,
    required this.onBeansTap,
    required this.onReportTap,
  });

  final double progress;
  final int completed;
  final int total;
  final int streak;
  final int beans;
  final String membershipLabel;
  final bool isPlus;
  final bool tablet;
  final bool allDone;
  final VoidCallback onBeansTap;
  final VoidCallback onReportTap;

  @override
  Widget build(BuildContext context) {
    final remaining = (total - completed).clamp(0, total);
    final statusLine = total == 0
        ? '今天暂无任务，先休息一下吧'
        : allDone
            ? '宝箱已解锁，太棒了！'
            : '再完成 $remaining 项，可打开宝箱';

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(tablet ? 22 : 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.brand.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '今日宝箱',
                      style: GoogleFonts.nunito(
                        fontSize: tablet ? 22 : 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandDeep,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '坚持打卡，解锁惊喜奖励！',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      total == 0 ? '今日暂无任务' : '已完成 $completed/$total',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : progress.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: AppColors.brandSoft,
                        color: AppColors.brand,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      statusLine,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandDeep,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _TreasureChestArt(size: tablet ? 100 : 88),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            MetaPill(
              icon: Icons.military_tech_rounded,
              label: membershipLabel,
              backgroundColor: isPlus
                  ? const Color(0xFFFFF3D0)
                  : const Color(0xFFE8EEF5),
              foregroundColor: isPlus
                  ? const Color(0xFF8A6508)
                  : AppColors.ink,
              iconColor: isPlus
                  ? const Color(0xFFE0A800)
                  : const Color(0xFF9AA8B5),
            ),
            const SizedBox(width: 8),
            MetaPill(
              icon: Icons.bolt_rounded,
              label: '$beans 乐豆',
              onTap: onBeansTap,
              emphasize: true,
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: onReportTap,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.brandDeep,
                side: const BorderSide(color: AppColors.brand),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.insights_rounded, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '报告',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ),
          ],
        ),
        if (streak > 0) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '连续打卡 $streak 天',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.inkFaint,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Decorative progress illustration — intentionally not tappable.
class _TreasureChestArt extends StatelessWidget {
  const _TreasureChestArt({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.brandSoft.withValues(alpha: 0.9),
                AppColors.brandSoft.withValues(alpha: 0.25),
                Colors.transparent,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.inventory_2_rounded,
              size: size * 0.42,
              color: AppColors.brand.withValues(alpha: 0.55),
            ),
          ),
        ),
        Text(
          '进度示意',
          style: GoogleFonts.nunito(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.inkFaint,
          ),
        ),
      ],
    );
  }
}
