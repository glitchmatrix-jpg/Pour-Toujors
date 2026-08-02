import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:pour_toujours/core/holidays/holiday_service.dart';
import 'package:pour_toujours/core/weather/weather_service.dart';
import 'package:pour_toujours/features/home/premium_home_screen_v2.dart';
import 'package:pour_toujours/features/onboarding/identity_setup_screen.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  CityWeather fixture({
    required double temperature,
    required double feelsLike,
    required double wind,
    required int code,
    required bool isDay,
    required double high,
    required double low,
    required int rain,
    bool isLive = true,
  }) {
    return CityWeather(
      temperature: temperature,
      feelsLike: feelsLike,
      windSpeed: wind,
      code: code,
      isDay: isDay,
      high: high,
      low: low,
      rainChance: rain,
      sunrise: DateTime(2026, 8, 2, 6),
      sunset: DateTime(2026, 8, 2, 19),
      isLive: isLive,
    );
  }

  setUp(() {
    WeatherService.debugOverrides = {
      'karachi': fixture(
        temperature: 34,
        feelsLike: 42,
        wind: 19,
        code: 2,
        isDay: true,
        high: 36,
        low: 29,
        rain: 38,
      ),
      'chiba': fixture(
        temperature: 27,
        feelsLike: 30,
        wind: 11,
        code: 61,
        isDay: false,
        high: 30,
        low: 24,
        rain: 78,
      ),
      'dublin': fixture(
        temperature: 17,
        feelsLike: 16,
        wind: 37,
        code: 3,
        isDay: true,
        high: 19,
        low: 12,
        rain: 45,
      ),
      'hattiesburg': fixture(
        temperature: 29,
        feelsLike: 35,
        wind: 14,
        code: 95,
        isDay: true,
        high: 33,
        low: 24,
        rain: 82,
      ),
    };

    final base = DateTime(2026, 8, 2);
    HolidayService.debugOverrides = {
      'karachi': [
        NationalHoliday(
          date: base.add(const Duration(days: 12)),
          name: 'Independence Day',
          countryCode: 'PK',
        ),
      ],
      'chiba': [
        NationalHoliday(
          date: base.add(const Duration(days: 9)),
          name: 'Mountain Day',
          countryCode: 'JP',
        ),
      ],
      'dublin': [
        NationalHoliday(
          date: base.add(const Duration(days: 85)),
          name: 'October Bank Holiday',
          countryCode: 'IE',
        ),
      ],
      'hattiesburg': [
        NationalHoliday(
          date: base.add(const Duration(days: 35)),
          name: 'Labor Day',
          countryCode: 'US',
        ),
      ],
    };
  });

  tearDown(() {
    WeatherService.debugOverrides = null;
    HolidayService.debugOverrides = null;
  });

  Future<void> setPhone(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpHome(
    WidgetTester tester,
    Size size, {
    String viewer = 'Hasan',
  }) async {
    await setPhone(tester, size);
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
    await tester.pumpAndSettle();
  }

  Future<void> pumpOnboarding(WidgetTester tester, Size size) async {
    await setPhone(tester, size);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: IdentitySetupScreen(onSelected: (_) async {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectClean(WidgetTester tester) {
    expect(
      tester.takeException(),
      isNull,
      reason: 'The screen produced a Flutter layout or paint exception.',
    );
  }

  for (final size in const <Size>[
    Size(360, 640),
    Size(390, 844),
    Size(412, 915),
  ]) {
    testWidgets(
      'Onboarding is clean at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await pumpOnboarding(tester, size);
        expect(find.text('Who are you?'), findsOneWidget);
        expect(find.text('Pour Toujours'), findsOneWidget);
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.textContaining('Continue as'), findsOneWidget);
        expectClean(tester);
      },
    );

    testWidgets(
      'Populated Today is clean at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await pumpHome(tester, size);
        expect(find.textContaining('Good '), findsOneWidget);
        expect(find.text('YOUR FAMILY WORLD'), findsOneWidget);
        expect(find.text('Family now'), findsOneWidget);
        expectClean(tester);

        await tester.drag(find.byType(ListView).first, const Offset(0, -700));
        await tester.pumpAndSettle();
        expect(find.text('34°'), findsOneWidget);
        expect(find.text('Feels 42°'), findsOneWidget);
        expect(find.text('19 km/h'), findsOneWidget);
        expectClean(tester);

        await tester.drag(find.byType(ListView).first, const Offset(0, -1800));
        await tester.pumpAndSettle();
        expect(find.text('Next birthdays'), findsOneWidget);
        expectClean(tester);
      },
    );
  }

  testWidgets('Offline weather is honest and omits fake metrics', (tester) async {
    final offline = fixture(
      temperature: 0,
      feelsLike: 0,
      wind: 0,
      code: 3,
      isDay: true,
      high: 0,
      low: 0,
      rain: 0,
      isLive: false,
    );
    WeatherService.debugOverrides = {
      for (final city in ['karachi', 'chiba', 'dublin', 'hattiesburg'])
        city: offline,
    };

    await pumpHome(tester, const Size(390, 844));
    await tester.drag(find.byType(ListView).first, const Offset(0, -700));
    await tester.pumpAndSettle();
    expect(find.textContaining('Weather unavailable'), findsWidgets);
    expect(find.text('Feels 0°'), findsNothing);
    expect(find.text('0 km/h'), findsNothing);
    expectClean(tester);
  });

  testWidgets('Relationships are relative to the selected viewer', (tester) async {
    await pumpHome(tester, const Size(390, 844), viewer: 'Talat');
    await tester.tap(find.text('People').last);
    await tester.pumpAndSettle();
    expect(find.text('Son'), findsWidgets);
    expect(find.text('Daughter'), findsOneWidget);
    expectClean(tester);
  });

  testWidgets('Calendar renders birthdays and holidays', (tester) async {
    await pumpHome(tester, const Size(390, 844));
    await tester.tap(find.text('Calendar').last);
    await tester.pumpAndSettle();
    expect(find.text('Birthdays'), findsOneWidget);
    expect(find.text('National holidays'), findsOneWidget);
    expect(find.text('Independence Day'), findsOneWidget);
    expect(find.text('Mountain Day'), findsOneWidget);
    expectClean(tester);

    final horizontal = find.byWidgetPredicate(
      (widget) =>
          widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    expect(horizontal, findsOneWidget);
    await tester.drag(horizontal, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expectClean(tester);
  });

  testWidgets('Settings works on the smallest supported phone', (tester) async {
    await pumpHome(tester, const Size(360, 640));
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    expect(find.text('Switch profile'), findsOneWidget);
    expect(find.textContaining('Using Pour Toujours as Hasan'), findsOneWidget);
    expectClean(tester);
  });
}
