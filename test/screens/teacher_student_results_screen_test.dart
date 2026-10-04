import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/teacher/teacher_student_results_screen.dart';

void main() {
  final sampleSubmissions = [
    {
      'attemptId': 'att-1',
      'roomId': 'room-1',
      'studentName': 'Nguyễn Văn An',
      'score': 9.5,
      'status': 'submitted',
      'submittedAt': '2026-10-04T08:30:00Z',
      'examTitle': 'Kiểm tra 15 phút Toán',
      'subject': 'Toán',
    },
    {
      'attemptId': 'att-2',
      'roomId': 'room-2',
      'studentName': 'Trần Thị Bình',
      'score': 6.0,
      'status': 'submitted',
      'submittedAt': '2026-10-04T08:45:00Z',
      'examTitle': 'Vật lý nhiệt học',
      'subject': 'Vật lý',
    },
  ];

  Widget buildWidget({List<Map<String, dynamic>>? submissions, Size size = const Size(1200, 800)}) {
    return MaterialApp(
      home: ChangeNotifierProvider<AuthProvider>.value(
        value: AuthProvider(isSupabaseInitialized: false),
        child: MediaQuery(
          data: MediaQueryData(size: size),
          child: TeacherStudentResultsScreen(testSubmissions: submissions),
        ),
      ),
    );
  }

  testWidgets('TeacherStudentResultsScreen renders empty state when no submissions exist', (tester) async {
    await tester.pumpWidget(buildWidget(submissions: []));
    await tester.pumpAndSettle();

    expect(find.text('Chưa có lượt nộp bài nào từ học sinh'), findsOneWidget);
    expect(find.text('📈 Kết Quả & Bài Nộp Học Sinh'), findsOneWidget);
  });

  testWidgets('TeacherStudentResultsScreen renders submissions and filters with search field', (tester) async {
    await tester.pumpWidget(buildWidget(submissions: sampleSubmissions));
    await tester.pumpAndSettle();

    // Verify header and count
    expect(find.text('Tổng số lượt nộp bài: 2'), findsOneWidget);
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('9.5 điểm'), findsOneWidget);
    expect(find.text('Trần Thị Bình'), findsOneWidget);
    expect(find.text('6.0 điểm'), findsOneWidget);

    // Search for 'An'
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);
    await tester.enterText(searchField, 'An');
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Trần Thị Bình'), findsNothing);

    // Clear search
    await tester.enterText(searchField, '');
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Trần Thị Bình'), findsOneWidget);
  });

  testWidgets('TeacherStudentResultsScreen renders without RenderFlex overflow on small mobile (360x640)', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildWidget(
      submissions: sampleSubmissions,
      size: const Size(360, 640),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
