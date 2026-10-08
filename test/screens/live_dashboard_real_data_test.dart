import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/exam/live_dashboard_screen.dart';

void main() {
  testWidgets('LiveDashboardScreen hiển thị chính xác số câu đã làm và tổng số câu thực tế', (tester) async {
    final mockStudents = [
      {
        'name': 'Trần Văn Nam',
        'initials': 'TN',
        'answered': 17,
        'totalQuestions': 25,
        'correct': null,
        'wrong': null,
        'completed': false,
        'score': 0.0,
        'violations': 1,
      },
      {
        'name': 'Lê Thị Mai',
        'initials': 'LM',
        'answered': 25,
        'totalQuestions': 25,
        'correct': 23,
        'wrong': 2,
        'completed': true,
        'score': 9.2,
        'violations': 0,
      },
    ];

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(isSupabaseInitialized: false)),
        ],
        child: MaterialApp(
          home: LiveDashboardScreen(
            roomCode: 'PT999999',
            initialStudents: mockStudents,
          ),
        ),
      ),
    );

    // Verify student names are rendered
    expect(find.text('Trần Văn Nam'), findsOneWidget);
    expect(find.text('Lê Thị Mai'), findsOneWidget);

    // Verify dynamic totalQuestions is used instead of hardcoded /20
    expect(find.textContaining('17/25'), findsAtLeastNWidgets(1));
    expect(find.textContaining('25/25'), findsAtLeastNWidgets(1));
    expect(find.text('Điểm: 9.2 đ'), findsAtLeastNWidgets(1));
    expect(find.textContaining('1 vi phạm'), findsAtLeastNWidgets(1));
  });
}
