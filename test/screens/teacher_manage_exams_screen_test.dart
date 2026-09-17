import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/screens/teacher/teacher_exams_screen.dart';

class MockTeacherExamRepository implements TeacherExamRepository {
  List<TeacherExamSummary> mockList = [
    const TeacherExamSummary(
      id: 'exam-1',
      code: 'DT001',
      title: 'Đề Nháp Số 1',
      subject: 'Toán',
      durationMinutes: 45,
      questionCount: 10,
      status: 'draft',
    ),
    const TeacherExamSummary(
      id: 'exam-2',
      code: 'DT002',
      title: 'Đề Công Khai Số 1',
      subject: 'Vật lý',
      durationMinutes: 60,
      questionCount: 20,
      status: 'published',
    ),
  ];

  @override
  Future<List<TeacherExamSummary>> summaries() async => mockList;

  @override
  Future<void> publish(String examId) async {
    final index = mockList.indexWhere((e) => e.id == examId);
    if (index != -1) {
      final old = mockList[index];
      mockList[index] = TeacherExamSummary(
        id: old.id,
        code: old.code,
        title: old.title,
        subject: old.subject,
        durationMinutes: old.durationMinutes,
        questionCount: old.questionCount,
        status: 'published',
      );
    }
  }

  @override
  Future<void> deleteDraft(String examId) async {
    mockList.removeWhere((e) => e.id == examId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('TeacherExamsScreen renders 3 tabs with badges and filters by tab', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final mockRepo = MockTeacherExamRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TeacherExamRepository>.value(value: mockRepo),
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: Scaffold(body: TeacherExamsScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header title and create button
    expect(find.text('📁 Quản Lý Kho Đề Thi Trắc Nghiệm'), findsOneWidget);
    expect(find.text('Tạo Đề Thi Mới'), findsOneWidget);

    // Verify 3 tabs present with exact counts
    expect(find.text('Tất cả (2)'), findsOneWidget);
    expect(find.text('Đề nháp (1)'), findsOneWidget);
    expect(find.text('Đã công khai (1)'), findsOneWidget);

    // Initial tab 'Tất cả' should show both exams
    expect(find.text('Đề Nháp Số 1'), findsOneWidget);
    expect(find.text('Đề Công Khai Số 1'), findsOneWidget);

    // Tap tab 'Đề nháp'
    await tester.tap(find.textContaining('Đề nháp'));
    await tester.pumpAndSettle();

    expect(find.text('Đề Nháp Số 1'), findsOneWidget);
    expect(find.text('Đề Công Khai Số 1'), findsNothing);
    expect(find.text('Public đề'), findsOneWidget);

    // Tap tab 'Đã công khai'
    await tester.tap(find.textContaining('Đã công khai'));
    await tester.pumpAndSettle();

    expect(find.text('Đề Công Khai Số 1'), findsOneWidget);
    expect(find.text('Đề Nháp Số 1'), findsNothing);
    expect(find.text('Tạo Phòng Thi'), findsOneWidget);
  });
}
