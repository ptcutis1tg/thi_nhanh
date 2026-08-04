import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Design Tokens - Colors
  static const Color primary = Color(0xFF6557E8); // Primary Violet
  static const Color primaryLight = Color(0xFF9B91F5); 
  static const Color primaryContainer = Color(0xFFE4DFFF); 
  
  static const Color background = Color(0xFFF8F8FC); // Paper
  static const Color surface = Color(0xFFFFFFFF);
  
  static const Color textMain = Color(0xFF24233A); // Ink
  static const Color textSecondary = Color(0xFF74748B); // Muted
  
  static const Color border = Color(0xFFE7E6EF); // Line
  
  static const Color success = Color(0xFF27885E);
  static const Color warning = Color(0xFFC87909);
  static const Color error = Color(0xFFBA1A1A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: primaryLight,
        surface: surface,
        background: background,
        error: error,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.beVietnamProTextTheme().copyWith(
        displayLarge: GoogleFonts.beVietnamPro(color: textMain, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.beVietnamPro(color: textMain, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.beVietnamPro(color: textMain, fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.beVietnamPro(color: textMain, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.beVietnamPro(color: textMain),
        bodyMedium: GoogleFonts.beVietnamPro(color: textMain),
        bodySmall: GoogleFonts.beVietnamPro(color: textSecondary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: textSecondary),
      ),
    );
  }
}
