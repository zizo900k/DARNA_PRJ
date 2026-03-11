import 'package:flutter/material.dart';

class AppColors {
  // Primary colors (consistent across themes)
  static const Color primary = Color(0xFF1ABC9C);
  static const Color primaryDark = Color(0xFF16A085);
  static const Color primaryLight = Color(0xFF48C9B0);

  // Status colors
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);
  static const Color info = Color(0xFF3498DB);

  // Common Grays
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}

class LightColors {
  static const Color background = Color(0xFFFFFFFF);
  static const Color backgroundSecondary = Color(0xFFF8F9FA);
  static const Color card = Color(0xFFFFFFFF);

  static const Color textPrimary = Color(0xFF2C3E50);
  static const Color textSecondary = Color(0xFF7F8C8D);
  static const Color textTertiary = Color(0xFF95A5A6);

  static const Color border = Color(0xFFE9ECEF);
  static const Color divider = Color(0xFFDEE2E6);
}

class DarkColors {
  static const Color background = Color(0xFF0F1419);
  static const Color backgroundSecondary = Color(0xFF1A1F26);
  static const Color card = Color(0xFF1E252D);

  static const Color textPrimary = Color(0xFFE8EAED);
  static const Color textSecondary = Color(0xFFB8BABD);
  static const Color textTertiary = Color(0xFF8A8C8F);

  static const Color border = Color(0xFF2A3038);
  static const Color divider = Color(0xFF333A42);
}

class AppTheme {
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
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: LightColors.textPrimary),
        bodyMedium: TextStyle(color: LightColors.textSecondary),
        bodySmall: TextStyle(color: LightColors.textTertiary),
      ),
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
        backgroundColor: LightColors.background,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: LightColors.textTertiary,
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
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: DarkColors.textPrimary),
        bodyMedium: TextStyle(color: DarkColors.textSecondary),
        bodySmall: TextStyle(color: DarkColors.textTertiary),
      ),
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
      ),
      useMaterial3: true,
    );
  }
}
