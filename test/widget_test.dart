import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/device_layout.dart';
import 'package:app/features/bind/bind_page.dart';

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
    expect(find.text('绑定设备'), findsOneWidget);
    expect(find.text('绑定并开始'), findsOneWidget);
  });
}
