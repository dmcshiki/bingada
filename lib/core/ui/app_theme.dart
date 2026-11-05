import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens from the canvas "Tokingo – telas" (§8). No brand assets.
abstract final class AppColors {
  static const primary = Color(0xFF779CCF);
  static const primaryStrong = Color(0xFF4F86C6);
  static const navy = Color(0xFF204A77);
  static const deepBlue = Color(0xFF1868A1);
  static const cyan = Color(0xFF09B5F0);
  static const pink = Color(0xFFC679CC);
  static const purple = Color(0xFF914EC4);
  static const green = Color(0xFF4EC45F);
  static const greenDark = Color(0xFF2E8A3E);
  static const light = Color(0xFFE6E9E9);
  static const surfaceSoft = Color(0xFFF4F6F6);
  static const blueSoft = Color(0xFFEEF3FA);
  static const blob = Color(0xFFD3DBE6);
  static const graphite = Color(0xFF424041);
  static const inkOnLight = Color(0xFF1A2B40);
  static const white = Color(0xFFFFFFFF);

  /// Default column colors (B I N G O).
  static const List<Color> columns = [primary, cyan, green, pink, purple];

  /// Readable foreground for a column/background color (AA).
  static Color onColor(Color c) =>
      c.computeLuminance() > 0.35 ? inkOnLight : white;

  static Color parseHex(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  }
}

abstract final class AppText {
  /// Days One: numbers, ball, column letters, BINGO, wordmark.
  static TextStyle display(double size, {Color? color}) =>
      GoogleFonts.daysOne(fontSize: size, color: color, height: 1.1);

  /// Montserrat: everything else.
  static TextStyle body(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color? color,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.montserrat(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );

  /// JetBrains Mono: hashes and ids (audit).
  static TextStyle mono(double size, {Color? color}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, color: color);

  /// Small uppercase kicker, e.g. "VALENDO AGORA".
  static TextStyle kicker({Color? color}) =>
      body(12, weight: FontWeight.w700, color: color, letterSpacing: .6);
}

abstract final class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.primary,
        error: AppColors.purple,
        surface: AppColors.white,
      ),
      scaffoldBackgroundColor: AppColors.light,
      fontFamily: GoogleFonts.montserrat().fontFamily,
    );
    return base.copyWith(
      // Screen changes fade forward instead of cutting (web default is none).
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final p in TargetPlatform.values)
            p: const FadeForwardsPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.light, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.light, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}
