import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/models/assessment.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/exam/wrong_questions_practice_screen.dart';

void main() {
  final sampleReview = AttemptReviewPayload(
    attemptId: 'test-attempt-1',
    examId: 'exam-1',
    title: 'Đề Thi Thử Toán THPT 2026',
    subject: 'Toán',
    status: 'submitted',
    resultReleased: true,
    score: 3.33,
    earnedPoints: 1.0,
    totalPoints: 3.0,
    maxScore: 10.0,
    correctCount: 1,
    wrongCount: 1,
    skippedCount: 1,
    totalQuestions: 3,
    answeredCount: 2,
    questions: [
      const ReviewQuestion(
        id: 'q1',
        position: 1,
        body: 'Câu hỏi 1 (Đã làm đúng): 1 + 1 = ?',
        points: 1.0,
        earnedPoints: 1.0,
        explanation: '1 + 1 = 2 rõ ràng.',
        selectedOptionId: 'opt-1-b',
        correctOptionId: 'opt-1-b',
        options: [
          ReviewOption(id: 'opt-1-a', position: 1, body: '1', isCorrect: false),
          ReviewOption(id: 'opt-1-b', position: 2, body: '2', isCorrect: true),
        ],
      ),
      const ReviewQuestion(
        id: 'q2',
        position: 2,
        body: 'Câu hỏi 2 (Làm sai): Đạo hàm của sin(x) là gì?',
        points: 1.0,
        earnedPoints: 0.0,
        explanation: '(sin x)\' = cos x theo định nghĩa đạo hàm lượng giác.',
        selectedOptionId: 'opt-2-b',
        correctOptionId: 'opt-2-a',
        options: [
          ReviewOption(id: 'opt-2-a', position: 1, body: 'cos(x)', isCorrect: true),
          ReviewOption(id: 'opt-2-b', position: 2, body: '-cos(x)', isCorrect: false),
        ],
      ),
      const ReviewQuestion(
        id: 'q3',
        position: 3,
        body: 'Câu hỏi 3 (Bỏ qua): Tích phân của 1/x dx là gì?',
        points: 1.0,
        earnedPoints: 0.0,
        explanation: 'Nguyên hàm của 1/x là ln|x| + C.',
        selectedOptionId: null,
        correctOptionId: 'opt-3-a',
        options: [
          ReviewOption(id: 'opt-3-a', position: 1, body: 'ln|x| + C', isCorrect: true),
          ReviewOption(id: 'opt-3-b', position: 2, body: 'e^x + C', isCorrect: false),
        ],
      ),
    ],
  );

  testWidgets('WrongQuestionsPracticeScreen filters and displays only wrong/skipped questions', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/practice/wrong_questions',
            routes: [
              GoRoute(
                path: '/practice/wrong_questions',
                builder: (_, __) => WrongQuestionsPracticeScreen(
                  attemptId: 'test-attempt-1',
                  testReviewPayload: sampleReview,
                ),
              ),
              GoRoute(
                path: '/student/history',
                builder: (_, __) => const Scaffold(body: Text('History Screen')),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Badge
    expect(find.text('Luyện Lại Câu Sai'), findsOneWidget);
    expect(find.text('2 câu cần khắc phục'), findsOneWidget);

    // Verify Correct Question 1 is filtered out
    expect(find.text('Câu hỏi 1 (Đã làm đúng): 1 + 1 = ?'), findsNothing);

    // Verify Wrong Question 2 and Skipped Question 3 are present
    expect(find.text('Câu hỏi 2 (Làm sai): Đạo hàm của sin(x) là gì?'), findsOneWidget);
    expect(find.text('Câu hỏi 3 (Bỏ qua): Tích phân của 1/x dx là gì?'), findsOneWidget);
  });

  testWidgets('WrongQuestionsPracticeScreen allows interactive re-answering and reveals explanation', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/practice/wrong_questions',
            routes: [
              GoRoute(
                path: '/practice/wrong_questions',
                builder: (_, __) => WrongQuestionsPracticeScreen(
                  attemptId: 'test-attempt-1',
                  testReviewPayload: sampleReview,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap correct option 'cos(x)' for Question 2
    final correctOptionFinder = find.text('cos(x)');
    expect(correctOptionFinder, findsOneWidget);
    await tester.ensureVisible(correctOptionFinder);
    await tester.tap(correctOptionFinder);
    await tester.pumpAndSettle();

    // Explanation should now be visible
    expect(find.textContaining('(sin x)\' = cos x'), findsOneWidget);
  });
}
