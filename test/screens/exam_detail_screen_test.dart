import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/screens/exam/exam_detail_screen.dart';

void main() {
  testWidgets('ExamDetailScreen renders breadcrumbs, exam info, and action panel', (tester) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExamDetailScreen(examId: '10000000-0000-4000-8000-000000000001'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify breadcrumbs
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Tìm kiếm'), findsOneWidget);
    expect(find.text('Chi tiết đề thi'), findsOneWidget);

    // Verify action panel
    expect(find.text('Sẵn sàng làm bài?'), findsOneWidget);
    expect(find.text('Bắt đầu tự luyện'), findsOneWidget);
    expect(find.text('Lưu vào yêu thích'), findsOneWidget);

    // Verify info boxes
    expect(find.text('Giới thiệu bài thi'), findsOneWidget);
    expect(find.text('Hướng dẫn & Quy chế'), findsOneWidget);
  });
}
