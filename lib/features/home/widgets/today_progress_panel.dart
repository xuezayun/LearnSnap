import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/kid_style.dart';
import 'meta_pill.dart';

class TodayProgressPanel extends StatelessWidget {
  const TodayProgressPanel({
    super.key,
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
    final statusLine = total == 0
        ? '今天暂无任务，先去玩一会儿吧'
        : allDone
            ? '宝箱打开啦，太棒了！'
            : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: tablet ? 14 : 12,
            vertical: tablet ? 8 : 6,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.beanGold.withValues(alpha: 0.55),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.beanGold.withValues(alpha: 0.28),
                offset: const Offset(0, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: total == 0
              ? Text(
                  '等家长布置任务哦',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkMuted,
                  ),
                )
              : _QuestSlots(
                  total: total,
                  completed: completed,
                ),
        ),
        if (statusLine != null || streak > 0) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (statusLine != null)
                Text(
                  statusLine,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              if (streak > 0)
                MetaPill(
                  icon: Icons.local_fire_department_rounded,
                  label: '连拍 $streak 天',
                  backgroundColor: AppColors.streakFireSoft,
                  foregroundColor: AppColors.streakFire,
                  iconColor: AppColors.streakFire,
                ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        _ShortcutBar(
          beans: beans,
          onBeansTap: onBeansTap,
          onUpcomingTap: onUpcomingTap,
          onHistoryTap: onHistoryTap,
          onReportTap: onReportTap,
        ),
      ],
    );
  }
}

class _ShortcutBar extends StatelessWidget {
  const _ShortcutBar({
    required this.beans,
    required this.onBeansTap,
    required this.onUpcomingTap,
    required this.onHistoryTap,
    required this.onReportTap,
  });

  final int beans;
  final VoidCallback onBeansTap;
  final VoidCallback onUpcomingTap;
  final VoidCallback onHistoryTap;
  final VoidCallback onReportTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          _BeanChip(beans: beans, onTap: onBeansTap),
          const _ShortcutDivider(),
          _ShortcutButton(label: '即将打卡', onTap: onUpcomingTap),
          const _ShortcutDivider(),
          _ShortcutButton(label: '打卡记录', onTap: onHistoryTap),
          const _ShortcutDivider(),
          _ShortcutButton(label: '成长相册', onTap: onReportTap),
        ],
      ),
    );
  }
}

class _BeanChip extends StatelessWidget {
  const _BeanChip({required this.beans, required this.onTap});

  final int beans;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF5A3A00);
    return Material(
      color: AppColors.beanGold,
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$beans',
                style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: ink,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              const BeanGlyph(size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutDivider extends StatelessWidget {
  const _ShortcutDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      color: AppColors.brand.withValues(alpha: 0.28),
    );
  }
}

class _ShortcutButton extends StatelessWidget {
  const _ShortcutButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppColors.brandDeep,
            ),
          ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < total; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            _Slot(filled: i < completed),
          ],
        ],
      ),
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
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: filled ? AppColors.beanGold : const Color(0xFFF3E6C8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: filled ? AppColors.beanGoldDeep : const Color(0xFFE0C98A),
          width: 1.5,
        ),
      ),
      child: filled
          ? const Icon(Icons.star_rounded, size: 13, color: Colors.white)
          : null,
    );
  }
}
