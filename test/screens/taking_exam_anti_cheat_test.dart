import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/screens/exam/taking_exam_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final sampleQuestions = [
    {
      'id': 'q-1',
      'position': 1,
      'body': 'Câu hỏi số 1: 1 + 1 bằng bao nhiêu?',
      'options': [
        {'id': 'opt-1-a', 'position': 1, 'body': '1', 'is_correct': false},
        {'id': 'opt-1-b', 'position': 2, 'body': '2', 'is_correct': true},
      ],
    },
    {
      'id': 'q-2',
      'position': 2,
      'body': 'Câu hỏi số 2: Thủ đô của Việt Nam là gì?',
      'options': [
        {'id': 'opt-2-a', 'position': 1, 'body': 'Hà Nội', 'is_correct': true},
        {'id': 'opt-2-b', 'position': 2, 'body': 'TP.HCM', 'is_correct': false},
      ],
    },
  ];

  testWidgets('TakingExamScreen contains SelectionContainer.disabled to lock copy/paste', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: TakingExamScreen(
          examId: 'exam-100',
          shuffleQuestions: false,
          initialQuestions: sampleQuestions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify SelectionContainer.disabled is present in the tree
    expect(find.byType(SelectionContainer), findsWidgets);
  });

  testWidgets('TakingExamScreen detects tab switch/blur, warns 3 times and auto-submits on 4th', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    Map<String, dynamic>? submittedPayload;

    await tester.pumpWidget(
      MaterialApp(
        home: TakingExamScreen(
          examId: 'exam-test-anti-cheat',
          enableAntiCheat: true,
          shuffleQuestions: false,
          initialQuestions: sampleQuestions,
          onSubmitAttempt: (payload) async {
            submittedPayload = payload;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1st VIOLATION: student leaves then returns
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('CẢNH BÁO VI PHẠM'), findsOneWidget);
    expect(find.textContaining('1/3'), findsOneWidget);

    // Dismiss 1st warning
    await tester.tap(find.text('Tôi đã hiểu & Quay lại làm bài'));
    await tester.pumpAndSettle();
    expect(find.text('CẢNH BÁO VI PHẠM'), findsNothing);

    // 2nd VIOLATION
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('CẢNH BÁO VI PHẠM'), findsOneWidget);
    expect(find.textContaining('2/3'), findsOneWidget);

    // Dismiss 2nd warning
    await tester.tap(find.text('Tôi đã hiểu & Quay lại làm bài'));
    await tester.pumpAndSettle();
    expect(find.text('CẢNH BÁO VI PHẠM'), findsNothing);

    // 3rd VIOLATION
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('CẢNH BÁO VI PHẠM'), findsOneWidget);
    expect(find.textContaining('3/3'), findsOneWidget);

    // Dismiss 3rd warning
    await tester.tap(find.text('Tôi đã hiểu & Quay lại làm bài'));
    await tester.pumpAndSettle();
    expect(find.text('CẢNH BÁO VI PHẠM'), findsNothing);

    // 4th VIOLATION -> AUTO SUBMIT!
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(submittedPayload, isNotNull);
    expect(submittedPayload!['violations'], equals(4));
  });

  testWidgets('TakingExamScreen anti-cheat warning dialog renders without overflow on mobile (360x640)', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: TakingExamScreen(
          examId: 'exam-mobile',
          initialQuestions: sampleQuestions,
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('CẢNH BÁO VI PHẠM'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
