import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:pour_toujours/features/onboarding/identity_gate.dart';

void main() {
  setUpAll(tz.initializeTimeZones);

  testWidgets('unknown saved identity returns safely to profile selection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'selected_family_member': 'Deleted profile',
    });

    await tester.pumpWidget(const MaterialApp(home: IdentityGate()));
    await tester.pumpAndSettle();

    expect(find.text('Who are you?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('blank saved identity returns safely to profile selection', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'selected_family_member': '   ',
    });

    await tester.pumpWidget(const MaterialApp(home: IdentityGate()));
    await tester.pumpAndSettle();

    expect(find.text('Who are you?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
