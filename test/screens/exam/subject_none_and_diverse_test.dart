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
  }) async => 'mock-exam-id-456';

  @override
  Future<void> publish(String examId) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('CreateExamScreen allows leaving subject empty and tags as none', (tester) async {
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

    // 1. Enter exam name but do NOT select any subject
    await tester.enterText(find.byKey(const Key('setup-name')), 'Đề kiểm tra không chọn môn');
    await tester.pump();

    // 2. Click continue
    await tester.ensureVisible(find.byKey(const Key('setup-continue')));
    await tester.tap(find.byKey(const Key('setup-continue')));
    await tester.pumpAndSettle();

    // 3. Verify it transitions to workstation and displays 'none' tag
    expect(find.text('DANH SÁCH CÂU HỎI'), findsOneWidget);
    expect(find.text('none'), findsWidgets);
  });
}
