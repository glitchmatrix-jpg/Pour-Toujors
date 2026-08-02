import 'package:flutter/material.dart';

abstract final class PtColors {
  static const ink = Color(0xFF17202A);
  static const mutedInk = Color(0xFF5F6872);
  static const paper = Color(0xFFF7F3EA);
  static const surface = Color(0xFFFFFCF6);
  static const line = Color(0xFFE5DED2);
  static const midnight = Color(0xFF24324A);
  static const mist = Color(0xFFDCE4E8);
  static const sun = Color(0xFFE6B866);
  static const leaf = Color(0xFF78947D);
  static const mauve = Color(0xFF9A8194);
}

abstract final class PourToujoursTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: PtColors.midnight,
      brightness: Brightness.light,
      surface: PtColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: PtColors.paper,
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 34,
          height: 1.08,
          fontWeight: FontWeight.w600,
          letterSpacing: -1.2,
          color: PtColors.ink,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          height: 1.15,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
          color: PtColors.ink,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: PtColors.ink,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          height: 1.45,
          color: PtColors.ink,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.4,
          color: PtColors.mutedInk,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: PtColors.surface,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(28)),
          side: BorderSide(color: PtColors.line),
        ),
      ),
      dividerTheme: const DividerThemeData(color: PtColors.line),
    );
  }
}
