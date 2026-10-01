import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/question_draft.dart';

void main() {
  group('QuestionDraft tests', () {
    test('Default QuestionDraft initializes with singleChoice and 4 options', () {
      final draft = QuestionDraft(id: 'q1');
      expect(draft.type, QuestionType.singleChoice);
      expect(draft.answers.length, 4);
      expect(draft.correctAnswers, [0]);
    });

    test('Serialization to and from JSON preserves all fields', () {
      final original = QuestionDraft(
        id: 'q2',
        type: QuestionType.multipleChoice,
        body: r'Giải phương trình $x^2 = 4$',
        answers: ['-2', '2', '0', '4'],
        correctAnswers: [0, 1],
        points: '2',
        timeLimitSeconds: 60,
        explanation: 'Phương trình có 2 nghiệm x = 2 hoặc x = -2.',
      );

      final json = original.toJson();
      final restored = QuestionDraft.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, QuestionType.multipleChoice);
      expect(restored.body, original.body);
      expect(restored.answers, original.answers);
      expect(restored.correctAnswers, [0, 1]);
      expect(restored.timeLimitSeconds, 60);
      expect(restored.explanation, original.explanation);
    });

    test('fromJson gracefully falls back for legacy question formats', () {
      final legacyJson = {
        'id': 'legacy_1',
        'body': 'Legacy question',
        'answers': ['A', 'B', 'C', 'D'],
        'correctAnswer': 2,
        'points': 1,
      };

      final restored = QuestionDraft.fromJson(legacyJson);
      expect(restored.type, QuestionType.singleChoice);
      expect(restored.correctAnswers, [2]);
    });
  });
}
