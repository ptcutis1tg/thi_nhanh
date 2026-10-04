import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/screens/room/create_room_screen.dart';

class FakeTeacherExamRepository implements TeacherExamRepository {
  @override
  Future<List<TeacherExamSummary>> summaries() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeTeacherExamRepositoryWithExams implements TeacherExamRepository {
  FakeTeacherExamRepositoryWithExams(this._exams);
  final List<TeacherExamSummary> _exams;

  @override
  Future<List<TeacherExamSummary>> summaries() async => _exams;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows an empty state until the teacher has created an exam', (tester) async {
    await tester.pumpWidget(
      Provider<TeacherExamRepository>(
        create: (_) => FakeTeacherExamRepository(),
        child: const MaterialApp(home: CreateRoomScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có đề nào để mở phòng.'), findsOneWidget);
    expect(find.text('Tạo đề mới'), findsOneWidget);
  });

  testWidgets('renders capacity selector, exam search filter, and exam rules', (tester) async {
    final fakeRepo = FakeTeacherExamRepositoryWithExams([
      const TeacherExamSummary(
        id: 'exam-1',
        title: 'Đề thi Khảo sát Toán 12',
        subject: 'Toán học',
        status: 'published',
        durationMinutes: 45,
        questionCount: 40,
      ),
      const TeacherExamSummary(
        id: 'exam-2',
        title: 'Kiểm tra Tiếng Anh Giữa kỳ',
        subject: 'Tiếng Anh',
        status: 'published',
        durationMinutes: 45,
        questionCount: 50,
      ),
    ]);

    await tester.pumpWidget(
      Provider<TeacherExamRepository>.value(
        value: fakeRepo,
        child: const MaterialApp(home: CreateRoomScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sĩ số tối đa'), findsOneWidget);
    expect(find.text('40 thí sinh'), findsOneWidget);
    expect(find.text('Tìm kiếm đề thi...'), findsOneWidget);
    expect(find.textContaining('Trộn ngẫu nhiên câu hỏi'), findsOneWidget);
  });
}
