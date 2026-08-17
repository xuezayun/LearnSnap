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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.brandSoft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.photo_camera_rounded,
            color: AppColors.brandDeep,
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          AppConfig.appName,
          style: GoogleFonts.nunito(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.brandDeep,
            letterSpacing: -0.4,
          ),
        ),
        const Spacer(),
        if (showReviewTools) ...[
          Tooltip(
            message: '审核助手',
            child: Material(
              color: AppColors.brandSoft,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onReviewToolsTap,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.fact_check_rounded,
                    color: AppColors.brandDeep,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (showUpdate) ...[
          Tooltip(
            message: updateInfo?.title.isNotEmpty == true
                ? updateInfo!.title
                : '有新版本',
            child: Material(
              color: AppColors.brandSoft,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onUpdateTap,
                child: SizedBox(
                  width: 40,
                  height: 40,
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
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Tooltip(
          message: '重新绑定',
          child: Material(
            color: AppColors.brandSoft,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onLogout,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.brand.withValues(alpha: 0.45),
                  ),
                ),
                child: const Icon(
                  Icons.link_off_rounded,
                  color: AppColors.brandDeep,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
