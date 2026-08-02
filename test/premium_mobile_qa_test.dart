import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:pour_toujours/features/home/premium_home_screen_v2.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  Future<void> pumpAtSize(
    WidgetTester tester,
    Size size, {
    String viewer = 'Hasan',
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: PremiumHomeScreenV2(
          viewerName: viewer,
          onSwitchProfile: () {},
        ),
      ),
    );
    await tester.pump();
  }

  void expectNoFrameworkException(WidgetTester tester) {
    final exception = tester.takeException();
    expect(exception, isNull, reason: 'The screen produced a Flutter layout or paint exception.');
  }

  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
    const Size(412, 915),
  ]) {
    testWidgets('Today renders and scrolls without overflow at ${size.width.toInt()}x${size.height.toInt()}', (tester) async {
      await pumpAtSize(tester, size);

      expect(find.textContaining('Good '), findsOneWidget);
      expect(find.text('YOUR FAMILY WORLD'), findsOneWidget);
      expect(find.text('Family now'), findsOneWidget);
      expectNoFrameworkException(tester);

      await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
      await tester.pump();
      expect(find.text('Next birthdays'), findsOneWidget);
      expectNoFrameworkException(tester);
    });
  }

  testWidgets('People page uses viewer-relative relationships', (tester) async {
    await pumpAtSize(tester, const Size(390, 844), viewer: 'Talat');

    await tester.tap(find.text('People').last);
    await tester.pump();

    expect(find.text('Son'), findsWidgets);
    expect(find.text('Daughter'), findsOneWidget);
    expectNoFrameworkException(tester);
  });

  testWidgets('Calendar birthday rail is reachable and horizontally scrollable', (tester) async {
    await pumpAtSize(tester, const Size(390, 844));

    await tester.tap(find.text('Calendar').last);
    await tester.pump();

    expect(find.text('Birthdays'), findsOneWidget);
    expect(find.text('National holidays'), findsOneWidget);
    expect(find.text('Yasin'), findsOneWidget);

    final horizontalLists = find.byWidgetPredicate(
      (widget) => widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    expect(horizontalLists, findsOneWidget);
    await tester.drag(horizontalLists, const Offset(-600, 0));
    await tester.pump();
    expectNoFrameworkException(tester);
  });

  testWidgets('Settings remains usable at the smallest supported phone size', (tester) async {
    await pumpAtSize(tester, const Size(360, 640));

    await tester.tap(find.text('Settings').last);
    await tester.pump();

    expect(find.text('Switch profile'), findsOneWidget);
    expectNoFrameworkException(tester);
  });
}
