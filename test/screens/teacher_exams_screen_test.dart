import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/screens/exam/teacher_exams_screen.dart';

class FakeTeacherExamRepository implements TeacherExamRepository {
  @override
  Future<List<TeacherExamSummary>> summaries() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the teacher exam management empty state', (tester) async {
    await tester.pumpWidget(
      Provider<TeacherExamRepository>(
        create: (_) => FakeTeacherExamRepository(),
        child: const MaterialApp(home: TeacherExamsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Quản lý đề thi'), findsOneWidget);
    expect(find.text('Chưa có đề nào.'), findsOneWidget);
  });
}
