import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/exam/live_dashboard_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final sampleStudents = [
    {
      'name': 'Nguyễn Văn An',
      'initials': 'NA',
      'answered': 15,
      'completed': false,
      'score': 0.0,
      'violations': 0,
    },
    {
      'name': 'Trần Thị Bình',
      'initials': 'TB',
      'answered': 12,
      'completed': false,
      'score': 0.0,
      'violations': 2,
    },
    {
      'name': 'Lê Hoàng Cường',
      'initials': 'LC',
      'answered': 20,
      'completed': true,
      'score': 3.5,
      'violations': 4,
    },
  ];

  Widget buildTestWidget({required Size size}) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: AuthProvider(isSupabaseInitialized: false),
      child: MaterialApp(
        home: LiveDashboardScreen(
          roomCode: 'TEST01',
          initialStudents: sampleStudents,
        ),
      ),
    );
  }

  testWidgets('LiveDashboardScreen displays violation indicators 🚩 and ⛔ for students with violations', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(size: const Size(1200, 800)));
    await tester.pumpAndSettle();

    // Verify student names are rendered
    expect(find.text('Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Trần Thị Bình'), findsOneWidget);
    expect(find.text('Lê Hoàng Cường'), findsOneWidget);

    // Student 2 has 2 violations -> 🚩 2 vi phạm
    expect(find.text('🚩 2 vi phạm'), findsOneWidget);

    // Student 3 has 4 violations -> ⛔ Thu bài (Vi phạm)
    expect(find.text('⛔ Thu bài (Vi phạm)'), findsOneWidget);

    // Student 1 has 0 violations -> no flag for student 1
    expect(find.text('🚩 0 vi phạm'), findsNothing);
  });

  testWidgets('LiveDashboardScreen renders without overflow on mobile (360x640)', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestWidget(size: const Size(360, 640)));
    await tester.pumpAndSettle();

    expect(find.text('🚩 2 vi phạm'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
