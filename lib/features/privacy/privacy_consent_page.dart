import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_config.dart';
import '../../core/legal_links.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_scaffold_bg.dart';

/// 首次启动隐私弹窗：必须点「同意」或「拒绝」，点背景或返回键不能关闭。
class PrivacyConsentPage extends StatefulWidget {
  const PrivacyConsentPage({super.key, required this.onAgree});

  final Future<void> Function() onAgree;

  @override
  State<PrivacyConsentPage> createState() => _PrivacyConsentPageState();
}

class _PrivacyConsentPageState extends State<PrivacyConsentPage> {
  bool _agreeing = false;

  Future<void> _reject() async {
    await SystemNavigator.pop();
    exit(0);
  }

  Future<void> _agree() async {
    if (_agreeing) return;
    setState(() => _agreeing = true);
    try {
      await widget.onAgree();
    } finally {
      if (mounted) setState(() => _agreeing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bodyStyle = TextStyle(
      fontSize: 15,
      height: 1.55,
      color: AppColors.inkMuted,
    );
    final linkStyle = bodyStyle.copyWith(
      color: AppColors.brandDeep,
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: AppColors.brandDeep.withValues(alpha: 0.45),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AppScaffoldBackground(
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Material(
                    color: Colors.white,
                    elevation: 8,
                    shadowColor: AppColors.ink.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            '用户协议与隐私政策',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text.rich(
                            TextSpan(
                              style: bodyStyle,
                              children: [
                                TextSpan(
                                  text:
                                      '欢迎使用${AppConfig.appName}。请充分阅读并理解',
                                ),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: GestureDetector(
                                    onTap: () => openUserAgreement(context),
                                    child: Text('《用户协议》', style: linkStyle),
                                  ),
                                ),
                                const TextSpan(text: '和'),
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.baseline,
                                  baseline: TextBaseline.alphabetic,
                                  child: GestureDetector(
                                    onTap: () => openPrivacyPolicy(context),
                                    child: Text('《隐私政策》', style: linkStyle),
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      '。我们将按政策说明收集、使用设备标识、相册/相机、剪切板（仅在您粘贴绑定时）等信息。点击「同意」后开始使用；点击「拒绝」将退出应用。',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _agreeing ? null : _reject,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.inkMuted,
                                    side: const BorderSide(
                                      color: Color(0xFFD7DEE0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text('拒绝'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: _agreeing ? null : _agree,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _agreeing
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('同意'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
