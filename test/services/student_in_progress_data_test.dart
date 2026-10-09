import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/services/profile_service.dart';

void main() {
  group('StudentTestHistoryData in-progress tests', () {
    test('isExpired returns true when expiresAt is in the past', () {
      final item = StudentTestHistoryData(
        id: 'att_expired',
        subjectIcon: '📐',
        title: 'Đề Toán 12',
        date: 'Hôm qua',
        score: '--',
        scoreValue: 0.0,
        status: 'in_progress',
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
        expiresAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );

      expect(item.status, 'in_progress');
      expect(item.isExpired, isTrue);
    });

    test('isExpired returns false when expiresAt is in the future', () {
      final item = StudentTestHistoryData(
        id: 'att_active',
        subjectIcon: '🔬',
        title: 'Đề Hóa 12',
        date: 'Vừa xong',
        score: '--',
        scoreValue: 0.0,
        status: 'in_progress',
        startedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(minutes: 40)),
      );

      expect(item.status, 'in_progress');
      expect(item.isExpired, isFalse);
    });

    test('StudentProfileData.empty provides empty inProgressTests', () {
      final profile = StudentProfileData.empty();
      expect(profile.inProgressTests, isEmpty);
    });
  });
}
