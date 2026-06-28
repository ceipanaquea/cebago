import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  // --- Hanken Grotesk (Headline & Body) ---
  static TextStyle headlineXl({Color? color}) => GoogleFonts.hankenGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 40 / 32,
        letterSpacing: -0.02 * 32,
        color: color,
      );

  static TextStyle headlineLg({Color? color}) => GoogleFonts.hankenGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
        letterSpacing: -0.01 * 24,
        color: color,
      );

  static TextStyle headlineMd({Color? color}) => GoogleFonts.hankenGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 28 / 20,
        color: color,
      );

  static TextStyle bodyLg({Color? color}) => GoogleFonts.hankenGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        height: 28 / 18,
        color: color,
      );

  static TextStyle bodyMd({Color? color}) => GoogleFonts.hankenGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
        color: color,
      );

  static TextStyle bodySm({Color? color}) => GoogleFonts.hankenGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
        color: color,
      );

  static TextStyle buttonText({Color? color}) => GoogleFonts.hankenGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        height: 24 / 16,
        color: color,
      );

  // --- Plus Jakarta Sans (Labels) ---
  static TextStyle labelLg({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 20 / 14,
        letterSpacing: 0.01 * 14,
        color: color,
      );

  static TextStyle labelSm({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 16 / 12,
        letterSpacing: 0.02 * 12,
        color: color,
      );

  static TextStyle labelXs({Color? color}) => GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        height: 14 / 10,
        letterSpacing: 0.02 * 10,
        color: color,
      );

  // --- TextTheme para MaterialApp ---
  static TextTheme get textTheme => TextTheme(
        displayLarge: headlineXl(),
        displayMedium: headlineLg(),
        displaySmall: headlineMd(),
        headlineLarge: headlineLg(),
        headlineMedium: headlineMd(),
        headlineSmall: bodyLg(),
        titleLarge: headlineMd(),
        titleMedium: bodyLg(),
        titleSmall: bodyMd(),
        bodyLarge: bodyLg(),
        bodyMedium: bodyMd(),
        bodySmall: bodySm(),
        labelLarge: labelLg(),
        labelMedium: labelSm(),
        labelSmall: labelXs(),
      );
}
