import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/teacher/teacher_exams_screen.dart';

void main() {
  testWidgets('TeacherExamsScreen renders header, search bar, and create exam button', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TeacherExamsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header title and button
    expect(find.text('📁 Quản Lý Kho Đề Thi Trắc Nghiệm'), findsOneWidget);
    expect(find.text('Tạo Đề Thi Mới'), findsOneWidget);

    // Verify search bar
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Tìm kiếm bộ đề theo tên hoặc môn học...'), findsOneWidget);
  });
}
