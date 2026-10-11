import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/question_content_lines.dart';

void main() {
  test('splits ordinary question lines', () {
    expect(QuestionContentLines.parse('Đề bài\nBiểu thức 1\nBiểu thức 2'), [
      'Đề bài',
      'Biểu thức 1',
      'Biểu thức 2',
    ]);
  });

  test('keeps multiline LaTeX environments in one editor line', () {
    const source = r'''Cho ma trận A
A=\begin{pmatrix}
1 & 2\\
3 & 4
\end{pmatrix}
Tính định thức.''';

    final lines = QuestionContentLines.parse(source);

    expect(lines, hasLength(3));
    expect(lines[1], contains(r'\begin{pmatrix}'));
    expect(lines[1], contains(r'\end{pmatrix}'));
    expect(QuestionContentLines.compile(lines), source);
  });

  test('keeps display math spanning physical lines together', () {
    const source = 'Đề bài\n\$\$x + y\n= 2\$\$\nKết luận';
    final lines = QuestionContentLines.parse(source);

    expect(lines, ['Đề bài', '\$\$x + y\n= 2\$\$', 'Kết luận']);
    expect(QuestionContentLines.compile(lines), source);
  });
}
