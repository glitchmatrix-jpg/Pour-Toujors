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
import 'package:pour_toujours/features/city/city_experience.dart';
import 'package:pour_toujours/features/navigation/detail_placeholders.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  WeatherBundle fixture(
    String cityId, {
    int code = 2,
    bool isDay = true,
    bool emptyHourly = false,
    bool stale = false,
  }) {
    final now = DateTime(2026, 11, 1, 12);
    final hourly = emptyHourly
        ? <HourlyWeather>[]
        : List.generate(
            48,
            (index) => HourlyWeather(
              time: now.add(Duration(hours: index)),
              temperature: 18 + index % 7,
              feelsLike: 17 + index % 8,
              weatherCode: code,
              precipitationProbability: index % 4 == 0 ? 80 : 20,
              precipitation: index % 4 == 0 ? 2 : 0,
              windSpeed: 16,
              windGusts: 28,
              humidity: 68,
              uvIndex: index % 24 < 8 ? 5 : 0,
              visibility: 10000,
            ),
          );
    final daily = List.generate(
      7,
      (index) => DailyWeather(
        date: now.add(Duration(days: index)),
        weatherCode: code,
        high: 27,
        low: 14,
        precipitationProbability: 55,
        precipitation: 3,
        windMaximum: 24,
        gustMaximum: 36,
        sunrise: DateTime(2026, 11, 1 + index, 6, 30),
        sunset: DateTime(2026, 11, 1 + index, 17, 10),
        daylightDuration: const Duration(hours: 10, minutes: 40),
        uvMaximum: 6,
      ),
    );
    return WeatherBundle(
      cityId: cityId,
      current: CurrentWeather(
        time: now,
        temperature: 22,
        feelsLike: 23,
        weatherCode: code,
        isDay: isDay,
        precipitation: 0,
        rainChance: 55,
        windSpeed: 16,
        windGusts: 28,
        windDirection: 180,
        humidity: 68,
        visibility: 10000,
        uvIndex: 5,
        cloudCover: 45,
        surfacePressure: 1012,
      ),
      hourly: hourly,
      daily: daily,
      updatedAt: now,
      isStale: stale,
    );
  }

  FamilyWeatherAlert official(String event) => FamilyWeatherAlert(
        id: event,
        cityId: 'hattiesburg',
        event: event,
        headline: '$event for Forrest County',
        instruction: event.contains('Warning')
            ? 'Seek shelter now in an interior room away from windows.'
            : 'Be ready to shelter and monitor official warnings.',
        source: WeatherAlertSource.official,
        severity: event.contains('Warning')
            ? WeatherAlertSeverity.extreme
            : WeatherAlertSeverity.severe,
        effective: DateTime(2026, 11, 1, 12),
        expires: DateTime(2026, 11, 1, 13),
        area: 'Forrest County',
        attribution: 'U.S. National Weather Service',
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    WeatherService.debugBundleOverrides = {
      'karachi': fixture('karachi', code: 1),
      'chiba': fixture('chiba', code: 61, isDay: false),
      'dublin': fixture('dublin', code: 45),
      'hattiesburg': fixture('hattiesburg', code: 95),
    };
    WeatherAlertService.debugOfficialOverrides = const {};
  });

  tearDown(() {
    WeatherService.debugBundleOverrides = null;
    WeatherAlertService.debugOfficialOverrides = null;
  });

  Future<void> pumpCity(
    WidgetTester tester, {
    String cityId = 'karachi',
    Size size = const Size(390, 844),
    AppSettings settings = const AppSettings(reducedMotion: true),
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
          home: CityExperienceScreen(
            initialCityId: cityId,
            viewerName: 'Hasan',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> revealForecast(WidgetTester tester) async {
    await tester.scrollUntilVisible(
      find.text('Seven-day forecast'),
      280,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('city renders full seven-day experience on narrow phones', (
    tester,
  ) async {
    await pumpCity(tester, size: const Size(360, 640));
    expect(find.text('Karachi'), findsWidgets);
    expect(find.text('The city’s light'), findsOneWidget);
    await revealForecast(tester);
    expect(find.text('Seven-day forecast'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('city switching does not return to Today', (tester) async {
    await pumpCity(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Chiba'));
    await tester.pumpAndSettle();
    expect(find.text('Chiba'), findsWidgets);
    await revealForecast(tester);
    expect(find.text('Seven-day forecast'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('official tornado warning is unmistakable and supported', (
    tester,
  ) async {
    WeatherAlertService.debugOfficialOverrides = {
      'hattiesburg': [official('Tornado Warning')],
    };
    await pumpCity(tester, cityId: 'hattiesburg');
    expect(find.text('OFFICIAL WARNING'), findsOneWidget);
    expect(find.text('Seek shelter now'), findsOneWidget);
    await tester.tap(find.text('OFFICIAL WARNING'));
    await tester.pumpAndSettle();
    expect(find.text('Forrest County'), findsWidgets);
    expect(find.text('U.S. National Weather Service'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('official watch avoids warning-only shelter command', (
    tester,
  ) async {
    WeatherAlertService.debugOfficialOverrides = {
      'hattiesburg': [official('Tornado Watch')],
    };
    await pumpCity(tester, cityId: 'hattiesburg');
    expect(find.text('OFFICIAL WATCH'), findsOneWidget);
    expect(find.text('Seek shelter now'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no official alerts still shows derived forecast guidance', (
    tester,
  ) async {
    await pumpCity(tester, cityId: 'hattiesburg');
    expect(find.text('FORECAST-DERIVED ADVISORY'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing hourly values show accessible fallback', (tester) async {
    final bundle = fixture('dublin', emptyHourly: true);
    const settings = AppSettings(reducedMotion: true);
    await tester.pumpWidget(
      AppSettingsScope(
        controller: AppSettingsController(initial: settings),
        child: MaterialApp(
          theme: PourToujoursTheme.build(
            settings.theme,
            Brightness.light,
          ),
          home: HourlyForecastScreen(
            payload: HourlyRoutePayload(
              city: const FamilyCity(
                id: 'dublin',
                name: 'Dublin',
                country: 'Ireland',
                timezone: 'Europe/Dublin',
                asset: '',
                weatherLine: '',
              ),
              bundle: bundle,
              day: bundle.daily.first,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hourly values unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('comparison matrix includes every city', (tester) async {
    await pumpCity(tester);
    await revealForecast(tester);
    await tester.tap(find.byIcon(Icons.view_agenda_outlined));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Compare all four cities'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Compare all four cities'));
    await tester.pumpAndSettle();
    for (final name in ['Karachi', 'Chiba', 'Dublin', 'Hattiesburg']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}
