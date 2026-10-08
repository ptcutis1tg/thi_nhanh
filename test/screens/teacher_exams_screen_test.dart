import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/teacher_exam_repository.dart';
import 'package:onthi_community/screens/teacher/teacher_exams_screen.dart';

class FakeTeacherExamRepository implements TeacherExamRepository {
  @override
  Future<List<TeacherExamSummary>> summaries() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('shows the official teacher exam management empty state', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TeacherExamRepository>(create: (_) => FakeTeacherExamRepository()),
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: const MaterialApp(home: Scaffold(body: TeacherExamsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('📁 Quản Lý Kho Đề Thi Trắc Nghiệm'), findsOneWidget);
    expect(find.text('Chưa có đề thi nào trong danh mục này.'), findsOneWidget);
  });
}
