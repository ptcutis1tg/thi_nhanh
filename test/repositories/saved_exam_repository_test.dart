import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onthi_community/core/repositories/saved_exam_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SavedExamRepository Tests', () {
    test('local fallback tracks saved state and persists to storage when Supabase is uninitialized', () async {
      final repo = SavedExamRepository(null);

      expect(await repo.isExamSaved('exam-1'), isFalse);

      final isNowSaved = await repo.toggleSaveExam('exam-1');
      expect(isNowSaved, isTrue);
      expect(await repo.isExamSaved('exam-1'), isTrue);

      // Verify a new repo instance picks up the persisted saved IDs
      final repo2 = SavedExamRepository(null);
      expect(await repo2.isExamSaved('exam-1'), isTrue);
      final savedIds = await repo2.getSavedExamIds();
      expect(savedIds.contains('exam-1'), isTrue);

      final isUnsaved = await repo.toggleSaveExam('exam-1');
      expect(isUnsaved, isFalse);
      expect(await repo.isExamSaved('exam-1'), isFalse);
    });

    test('getSavedExams returns fallback summaries for local saved exams', () async {
      final repo = SavedExamRepository(null);
      await repo.toggleSaveExam('exam-100');

      final list = await repo.getSavedExams();
      expect(list, isNotEmpty);
      expect(list.any((e) => e.id == 'exam-100'), isTrue);
    });
  });
}

