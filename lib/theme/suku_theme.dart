import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SukuColors {
  // Primary brand palette
  static const green = Color(0xFF00A859);
  static const greenLight = Color(0xFF00C96A);
  static const greenDark = Color(0xFF007A41);
  static const greenSurface = Color(0xFFE8F8EF);

  // Pocket Navy
  static const navy = Color(0xFF102A43);
  static const navyLight = Color(0xFF1A3D5C);
  static const navyDark = Color(0xFF0A1E30);
  static const navySurface = Color(0xFFECF1F6);

  // Chapaa Orange
  static const orange = Color(0xFFFF6B35);
  static const orangeLight = Color(0xFFFF8C5A);
  static const orangeSurface = Color(0xFFFFF0EB);

  // Neutrals
  static const white = Color(0xFFFFFFFF);
  static const background = Color(0xFFF5F7FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0F4F8);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F1923);
  static const textSecondary = Color(0xFF5A7184);
  static const textHint = Color(0xFF9BAAB8);

  // Semantic
  static const success = Color(0xFF00A859);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Category colors
  static const catStock = Color(0xFF8B5CF6);
  static const catRent = Color(0xFF3B82F6);
  static const catSalary = Color(0xFFEC4899);
  static const catTransport = Color(0xFFF59E0B);
  static const catOther = Color(0xFF6B7280);
}

class SukuTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SukuColors.green,
        brightness: Brightness.light,
        primary: SukuColors.green,
        secondary: SukuColors.navy,
        tertiary: SukuColors.orange,
        surface: SukuColors.surface,
      ),
      scaffoldBackgroundColor: SukuColors.background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 32, fontWeight: FontWeight.w800, color: SukuColors.textPrimary, letterSpacing: -1),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 28, fontWeight: FontWeight.w700, color: SukuColors.textPrimary, letterSpacing: -0.5),
        displaySmall: GoogleFonts.plusJakartaSans(
          fontSize: 24, fontWeight: FontWeight.w700, color: SukuColors.textPrimary),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 22, fontWeight: FontWeight.w700, color: SukuColors.textPrimary),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w600, color: SukuColors.textPrimary),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w600, color: SukuColors.textPrimary),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16, fontWeight: FontWeight.w600, color: SukuColors.textPrimary),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w500, color: SukuColors.textPrimary),
        titleSmall: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w500, color: SukuColors.textPrimary),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15, fontWeight: FontWeight.w400, color: SukuColors.textPrimary),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w400, color: SukuColors.textSecondary),
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12, fontWeight: FontWeight.w400, color: SukuColors.textSecondary),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 14, fontWeight: FontWeight.w600, color: SukuColors.textPrimary),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: SukuColors.textPrimary),
        iconTheme: const IconThemeData(color: SukuColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SukuColors.green,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: SukuColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: SukuColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
