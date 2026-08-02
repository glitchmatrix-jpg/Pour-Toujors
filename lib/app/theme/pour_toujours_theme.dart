import 'package:flutter/material.dart';

import '../../core/settings/app_settings.dart';

@immutable
class PtThemeTokens extends ThemeExtension<PtThemeTokens> {
  const PtThemeTokens({
    required this.card,
    required this.elevated,
    required this.outline,
    required this.secondaryText,
    required this.success,
    required this.warning,
    required this.uncertain,
    required this.asleep,
    required this.working,
    required this.unavailable,
    required this.globe,
    required this.globeAccent,
    required this.birthday,
    required this.holiday,
    required this.chart,
    required this.weatherDay,
    required this.weatherNight,
    required this.cityTint,
  });

  final Color card;
  final Color elevated;
  final Color outline;
  final Color secondaryText;
  final Color success;
  final Color warning;
  final Color uncertain;
  final Color asleep;
  final Color working;
  final Color unavailable;
  final Color globe;
  final Color globeAccent;
  final Color birthday;
  final Color holiday;
  final List<Color> chart;
  final List<Color> weatherDay;
  final List<Color> weatherNight;
  final Color cityTint;

  @override
  PtThemeTokens copyWith({
    Color? card,
    Color? elevated,
    Color? outline,
    Color? secondaryText,
    Color? success,
    Color? warning,
    Color? uncertain,
    Color? asleep,
    Color? working,
    Color? unavailable,
    Color? globe,
    Color? globeAccent,
    Color? birthday,
    Color? holiday,
    List<Color>? chart,
    List<Color>? weatherDay,
    List<Color>? weatherNight,
    Color? cityTint,
  }) => PtThemeTokens(
        card: card ?? this.card,
        elevated: elevated ?? this.elevated,
        outline: outline ?? this.outline,
        secondaryText: secondaryText ?? this.secondaryText,
        success: success ?? this.success,
        warning: warning ?? this.warning,
        uncertain: uncertain ?? this.uncertain,
        asleep: asleep ?? this.asleep,
        working: working ?? this.working,
        unavailable: unavailable ?? this.unavailable,
        globe: globe ?? this.globe,
        globeAccent: globeAccent ?? this.globeAccent,
        birthday: birthday ?? this.birthday,
        holiday: holiday ?? this.holiday,
        chart: chart ?? this.chart,
        weatherDay: weatherDay ?? this.weatherDay,
        weatherNight: weatherNight ?? this.weatherNight,
        cityTint: cityTint ?? this.cityTint,
      );

  @override
  PtThemeTokens lerp(covariant PtThemeTokens? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    List<Color> list(List<Color> a, List<Color> b) => [
          for (var i = 0; i < a.length; i++) c(a[i], b[i % b.length]),
        ];
    return PtThemeTokens(
      card: c(card, other.card),
      elevated: c(elevated, other.elevated),
      outline: c(outline, other.outline),
      secondaryText: c(secondaryText, other.secondaryText),
      success: c(success, other.success),
      warning: c(warning, other.warning),
      uncertain: c(uncertain, other.uncertain),
      asleep: c(asleep, other.asleep),
      working: c(working, other.working),
      unavailable: c(unavailable, other.unavailable),
      globe: c(globe, other.globe),
      globeAccent: c(globeAccent, other.globeAccent),
      birthday: c(birthday, other.birthday),
      holiday: c(holiday, other.holiday),
      chart: list(chart, other.chart),
      weatherDay: list(weatherDay, other.weatherDay),
      weatherNight: list(weatherNight, other.weatherNight),
      cityTint: c(cityTint, other.cityTint),
    );
  }
}

extension PtThemeContext on BuildContext {
  PtThemeTokens get pt => Theme.of(this).extension<PtThemeTokens>()!;
}

abstract final class PourToujoursTheme {
  static ThemeData build(PtThemeCollection collection, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final palette = _palette(collection, dark);
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.accent,
      brightness: brightness,
      surface: palette.card,
      primary: palette.accent,
      secondary: palette.secondary,
      error: palette.warning,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      canvasColor: palette.background,
      extensions: [palette.tokens],
      textTheme: TextTheme(
        displaySmall: TextStyle(
          fontSize: 36,
          height: 1.04,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.4,
          color: palette.text,
        ),
        headlineSmall: TextStyle(
          fontSize: 26,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
          color: palette.text,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w750,
          color: palette.text,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: palette.text,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.42, color: palette.text),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: palette.tokens.secondaryText,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: palette.card,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: palette.tokens.outline),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: palette.elevated,
        indicatorColor: palette.accent.withValues(alpha: dark ? .28 : .14),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: palette.text, fontWeight: FontWeight.w650),
        ),
      ),
      dividerTheme: DividerThemeData(color: palette.tokens.outline),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: palette.tokens.outline),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static _Palette _palette(PtThemeCollection theme, bool dark) {
    return switch ((theme, dark)) {
      (PtThemeCollection.evergreen, false) => _Palette.light(
          background: const Color(0xFFF2F5F0),
          card: const Color(0xFFFCFDF9),
          elevated: const Color(0xFFE8EFEB),
          text: const Color(0xFF142B29),
          accent: const Color(0xFF2E7A68),
          secondary: const Color(0xFF7D9B86),
          globe: const Color(0xFF0B3938),
          globeAccent: const Color(0xFF6BD1B6),
        ),
      (PtThemeCollection.evergreen, true) => _Palette.dark(
          background: const Color(0xFF071514),
          card: const Color(0xFF102321),
          elevated: const Color(0xFF17302C),
          text: const Color(0xFFF1F7F4),
          accent: const Color(0xFF70CDB2),
          secondary: const Color(0xFF85A99A),
          globe: const Color(0xFF062E31),
          globeAccent: const Color(0xFF8CE5C8),
        ),
      (PtThemeCollection.cherryCola, false) => _Palette.light(
          background: const Color(0xFFFFF7F3),
          card: const Color(0xFFFFFCFA),
          elevated: const Color(0xFFF6E7E3),
          text: const Color(0xFF3B1820),
          accent: const Color(0xFF8B2940),
          secondary: const Color(0xFFC16B6D),
          globe: const Color(0xFF4B1224),
          globeAccent: const Color(0xFFE3A05A),
        ),
      (PtThemeCollection.cherryCola, true) => _Palette.dark(
          background: const Color(0xFF16090D),
          card: const Color(0xFF281017),
          elevated: const Color(0xFF35151E),
          text: const Color(0xFFFFE8EC),
          accent: const Color(0xFFD66C81),
          secondary: const Color(0xFFC38B93),
          globe: const Color(0xFF3B0B19),
          globeAccent: const Color(0xFFF0B56B),
        ),
      (PtThemeCollection.midnight, false) => _Palette.light(
          background: const Color(0xFFF2F4FA),
          card: const Color(0xFFFCFCFF),
          elevated: const Color(0xFFE7EAF5),
          text: const Color(0xFF17213C),
          accent: const Color(0xFF4359B8),
          secondary: const Color(0xFF6C78A5),
          globe: const Color(0xFF111C46),
          globeAccent: const Color(0xFF69A5FF),
        ),
      (PtThemeCollection.midnight, true) => _Palette.dark(
          background: const Color(0xFF070A16),
          card: const Color(0xFF111629),
          elevated: const Color(0xFF181F38),
          text: const Color(0xFFEFF2FF),
          accent: const Color(0xFF7B9CFF),
          secondary: const Color(0xFF9AA5C9),
          globe: const Color(0xFF090F2B),
          globeAccent: const Color(0xFF69B8FF),
        ),
      (PtThemeCollection.mint, false) => _Palette.light(
          background: const Color(0xFFF2FBF7),
          card: const Color(0xFFFCFFFD),
          elevated: const Color(0xFFDFF4EA),
          text: const Color(0xFF16362B),
          accent: const Color(0xFF4AAE88),
          secondary: const Color(0xFF7BAE99),
          globe: const Color(0xFF174C42),
          globeAccent: const Color(0xFF9AE5C9),
        ),
      (PtThemeCollection.mint, true) => _Palette.dark(
          background: const Color(0xFF081814),
          card: const Color(0xFF10271F),
          elevated: const Color(0xFF18372D),
          text: const Color(0xFFE9FFF5),
          accent: const Color(0xFF79D7B2),
          secondary: const Color(0xFF92B9AA),
          globe: const Color(0xFF0B3832),
          globeAccent: const Color(0xFFAEF1D7),
        ),
      (PtThemeCollection.sunset, false) => _Palette.light(
          background: const Color(0xFFFFF6EF),
          card: const Color(0xFFFFFCF8),
          elevated: const Color(0xFFF8E3D7),
          text: const Color(0xFF45243A),
          accent: const Color(0xFFB45F72),
          secondary: const Color(0xFFD48E72),
          globe: const Color(0xFF552844),
          globeAccent: const Color(0xFFFFBE67),
        ),
      (PtThemeCollection.sunset, true) => _Palette.dark(
          background: const Color(0xFF1A0E18),
          card: const Color(0xFF2C1728),
          elevated: const Color(0xFF3A2034),
          text: const Color(0xFFFFECE5),
          accent: const Color(0xFFE78A9E),
          secondary: const Color(0xFFD8A092),
          globe: const Color(0xFF3A1634),
          globeAccent: const Color(0xFFFFC46D),
        ),
      (PtThemeCollection.paper, false) => _Palette.light(
          background: const Color(0xFFF4F0E7),
          card: const Color(0xFFFAF7F0),
          elevated: const Color(0xFFEDE6D8),
          text: const Color(0xFF2B2924),
          accent: const Color(0xFF725C42),
          secondary: const Color(0xFF8C806E),
          globe: const Color(0xFF3C3932),
          globeAccent: const Color(0xFFC5A46F),
        ),
      (PtThemeCollection.paper, true) => _Palette.dark(
          background: const Color(0xFF181613),
          card: const Color(0xFF24211D),
          elevated: const Color(0xFF302C26),
          text: const Color(0xFFF3EBDD),
          accent: const Color(0xFFC9AA78),
          secondary: const Color(0xFFB3A690),
          globe: const Color(0xFF2B2924),
          globeAccent: const Color(0xFFDDBA79),
        ),
    };
  }
}

class _Palette {
  const _Palette({
    required this.background,
    required this.card,
    required this.elevated,
    required this.text,
    required this.accent,
    required this.secondary,
    required this.warning,
    required this.tokens,
  });

  factory _Palette.light({
    required Color background,
    required Color card,
    required Color elevated,
    required Color text,
    required Color accent,
    required Color secondary,
    required Color globe,
    required Color globeAccent,
  }) => _Palette._common(
        background: background,
        card: card,
        elevated: elevated,
        text: text,
        accent: accent,
        secondary: secondary,
        globe: globe,
        globeAccent: globeAccent,
        dark: false,
      );

  factory _Palette.dark({
    required Color background,
    required Color card,
    required Color elevated,
    required Color text,
    required Color accent,
    required Color secondary,
    required Color globe,
    required Color globeAccent,
  }) => _Palette._common(
        background: background,
        card: card,
        elevated: elevated,
        text: text,
        accent: accent,
        secondary: secondary,
        globe: globe,
        globeAccent: globeAccent,
        dark: true,
      );

  factory _Palette._common({
    required Color background,
    required Color card,
    required Color elevated,
    required Color text,
    required Color accent,
    required Color secondary,
    required Color globe,
    required Color globeAccent,
    required bool dark,
  }) {
    final outline = dark ? Colors.white12 : const Color(0x1A2A2A2A);
    final warning = dark ? const Color(0xFFFF9A76) : const Color(0xFFB84D2D);
    return _Palette(
      background: background,
      card: card,
      elevated: elevated,
      text: text,
      accent: accent,
      secondary: secondary,
      warning: warning,
      tokens: PtThemeTokens(
        card: card,
        elevated: elevated,
        outline: outline,
        secondaryText: secondary,
        success: dark ? const Color(0xFF72D7B3) : const Color(0xFF26765F),
        warning: warning,
        uncertain: dark ? const Color(0xFFE8BC68) : const Color(0xFF9A681C),
        asleep: dark ? const Color(0xFF91A4CE) : const Color(0xFF596B91),
        working: dark ? const Color(0xFFE889A2) : const Color(0xFF9B415A),
        unavailable: secondary,
        globe: globe,
        globeAccent: globeAccent,
        birthday: dark ? const Color(0xFFE4A06F) : const Color(0xFFB96B3B),
        holiday: dark ? const Color(0xFFB8A7E6) : const Color(0xFF7059A8),
        chart: [accent, globeAccent, warning, secondary],
        weatherDay: [accent.withValues(alpha: .42), const Color(0xFFF5C978)],
        weatherNight: [globe, dark ? const Color(0xFF26385B) : const Color(0xFF405275)],
        cityTint: accent.withValues(alpha: dark ? .42 : .25),
      ),
    );
  }

  final Color background;
  final Color card;
  final Color elevated;
  final Color text;
  final Color accent;
  final Color secondary;
  final Color warning;
  final PtThemeTokens tokens;
}
