import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/core/services/profile_service.dart';
import 'package:onthi_community/screens/student/student_history_screen.dart';

void main() {
  testWidgets('StudentHistoryScreen opens in-progress tab when initialTab is in_progress', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final completedItem = StudentTestHistoryData(
      id: 'att_completed',
      subjectIcon: '📐',
      title: 'Đề Toán Đã Nộp',
      date: 'Hôm nay',
      score: '9.0',
      scoreValue: 9.0,
      status: 'submitted',
      submittedAt: DateTime.now(),
    );

    final inProgressItem = StudentTestHistoryData(
      id: 'att_active',
      subjectIcon: '🧪',
      title: 'Đề Hóa Đang Làm Dở',
      date: 'Vừa xong',
      score: '--',
      scoreValue: 0.0,
      status: 'in_progress',
      startedAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );

    final testData = StudentProfileData(
      completedTestsCount: 1,
      averageScore: 9.0,
      streakDays: 1,
      chartValues: [9.0],
      chartLabels: ['Bài 1'],
      highestScore: 9.0,
      totalTimeSpent: const Duration(minutes: 30),
      achievements: [],
      recentTests: [completedItem],
      inProgressTests: [inProgressItem],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentHistoryScreen(
            testData: testData,
            initialTab: 'in_progress',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Tab "Chưa hoàn thành" is selected and shows the in-progress card
    expect(find.text('Đề Hóa Đang Làm Dở'), findsOneWidget);
    expect(find.text('Tiếp tục làm bài'), findsOneWidget);
    expect(find.text('Hủy bài'), findsOneWidget);

    // Tap on "Đã hoàn thành" tab
    await tester.tap(find.text('Đã hoàn thành'));
    await tester.pump();

    // Verify completed exam is shown
    expect(find.text('Đề Toán Đã Nộp'), findsOneWidget);
    expect(find.text('Đề Hóa Đang Làm Dở'), findsNothing);
  });

  testWidgets('StudentHistoryScreen shows expired banner and actions for overdue attempt', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final expiredItem = StudentTestHistoryData(
      id: 'att_overdue',
      subjectIcon: '⚡',
      title: 'Đề Lý Quá Giờ',
      date: 'Hôm qua',
      score: '--',
      scoreValue: 0.0,
      status: 'in_progress',
      startedAt: DateTime.now().subtract(const Duration(hours: 3)),
      expiresAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    final testData = StudentProfileData(
      completedTestsCount: 0,
      averageScore: 0.0,
      streakDays: 0,
      chartValues: [],
      chartLabels: [],
      highestScore: 0.0,
      totalTimeSpent: Duration.zero,
      achievements: [],
      recentTests: [],
      inProgressTests: [expiredItem],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StudentHistoryScreen(
            testData: testData,
            initialTab: 'in_progress',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Đề Lý Quá Giờ'), findsOneWidget);
    expect(find.text('Đã hết hạn làm bài'), findsOneWidget);
    expect(find.text('Nộp để chấm điểm'), findsOneWidget);
    expect(find.text('Xóa bài'), findsOneWidget);
  });
}
