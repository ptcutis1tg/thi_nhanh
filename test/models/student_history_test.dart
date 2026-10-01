import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/services/profile_service.dart';

void main() {
  group('StudentTestHistoryData Tests', () {
    test('instantiates with subject and submittedAt fields', () {
      final now = DateTime(2026, 10, 2, 14, 30);
      final item = StudentTestHistoryData(
        id: 'att-123',
        subjectIcon: '📐',
        title: 'Đề thi Toán đại số',
        date: '02/10/2026',
        score: '8.5 điểm',
        scoreValue: 8.5,
        subject: 'Toán',
        submittedAt: now,
      );

      expect(item.id, 'att-123');
      expect(item.subject, 'Toán');
      expect(item.submittedAt, now);
      expect(item.scoreValue, 8.5);
    });

    test('defaults subject to Khác if not provided', () {
      final item = StudentTestHistoryData(
        id: 'att-456',
        subjectIcon: '📝',
        title: 'Đề tổng hợp',
        date: '01/10/2026',
        score: '5.0 điểm',
        scoreValue: 5.0,
      );

      expect(item.subject, 'Khác');
      expect(item.submittedAt, isNull);
    });
  });
}
