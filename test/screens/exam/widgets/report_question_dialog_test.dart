import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/repositories/question_report_repository.dart';
import 'package:onthi_community/screens/exam/widgets/report_question_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('student can submit a question report', (tester) async {
    final repository = QuestionReportRepository();
    await tester.pumpWidget(
      Provider.value(
        value: repository,
        child: const MaterialApp(
          home: Scaffold(
            body: ReportQuestionDialog(
              attemptId: 'attempt-1',
              examId: 'exam-1',
              examTitle: 'Đề kiểm tra',
              questionId: 'question-1',
              questionPosition: 1,
              questionBody: 'Nội dung câu hỏi',
            ),
          ),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('report-detail')),
      'Đáp án được đánh dấu chưa đúng.',
    );
    await tester.tap(find.byKey(const Key('submit-question-report')));
    await tester.pumpAndSettle();

    final reports = await repository.teacherReports();
    expect(reports, hasLength(1));
    expect(reports.single.questionId, 'question-1');
    expect(reports.single.status, 'pending');
  });
}
