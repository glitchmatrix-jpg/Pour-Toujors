import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:pour_toujours/app/theme/pour_toujours_theme.dart';
import 'package:pour_toujours/core/holidays/holiday_service.dart';
import 'package:pour_toujours/core/settings/app_settings.dart';
import 'package:pour_toujours/core/weather/weather_models.dart';
import 'package:pour_toujours/core/weather/weather_service.dart';
import 'package:pour_toujours/features/home/premium_home_screen_v3.dart';
import 'package:pour_toujours/features/navigation/detail_placeholders.dart';
import 'package:pour_toujours/features/today/ambient_sky.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  WeatherBundle fixture(String cityId, {bool day = true, int code = 2}) {
    final now = DateTime(2026, 8, 2, 12);
    final current = CurrentWeather(
      time: now,
      temperature: 31,
      feelsLike: 36,
      weatherCode: code,
      isDay: day,
      precipitation: 0,
      rainChance: 62,
      windSpeed: 18,
      windGusts: 31,
      windDirection: 180,
      humidity: 72,
      visibility: 10000,
      uvIndex: 7,
      cloudCover: 54,
      surfacePressure: 1009,
    );
    final hourly = List.generate(
      48,
      (index) => HourlyWeather(
        time: now.add(Duration(hours: index)),
        temperature: 28 + (index % 5),
        feelsLike: 31 + (index % 5),
        weatherCode: code,
        precipitationProbability: 40 + (index % 50),
        precipitation: index.isEven ? .2 : 0,
        windSpeed: 15,
        windGusts: 28,
        humidity: 70,
        uvIndex: index < 8 ? 6 : 0,
        visibility: 10000,
      ),
    );
    final daily = List.generate(
      7,
      (index) => DailyWeather(
        date: now.add(Duration(days: index)),
        weatherCode: code,
        high: 34,
        low: 25,
        precipitationProbability: 70,
        precipitation: 4,
        windMaximum: 24,
        gustMaximum: 38,
        sunrise: DateTime(2026, 8, 2 + index, 6),
        sunset: DateTime(2026, 8, 2 + index, 19),
        daylightDuration: const Duration(hours: 13),
        uvMaximum: 8,
      ),
    );
    return WeatherBundle(
      cityId: cityId,
      current: current,
      hourly: hourly,
      daily: daily,
      updatedAt: now,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WeatherService.debugBundleOverrides = {
      'karachi': fixture('karachi'),
      'chiba': fixture('chiba', day: false, code: 61),
      'dublin': fixture('dublin', code: 3),
      'hattiesburg': fixture('hattiesburg', code: 95),
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
    WeatherService.debugBundleOverrides = null;
    HolidayService.debugOverrides = null;
  });

  Future<AppSettingsController> pumpHome(
    WidgetTester tester,
    Size size, {
    String viewer = 'Hasan',
    AppSettings initial = const AppSettings(),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppSettingsController(initial: initial);
    await tester.pumpWidget(
      AppSettingsScope(
        controller: controller,
        child: MaterialApp(
          themeMode: initial.themeMode,
          theme: PourToujoursTheme.build(initial.theme, Brightness.light),
          darkTheme: PourToujoursTheme.build(initial.theme, Brightness.dark),
          onGenerateRoute: (settings) {
            if (settings.name == '/') return null;
            final args = settings.arguments is DetailRouteArgs
                ? settings.arguments! as DetailRouteArgs
                : DetailRouteArgs(title: settings.name ?? 'Details');
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (context) => Scaffold(
                appBar: AppBar(title: Text(args.title)),
                body: Center(child: Text(args.subtitle ?? args.title)),
              ),
            );
          },
          home: PremiumHomeScreenV3(
            viewerName: viewer,
            onSwitchProfile: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  void expectClean(WidgetTester tester) {
    expect(
      tester.takeException(),
      isNull,
      reason: 'A layout, paint, or framework exception occurred.',
    );
  }

  for (final size in const [
    Size(360, 640),
    Size(390, 844),
    Size(412, 915),
    Size(768, 1024),
    Size(1440, 900),
  ]) {
    testWidgets(
      'Living Today is clean at ${size.width}x${size.height}',
      (tester) async {
        await pumpHome(tester, size);
        expect(find.textContaining('Good '), findsOneWidget);
        expect(find.text('Four places, one shared day.'), findsOneWidget);
        expectClean(tester);

        final mainScroll = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.text('Family pulse'),
          220,
          scrollable: mainScroll,
        );
        expect(find.text('Family pulse'), findsOneWidget);
        expectClean(tester);

        await tester.scrollUntilVisible(
          find.text('City conditions'),
          320,
          scrollable: mainScroll,
        );
        expect(find.textContaining('31'), findsWidgets);
        expectClean(tester);
      },
    );
  }

  for (final collection in PtThemeCollection.values) {
    testWidgets('${collection.name} supports light and dark settings', (
      tester,
    ) async {
      await pumpHome(
        tester,
        const Size(390, 844),
        initial: AppSettings(
          theme: collection,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expectClean(tester);
    });
  }

  testWidgets('Settings changes theme and reduced motion', (tester) async {
    final controller = await pumpHome(tester, const Size(390, 844));
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();

    expect(find.text('Evergreen'), findsOneWidget);
    expect(find.text('Cherry Cola'), findsOneWidget);
    await tester.tap(find.text('Cherry Cola'));
    await tester.pump();
    expect(controller.value.theme, PtThemeCollection.cherryCola);

    final settingsScroll = find.byType(Scrollable).first;
    final switchTile = find.widgetWithText(SwitchListTile, 'Reduce motion');
    await tester.scrollUntilVisible(
      switchTile,
      320,
      scrollable: settingsScroll,
    );
    await tester.drag(settingsScroll, const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(switchTile);
    await tester.pump();

    expect(controller.value.reducedMotion, isTrue);
    expectClean(tester);
  });

  testWidgets('People relationships remain viewer-relative', (tester) async {
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
    expect(find.text('Independence Day'), findsOneWidget);
    expect(find.text('Mountain Day'), findsOneWidget);
    expectClean(tester);
  });

  testWidgets('City nodes and shared-time ribbon are interactive', (
    tester,
  ) async {
    await pumpHome(tester, const Size(390, 844));
    expect(find.text('Karachi'), findsWidgets);
    await tester.tap(find.text('Karachi').first);
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('Karachi'), findsWidgets);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    final mainScroll = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Next 24 hours'),
      300,
      scrollable: mainScroll,
    );
    final horizontal = find.byWidgetPredicate(
      (widget) => widget is SingleChildScrollView &&
          widget.scrollDirection == Axis.horizontal,
    );
    expect(horizontal, findsWidgets);
    await tester.drag(horizontal.first, const Offset(-300, 0));
    await tester.pump();
    expectClean(tester);
  });

  test('Ambient sky classifies common weather states', () {
    final clear = fixture('clear').current;
    expect(ambientSkyKindFor(clear, null), AmbientSkyKind.partlyCloudyDay);
    expect(
      ambientSkyKindFor(fixture('rain', code: 61).current, null),
      AmbientSkyKind.rain,
    );
    expect(
      ambientSkyKindFor(fixture('storm', code: 95).current, null),
      AmbientSkyKind.thunderstorm,
    );
    expect(
      ambientSkyKindFor(fixture('fog', code: 45).current, null),
      AmbientSkyKind.fog,
    );
    expect(
      ambientSkyKindFor(fixture('night', day: false, code: 0).current, null),
      AmbientSkyKind.clearNight,
    );
  });

  testWidgets('Large text and reduced motion remain usable', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const settings = AppSettings(reducedMotion: true);
    final controller = AppSettingsController(initial: settings);
    await tester.pumpWidget(
      AppSettingsScope(
        controller: controller,
        child: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.5),
            disableAnimations: true,
          ),
          child: MaterialApp(
            theme: PourToujoursTheme.build(
              settings.theme,
              Brightness.light,
            ),
            home: const PremiumHomeScreenV3(
              viewerName: 'Hasan',
              onSwitchProfile: _noop,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Four places, one shared day.'), findsOneWidget);
    expectClean(tester);
  });
}

void _noop() {}
