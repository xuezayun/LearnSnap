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
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.brand.withValues(alpha: 0.18), width: 2),
      ),
      child: Column(
        children: [
          const Text('🐣', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            '今天还没有冒险',
            style: GoogleFonts.nunito(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请爸爸妈妈在微信小程序「${AppConfig.miniprogramName}」给你布置一个小任务吧',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              color: AppColors.inkMuted,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
