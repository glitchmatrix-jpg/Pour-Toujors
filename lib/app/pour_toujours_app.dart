import 'package:flutter/material.dart';

import '../core/settings/app_settings.dart';
import '../features/navigation/detail_placeholders.dart';
import '../features/onboarding/identity_gate.dart';
import 'theme/pour_toujours_theme.dart';

class PourToujoursApp extends StatefulWidget {
  const PourToujoursApp({super.key});

  @override
  State<PourToujoursApp> createState() => _PourToujoursAppState();
}

class _PourToujoursAppState extends State<PourToujoursApp> {
  final AppSettingsController _settings = AppSettingsController();

  @override
  void initState() {
    super.initState();
    _settings.load();
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      controller: _settings,
      child: AnimatedBuilder(
        animation: _settings,
        builder: (context, _) {
          final value = _settings.value;
          return MaterialApp(
            title: 'Pour Toujours',
            debugShowCheckedModeBanner: false,
            themeMode: value.themeMode,
            theme: PourToujoursTheme.build(value.theme, Brightness.light),
            darkTheme: PourToujoursTheme.build(value.theme, Brightness.dark),
            home: const IdentityGate(),
            onGenerateRoute: PourToujoursRoutes.onGenerateRoute,
          );
        },
      ),
    );
  }
}
