import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Primary colors (modern teal palette)
  static const Color primary = Color(0xFF0D9488); // Teal 600
  static const Color primaryDark = Color(0xFF0F766E); // Teal 700
  static const Color primaryLight = Color(0xFF2DD4BF); // Teal 400

  // Status colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Common Grays - NO PURE WHITE/BLACK
  static const Color white = Color(0xFFFDFDFD);
  static const Color black = Color(0xFF0B0F19);
}

class LightColors {
  // Soft, premium elegant light theme neutrals
  static const Color background = Color(0xFFF8FAFC); // Very subtle slate 50
  static const Color backgroundSecondary = Color(0xFFF1F5F9); // Slate 100
  static const Color card = Color(0xFFFFFFFF); // Pure white, relies on elegant shadows

  static const Color textPrimary = Color(0xFF0F172A); // Very dark slate (readable but soft)
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textTertiary = Color(0xFF64748B); // Slate 500 (improved contrast from 400)

  static const Color border = Color(0xFFE2E8F0); // Slate 200
  static const Color divider = Color(0xFFCBD5E1); // Slate 300
}

class DarkColors {
  // Tinted neutrals for dark theme (Slate-based instead of pure black)
  static const Color background = Color(0xFF0F172A); // Slate 900
  static const Color backgroundSecondary = Color(0xFF1E293B); // Slate 800
  static const Color card = Color(0xFF1E293B); // Slate 800

  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textTertiary = Color(0xFF64748B); // Slate 500

  static const Color border = Color(0xFF334155); // Slate 700
  static const Color divider = Color(0xFF475569); // Slate 600
}

class AppTheme {
  static TextTheme _buildTextTheme(TextTheme base, Color primaryColor, Color secondaryColor, Color tertiaryColor) {
    return GoogleFonts.plusJakartaSansTextTheme(base).copyWith(
      displayLarge: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.w800, letterSpacing: -1.0),
      displayMedium: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      displaySmall: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineMedium: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.w600),
      titleSmall: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.w400),
      bodyMedium: GoogleFonts.plusJakartaSans(color: secondaryColor, fontWeight: FontWeight.w400),
      bodySmall: GoogleFonts.plusJakartaSans(color: tertiaryColor, fontWeight: FontWeight.w400),
      labelLarge: GoogleFonts.plusJakartaSans(color: primaryColor, fontWeight: FontWeight.w600, letterSpacing: 0.2),
      labelMedium: GoogleFonts.plusJakartaSans(color: secondaryColor, fontWeight: FontWeight.w500),
      labelSmall: GoogleFonts.plusJakartaSans(color: tertiaryColor, fontWeight: FontWeight.w500),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: LightColors.background,
      cardColor: LightColors.card,
      dividerColor: LightColors.divider,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: LightColors.card,
        error: AppColors.error,
        onSurface: LightColors.textPrimary,
      ),
      textTheme: _buildTextTheme(ThemeData.light().textTheme, LightColors.textPrimary, LightColors.textSecondary, LightColors.textTertiary),
      appBarTheme: const AppBarTheme(
        backgroundColor: LightColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: LightColors.textPrimary),
        titleTextStyle: TextStyle(
          color: LightColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: LightColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: LightColors.textTertiary,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: DarkColors.background,
      cardColor: DarkColors.card,
      dividerColor: DarkColors.divider,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
        surface: DarkColors.card,
        error: AppColors.error,
        onSurface: DarkColors.textPrimary,
      ),
      textTheme: _buildTextTheme(ThemeData.dark().textTheme, DarkColors.textPrimary, DarkColors.textSecondary, DarkColors.textTertiary),
      appBarTheme: const AppBarTheme(
        backgroundColor: DarkColors.background,
        elevation: 0,
        iconTheme: IconThemeData(color: DarkColors.textPrimary),
        titleTextStyle: TextStyle(
          color: DarkColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: DarkColors.card,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: DarkColors.textTertiary,
        elevation: 10,
      ),
      useMaterial3: true,
    );
  }
}


