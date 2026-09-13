import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/exam/taking_exam_screen.dart';

void main() {
  final sampleQuestions = [
    {
      'id': 'q1',
      'body': 'Câu hỏi 1: 1 + 1 bằng mấy?',
      'position': 1,
      'options': [
        {'id': 'opt1', 'body': '2', 'is_correct': true, 'position': 1},
        {'id': 'opt2', 'body': '3', 'is_correct': false, 'position': 2},
      ],
    },
    {
      'id': 'q2',
      'body': 'Câu hỏi 2: Thủ đô của Việt Nam là gì?',
      'position': 2,
      'options': [
        {'id': 'opt3', 'body': 'Hà Nội', 'is_correct': true, 'position': 1},
        {'id': 'opt4', 'body': 'Đà Nẵng', 'is_correct': false, 'position': 2},
      ],
    },
  ];

  testWidgets('TakingExamScreen prevents multiple submissions when submit is spam clicked', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    int submitCallCount = 0;
    final submitCompleter = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: TakingExamScreen(
          examId: 'test-exam-id',
          initialQuestions: sampleQuestions,
          onSubmitAttempt: (payload) async {
            submitCallCount++;
            await submitCompleter.future; // Simulate network latency
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Go to the last question (Question 2)
    final nextBtn = find.widgetWithText(ElevatedButton, 'Câu sau');
    expect(nextBtn, findsOneWidget);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // Now button text is 'Nộp bài'
    final submitBtn = find.widgetWithText(ElevatedButton, 'Nộp bài');
    expect(submitBtn, findsOneWidget);

    // Tap 'Nộp bài' - opens confirmation dialog
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Confirmation dialog should appear
    expect(find.text('Xác nhận nộp bài thi'), findsOneWidget);
    expect(find.text('Nộp bài ngay'), findsOneWidget);

    // Find the confirm button in dialog
    final confirmSubmitBtn = find.widgetWithText(ElevatedButton, 'Nộp bài ngay');

    // Spam click 5 times rapidly on the confirm button
    await tester.tap(confirmSubmitBtn);
    await tester.tap(confirmSubmitBtn, warnIfMissed: false);
    await tester.tap(confirmSubmitBtn, warnIfMissed: false);
    await tester.tap(confirmSubmitBtn, warnIfMissed: false);
    await tester.tap(confirmSubmitBtn, warnIfMissed: false);
    await tester.pump();

    // Verify submitCallCount is exactly 1 despite 5 rapid clicks!
    expect(submitCallCount, equals(1));

    // Complete the network call
    submitCompleter.complete();
    await tester.pumpAndSettle();

    // Verify it remains exactly 1
    expect(submitCallCount, equals(1));
  });

  testWidgets('Sidebar submit button also prevents double submission', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    int submitCallCount = 0;
    final submitCompleter = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: TakingExamScreen(
          examId: 'test-exam-id',
          initialQuestions: sampleQuestions,
          onSubmitAttempt: (payload) async {
            submitCallCount++;
            await submitCompleter.future;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Sidebar has 'Nộp bài thi'
    final sidebarSubmitBtn = find.widgetWithText(ElevatedButton, 'Nộp bài thi');
    expect(sidebarSubmitBtn, findsOneWidget);

    await tester.tap(sidebarSubmitBtn);
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Xác nhận nộp bài thi'), findsOneWidget);
    final confirmSubmitBtn = find.widgetWithText(ElevatedButton, 'Nộp bài ngay');

    // Spam click
    await tester.tap(confirmSubmitBtn);
    await tester.tap(confirmSubmitBtn, warnIfMissed: false);
    await tester.tap(confirmSubmitBtn, warnIfMissed: false);
    await tester.pump();

    expect(submitCallCount, equals(1));

    submitCompleter.complete();
    await tester.pumpAndSettle();

    expect(submitCallCount, equals(1));
  });
}
