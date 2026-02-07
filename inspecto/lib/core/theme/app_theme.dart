import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pure Dark Cyber Palette
  // Background: Pitch Black (0xFF000000)
  // Text: Bright White & Slate Grey
  // Accents: Indigo & Emerald

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6366F1),
        brightness: Brightness.dark,
        surface: const Color(0xFF000000), // Pure Black
        onSurface: const Color(0xFFFFFFFF),
        primary: const Color(0xFF818CF8),
        secondary: const Color(0xFF10B981),
        surfaceContainerHighest: const Color(0xFF000000),
      ),
      scaffoldBackgroundColor: const Color(0xFF000000), // Pitch Black
      dividerColor: const Color(0xFF1A1A1A),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF000000),
        indicatorColor: const Color(0xFF818CF8).withOpacity(0.1),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
        ),
      ),
      textTheme:
          GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.outfit(
            fontWeight: FontWeight.bold, color: const Color(0xFFFFFFFF)),
        bodyMedium: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
        bodySmall: GoogleFonts.inter(color: const Color(0xFF64748B)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF000000),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Color(0xFFFFFFFF)),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF050505), // Extremely dark grey for depth
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1A1A1A), width: 1),
        ),
      ),
      tabBarTheme: TabBarTheme(
        labelColor: const Color(0xFF818CF8),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF818CF8),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle:
            GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle:
            GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
      ),
      inputDecorationTheme: _inputTheme(),
    );
  }

  // Fallback light theme (internal use only, effectively hidden)
  static ThemeData get lightTheme => darkTheme;

  static InputDecorationTheme _inputTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0D0D0D),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A1A1A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1A1A1A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
      ),
      hintStyle: const TextStyle(color: Color(0xFF475569)),
      labelStyle: const TextStyle(
          color: Color(0xFFF1F5F9), fontWeight: FontWeight.w600),
    );
  }
}
