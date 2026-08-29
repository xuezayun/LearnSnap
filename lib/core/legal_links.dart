import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'app_config.dart';

Future<void> openLegalUrl(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (ok || !context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('无法打开页面，请稍后重试')),
  );
}

Future<void> openPrivacyPolicy(BuildContext context) {
  return openLegalUrl(context, AppConfig.privacyPolicyUrl);
}

Future<void> openUserAgreement(BuildContext context) {
  return openLegalUrl(context, AppConfig.userAgreementUrl);
}
