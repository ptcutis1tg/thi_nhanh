import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/exam/taking_exam_screen.dart';

void main() {
  testWidgets('TakingExamScreen auto-submits when host closes room', (tester) async {
    bool submitted = false;

    final dummyQuestions = [
      {
        'id': 'q1',
        'body': 'Câu hỏi 1?',
        'options': [
          {'id': 'opt1', 'body': 'A', 'is_correct': true},
          {'id': 'opt2', 'body': 'B', 'is_correct': false},
        ],
      }
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TakingExamScreen(
            examId: 'test-exam',
            roomId: 'test-room-123',
            initialQuestions: dummyQuestions,
            onSubmitAttempt: (payload) async {
              submitted = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Câu hỏi 1?'), findsOneWidget);

    // Get the state and trigger _handleHostClosedRoom (or public test helper)
    final state = tester.state(find.byType(TakingExamScreen)) as dynamic;
    state.handleHostClosedRoom();
    await tester.pumpAndSettle();

    expect(submitted, isTrue);
    expect(find.text('Phòng thi đã kết thúc bởi giáo viên. Đang tự động nộp bài...'), findsOneWidget);
  });
}
