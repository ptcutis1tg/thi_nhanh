import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Design Tokens - Hatsune Miku Cyber-Aqua Palette & Pale Mint
  static const Color primary = Color(0xFF39C5BB);          // Miku Vivid Aqua
  static const Color primaryDark = Color(0xFF00A896);      // Deep Cyber Teal
  static const Color primaryDarker = Color(0xFF008080);    // Solid Teal
  static const Color primaryLight = Color(0xFF7FE3DB);     // Soft Cyan Glow
  static const Color primaryContainer = Color(0xFFE6FAF8); // Pale Miku Mint Pill
  static const Color primarySubtle = Color(0xFFF0FDFB);    // Tinted Surface
  
  // Accents & Contrast
  static const Color accentMagenta = Color(0xFFE84188);    // Miku Pink Accent
  static const Color accentCyan = Color(0xFF00F0FF);       // Neon Electric Cyan
  
  // Canvas & Surfaces
  static const Color background = Color(0xFFF4FAF9);       // Milky Mint Canvas
  static const Color surface = Color(0xFFFFFFFF);          // Enamel Pure White
  static const Color surfaceLavender = Color(0xFFE6FAF8);  // Backward compatible surface accent
  static const Color surfaceMuted = Color(0xFFF8FCFC);     // Secondary Surface
  
  // Typography Colors
  static const Color textMain = Color(0xFF1E293B);         // Deep Slate Ink
  static const Color textSecondary = Color(0xFF64748B);    // Muted Slate
  static const Color textPlaceholder = Color(0xFF94A3B8);  // Hint
  
  // Borders
  static const Color border = Color(0xFFE2EFEF);           // 1px Hairline Border
  static const Color borderFocused = Color(0xFF39C5BB);    // Focus Border
  static const Color borderSubtle = Color(0x1A39C5BB);     // Translucent Border
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // 4-Tier Radii Hierarchy
  static const double shellRadius = 32.0;
  static const double heroRadius = 24.0;
  static const double cardRadius = 16.0;
  static const double inputRadius = 12.0;
  static const double pillRadius = 100.0;

  // Shadows
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0A0F2B28),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> luminescenceShadow = [
    BoxShadow(
      color: Color(0x2839C5BB),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> hoverGlowShadow = [
    BoxShadow(
      color: Color(0x3D39C5BB),
      blurRadius: 24,
      offset: Offset(0, 8),
      spreadRadius: 1,
    ),
  ];

  // Monospace Text Style for Code / PIN / Timer
  static TextStyle get firaCodeStyle => GoogleFonts.firaCode(
    color: textMain,
    fontWeight: FontWeight.w600,
  );

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
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: const BorderSide(color: border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return const Color(0xFF45D0C6);
            }
            if (states.contains(WidgetState.disabled)) {
              return primary.withOpacity(0.4);
            }
            return primary;
          }),
          foregroundColor: WidgetStateProperty.all(Colors.white),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return 4.0;
            }
            return 0.0;
          }),
          shadowColor: WidgetStateProperty.all(const Color(0x3D39C5BB)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(pillRadius)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        hintStyle: const TextStyle(color: textPlaceholder),
      ),
    );
  }
}
