import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_config.dart';
import '../../../models/client_version.dart';
import '../../../theme/app_colors.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.onLogout,
    this.updateInfo,
    this.onUpdateTap,
    this.showReviewTools = false,
    this.onReviewToolsTap,
  });

  final VoidCallback onLogout;
  final ClientVersionInfo? updateInfo;
  final VoidCallback? onUpdateTap;
  final bool showReviewTools;
  final VoidCallback? onReviewToolsTap;

  @override
  Widget build(BuildContext context) {
    final showUpdate = updateInfo?.updateAvailable == true;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.photo_camera_rounded,
            color: AppColors.brandDeep,
            size: 24,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          AppConfig.appName,
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.brandDeep,
            letterSpacing: -0.4,
          ),
        ),
        const Spacer(),
        if (showUpdate) ...[
          _RoundIconButton(
            tooltip: updateInfo?.title.isNotEmpty == true
                ? updateInfo!.title
                : '有新版本',
            onTap: onUpdateTap,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.system_update_rounded,
                  color: AppColors.brandDeep,
                  size: 22,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
        PopupMenuButton<String>(
          tooltip: '更多',
          offset: const Offset(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) {
            if (value == 'review') onReviewToolsTap?.call();
            if (value == 'rebind') onLogout();
          },
          itemBuilder: (context) => [
            if (showReviewTools)
              const PopupMenuItem(
                value: 'review',
                child: Text('审核助手'),
              ),
            const PopupMenuItem(
              value: 'rebind',
              child: Text('换一台设备'),
            ),
          ],
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.more_horiz_rounded,
              color: AppColors.brandDeep,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.child,
    required this.onTap,
    required this.tooltip,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.brandSoft,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 44, height: 44, child: child),
        ),
      ),
    );
  }
}
