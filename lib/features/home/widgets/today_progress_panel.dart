import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/kid_style.dart';
import '../../../widgets/treasure_chest.dart';
import 'meta_pill.dart';

class TodayProgressPanel extends StatelessWidget {
  const TodayProgressPanel({
    super.key,
    required this.progress,
    required this.completed,
    required this.total,
    required this.streak,
    required this.beans,
    required this.tablet,
    required this.allDone,
    required this.onBeansTap,
    required this.onReportTap,
    required this.onHistoryTap,
    required this.onUpcomingTap,
  });

  final double progress;
  final int completed;
  final int total;
  final int streak;
  final int beans;
  final bool tablet;
  final bool allDone;
  final VoidCallback onBeansTap;
  final VoidCallback onReportTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onUpcomingTap;

  @override
  Widget build(BuildContext context) {
    final remaining = (total - completed).clamp(0, total);
    final statusLine = total == 0
        ? '今天暂无任务，先去玩一会儿吧'
        : allDone
            ? '宝箱打开啦，太棒了！'
            : remaining == 1
                ? '再拍 1 个就能打开宝箱'
                : '再拍 $remaining 个就能打开宝箱';

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(tablet ? 22 : 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.beanGold.withValues(alpha: 0.55),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.beanGold.withValues(alpha: 0.28),
                offset: const Offset(0, 6),
                blurRadius: 0,
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
                      statusLine,
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (total == 0)
                      Text(
                        '等家长布置任务哦',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.inkMuted,
                        ),
                      )
                    else if (total <= 8)
                      _QuestSlots(
                        total: total,
                        completed: completed,
                      )
                    else ...[
                      Text(
                        '已拍 $completed/$total',
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 14,
                          backgroundColor: AppColors.beanGoldSoft,
                          color: AppColors.beanGold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TreasureChestArt(
                size: tablet ? 104 : 92,
                open: allDone,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MetaPill(
              icon: Icons.savings_rounded,
              label: '$beans 金豆',
              onTap: onBeansTap,
              emphasize: true,
              backgroundColor: AppColors.beanGold,
              foregroundColor: const Color(0xFF5A3A00),
              iconColor: const Color(0xFF5A3A00),
              leading: const BeanGlyph(size: 18),
            ),
            if (streak > 0)
              MetaPill(
                icon: Icons.local_fire_department_rounded,
                label: '连拍 $streak 天',
                backgroundColor: AppColors.streakFireSoft,
                foregroundColor: AppColors.streakFire,
                iconColor: AppColors.streakFire,
              ),
            _LinkChip(label: '即将打卡', onTap: onUpcomingTap),
            _LinkChip(label: '打卡记录', onTap: onHistoryTap),
            _LinkChip(label: '成长相册', onTap: onReportTap),
          ],
        ),
      ],
    );
  }
}

class _LinkChip extends StatelessWidget {
  const _LinkChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.brandDeep,
        side: const BorderSide(color: AppColors.brand, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _QuestSlots extends StatelessWidget {
  const _QuestSlots({required this.total, required this.completed});

  final int total;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var i = 0; i < total; i++)
          _Slot(filled: i < completed),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: filled ? AppColors.beanGold : const Color(0xFFF3E6C8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: filled ? AppColors.beanGoldDeep : const Color(0xFFE0C98A),
          width: 1.5,
        ),
      ),
      child: filled
          ? const Icon(Icons.star_rounded, size: 16, color: Colors.white)
          : null,
    );
  }
}
