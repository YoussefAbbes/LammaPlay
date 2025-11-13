import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class LmTypography {
  // Base text themes merged onto GoogleFonts Rubik
  static final textTheme = TextTheme(
    displayLarge: GoogleFonts.rubik(
      fontWeight: FontWeight.w800,
      fontSize: 44,
      color: LmColors.textPrimaryLight,
    ),
    displayMedium: GoogleFonts.rubik(
      fontWeight: FontWeight.w800,
      fontSize: 36,
      color: LmColors.textPrimaryLight,
    ),
    headlineMedium: GoogleFonts.rubik(
      fontWeight: FontWeight.w700,
      fontSize: 24,
      color: LmColors.textPrimaryLight,
    ),
    bodyLarge: GoogleFonts.rubik(
      fontWeight: FontWeight.w400,
      height: 1.4,
      fontSize: 16,
      color: LmColors.textPrimaryLight,
    ),
    bodyMedium: GoogleFonts.rubik(
      fontWeight: FontWeight.w400,
      height: 1.4,
      fontSize: 14,
      color: LmColors.textPrimaryLight,
    ),
    labelLarge: GoogleFonts.rubik(
      fontWeight: FontWeight.w700,
      fontSize: 14,
      color: LmColors.textPrimaryLight,
    ),
  );

  static final textThemeDark = textTheme.apply(
    bodyColor: LmColors.textPrimaryDark,
    displayColor: LmColors.textPrimaryDark,
  );

  static TextStyle number({double fontSize = 18, bool bold = true}) =>
      GoogleFonts.rubik(
        fontFeatures: const [FontFeature.tabularFigures()],
        fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        fontSize: fontSize,
      );
}
