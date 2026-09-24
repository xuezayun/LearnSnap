import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/device_layout.dart';
import 'package:app/features/bind/bind_page.dart';
import 'package:app/features/privacy/privacy_consent_page.dart';

void main() {
  Future<void> setPhoneSize(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> setTabletSize(WidgetTester tester) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('isTablet is true for iPad-sized screens', (tester) async {
    await setTabletSize(tester);

    var tablet = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            tablet = isTablet(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(tablet, isTrue);
  });

  testWidgets('isTablet is false for phone-sized screens', (tester) async {
    await setPhoneSize(tester);

    var tablet = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            tablet = isTablet(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(tablet, isFalse);
  });

  testWidgets('mediaGridColumnCount increases on tablet width', (tester) async {
    await setTabletSize(tester);

    var columns = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            columns = mediaGridColumnCount(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(columns, greaterThanOrEqualTo(3));
  });

  testWidgets('bind page uses adaptive layout on tablet', (tester) async {
    await setTabletSize(tester);

    await tester.pumpWidget(
      MaterialApp(
        home: BindPage(onBound: () {}),
      ),
    );
    expect(find.textContaining('暗号'), findsWidgets);
    expect(find.text('开始探险'), findsOneWidget);
    expect(find.text('隐私政策'), findsOneWidget);
  });

  testWidgets('privacy consent dialog has 同意 and 拒绝', (tester) async {
    var agreed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyConsentPage(
          onAgree: () async {
            agreed = true;
          },
        ),
      ),
    );
    expect(find.text('同意'), findsOneWidget);
    expect(find.text('拒绝'), findsOneWidget);
    expect(find.textContaining('隐私政策'), findsWidgets);
    await tester.tap(find.text('同意'));
    await tester.pump();
    expect(agreed, isTrue);
  });
}
