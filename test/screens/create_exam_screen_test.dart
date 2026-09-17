import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/screens/exam/create_exam_screen.dart';

class MockExamRepo implements TeacherExamRepository {
  @override
  Future<String> saveDraft({
    String? examId,
    required String title,
    required String subject,
    required int durationMinutes,
    required List<Map<String, dynamic>> questions,
  }) async => 'new-exam-id-123';

  @override
  Future<void> publish(String examId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('switching questions keeps each question draft independent', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(home: CreateExamScreen()));

    await tester.enterText(find.byKey(const Key('setup-name')), 'Practice exam');
    await tester.tap(find.byKey(const Key('setup-subject')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toán').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('setup-continue')));
    await tester.tap(find.byKey(const Key('setup-continue')));
    await tester.pump();

    await tester.enterText(find.byType(TextFormField).first, 'Question one content');
    await tester.tap(find.byKey(const Key('add-question')));
    await tester.pump();
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first).initialValue, isEmpty);

    await tester.tap(find.byKey(const Key('question-list-0')));
    await tester.pump();
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first).initialValue, 'Question one content');
  });

  testWidgets('CreateExamScreen setup and bottom bar shows publish button', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TeacherExamRepository>(create: (_) => MockExamRepo()),
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(
          home: CreateExamScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Fill setup form
    await tester.enterText(find.byKey(const Key('setup-name')), 'Đề kiểm tra đại số');
    await tester.tap(find.byKey(const Key('setup-subject')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toán').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('setup-continue')));
    await tester.tap(find.byKey(const Key('setup-continue')));
    await tester.pumpAndSettle();

    // Bottom action bar should have both "Lưu bản nháp" and "Lưu & Xuất bản ngay"
    expect(find.text('Lưu bản nháp'), findsOneWidget);
    expect(find.text('Lưu & Xuất bản ngay'), findsOneWidget);
  });
}
