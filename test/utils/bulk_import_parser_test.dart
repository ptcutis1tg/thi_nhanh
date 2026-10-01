import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/utils/bulk_import_parser.dart';
import 'package:onthi_community/core/models/question_draft.dart';

void main() {
  test('BulkImportParser parses single choice questions with asterisk marker', () {
    const raw = '''
Câu 1: Cho hàm số f(x) = x^2. Đạo hàm là:
*A. 2x
B. x
C. 2
D. 0
Lời giải: Áp dụng quy tắc tính đạo hàm x^n.

Câu 2: Thủ đô của Pháp là gì?
A. London
*B. Paris
C. Berlin
D. Madrid
''';

    final questions = BulkImportParser.parse(raw);
    expect(questions.length, 2);
    expect(questions[0].body, contains('Cho hàm số f(x) = x^2'));
    expect(questions[0].answers.length, 4);
    expect(questions[0].correctAnswers, [0]);
    expect(questions[0].explanation, contains('Áp dụng quy tắc tính đạo hàm'));

    expect(questions[1].answers.length, 4);
    expect(questions[1].correctAnswers, [1]);
  });

  test('BulkImportParser identifies multiple choice and true/false types', () {
    const raw = '''
Câu 1: Những số nào chia hết cho 2?
*A. 4
B. 5
*C. 8
D. 9

Câu 2: Trái Đất quay quanh Mặt Trời.
*A. Đúng
B. Sai
''';

    final questions = BulkImportParser.parse(raw);
    expect(questions.length, 2);
    expect(questions[0].type, QuestionType.multipleChoice);
    expect(questions[0].correctAnswers, [0, 2]);

    expect(questions[1].type, QuestionType.trueFalse);
    expect(questions[1].correctAnswers, [0]);
  });
}
