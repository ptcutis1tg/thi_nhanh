import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/utils/exam_shuffle_helper.dart';

void main() {
  final sampleQuestions = [
    {
      'id': 'q1',
      'body': 'Câu hỏi 1',
      'question_options': [
        {'id': 'opt1', 'body': 'A', 'is_correct': true},
        {'id': 'opt2', 'body': 'B', 'is_correct': false},
      ],
    },
    {
      'id': 'q2',
      'body': 'Câu hỏi 2',
      'question_options': [
        {'id': 'opt3', 'body': 'C', 'is_correct': false},
        {'id': 'opt4', 'body': 'D', 'is_correct': true},
      ],
    },
    {
      'id': 'q3',
      'body': 'Câu hỏi 3',
      'question_options': [
        {'id': 'opt5', 'body': 'E', 'is_correct': true},
        {'id': 'opt6', 'body': 'F', 'is_correct': false},
      ],
    },
  ];

  test('ExamShuffleHelper produces deterministic order for same seed', () {
    final shuffled1 = ExamShuffleHelper.shuffleQuestionsAndOptions(sampleQuestions, seed: 12345);
    final shuffled2 = ExamShuffleHelper.shuffleQuestionsAndOptions(sampleQuestions, seed: 12345);
    expect(shuffled1.map((q) => q['id']).toList(), equals(shuffled2.map((q) => q['id']).toList()));
    expect(shuffled1.toString(), equals(shuffled2.toString()));
  });

  test('ExamShuffleHelper produces different order for different seeds', () {
    final shuffled1 = ExamShuffleHelper.shuffleQuestionsAndOptions(sampleQuestions, seed: 11111);
    final shuffled2 = ExamShuffleHelper.shuffleQuestionsAndOptions(sampleQuestions, seed: 99999);
    // Across 3 questions, order should differ or options differ
    expect(shuffled1.toString() != shuffled2.toString(), isTrue);
  });

  test('ExamShuffleHelper preserves question and option IDs and correctness', () {
    final shuffled = ExamShuffleHelper.shuffleQuestionsAndOptions(sampleQuestions, seed: 42);
    expect(shuffled.length, equals(3));
    for (final q in shuffled) {
      final opts = (q['question_options'] ?? q['options']) as List;
      expect(opts.length, equals(2));
      expect(opts.any((o) => o['is_correct'] == true), isTrue);
    }
  });

  test('ExamShuffleHelper does not mutate the original questions list', () {
    final originalCopy = sampleQuestions.map((q) => Map<String, dynamic>.from(q)).toList();
    ExamShuffleHelper.shuffleQuestionsAndOptions(sampleQuestions, seed: 999);
    expect(sampleQuestions[0]['id'], equals(originalCopy[0]['id']));
  });
}
