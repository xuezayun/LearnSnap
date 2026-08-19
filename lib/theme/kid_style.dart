import 'package:flutter/material.dart';

import '../models/task_list_group.dart';
import 'app_colors.dart';

/// Color + icon for a habit task type (child-facing quest card).
class TaskTypeLook {
  const TaskTypeLook({
    required this.color,
    required this.wash,
    required this.icon,
    required this.label,
  });

  final Color color;
  final Color wash;
  final IconData icon;
  final String label;
}

TaskTypeLook lookForTaskType(String type) {
  switch (type) {
    case 'reading':
      return const TaskTypeLook(
        color: AppColors.subjectRead,
        wash: Color(0xFFFFF1E6),
        icon: Icons.auto_stories_rounded,
        label: '阅读',
      );
    case 'english_read':
      return const TaskTypeLook(
        color: AppColors.subjectRead,
        wash: Color(0xFFFFF1E6),
        icon: Icons.headphones_rounded,
        label: '英语',
      );
    case 'recitation':
      return const TaskTypeLook(
        color: AppColors.subjectRead,
        wash: Color(0xFFFFF1E6),
        icon: Icons.record_voice_over_rounded,
        label: '背诵',
      );
    case 'handwriting':
      return const TaskTypeLook(
        color: AppColors.subjectWrite,
        wash: Color(0xFFE8F3FF),
        icon: Icons.edit_rounded,
        label: '写字',
      );
    case 'diary':
      return const TaskTypeLook(
        color: AppColors.subjectWrite,
        wash: Color(0xFFE8F3FF),
        icon: Icons.edit_note_rounded,
        label: '日记',
      );
    case 'posture':
      return const TaskTypeLook(
        color: AppColors.subjectWrite,
        wash: Color(0xFFE8F3FF),
        icon: Icons.accessibility_new_rounded,
        label: '坐姿',
      );
    case 'oral_calc':
      return const TaskTypeLook(
        color: AppColors.subjectMath,
        wash: Color(0xFFF0ECFF),
        icon: Icons.calculate_rounded,
        label: '口算',
      );
    case 'mistake_book':
      return const TaskTypeLook(
        color: AppColors.subjectMath,
        wash: Color(0xFFF0ECFF),
        icon: Icons.fact_check_rounded,
        label: '错题',
      );
    case 'exercise':
      return const TaskTypeLook(
        color: AppColors.subjectSport,
        wash: Color(0xFFE6F9EC),
        icon: Icons.sports_soccer_rounded,
        label: '运动',
      );
    case 'coding':
      return const TaskTypeLook(
        color: AppColors.subjectCode,
        wash: Color(0xFFFFEEF2),
        icon: Icons.smart_toy_rounded,
        label: '编程',
      );
    case 'labor':
    case 'life':
      return const TaskTypeLook(
        color: AppColors.subjectLife,
        wash: Color(0xFFFFF4E8),
        icon: Icons.home_rounded,
        label: '家务',
      );
    case 'preview':
      return const TaskTypeLook(
        color: AppColors.brandDeep,
        wash: AppColors.brandSoft,
        icon: Icons.visibility_rounded,
        label: '预习',
      );
    case 'study':
    default:
      return const TaskTypeLook(
        color: AppColors.brandDeep,
        wash: AppColors.brandSoft,
        icon: Icons.school_rounded,
        label: '学习',
      );
  }
}

String kidSectionTitle(TaskCategory category) {
  switch (category) {
    case TaskCategory.pending:
      return '还没拍';
    case TaskCategory.awaitingReview:
      return '等家长看';
    case TaskCategory.rejected:
      return '再拍一次会更好';
    case TaskCategory.completed:
      return '过关啦';
  }
}

String kidChipLabel(TaskCategory category) {
  switch (category) {
    case TaskCategory.pending:
      return '还没拍';
    case TaskCategory.awaitingReview:
      return '等家长看';
    case TaskCategory.rejected:
      return '再试试';
    case TaskCategory.completed:
      return '过关啦';
  }
}

String kidCtaLabel(TaskCategory category) {
  switch (category) {
    case TaskCategory.pending:
      return '去拍照';
    case TaskCategory.awaitingReview:
      return '看看进度';
    case TaskCategory.rejected:
      return '再拍一次';
    case TaskCategory.completed:
      return '看看表扬';
  }
}

String kidStatusLabel({required String status, String fallback = ''}) {
  switch (status) {
    case 'approved':
      return '过关啦';
    case 'encourage':
      return '家长给你加油啦';
    case 'rejected':
      return '再拍一次会更好';
    case 'pending_review':
    case 'submitted':
    case 'ai_processing':
      return '等家长看';
    default:
      break;
  }
  if (fallback.contains('驳回')) return '再拍一次会更好';
  if (fallback.contains('待家长') || fallback.contains('已提交') || fallback.contains('处理中')) {
    return '等家长看';
  }
  if (fallback.contains('通过') || fallback.contains('完成')) return '过关啦';
  if (fallback.contains('鼓励')) return '家长给你加油啦';
  return fallback.isNotEmpty ? fallback : '进行中';
}

String kidQuotaBlockedTip({required String tier, required int limit}) {
  if (tier == 'free') {
    return '今天的免费次数用完啦，请爸爸妈妈开一下 Plus';
  }
  if (tier == 'plus') {
    return '今天拍的次数用完啦，请爸爸妈妈升级到 Pro';
  }
  return '今天拍的次数已经满了（$limit 个），明天再来吧';
}

/// Gold “豆” glyph used for energy beans.
class BeanGlyph extends StatelessWidget {
  const BeanGlyph({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFE08A),
            AppColors.beanGold,
            AppColors.beanGoldDeep,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.beanGoldDeep.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '豆',
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}
