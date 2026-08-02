import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PtThemeCollection { evergreen, cherryCola, midnight, mint, sunset, paper }
enum TemperatureUnit { celsius, fahrenheit }
enum WindUnit { kilometersPerHour, milesPerHour }
enum ClockFormat { twelveHour, twentyFourHour }

class AppSettings {
  const AppSettings({
    this.theme = PtThemeCollection.evergreen,
    this.themeMode = ThemeMode.system,
    this.temperatureUnit = TemperatureUnit.celsius,
    this.windUnit = WindUnit.kilometersPerHour,
    this.clockFormat = ClockFormat.twelveHour,
    this.reducedMotion = false,
  });

  final PtThemeCollection theme;
  final ThemeMode themeMode;
  final TemperatureUnit temperatureUnit;
  final WindUnit windUnit;
  final ClockFormat clockFormat;
  final bool reducedMotion;

  AppSettings copyWith({
    PtThemeCollection? theme,
    ThemeMode? themeMode,
    TemperatureUnit? temperatureUnit,
    WindUnit? windUnit,
    ClockFormat? clockFormat,
    bool? reducedMotion,
  }) => AppSettings(
        theme: theme ?? this.theme,
        themeMode: themeMode ?? this.themeMode,
        temperatureUnit: temperatureUnit ?? this.temperatureUnit,
        windUnit: windUnit ?? this.windUnit,
        clockFormat: clockFormat ?? this.clockFormat,
        reducedMotion: reducedMotion ?? this.reducedMotion,
      );
}

class AppSettingsController extends ChangeNotifier {
  AppSettingsController({AppSettings initial = const AppSettings()}) : _value = initial;

  AppSettings _value;
  AppSettings get value => _value;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _value = AppSettings(
      theme: PtThemeCollection.values.byName(
        prefs.getString('themeCollection') ?? PtThemeCollection.evergreen.name,
      ),
      themeMode: ThemeMode.values.byName(
        prefs.getString('themeMode') ?? ThemeMode.system.name,
      ),
      temperatureUnit: TemperatureUnit.values.byName(
        prefs.getString('temperatureUnit') ?? TemperatureUnit.celsius.name,
      ),
      windUnit: WindUnit.values.byName(
        prefs.getString('windUnit') ?? WindUnit.kilometersPerHour.name,
      ),
      clockFormat: ClockFormat.values.byName(
        prefs.getString('clockFormat') ?? ClockFormat.twelveHour.name,
      ),
      reducedMotion: prefs.getBool('reducedMotion') ?? false,
    );
    notifyListeners();
  }

  Future<void> update(AppSettings next) async {
    _value = next;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString('themeCollection', next.theme.name),
      prefs.setString('themeMode', next.themeMode.name),
      prefs.setString('temperatureUnit', next.temperatureUnit.name),
      prefs.setString('windUnit', next.windUnit.name),
      prefs.setString('clockFormat', next.clockFormat.name),
      prefs.setBool('reducedMotion', next.reducedMotion),
    ]);
  }
}

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    super.key,
    required AppSettingsController controller,
    required super.child,
  }) : super(notifier: controller);

  static AppSettingsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope is missing above this context.');
    return scope!.notifier!;
  }
}

extension AppSettingsFormatting on AppSettings {
  String temperature(double celsius, {int decimals = 0}) {
    final value = temperatureUnit == TemperatureUnit.celsius
        ? celsius
        : (celsius * 9 / 5) + 32;
    final suffix = temperatureUnit == TemperatureUnit.celsius ? '°C' : '°F';
    return '${value.toStringAsFixed(decimals)}$suffix';
  }

  String wind(double kilometersPerHour) {
    final value = windUnit == WindUnit.kilometersPerHour
        ? kilometersPerHour
        : kilometersPerHour * 0.621371;
    final suffix = windUnit == WindUnit.kilometersPerHour ? 'km/h' : 'mph';
    return '${value.round()} $suffix';
  }
}
