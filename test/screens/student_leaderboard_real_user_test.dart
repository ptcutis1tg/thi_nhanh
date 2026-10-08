import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/student/student_leaderboard_screen.dart';

void main() {
  Widget buildLeaderboardScreen({
    List<LeaderboardUser>? initialUsers,
    String? currentUserId,
    String? currentUserEmail,
    String? currentUserName,
  }) {
    final auth = AuthProvider(isSupabaseInitialized: false);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ],
      child: MaterialApp(
        home: StudentLeaderboardScreen(
          initialUsers: initialUsers,
        ),
      ),
    );
  }

  testWidgets('StudentLeaderboardScreen renders ranked users and podium without fake emails', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final users = [
      LeaderboardUser(
        id: 'u1',
        name: 'Trần Văn Nam',
        avgScore: 9.5,
        totalTests: 12,
        rank: 1,
        isGuest: false,
      ),
      LeaderboardUser(
        id: 'u2',
        name: 'Lê Thị Mai',
        avgScore: 9.0,
        totalTests: 10,
        rank: 2,
        isGuest: false,
      ),
      LeaderboardUser(
        id: 'u3',
        name: 'Nguyễn Văn An (Khách)',
        avgScore: 8.5,
        totalTests: 5,
        rank: 3,
        isGuest: true,
      ),
      LeaderboardUser(
        id: 'u4',
        name: 'Phạm Minh Khôi (Khách)',
        avgScore: 7.8,
        totalTests: 3,
        rank: 4,
        isGuest: true,
      ),
    ];

    await tester.pumpWidget(buildLeaderboardScreen(initialUsers: users));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify podium and rankings
    expect(find.text('Trần Văn Nam'), findsWidgets);
    expect(find.text('Lê Thị Mai'), findsWidgets);
    expect(find.text('Nguyễn Văn An (Khách)'), findsWidgets);
    expect(find.text('Phạm Minh Khôi (Khách)'), findsOneWidget);

    // Verify scores are displayed
    expect(find.text('9.5 điểm'), findsWidgets);
    expect(find.text('9.0 điểm'), findsWidgets);

    // Verify no fake email placeholder exists anywhere in the widget tree
    expect(find.textContaining('hocsinh@gmail.com'), findsNothing);
  });
}
