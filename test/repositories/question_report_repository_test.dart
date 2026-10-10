import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/repositories/question_report_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('local reports can be submitted and resolved', () async {
    final repository = QuestionReportRepository();

    final id = await repository.submit(
      attemptId: 'attempt-1',
      examId: 'exam-1',
      examTitle: 'Đề kiểm tra',
      questionId: 'question-1',
      questionPosition: 2,
      questionBody: 'Nội dung câu hỏi',
      category: QuestionReportCategory.wrongAnswer,
      detail: 'Đáp án đúng phải là B.',
    );

    var reports = await repository.teacherReports();
    expect(reports, hasLength(1));
    expect(reports.single.id, id);
    expect(reports.single.status, 'pending');

    await repository.resolve(
      reportId: id,
      accepted: true,
      teacherNote: 'Đã sửa đáp án.',
    );

    reports = await repository.teacherReports();
    expect(reports.single.status, 'resolved');
    expect(reports.single.teacherNote, 'Đã sửa đáp án.');
  });

  test('a duplicate report updates instead of creating spam', () async {
    final repository = QuestionReportRepository();
    final firstId = await repository.submit(
      attemptId: 'attempt-1',
      examId: 'exam-1',
      examTitle: 'Đề kiểm tra',
      questionId: 'question-1',
      questionPosition: 1,
      questionBody: 'Câu hỏi',
      category: QuestionReportCategory.typo,
      detail: 'Sai chính tả.',
    );
    final secondId = await repository.submit(
      attemptId: 'attempt-1',
      examId: 'exam-1',
      examTitle: 'Đề kiểm tra',
      questionId: 'question-1',
      questionPosition: 1,
      questionBody: 'Câu hỏi',
      category: QuestionReportCategory.typo,
      detail: 'Sai chính tả ở dòng đầu.',
    );

    final reports = await repository.teacherReports();
    expect(secondId, firstId);
    expect(reports, hasLength(1));
    expect(reports.single.detail, 'Sai chính tả ở dòng đầu.');
  });
}
