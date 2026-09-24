import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/privacy_consent_store.dart';

void main() {
  test('privacy consent is stored by policy version', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PrivacyConsentStore();
    expect(await store.hasAgreed(), isFalse);
    await store.agree();
    expect(await store.hasAgreed(), isTrue);
  });
}
