import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - Deep Sapphire & Electric Cyan / Teal
  static const Color primary = Color(0xFF00B4DB);
  static const Color primaryBright = Color(0xFF00F2FE);
  static const Color primaryWash = Color(0xFF0D2838);
  static const Color accentGradientStart = Color(0xFF00F2FE);
  static const Color accentGradientEnd = Color(0xFF4FACFE);

  // Surface & Background Colors
  static const Color bgDark = Color(0xFF0A0E17);
  static const Color surfaceDark = Color(0xFF131924);
  static const Color cardDark = Color(0xFF1A2232);
  static const Color borderDark = Color(0xFF263348);
  static const Color borderLightGlow = Color(0xFF384A68);

  // Status Token Colors
  static const Color colorAvailable = Color(0xFF10B981); // Emerald
  static const Color colorHeld = Color(0xFFF59E0B);      // Amber
  static const Color colorBooked = Color(0xFFEF4444);    // Crimson

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    colorScheme: const ColorScheme.dark(
      primary: primaryBright,
      secondary: primary,
      surface: surfaceDark,
    ),
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceDark,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: borderDark, width: 1.2),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryBright, width: 2),
      ),
    ),
  );
}
