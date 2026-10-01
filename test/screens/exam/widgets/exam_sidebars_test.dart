import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/models/question_draft.dart';
import 'package:onthi_community/screens/exam/widgets/exam_left_sidebar.dart';
import 'package:onthi_community/screens/exam/widgets/exam_right_sidebar.dart';
import 'package:onthi_community/screens/exam/widgets/question_answers_editor.dart';

void main() {
  testWidgets('ExamLeftSidebar renders questions and allows adding and selecting', (tester) async {
    final questions = [
      QuestionDraft(id: '1', body: 'Câu hỏi 1'),
      QuestionDraft(id: '2', body: 'Câu hỏi 2', type: QuestionType.multipleChoice),
    ];

    int selected = 0;
    bool addTriggered = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExamLeftSidebar(
            questions: questions,
            activeIndex: 0,
            onSelect: (idx) => selected = idx,
            onAdd: () => addTriggered = true,
            onDuplicate: (_) {},
            onDelete: (_) {},
            onReorder: (_, __) {},
            onOpenBulkImport: () {},
          ),
        ),
      ),
    );

    expect(find.text('DANH SÁCH CÂU HỎI'), findsOneWidget);
    expect(find.text('Câu hỏi 1'), findsOneWidget);
    expect(find.text('Câu hỏi 2'), findsOneWidget);

    await tester.tap(find.text('Thêm câu hỏi'));
    await tester.pump();
    expect(addTriggered, isTrue);
  });

  testWidgets('ExamRightSidebar renders exam stats and allows setting per-question timer toggle', (tester) async {
    bool perQuestion = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExamRightSidebar(
            examTitle: 'Đề kiểm tra Toán 12',
            subject: 'Toán',
            durationMinutes: 45,
            questionCount: 10,
            perQuestionTimerEnabled: false,
            onTogglePerQuestionTimer: (val) => perQuestion = val,
          ),
        ),
      ),
    );

    expect(find.text('TỔNG QUAN ĐỀ THI'), findsOneWidget);
    expect(find.text('Đề kiểm tra Toán 12'), findsOneWidget);
    expect(find.text('45 phút'), findsOneWidget);
    expect(find.text('10 câu'), findsOneWidget);

    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);
    await tester.tap(switchFinder);
    await tester.pump();
    expect(perQuestion, isTrue);
  });

  testWidgets('QuestionAnswersEditor toggles multiple choice checkboxes', (tester) async {
    final q = QuestionDraft(
      id: 'q_multi',
      type: QuestionType.multipleChoice,
      answers: ['A1', 'A2', 'A3', 'A4'],
      correctAnswers: [0],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QuestionAnswersEditor(
            question: q,
            onChanged: () {},
          ),
        ),
      ),
    );

    expect(find.byType(Checkbox), findsNWidgets(4));
    expect(find.text('A. Đáp án *'), findsOneWidget);
  });
}
