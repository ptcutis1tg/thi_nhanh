import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/screens/exam/create_exam_screen.dart';
import 'package:onthi_community/screens/exam/widgets/scientific_bottom_toolbar.dart';
import 'package:onthi_community/screens/exam/widgets/student_exam_preview_dialog.dart';

class MockExamRepo implements TeacherExamRepository {
  @override
  Future<String> saveDraft({
    String? examId,
    required String title,
    required String subject,
    required int durationMinutes,
    required List<Map<String, dynamic>> questions,
  }) async => 'mock-exam-id-456';

  @override
  Future<void> publish(String examId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('CreateExamScreen comprehensive flow: duplicate, preview, and scientific toolbar', (tester) async {
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

    // 1. Setup form
    await tester.enterText(find.byKey(const Key('setup-name')), 'Đề thi Khảo sát Nâng cao');
    await tester.tap(find.byKey(const Key('setup-subject')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Toán').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('setup-continue')));
    await tester.tap(find.byKey(const Key('setup-continue')));
    await tester.pumpAndSettle();

    // 2. Workstation is displayed
    expect(find.text('DANH SÁCH CÂU HỎI'), findsOneWidget);
    expect(find.text('TỔNG QUAN ĐỀ THI'), findsOneWidget);
    expect(find.byType(ScientificBottomToolbar), findsOneWidget);

    // 3. Question duplication
    final duplicateBtn = find.byTooltip('Nhân bản câu này').first;
    await tester.tap(duplicateBtn);
    await tester.pump();
    expect(find.text('2 câu hỏi'), findsOneWidget);

    // 4. Test Student Preview Dialog trigger
    final previewBtn = find.text('Xem trước học sinh');
    expect(previewBtn, findsOneWidget);
    await tester.tap(previewBtn);
    await tester.pumpAndSettle();

    expect(find.byType(StudentExamPreviewDialog), findsOneWidget);
    expect(find.text('Xem trước góc nhìn học sinh'), findsOneWidget);

    // Close preview dialog via AppBar close button
    await tester.tap(find.descendant(of: find.byType(AppBar), matching: find.byIcon(Icons.close)));
    await tester.pumpAndSettle();

    expect(find.byType(StudentExamPreviewDialog), findsNothing);
  });
}
