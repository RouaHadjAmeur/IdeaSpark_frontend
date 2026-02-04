import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const Color primary = Color(0xFF00D9FF);
  static const Color primaryGlow = Color(0x4D00D9FF);
  static const Color secondary = Color(0xFFFF3D71);
  static const Color accent = Color(0xFFFFD93D);
  static const Color success = Color(0xFF00FF88);
  static const Color bgDark = Color(0xFF0A0E1A);
  static const Color bgCard = Color(0xFF151B2D);
  static const Color bgElevated = Color(0xFF1A2139);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B95B0);
  static const Color textTertiary = Color(0xFF5A6482);
  static const Color border = Color(0x268B95B0);

  /// Onboarding / CTA gradient (from reference UI)
  static const Color gradientCyan = Color(0xFF00C2FF);
  static const Color gradientPink = Color(0xFFFF4081);
  static const Color bgOnboarding = Color(0xFF1A1C28);
  static const Color indicatorInactive = Color(0xFF3A3F47);
}

/// Light theme colors (for mode clair) — contrast élevé pour une bonne lisibilité.
class AppColorsLight {
  static const Color primary = Color(0xFF00B8D9);
  static const Color secondary = Color(0xFFE91E63);
  static const Color accent = Color(0xFFF9A825);
  static const Color bgLight = Color(0xFFF5F6FA);
  static const Color bgCard = Color(0xFFFFFFFF);
  static const Color bgElevated = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1D29);
  /// Texte secondaire (métadonnées, footer) — gris foncé lisible sur fond clair.
  static const Color textSecondary = Color(0xFF3D4A5C);
  /// Texte tertiaire (hints) — gris moyen lisible.
  static const Color textTertiary = Color(0xFF5A6578);
  static const Color border = Color(0xFFE2E4E9);
  static const Color success = Color(0xFF00A86B);
}

/// Couleurs s'adaptant au thème (dark/light) pour éviter les écrans non ajustés.
extension ThemeAwareColors on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;
  Color get accentColor => _isDark ? AppColors.accent : AppColorsLight.accent;
  Color get successColor => _isDark ? AppColors.success : AppColorsLight.success;
  Color get errorColor => _isDark ? AppColors.secondary : AppColorsLight.secondary;
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.bgCard,
        error: AppColors.secondary,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onSurfaceVariant: AppColors.textSecondary,
        outlineVariant: AppColors.border,
        surfaceContainerHighest: AppColors.bgElevated,
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.syne(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          decoration: TextDecoration.none,
        ),
        headlineMedium: GoogleFonts.syne(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          decoration: TextDecoration.none,
        ),
        titleLarge: GoogleFonts.syne(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          decoration: TextDecoration.none,
        ),
        titleMedium: GoogleFonts.syne(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          decoration: TextDecoration.none,
        ),
        bodyLarge: GoogleFonts.spaceMono(
          fontSize: 14,
          color: AppColors.textSecondary,
          decoration: TextDecoration.none,
        ),
        bodyMedium: GoogleFonts.spaceMono(
          fontSize: 13,
          color: AppColors.textSecondary,
          decoration: TextDecoration.none,
        ),
        labelLarge: GoogleFonts.syne(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          decoration: TextDecoration.none,
        ),
        bodySmall: GoogleFonts.spaceMono(fontSize: 12, color: AppColors.textSecondary, decoration: TextDecoration.none),
        labelSmall: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary, decoration: TextDecoration.none),
        headlineSmall: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary, decoration: TextDecoration.none),
        titleSmall: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, decoration: TextDecoration.none),
        labelMedium: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary, decoration: TextDecoration.none),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          textStyle: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w500, decoration: TextDecoration.none),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w500, decoration: TextDecoration.none),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgDark,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.syne(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.textTertiary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColorsLight.bgLight,
      colorScheme: ColorScheme.light(
        primary: AppColorsLight.primary,
        secondary: AppColorsLight.secondary,
        surface: AppColorsLight.bgCard,
        error: AppColorsLight.secondary,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColorsLight.textPrimary,
        onSurfaceVariant: AppColorsLight.textSecondary,
        outlineVariant: AppColorsLight.border,
        surfaceContainerHighest: const Color(0xFFE8EAEF),
        onError: Colors.white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.syne(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColorsLight.textPrimary,
          decoration: TextDecoration.none,
        ),
        headlineMedium: GoogleFonts.syne(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColorsLight.textPrimary,
          decoration: TextDecoration.none,
        ),
        titleLarge: GoogleFonts.syne(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColorsLight.textPrimary,
          decoration: TextDecoration.none,
        ),
        titleMedium: GoogleFonts.syne(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColorsLight.textPrimary,
          decoration: TextDecoration.none,
        ),
        bodyLarge: GoogleFonts.spaceMono(
          fontSize: 14,
          color: AppColorsLight.textSecondary,
          decoration: TextDecoration.none,
        ),
        bodyMedium: GoogleFonts.spaceMono(
          fontSize: 13,
          color: AppColorsLight.textSecondary,
          decoration: TextDecoration.none,
        ),
        labelLarge: GoogleFonts.syne(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColorsLight.textPrimary,
          decoration: TextDecoration.none,
        ),
        bodySmall: GoogleFonts.spaceMono(fontSize: 12, color: AppColorsLight.textSecondary, decoration: TextDecoration.none),
        labelSmall: GoogleFonts.syne(fontSize: 11, fontWeight: FontWeight.w500, color: AppColorsLight.textSecondary, decoration: TextDecoration.none),
        headlineSmall: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w600, color: AppColorsLight.textPrimary, decoration: TextDecoration.none),
        titleSmall: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w600, color: AppColorsLight.textPrimary, decoration: TextDecoration.none),
        labelMedium: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w500, color: AppColorsLight.textPrimary, decoration: TextDecoration.none),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColorsLight.bgLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColorsLight.textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorsLight.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.syne(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.none,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsLight.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsLight.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColorsLight.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColorsLight.textTertiary),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColorsLight.bgCard,
        selectedItemColor: AppColorsLight.primary,
        unselectedItemColor: AppColorsLight.textTertiary,
        type: BottomNavigationBarType.fixed,
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsLight.textPrimary,
          textStyle: GoogleFonts.syne(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsLight.textPrimary,
          textStyle: GoogleFonts.syne(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}
