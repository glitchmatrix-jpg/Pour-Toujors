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

  final fixtureDate = DateTime(2026, 8, 2);

  CityWeather weather({
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
      'karachi': weather(
        temperature: 34,
        feelsLike: 42,
        wind: 19,
        code: 2,
        isDay: true,
        high: 36,
        low: 29,
        rain: 38,
      ),
      'chiba': weather(
        temperature: 27,
        feelsLike: 30,
        wind: 11,
        code: 61,
        isDay: false,
        high: 30,
        low: 24,
        rain: 78,
      ),
      'dublin': weather(
        temperature: 17,
        feelsLike: 16,
        wind: 37,
        code: 3,
        isDay: true,
        high: 19,
        low: 12,
        rain: 45,
      ),
      'hattiesburg': weather(
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

    HolidayService.debugOverrides = {
      'karachi': [
        NationalHoliday(
          date: fixtureDate.add(const Duration(days: 12)),
          name: 'Independence Day',
          countryCode: 'PK',
        ),
      ],
      'chiba': [
        NationalHoliday(
          date: fixtureDate.add(const Duration(days: 9)),
          name: 'Mountain Day',
          countryCode: 'JP',
        ),
      ],
      'dublin': [
        NationalHoliday(
          date: fixtureDate.add(const Duration(days: 85)),
          name: 'October Bank Holiday',
          countryCode: 'IE',
        ),
      ],
      'hattiesburg': [
        NationalHoliday(
          date: fixtureDate.add(const Duration(days: 35)),
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

  Future<void> pumpHomeAtSize(
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
    await tester.pumpAndSettle();
  }

  Future<void> pumpOnboardingAtSize(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        home: IdentitySetupScreen(onSelected: (_) async {}),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectNoFrameworkException(WidgetTester tester) {
    final exception = tester.takeException();
    expect(
      exception,
      isNull,
      reason: 'The screen produced a Flutter layout or paint exception.',
    );
  }

  for (final size in <Size>[
    const Size(360, 640),
    const Size(390, 844),
    const Size(412, 915),
  ]) {
    testWidgets(
      'Onboarding renders without overflow at '
      '${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await pumpOnboardingAtSize(tester, size);

        expect(find.text('Who are you?'), findsOneWidget);
        expect(find.text('Pour Toujours'), findsOneWidget);
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.textContaining('Continue as'), findsOneWidget);
        expectNoFrameworkException(tester);
      },
    );

    testWidgets(
      'Today with populated weather renders and scrolls without overflow at '
      '${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        await pumpHomeAtSize(tester, size);

        expect(find.textContaining('Good '), findsOneWidget);
        expect(find.text('YOUR FAMILY WORLD'), findsOneWidget);
        expect(find.text('Family now'), findsOneWidget);
        expect(find.text('34°'), findsOneWidget);
        expect(find.text('Feels 42°'), findsOneWidget);
        expect(find.text('19 km/h'), findsOneWidget);
        expectNoFrameworkException(tester);

        await tester.drag(find.byType(ListView).first, const Offset(0, -1800));
        await tester.pumpAndSettle();
        expect(find.text('Next birthdays'), findsOneWidget);
        expectNoFrameworkException(tester);
      },
    );
  }

  testWidgets('Offline weather is honest and never displays fake metrics',
      (tester) async {
    final offline = weather(
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

    await pumpHomeAtSize(tester, const Size(390, 844));

    expect(find.textContaining('Weather unavailable'), findsWidgets);
    expect(find.text('Feels 0°'), findsNothing);
    expect(find.text('0 km/h'), findsNothing);
    expectNoFrameworkException(tester);
  });

  testWidgets('People page uses viewer-relative relationships', (tester) async {
    await pumpHomeAtSize(tester, const Size(390, 844), viewer: 'Talat');

    await tester.tap(find.text('People').last);
    await tester.pumpAndSettle();

    expect(find.text('Son'), findsWidgets);
    expect(find.text('Daughter'), findsOneWidget);
    expectNoFrameworkException(tester);
  });

  testWidgets('Calendar shows birthdays and deterministic national holidays',
      (tester) async {
    await pumpHomeAtSize(tester, const Size(390, 844));

    await tester.tap(find.text('Calendar').last);
    await tester.pumpAndSettle();

    expect(find.text('Birthdays'), findsOneWidget);
    expect(find.text('National holidays'), findsOneWidget);
    expect(find.text('Independence Day'), findsOneWidget);
    expect(find.text('Mountain Day'), findsOneWidget);

    final horizontalLists = find.byWidgetPredicate(
      (widget) =>
          widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    expect(horizontalLists, findsOneWidget);
    await tester.drag(horizontalLists, const Offset(-600, 0));
    await tester.pumpAndSettle();
    expectNoFrameworkException(tester);
  });

  testWidgets('Settings remains usable at the smallest supported phone size',
      (tester) async {
    await pumpHomeAtSize(tester, const Size(360, 640));

    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('Switch profile'), findsOneWidget);
    expect(find.textContaining('Using Pour Toujours as Hasan'), findsOneWidget);
    expectNoFrameworkException(tester);
  });
}
