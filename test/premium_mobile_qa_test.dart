import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:pour_toujours/app/theme/pour_toujours_theme.dart';
import 'package:pour_toujours/core/alerts/weather_alert_service.dart';
import 'package:pour_toujours/core/settings/app_settings.dart';
import 'package:pour_toujours/core/weather/weather_models.dart';
import 'package:pour_toujours/core/weather/weather_service.dart';
import 'package:pour_toujours/data/family_seed.dart';
import 'package:pour_toujours/features/home/premium_home_screen_v3.dart';
import 'package:pour_toujours/features/navigation/detail_placeholders.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  WeatherBundle fixture(String cityId) {
    final now = DateTime(2026, 8, 2, 12);
    return WeatherBundle(
      cityId: cityId,
      current: CurrentWeather(
        time: now,
        temperature: 28,
        feelsLike: 30,
        weatherCode: 1,
        isDay: true,
        precipitation: 0,
        rainChance: 15,
        windSpeed: 12,
        windGusts: 18,
        windDirection: 180,
        humidity: 60,
        visibility: 10000,
        uvIndex: 5,
        cloudCover: 20,
        surfacePressure: 1012,
      ),
      hourly: List.generate(
        48,
        (index) => HourlyWeather(
          time: now.add(Duration(hours: index)),
          temperature: 28,
          feelsLike: 30,
          weatherCode: 1,
          precipitationProbability: 15,
          precipitation: 0,
          windSpeed: 12,
          windGusts: 18,
          humidity: 60,
          uvIndex: 5,
          visibility: 10000,
        ),
      ),
      daily: List.generate(
        7,
        (index) => DailyWeather(
          date: now.add(Duration(days: index)),
          weatherCode: 1,
          high: 31,
          low: 24,
          precipitationProbability: 15,
          precipitation: 0,
          windMaximum: 18,
          gustMaximum: 25,
          sunrise: DateTime(2026, 8, 2 + index, 6),
          sunset: DateTime(2026, 8, 2 + index, 19),
          daylightDuration: const Duration(hours: 13),
          uvMaximum: 6,
        ),
      ),
      updatedAt: now,
    );
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WeatherService.debugBundleOverrides = {
      for (final city in cities) city.id: fixture(city.id),
    };
    WeatherAlertService.debugOfficialOverrides = const {};
  });

  tearDown(() {
    WeatherService.debugBundleOverrides = null;
    WeatherAlertService.debugOfficialOverrides = null;
  });

  Future<AppSettingsController> pumpHome(
    WidgetTester tester,
    Size size, {
    String viewer = 'Hasan',
    AppSettings settings = const AppSettings(reducedMotion: true),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppSettingsController(initial: settings);
    await tester.pumpWidget(
      AppSettingsScope(
        controller: controller,
        child: MaterialApp(
          theme: PourToujoursTheme.build(settings.theme, Brightness.light),
          darkTheme: PourToujoursTheme.build(settings.theme, Brightness.dark),
          themeMode: settings.themeMode,
          onGenerateRoute: PourToujoursRoutes.onGenerateRoute,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(textScale),
            ),
            child: child!,
          ),
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
    expect(tester.takeException(), isNull);
  }

  for (final size in const [
    Size(360, 640),
    Size(390, 844),
    Size(412, 915),
    Size(768, 1024),
    Size(1440, 900),
  ]) {
    testWidgets('Living Today is clean at ${size.width}x${size.height}', (
      tester,
    ) async {
      await pumpHome(tester, size);
      expect(find.text('Today'), findsWidgets);
      expectClean(tester);
    });
  }

  for (final theme in PtThemeCollection.values) {
    testWidgets('${theme.name} supports light and dark settings', (tester) async {
      await pumpHome(
        tester,
        const Size(390, 844),
        settings: AppSettings(
          theme: theme,
          themeMode: ThemeMode.dark,
          reducedMotion: true,
        ),
      );
      expect(find.text('Today'), findsWidgets);
      expectClean(tester);
    });
  }

  testWidgets('Settings changes theme and reduced motion', (tester) async {
    final controller = await pumpHome(
      tester,
      const Size(390, 844),
      settings: const AppSettings(reducedMotion: false),
    );
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
    expect(find.textContaining('Son'), findsWidgets);
    expect(find.textContaining('Daughter'), findsOneWidget);
    expect(find.text('Plan a call'), findsOneWidget);
    expectClean(tester);
  });

  testWidgets('Calendar renders monthly family experience', (tester) async {
    await pumpHome(tester, const Size(390, 844));
    await tester.tap(find.text('Calendar').last);
    await tester.pumpAndSettle();
    expect(find.text('Birthdays'), findsOneWidget);
    expect(find.text('Holidays'), findsOneWidget);
    expect(find.text('Family events'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.text('Event'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expectClean(tester);
  });

  testWidgets('City nodes and shared-time ribbon are interactive', (
    tester,
  ) async {
    await pumpHome(tester, const Size(390, 844));
    expect(find.text('Karachi'), findsWidgets);
    await tester.tap(find.text('Karachi').first);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.text('Karachi'), findsWidgets);
    expectClean(tester);
  });

  testWidgets('Large text and reduced motion remain usable', (tester) async {
    await pumpHome(
      tester,
      const Size(360, 640),
      settings: const AppSettings(reducedMotion: true),
      textScale: 1.4,
    );
    expect(find.text('Today'), findsWidgets);
    expectClean(tester);
  });
}
