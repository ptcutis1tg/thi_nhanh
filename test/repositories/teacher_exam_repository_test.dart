import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';

void main() {
  group('TeacherExamSummary Model', () {
    test('parses all fields from json correctly including code and createdAt', () {
      final json = {
        'id': 'exam-123',
        'code': 'DT001234',
        'title': 'Đề thi Toán học kỳ 1',
        'subject': 'Toán',
        'durationMinutes': 60,
        'questionCount': 25,
        'status': 'draft',
        'createdAt': '2026-09-17T10:00:00Z',
      };

      final summary = TeacherExamSummary.fromJson(json);

      expect(summary.id, 'exam-123');
      expect(summary.code, 'DT001234');
      expect(summary.title, 'Đề thi Toán học kỳ 1');
      expect(summary.subject, 'Toán');
      expect(summary.durationMinutes, 60);
      expect(summary.questionCount, 25);
      expect(summary.status, 'draft');
      expect(summary.isDraft, true);
      expect(summary.isPublished, false);
      expect(summary.createdAt, isNotNull);
    });

    test('isPublished returns true when status is published', () {
      final json = {
        'id': 'exam-456',
        'code': 'DT005678',
        'title': 'Đề thi Vật lý',
        'subject': 'Vật lý',
        'durationMinutes': 45,
        'questionCount': 30,
        'status': 'published',
      };

      final summary = TeacherExamSummary.fromJson(json);

      expect(summary.isDraft, false);
      expect(summary.isPublished, true);
    });
  });
}
