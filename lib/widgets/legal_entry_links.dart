import 'package:flutter/material.dart';

import '../core/legal_links.dart';
import '../theme/app_colors.dart';

/// 登录/绑定页底部：默认未勾选，协议名可点开。
class LegalConsentCheckbox extends StatelessWidget {
  const LegalConsentCheckbox({
    super.key,
    required this.agreed,
    required this.onChanged,
  });

  final bool agreed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.inkMuted,
      height: 1.4,
    );
    const linkStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      color: AppColors.brandDeep,
      height: 1.4,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Checkbox(
            value: agreed,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: (value) => onChanged(value ?? false),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('我已阅读并同意', style: bodyStyle),
                GestureDetector(
                  onTap: () => openPrivacyPolicy(context),
                  child: const Text('《隐私政策》', style: linkStyle),
                ),
                const Text('和', style: bodyStyle),
                GestureDetector(
                  onTap: () => openUserAgreement(context),
                  child: const Text('《用户协议》', style: linkStyle),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

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
