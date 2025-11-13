import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lamaplay/core/theme/colors.dart';
import 'package:lamaplay/core/theme/typography.dart';

/// Defines light and dark themes for the app.
class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: LmColors.primary,
        brightness: Brightness.light,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.rubikTextTheme(
        base.textTheme,
      ).merge(LmTypography.textTheme),
      scaffoldBackgroundColor: LmColors.surfaceLight,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: LmColors.textPrimaryLight,
        titleTextStyle: GoogleFonts.rubik(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: LmColors.textPrimaryLight,
        ),
      ),
      cardTheme: const CardThemeData(
        color: LmColors.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.rubik(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: LmColors.primary,
        brightness: Brightness.dark,
      ),
    );
    return base.copyWith(
      textTheme: GoogleFonts.rubikTextTheme(
        base.textTheme,
      ).merge(LmTypography.textThemeDark),
      scaffoldBackgroundColor: LmColors.surfaceDark,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: LmColors.textPrimaryDark,
        titleTextStyle: GoogleFonts.rubik(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: LmColors.textPrimaryDark,
        ),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF101726),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: GoogleFonts.rubik(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
