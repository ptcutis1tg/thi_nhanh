import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AppTheme Miku Tokens & 3D Container Design Tests', () {
    test('should expose correct Hatsune Miku Cyber-Teal and Pale Mint color tokens', () {
      expect(AppTheme.primary, const Color(0xFF39C5BB));
      expect(AppTheme.primaryDark, const Color(0xFF00A896));
      expect(AppTheme.primaryLight, const Color(0xFF7FE3DB));
      expect(AppTheme.primaryContainer, const Color(0xFFE6FAF8));
      expect(AppTheme.accentMagenta, const Color(0xFFE84188));
      expect(AppTheme.background, const Color(0xFFF4FAF9));
      expect(AppTheme.surface, const Color(0xFFFFFFFF));
      expect(AppTheme.textMain, const Color(0xFF1E293B));
      expect(AppTheme.textSecondary, const Color(0xFF64748B));
      expect(AppTheme.border, const Color(0xFFE2EFEF));
    });

    test('should provide luminescence, card, and hover glow shadows', () {
      expect(AppTheme.luminescenceShadow, isNotEmpty);
      expect(AppTheme.cardShadow, isNotEmpty);
      expect(AppTheme.hoverGlowShadow, isNotEmpty);
      expect(AppTheme.hoverGlowShadow.first.blurRadius, 24.0);
    });

    test('should define 4-tier radius hierarchy', () {
      expect(AppTheme.shellRadius, 32.0);
      expect(AppTheme.heroRadius, 24.0);
      expect(AppTheme.cardRadius, 16.0);
      expect(AppTheme.pillRadius, 100.0);
      expect(AppTheme.inputRadius, 12.0);
    });

    test('should configure lightTheme with Material3, Miku ColorScheme, and button hover states', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppTheme.primary);
      expect(theme.scaffoldBackgroundColor, AppTheme.background);
      expect(theme.cardTheme.color, AppTheme.surface);
    });
  });
}
