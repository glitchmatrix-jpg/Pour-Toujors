import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:pour_toujours/app/theme/pour_toujours_theme.dart';
import 'package:pour_toujours/core/settings/app_settings.dart';
import 'package:pour_toujours/data/family_graph.dart';
import 'package:pour_toujours/features/people/family_calendar_final.dart';
import 'package:pour_toujours/features/people/people_calendar_experience.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('family graph resolves documented viewer-relative relationships', () {
    expect(familyGraph.relationship(viewer: 'Hasan', person: 'Hasan'), 'You');
    expect(familyGraph.relationship(viewer: 'Hasan', person: 'Talat'), 'Mother');
    expect(familyGraph.relationship(viewer: 'Hasan', person: 'Shahid'), 'Father');
    expect(familyGraph.relationship(viewer: 'Talat', person: 'Hasan'), 'Son');
    expect(familyGraph.relationship(viewer: 'Talat', person: 'Ramsha'), 'Daughter');
    expect(familyGraph.relationship(viewer: 'Ramsha', person: 'Salman'), 'Brother');
    expect(familyGraph.relationship(viewer: 'Salman', person: 'Ramsha'), 'Sister');
    expect(familyGraph.relationship(viewer: 'Hasan', person: 'Ami'), 'Grandmother');
    expect(familyGraph.relationship(viewer: 'Ami', person: 'Hasan'), 'Grandson');
    expect(familyGraph.relationship(viewer: 'Talat', person: 'Shahid'), 'Husband');
    expect(familyGraph.relationship(viewer: 'Shahid', person: 'Talat'), 'Wife');
    expect(familyGraph.relationship(viewer: 'Hasan', person: 'Affan'), 'Cousin');
    expect(familyGraph.relationship(viewer: 'Ramsha', person: 'Affan'), 'Cousin');
    expect(
      familyGraph.relationship(viewer: 'Shahid', person: 'Affan'),
      'Nephew by marriage',
    );
    expect(
      familyGraph.relationship(viewer: 'Ami', person: 'Sarwat'),
      'Daughter-in-law',
    );
  });

  test('unrecorded relationships remain explicit and conservative', () {
    expect(
      familyGraph.relationship(
        viewer: 'Hasan',
        person: 'Unrecorded relative',
      ),
      'Relationship not mapped',
    );
    expect(familyGraph.missingLinks, isNotEmpty);
  });

  test('family events round-trip in UTC without changing participants', () {
    final event = FamilyEvent(
      id: 'event-1',
      title: 'Family dinner',
      type: FamilyEventType.dinner,
      utcStart: DateTime.utc(2026, 11, 1, 15, 30),
      timezone: 'America/Chicago',
      participants: const ['Hasan', 'Ramsha'],
      notes: 'DST boundary fixture',
    );
    final restored = FamilyEvent.fromJson(event.toJson());
    expect(restored.utcStart, DateTime.utc(2026, 11, 1, 15, 30));
    expect(restored.timezone, 'America/Chicago');
    expect(restored.participants, ['Hasan', 'Ramsha']);
  });

  testWidgets('polished monthly calendar works on a narrow dark phone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settings = const AppSettings(
      themeMode: ThemeMode.dark,
      reducedMotion: true,
    );
    await tester.pumpWidget(
      AppSettingsScope(
        controller: AppSettingsController(initial: settings),
        child: MaterialApp(
          theme: PourToujoursTheme.build(settings.theme, Brightness.light),
          darkTheme: PourToujoursTheme.build(settings.theme, Brightness.dark),
          themeMode: ThemeMode.dark,
          home: const FamilyCalendarFinalScreen(viewerName: 'Hasan'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('polished-month-grid')), findsOneWidget);
    expect(find.text('Birthdays'), findsOneWidget);
    expect(find.text('Holidays'), findsOneWidget);
    expect(find.text('Family events'), findsOneWidget);
    expect(find.text('Add event'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('planner is not part of the final product surface', (
    tester,
  ) async {
    final settings = const AppSettings(reducedMotion: true);
    await tester.pumpWidget(
      AppSettingsScope(
        controller: AppSettingsController(initial: settings),
        child: MaterialApp(
          theme: PourToujoursTheme.build(settings.theme, Brightness.light),
          home: const FamilyCalendarFinalScreen(viewerName: 'Hasan'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Family contact planner'), findsNothing);
    expect(find.text('Plan a call'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('birthday detail keeps age unknown without a birth year', (
    tester,
  ) async {
    final settings = const AppSettings(reducedMotion: true);
    await tester.pumpWidget(
      AppSettingsScope(
        controller: AppSettingsController(initial: settings),
        child: MaterialApp(
          theme: PourToujoursTheme.build(settings.theme, Brightness.light),
          home: const BirthdayDetailScreen(
            payload: BirthdayRoutePayload(
              personName: 'Ramsha',
              viewerName: 'Hasan',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('15 January'), findsOneWidget);
    expect(find.text('Unknown — no birth year provided'), findsOneWidget);
    expect(find.text('Open person'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
