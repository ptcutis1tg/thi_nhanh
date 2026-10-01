import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/question_draft.dart';
import 'package:onthi_community/screens/exam/widgets/student_exam_preview_dialog.dart';

void main() {
  testWidgets('StudentExamPreviewDialog renders exam title, questions, and toggles answers', (tester) async {
    final questions = [
      QuestionDraft(
        id: '1',
        body: r'Giải phương trình $x^2 - 4 = 0$',
        answers: ['x = 2', 'x = -2', 'x = ±2', 'Vô nghiệm'],
        correctAnswers: [2],
        explanation: 'Phương trình tương đương (x-2)(x+2) = 0.',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentExamPreviewDialog(
            examTitle: 'Đề thi Thử Đại Học',
            subject: 'Toán',
            durationMinutes: 45,
            questions: questions,
          ),
        ),
      ),
    );

    expect(find.text('Xem trước góc nhìn học sinh'), findsOneWidget);
    expect(find.text('Đề thi Thử Đại Học'), findsOneWidget);
    expect(find.text('Câu 1/1'), findsOneWidget);

    // Check solution toggle
    final toggleBtn = find.text('Hiện đáp án & Lời giải');
    expect(toggleBtn, findsOneWidget);
    await tester.tap(toggleBtn);
    await tester.pump();

    expect(find.text('Phương trình tương đương (x-2)(x+2) = 0.'), findsOneWidget);
  });
}
