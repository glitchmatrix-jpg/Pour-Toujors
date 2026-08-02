import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:pour_toujours/app/theme/pour_toujours_theme.dart';
import 'package:pour_toujours/core/release/v1_platform_services.dart';
import 'package:pour_toujours/core/settings/app_settings.dart';
import 'package:pour_toujours/features/settings/v1_release_center.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('notification preferences survive local round-trip', () async {
    const expected = NotificationPreferences(
      enabled: true,
      birthdays: false,
      events: true,
      callWindows: true,
      dstChanges: false,
      severeWeather: true,
      quietStartHour: 23,
      quietEndHour: 7,
      birthdayLeadDays: 3,
      minimumAlertSeverity: 3,
    );
    await expected.save();
    final actual = await NotificationPreferences.load();
    expect(actual.toMap(), expected.toMap());
  });

  test('corrupted notification preferences fail closed', () async {
    SharedPreferences.setMockInitialValues({
      NotificationPreferences.storageKey: '{broken',
      NotificationPreferences.enabledKey: true,
    });
    final preferences = await NotificationPreferences.load();
    expect(preferences.enabled, isFalse);
    expect(preferences.severeWeather, isTrue);
  });

  test('quiet hours cross midnight correctly', () {
    const preferences = NotificationPreferences(
      enabled: true,
      quietStartHour: 22,
      quietEndHour: 8,
    );
    final location = tz.getLocation('America/Chicago');
    expect(preferences.isQuiet(tz.TZDateTime(location, 2026, 8, 2, 23)), isTrue);
    expect(preferences.isQuiet(tz.TZDateTime(location, 2026, 8, 3, 7)), isTrue);
    expect(preferences.isQuiet(tz.TZDateTime(location, 2026, 8, 3, 12)), isFalse);
  });

  test('widget snapshot contains expanded platform-neutral contract', () {
    final snapshot = WidgetSnapshot(
      primaryLine: 'Family across four cities',
      secondaryLine: 'Weather, time, and family context',
      citiesLine: 'Karachi 9:00 PM · Dublin 5:00 PM',
      timelineLine: 'Hasan · Hattiesburg 11:00 AM',
      nextEventLine: 'Family call tomorrow',
      alertLine: 'No important alert',
      updatedAt: DateTime.utc(2026, 8, 2, 16),
      citySnapshots: const [
        WidgetCitySnapshot(
          id: 'karachi',
          name: 'Karachi',
          time: '9:00 PM',
          date: 'Sun, 2 Aug',
          temperature: '28°C',
          condition: 'Partly cloudy',
          weatherCode: 2,
          isDay: false,
          status: '0 likely free · 11 here',
          alert: 'No important alert',
        ),
      ],
      daylightCities: 2,
      activeAlerts: 1,
      isStale: true,
    );
    final map = snapshot.toMap();
    expect(map.keys, containsAll(IosWidgetDataContract.keys));
    expect(map['pt_stale'], '1');
    expect(map['pt_karachi_temp'], '28°C');
    expect(map['pt_daylight_cities'], '2');
    expect(map['pt_active_alerts'], '1');
    expect(IosWidgetDataContract.schemaVersion, 2);
  });

  for (final screen in <Widget>[
    const PrivacyTrustScreen(),
    const AttributionScreen(),
    const NotificationControlScreen(),
  ]) {
    testWidgets(
      '${screen.runtimeType} supports narrow dark 200% text',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            theme: PourToujoursTheme.build(
              PtThemeCollection.evergreen,
              Brightness.dark,
            ),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
              ),
              child: child!,
            ),
            home: screen,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(Scaffold), findsOneWidget);
      },
    );
  }
}
