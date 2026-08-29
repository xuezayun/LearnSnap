import 'package:flutter/material.dart';

import '../core/legal_links.dart';
import '../theme/app_colors.dart';

/// 隐私政策常驻入口（绑定页、首页菜单等复用）。
class LegalEntryLinks extends StatelessWidget {
  const LegalEntryLinks({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: compact ? 12 : 13,
      fontWeight: FontWeight.w700,
      color: AppColors.brandDeep,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton(
          onPressed: () => openPrivacyPolicy(context),
          child: Text('隐私政策', style: style),
        ),
        Text(
          '·',
          style: TextStyle(color: AppColors.inkFaint, fontSize: compact ? 12 : 13),
        ),
        TextButton(
          onPressed: () => openUserAgreement(context),
          child: Text('用户协议', style: style),
        ),
      ],
    );
  }
}
