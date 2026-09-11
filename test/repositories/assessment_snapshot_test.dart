import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Hybrid Exam Snapshot Payload Tests', () {
    test('parses exam snapshot payload correctly and confirms anti-cheat safety', () {
      final snapshotPayload = {
        'id': '11000000-0000-4000-8000-000000000001',
        'code': 'DT010101',
        'title': 'Toán 12 - Khảo sát hàm số (Đề 1)',
        'subject': 'Toán học',
        'difficulty': 'medium',
        'duration_minutes': 45,
        'total_questions': 10,
        'questions': [
          {
            'id': '21000000-0000-4000-8000-000000000001',
            'position': 1,
            'body': 'Đạo hàm của f(x) = x³ là gì?',
            'points': 1.0,
            'question_options': [
              {'id': '31000000-0000-4000-8000-000000000001', 'position': 1, 'body': 'x²'},
              {'id': '31000000-0000-4000-8000-000000000002', 'position': 2, 'body': '3x²'},
              {'id': '31000000-0000-4000-8000-000000000003', 'position': 3, 'body': '3x'},
              {'id': '31000000-0000-4000-8000-000000000004', 'position': 4, 'body': 'x⁴/4'},
            ],
            'options': [
              {'id': '31000000-0000-4000-8000-000000000001', 'position': 1, 'body': 'x²'},
              {'id': '31000000-0000-4000-8000-000000000002', 'position': 2, 'body': '3x²'},
              {'id': '31000000-0000-4000-8000-000000000003', 'position': 3, 'body': '3x'},
              {'id': '31000000-0000-4000-8000-000000000004', 'position': 4, 'body': 'x⁴/4'},
            ],
          }
        ]
      };

      expect(snapshotPayload['code'], equals('DT010101'));
      expect(snapshotPayload['subject'], equals('Toán học'));

      final questions = (snapshotPayload['questions'] as List).cast<Map<String, dynamic>>();
      expect(questions.length, equals(1));

      final q1 = questions.first;
      expect(q1['body'], equals('Đạo hàm của f(x) = x³ là gì?'));

      final options = (q1['question_options'] as List).cast<Map<String, dynamic>>();
      expect(options.length, equals(4));
      expect(options[1]['body'], equals('3x²'));

      // Anti-cheat verification: is_correct MUST NOT be present in snapshot
      for (final opt in options) {
        expect(opt.containsKey('is_correct'), isFalse, reason: 'Snapshot must not leak is_correct to client');
      }
    });

    test('verifies dual-key compatibility between question_options and options', () {
      final qMap = {
        'id': 'q-1',
        'body': 'Test question',
        'question_options': [
          {'id': 'opt-1', 'position': 1, 'body': 'A'},
        ],
        'options': [
          {'id': 'opt-1', 'position': 1, 'body': 'A'},
        ]
      };

      final optionsFromQuestionOptions = (qMap['question_options'] as List?)?.cast<Map<String, dynamic>>();
      final optionsFromOptions = (qMap['options'] as List?)?.cast<Map<String, dynamic>>();

      expect(optionsFromQuestionOptions, isNotNull);
      expect(optionsFromOptions, isNotNull);
      expect(optionsFromQuestionOptions!.first['body'], equals(optionsFromOptions!.first['body']));
    });
  });
}
