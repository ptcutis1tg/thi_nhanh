import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/models/assessment.dart';
import 'package:onthi_community/core/repositories/assessment_repository.dart';
import 'package:onthi_community/screens/exam/taking_exam_screen.dart';

class _FakeAssessmentRepository implements AssessmentRepository {
  final AttemptPayload Function(String attemptId)? onLoadAttempt;
  final Future<AttemptSubmissionResult> Function(String attemptId)? onSubmit;

  _FakeAssessmentRepository({this.onLoadAttempt, this.onSubmit});

  @override
  Future<AttemptPayload> loadAttempt(String attemptId) async {
    if (onLoadAttempt != null) {
      return onLoadAttempt!(attemptId);
    }
    throw UnimplementedError();
  }

  @override
  Future<AttemptSubmissionResult> submit(String attemptId) async {
    if (onSubmit != null) {
      return onSubmit!(attemptId);
    }
    return AttemptSubmissionResult(
      attemptId: attemptId,
      status: 'submitted',
      resultReleased: true,
      answeredCount: 1,
      totalQuestions: 1,
      score: 10.0,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final sampleExamQuestions = [
    ExamQuestion(
      id: 'q1',
      position: 1,
      body: '1 + 1 = ?',
      points: 1.0,
      options: [
        ExamOption(id: 'opt1', position: 1, body: '2'),
        ExamOption(id: 'opt2', position: 2, body: '3'),
      ],
    ),
  ];

  Widget buildTestApp({
    required String attemptId,
    required _FakeAssessmentRepository repo,
    void Function(String uri)? onNavigated,
  }) {
    final router = GoRouter(
      initialLocation: '/taking_exam?attemptId=$attemptId',
      routes: [
        GoRoute(
          path: '/taking_exam',
          builder: (context, state) => TakingExamScreen(
            attemptId: state.uri.queryParameters['attemptId'],
            enableAntiCheat: false,
          ),
        ),
        GoRoute(
          path: '/student/history',
          builder: (context, state) {
            onNavigated?.call(state.uri.toString());
            return Scaffold(
              body: Text('History Target: ${state.uri.queryParameters['tab']}'),
            );
          },
        ),
        GoRoute(
          path: '/result',
          builder: (context, state) {
            onNavigated?.call(state.uri.toString());
            return Scaffold(
              body: Text('Result Target: ${state.uri.queryParameters['attemptId']}'),
            );
          },
        ),
      ],
    );

    return MultiProvider(
      providers: [
        Provider<AssessmentRepository>.value(value: repo),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('TakingExamScreen shows expired dialog when opening an expired attempt and allows navigation back to history', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? lastNavigated;
    final repo = _FakeAssessmentRepository(
      onLoadAttempt: (id) => AttemptPayload(
        attemptId: id,
        title: 'Đề Toán Đã Hết Giờ',
        durationMinutes: 45,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 10)),
        status: 'expired',
        questions: sampleExamQuestions,
        answers: {'q1': 'opt1'},
      ),
    );

    await tester.pumpWidget(
      buildTestApp(
        attemptId: 'att-expired-1',
        repo: repo,
        onNavigated: (uri) => lastNavigated = uri,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify dialog content
    expect(find.text('Bài thi đã hết thời gian'), findsOneWidget);
    expect(find.textContaining('Thời gian làm bài cho đề thi này đã kết thúc trước đó'), findsOneWidget);
    expect(find.text('Đã làm: 1/1 câu'), findsOneWidget);

    final historyBtn = find.text('Quay về Lịch sử');
    expect(historyBtn, findsOneWidget);

    await tester.tap(historyBtn);
    await tester.pumpAndSettle();

    expect(lastNavigated, '/student/history?tab=in_progress');
  });

  testWidgets('TakingExamScreen shows already submitted dialog when opening a submitted attempt', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? lastNavigated;
    final repo = _FakeAssessmentRepository(
      onLoadAttempt: (id) => AttemptPayload(
        attemptId: id,
        title: 'Đề Đã Nộp',
        durationMinutes: 45,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 5)),
        status: 'submitted',
        questions: sampleExamQuestions,
        answers: {'q1': 'opt1'},
      ),
    );

    await tester.pumpWidget(
      buildTestApp(
        attemptId: 'att-submitted-1',
        repo: repo,
        onNavigated: (uri) => lastNavigated = uri,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    // Verify already submitted dialog
    expect(find.text('Bài thi đã nộp'), findsOneWidget);
    expect(find.textContaining('Bài thi này đã được hoàn thành và nộp trước đó'), findsOneWidget);

    final viewResultBtn = find.text('Xem kết quả');
    expect(viewResultBtn, findsOneWidget);

    await tester.tap(viewResultBtn);
    await tester.pumpAndSettle();

    expect(lastNavigated, '/result?attemptId=att-submitted-1');
  });

  testWidgets('TakingExamScreen submits expired attempt when user clicks "Nộp bài chấm điểm"', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? submittedAttemptId;
    String? lastNavigated;
    final repo = _FakeAssessmentRepository(
      onLoadAttempt: (id) => AttemptPayload(
        attemptId: id,
        title: 'Đề Hết Hạn Cần Chấm',
        durationMinutes: 45,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 20)),
        status: 'expired',
        questions: sampleExamQuestions,
        answers: {'q1': 'opt1'},
      ),
      onSubmit: (id) async {
        submittedAttemptId = id;
        return AttemptSubmissionResult(
          attemptId: id,
          status: 'submitted',
          resultReleased: true,
          answeredCount: 1,
          totalQuestions: 1,
          score: 10.0,
        );
      },
    );

    await tester.pumpWidget(
      buildTestApp(
        attemptId: 'att-expired-2',
        repo: repo,
        onNavigated: (uri) => lastNavigated = uri,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final submitBtn = find.text('Nộp bài chấm điểm');
    expect(submitBtn, findsOneWidget);

    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    expect(submittedAttemptId, 'att-expired-2');
    expect(lastNavigated, '/result?attemptId=att-expired-2');
  });

  testWidgets('TakingExamScreen handles closed/expired submit error gracefully and routes to history', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? lastNavigated;
    final repo = _FakeAssessmentRepository(
      onLoadAttempt: (id) => AttemptPayload(
        attemptId: id,
        title: 'Đề Đã Đóng',
        durationMinutes: 45,
        expiresAt: DateTime.now().subtract(const Duration(minutes: 50)),
        status: 'expired',
        questions: sampleExamQuestions,
        answers: {'q1': 'opt1'},
      ),
      onSubmit: (id) async {
        throw Exception('PostgrestException: Attempt is closed');
      },
    );

    await tester.pumpWidget(
      buildTestApp(
        attemptId: 'att-closed-err',
        repo: repo,
        onNavigated: (uri) => lastNavigated = uri,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    final submitBtn = find.text('Nộp bài chấm điểm');
    expect(submitBtn, findsOneWidget);

    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Verify graceful error dialog
    expect(find.text('Bài thi đã kết thúc'), findsOneWidget);
    expect(find.textContaining('Bài thi này đã được hệ thống ghi nhận kết thúc hoặc đã quá hạn làm bài.'), findsOneWidget);

    final returnBtn = find.text('Về danh sách bài thi');
    expect(returnBtn, findsOneWidget);

    await tester.tap(returnBtn);
    await tester.pumpAndSettle();

    expect(lastNavigated, '/student/history?tab=in_progress');
  });
}
