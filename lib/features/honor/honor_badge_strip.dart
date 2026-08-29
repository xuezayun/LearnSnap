import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/honor_badge.dart';
import '../../theme/app_colors.dart';
import 'honor_badge_icons.dart';

class HonorBadgeStrip extends StatelessWidget {
  const HonorBadgeStrip({
    super.key,
    required this.badge,
    this.onTap,
    this.compact = false,
    this.glyphSize,
  });

  final HonorBadge badge;
  final VoidCallback? onTap;
  final bool compact;
  final double? glyphSize;

  @override
  Widget build(BuildContext context) {
    final icons = badge.display;
    final child = icons.isEmpty
        ? Text(
            compact ? '还没有奖杯' : '还没有奖杯，去点亮一颗星吧',
            style: GoogleFonts.nunito(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: AppColors.inkMuted,
            ),
          )
        : Wrap(
            spacing: (glyphSize ?? 26) >= 34 ? 10 : 4,
            runSpacing: (glyphSize ?? 26) >= 34 ? 10 : 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final icon in icons)
                _HonorIconChip(
                  icon: icon,
                  compact: compact,
                  glyphSize: glyphSize,
                ),
            ],
          );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: child,
      ),
    );
  }
}

class _HonorIconChip extends StatelessWidget {
  const _HonorIconChip({
    required this.icon,
    required this.compact,
    this.glyphSize,
  });

  final HonorBadgeIcon icon;
  final bool compact;
  final double? glyphSize;

  @override
  Widget build(BuildContext context) {
    final color = switch (icon.type) {
      'sun' => AppColors.accentSun,
      'moon' => const Color(0xFF7B8CDE),
      _ => const Color(0xFFF5C542),
    };
    final size = glyphSize ?? (compact ? 20.0 : 26.0);
    final bump = size >= 34;
    if (icon.count > 1) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: bump ? 10 : 6,
          vertical: bump ? 6 : 3,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HonorBadgeGlyph(type: icon.type, size: size),
            SizedBox(width: bump ? 4 : 2),
            Text(
              '×${icon.count}',
              style: GoogleFonts.nunito(
                fontSize: bump ? 16 : (compact ? 12 : 14),
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      );
    }
    return HonorBadgeGlyph(type: icon.type, size: size);
  }
}
