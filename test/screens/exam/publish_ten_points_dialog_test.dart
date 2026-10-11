import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/screens/exam/create_exam_screen.dart';
import 'package:onthi_community/screens/exam/widgets/inline_visual_math_editor.dart';
import 'package:onthi_community/screens/exam/widgets/question_answers_editor.dart';

class MockTeacherRepo implements TeacherExamRepository {
  bool publishCalled = false;

  @override
  Future<String> saveDraft({
    String? examId,
    required String title,
    required String subject,
    required int durationMinutes,
    required List<Map<String, dynamic>> questions,
  }) async => 'draft-123';

  @override
  Future<void> publish(String examId) async {
    publishCalled = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthProvider extends ChangeNotifier implements AuthProvider {
  @override
  bool get hasSupabaseSession => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Publish exam prompts dialog when total points is not 10', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockRepo = MockTeacherRepo();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TeacherExamRepository>.value(value: mockRepo),
          ChangeNotifierProvider<AuthProvider>.value(value: FakeAuthProvider()),
        ],
        child: const MaterialApp(
          home: CreateExamScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Enter setup and continue
    await tester.enterText(find.byKey(const Key('setup-name')), 'Đề kiểm tra 10 điểm');
    await tester.ensureVisible(find.byKey(const Key('setup-continue')));
    await tester.tap(find.byKey(const Key('setup-continue')));
    await tester.pumpAndSettle();

    // 2. Fill question 1 content and answer
    // Total points is 1.0 (default for 1 question) != 10.0
    final editorField = find.descendant(of: find.byType(InlineVisualMathEditor), matching: find.byType(TextField)).first;
    await tester.enterText(editorField, 'Câu hỏi kiểm tra 1?');

    final answerFields = find.descendant(of: find.byType(QuestionAnswersEditor), matching: find.byType(TextField));
    await tester.enterText(answerFields.at(0), 'Đáp án A');
    await tester.enterText(answerFields.at(1), 'Đáp án B');
    await tester.enterText(answerFields.at(2), 'Đáp án C');
    await tester.enterText(answerFields.at(3), 'Đáp án D');
    await tester.pumpAndSettle();

    // 3. Tap "Lưu & Xuất bản ngay" button
    final publishBtn = find.byKey(const Key('publish-exam-btn'));
    await tester.ensureVisible(publishBtn);
    await tester.tap(publishBtn);
    await tester.pumpAndSettle();

    // 4. Verify popup warns total score is not 10
    expect(find.text('Tổng điểm bài thi chưa đạt 10 điểm'), findsOneWidget);
    expect(find.text('Sửa tiếp'), findsOneWidget);
    expect(find.text('Tự động chia đều điểm thành 10'), findsOneWidget);
    expect(mockRepo.publishCalled, isFalse);

    // 5. Tap "Tự động chia đều điểm thành 10"
    await tester.tap(find.text('Tự động chia đều điểm thành 10'));
    await tester.pumpAndSettle();

    // Dialog should be dismissed
    expect(find.text('Tổng điểm bài thi chưa đạt 10 điểm'), findsNothing);
    // Question points should now be 10.00 đ
    expect(find.text('10.00 đ'), findsOneWidget);
  });
}
