import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_config.dart';
import '../../../theme/app_colors.dart';

class EmptyTasksHint extends StatelessWidget {
  const EmptyTasksHint({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 42,
            color: AppColors.brand.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 12),
          Text(
            '今天还没有任务',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '请家长在微信小程序「${AppConfig.miniprogramName}」为你分配习惯任务',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
