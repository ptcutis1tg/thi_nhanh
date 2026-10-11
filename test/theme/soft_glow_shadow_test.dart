import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/theme/app_theme.dart';

void main() {
  test('AppTheme.softGlowShadow provides soft subtle gray shadow for floating blocks', () {
    final shadows = AppTheme.softGlowShadow;
    expect(shadows, isNotEmpty);
    expect(shadows.length, greaterThanOrEqualTo(2));
    expect(shadows.first.blurRadius, greaterThanOrEqualTo(10.0));
  });
}
