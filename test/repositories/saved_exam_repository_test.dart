import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/repositories/saved_exam_repository.dart';

void main() {
  group('SavedExamRepository Tests', () {
    test('local fallback tracks saved state in memory when Supabase is uninitialized', () async {
      final repo = SavedExamRepository(null);

      expect(await repo.isExamSaved('exam-1'), isFalse);

      final isNowSaved = await repo.toggleSaveExam('exam-1');
      expect(isNowSaved, isTrue);
      expect(await repo.isExamSaved('exam-1'), isTrue);

      final isUnsaved = await repo.toggleSaveExam('exam-1');
      expect(isUnsaved, isFalse);
      expect(await repo.isExamSaved('exam-1'), isFalse);
    });

    test('getSavedExams returns empty or local list gracefully', () async {
      final repo = SavedExamRepository(null);
      final list = await repo.getSavedExams();
      expect(list, isA<List>());
    });
  });
}
