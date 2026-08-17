import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../models/honor_badge.dart';
import '../../../theme/app_colors.dart';
import '../../honor/honor_badge_strip.dart';

String homeGreetingPrefix() {
  final hour = DateTime.now().hour;
  if (hour < 12) return '早上好';
  if (hour < 18) return '下午好';
  return '晚上好';
}

class HomeGreeting extends StatelessWidget {
  const HomeGreeting({
    super.key,
    required this.nickname,
    this.tablet = false,
    this.honorBadge,
    this.onHonorTap,
  });

  final String nickname;
  final bool tablet;
  final HonorBadge? honorBadge;
  final VoidCallback? onHonorTap;

  @override
  Widget build(BuildContext context) {
    final name = nickname.trim().isEmpty ? '同学' : nickname.trim();
    final badge = honorBadge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${homeGreetingPrefix()}，$name！',
          style: GoogleFonts.nunito(
            fontSize: tablet ? 26 : 22,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            height: 1.2,
          ),
        ),
        if (badge != null) ...[
          const SizedBox(height: 8),
          HonorBadgeStrip(
            badge: badge,
            compact: true,
            onTap: onHonorTap,
          ),
        ],
        const SizedBox(height: 6),
        Text(
          '好习惯，从每一次坚持开始',
          style: GoogleFonts.nunito(
            fontSize: tablet ? 15 : 14,
            fontWeight: FontWeight.w600,
            color: AppColors.inkMuted,
          ),
        ),
      ],
    );
  }
}
