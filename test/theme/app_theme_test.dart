import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('AppTheme Tokens & Extended Theme Tests', () {
    test('should expose correct Stitch EdTech color tokens', () {
      expect(AppTheme.primary, const Color(0xFF6557E8));
      expect(AppTheme.primaryDark, const Color(0xFF4C3BCE));
      expect(AppTheme.surfaceLavender, const Color(0xFFF7F5FE));
      expect(AppTheme.background, const Color(0xFFF8F8FC));
      expect(AppTheme.textMain, const Color(0xFF24233A));
      expect(AppTheme.textSecondary, const Color(0xFF74748B));
      expect(AppTheme.border, const Color(0xFFE7E6EF));
    });

    test('should provide luminescence and card shadows', () {
      expect(AppTheme.luminescenceShadow, isNotEmpty);
      expect(AppTheme.luminescenceShadow.first.color, const Color(0x146557E8));
      expect(AppTheme.cardShadow, isNotEmpty);
    });

    test('should define consistent border radii', () {
      expect(AppTheme.cardRadius, 16.0);
      expect(AppTheme.pillRadius, 100.0);
      expect(AppTheme.inputRadius, 12.0);
    });

    test('should configure lightTheme with Material3 and custom styles', () {
      final theme = AppTheme.lightTheme;
      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.primary, AppTheme.primary);
      expect(theme.scaffoldBackgroundColor, AppTheme.background);
    });
  });
}
