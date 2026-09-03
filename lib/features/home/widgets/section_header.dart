import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/task_list_group.dart';
import '../../../theme/app_colors.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.count,
    required this.category,
  });

  final String title;
  final int count;
  final TaskCategory category;

  Color get _tone {
    switch (category) {
      case TaskCategory.pending:
        return AppColors.brandDeep;
      case TaskCategory.awaitingReview:
        return AppColors.accentSun;
      case TaskCategory.rejected:
        return AppColors.danger;
      case TaskCategory.completed:
        return AppColors.success;
      case TaskCategory.upcoming:
        return AppColors.inkMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: _tone,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _tone,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
