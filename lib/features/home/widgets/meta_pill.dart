import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_colors.dart';

class MetaPill extends StatelessWidget {
  const MetaPill({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.emphasize = false,
    this.backgroundColor,
    this.foregroundColor,
    this.iconColor,
    this.leading,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool emphasize;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? iconColor;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final tappable = onTap != null;
    late final Color bg;
    late final Color fg;
    late final Color iconFg;

    if (backgroundColor != null && foregroundColor != null) {
      bg = backgroundColor!;
      fg = foregroundColor!;
      iconFg = iconColor ?? foregroundColor!;
    } else if (tappable && emphasize) {
      bg = AppColors.brand;
      fg = Colors.white;
      iconFg = Colors.white;
    } else {
      bg = AppColors.brandSoft;
      fg = AppColors.brandDeep;
      iconFg = AppColors.brandDeep;
    }

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading ?? Icon(icon, size: 16, color: iconFg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ),
          if (tappable) ...[
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, size: 16, color: fg),
          ],
        ],
      ),
    );

    if (!tappable) {
      return Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: content,
      );
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: content,
      ),
    );
  }
}
