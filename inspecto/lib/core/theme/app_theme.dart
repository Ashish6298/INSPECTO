import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Dark Mode Palette ---
  static const Color darkBg = Color(0xFF0D0D0D);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkSurfaceVariant = Color(0xFF222222);
  static const Color darkBorder = Color(0xFF2A2A2A);
  static const Color darkText = Color(0xFFE0E0E0);
  static const Color darkPrimary = Color(0xFF818CF8); // Indigo/Purple
  static const Color darkSecondary = Color(0xFF10B981); // Emerald

  // --- Light Mode Palette ---
  static const Color lightBg = Color(0xFFF7F7F9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF0F0F3);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color lightText = Color(0xFF333333);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightPrimary = Color(0xFF6366F1); // Slightly desaturated Indigo
  static const Color lightSecondary = Color(0xFF059669); // Desaturated Emerald

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkPrimary,
        brightness: Brightness.dark,
        surface: darkBg,
        onSurface: darkText,
        primary: darkPrimary,
        secondary: darkSecondary,
        surfaceContainerHighest: darkSurface,
      ),
      scaffoldBackgroundColor: darkBg,
      dividerColor: darkBorder,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkBg,
        indicatorColor: darkPrimary.withOpacity(0.1),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
        ),
      ),
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        bodyMedium: GoogleFonts.inter(color: darkText),
        bodySmall: GoogleFonts.inter(color: Colors.grey[500]),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
      ),
      cardTheme: CardTheme(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: darkPrimary,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: darkPrimary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      inputDecorationTheme: _inputTheme(darkBg, darkBorder, darkPrimary),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lightPrimary,
        brightness: Brightness.light,
        surface: lightBg,
        onSurface: lightText,
        primary: lightPrimary,
        secondary: lightSecondary,
        surfaceContainerHighest: lightSurfaceVariant,
      ),
      scaffoldBackgroundColor: lightBg,
      dividerColor: lightBorder,
      textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme).copyWith(
        titleLarge: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: lightText),
        bodyMedium: GoogleFonts.inter(color: lightText),
        bodySmall: GoogleFonts.inter(color: lightTextSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: lightText),
        iconTheme: IconThemeData(color: lightText),
      ),
      cardTheme: CardTheme(
        color: lightSurface,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 0.5),
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: lightPrimary,
        unselectedLabelColor: lightTextSecondary,
        indicatorColor: lightPrimary,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      inputDecorationTheme: _inputTheme(lightSurface, lightBorder, lightPrimary),
    );
  }

  static InputDecorationTheme _inputTheme(Color fillColor, Color borderColor, Color primaryColor) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 1.5),
      ),
      hintStyle: TextStyle(color: Colors.grey[500]),
    );
  }
}
