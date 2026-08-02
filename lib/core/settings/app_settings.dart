import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PtThemeCollection { evergreen, cherryCola, midnight, mint, sunset, paper }
enum TemperatureUnit { celsius, fahrenheit }
enum WindUnit { kilometersPerHour, milesPerHour }
enum ClockFormat { twelveHour, twentyFourHour }

class CupertinoPageTransitionsBuilder extends PageTransitionsBuilder {
  const CupertinoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

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
      theme: _enumValue(
        PtThemeCollection.values,
        prefs.getString('themeCollection'),
        PtThemeCollection.evergreen,
      ),
      themeMode: _enumValue(
        ThemeMode.values,
        prefs.getString('themeMode'),
        ThemeMode.system,
      ),
      temperatureUnit: _enumValue(
        TemperatureUnit.values,
        prefs.getString('temperatureUnit'),
        TemperatureUnit.celsius,
      ),
      windUnit: _enumValue(
        WindUnit.values,
        prefs.getString('windUnit'),
        WindUnit.kilometersPerHour,
      ),
      clockFormat: _enumValue(
        ClockFormat.values,
        prefs.getString('clockFormat'),
        ClockFormat.twelveHour,
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

  static T _enumValue<T extends Enum>(
    List<T> values,
    String? stored,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == stored) return value;
    }
    return fallback;
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
