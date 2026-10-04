import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/services/profile_service.dart';
import 'package:onthi_community/screens/student/student_history_screen.dart';
import 'package:onthi_community/shared/widgets/google_pagination_bar.dart';

void main() {
  testWidgets('StudentHistoryScreen renders header, search box and filter panel', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/student/history',
            routes: [
              GoRoute(path: '/student/history', builder: (_, __) => const StudentHistoryScreen()),
              GoRoute(path: '/profile', builder: (_, __) => const Scaffold(body: Text('Profile Screen'))),
              GoRoute(path: '/result', builder: (_, __) => const Scaffold(body: Text('Result Screen'))),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Title & Search
    expect(find.text('📊 Lịch Sử Làm Bài Thi'), findsOneWidget);
    expect(find.byKey(const Key('history-search-field')), findsOneWidget);

    // Verify Filter categories
    expect(find.text('Môn thi'), findsOneWidget);
    expect(find.text('Thời gian nộp'), findsOneWidget);
    expect(find.text('Điểm số'), findsOneWidget);
    expect(find.text('Sắp xếp'), findsOneWidget);
  });

  testWidgets('StudentHistoryScreen search box updates input and filters', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/student/history',
            routes: [
              GoRoute(path: '/student/history', builder: (_, __) => const StudentHistoryScreen()),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final searchField = find.byKey(const Key('history-search-field'));
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'Hình học');
    await tester.pump();
    expect(find.text('Hình học'), findsOneWidget);

    // Verify clear button appears and clears input
    final clearBtn = find.byIcon(Icons.close_rounded);
    expect(clearBtn, findsOneWidget);
    await tester.tap(clearBtn);
    await tester.pump();
    expect(find.text('Hình học'), findsNothing);
  });

  testWidgets('StudentHistoryScreen back button pops back to previous screen when canPop is true', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/result',
      routes: [
        GoRoute(
          path: '/result',
          builder: (ctx, _) => Scaffold(
            body: ElevatedButton(
              onPressed: () => ctx.push('/student/history'),
              child: const Text('Go To History'),
            ),
          ),
        ),
        GoRoute(
          path: '/student/history',
          builder: (_, __) => const StudentHistoryScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const Scaffold(body: Text('Profile Screen')),
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to history from /result
    await tester.tap(find.text('Go To History'));
    await tester.pumpAndSettle();

    expect(find.text('📊 Lịch Sử Làm Bài Thi'), findsOneWidget);

    // Tap back button
    final backBtn = find.byTooltip('Quay lại');
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // Should return to Result Screen, NOT Profile Screen
    expect(find.text('Go To History'), findsOneWidget);
    expect(find.text('Profile Screen'), findsNothing);
  });

  testWidgets('StudentHistoryScreen renders without overflow on 360x640 mobile screen and has 3 mode tabs', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/student/history',
            routes: [
              GoRoute(path: '/student/history', builder: (_, __) => const StudentHistoryScreen()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 3 mode tabs exist
    expect(find.text('Tất cả bài thi'), findsOneWidget);
    expect(find.text('Phòng thi trực tiếp'), findsOneWidget);
    expect(find.text('Tự luyện tập'), findsOneWidget);

    // Tap 'Phòng thi trực tiếp'
    final tabFinder = find.text('Phòng thi trực tiếp');
    expect(tabFinder, findsOneWidget);
    await tester.ensureVisible(tabFinder);
    await tester.tap(tabFinder);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('History card renders exam mode badge, duration, and pending release state correctly', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sampleData = StudentProfileData(
      completedTestsCount: 2,
      averageScore: 6.75,
      highestScore: 9.0,
      streakDays: 2,
      chartValues: [9.0, 4.5],
      chartLabels: ['Bài 1', 'Bài 2'],
      totalTimeSpent: const Duration(minutes: 35),
      achievements: [],
      recentTests: [
        StudentTestHistoryData(
          id: 'attempt-1',
          subjectIcon: '📐',
          title: 'Đề Toán Nâng Cao',
          date: '04/10/2026',
          score: '9.0 điểm',
          scoreValue: 9.0,
          subject: 'Toán',
          isLiveRoom: true,
          roomId: 'room-1',
          roomCode: 'PT999888',
          durationSeconds: 1200,
          resultReleased: true,
        ),
        StudentTestHistoryData(
          id: 'attempt-2',
          subjectIcon: '🧪',
          title: 'Đề Hóa Hữu Cơ',
          date: '03/10/2026',
          score: '4.5 điểm',
          scoreValue: 4.5,
          subject: 'Hóa học',
          isLiveRoom: false,
          durationSeconds: 900,
          resultReleased: false,
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/student/history',
            routes: [
              GoRoute(
                path: '/student/history',
                builder: (_, __) => StudentHistoryScreen(testData: sampleData),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify item 1 (Live Room):
    expect(find.text('Phòng thi: PT999888'), findsOneWidget);
    expect(find.text('20:00'), findsOneWidget);
    expect(find.text('9.0 điểm'), findsOneWidget);
    expect(find.text('Luyện lại câu sai'), findsOneWidget);

    // Verify item 2 (Practice mode & pending release):
    expect(find.text('Chờ công bố'), findsOneWidget);
  });

  testWidgets('History card renders without overflow on 360x640 mobile screen with items', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sampleData = StudentProfileData(
      completedTestsCount: 2,
      averageScore: 6.75,
      highestScore: 9.0,
      streakDays: 2,
      chartValues: [9.0, 4.5],
      chartLabels: ['Bài 1', 'Bài 2'],
      totalTimeSpent: const Duration(minutes: 35),
      achievements: [],
      recentTests: [
        StudentTestHistoryData(
          id: 'attempt-1',
          subjectIcon: '📐',
          title: 'Đề Kiểm Tra Toán Giữa Kỳ 1 Năm Học 2026',
          date: '04/10/2026',
          score: '9.0 điểm',
          scoreValue: 9.0,
          subject: 'Toán',
          isLiveRoom: true,
          roomId: 'room-1',
          roomCode: 'PT999888',
          durationSeconds: 1200,
          resultReleased: true,
        ),
        StudentTestHistoryData(
          id: 'attempt-2',
          subjectIcon: '🧪',
          title: 'Đề Hóa Hữu Cơ Lớp 12 Chương 3',
          date: '03/10/2026',
          score: '4.5 điểm',
          scoreValue: 4.5,
          subject: 'Hóa học',
          isLiveRoom: false,
          durationSeconds: 900,
          resultReleased: false,
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/student/history',
            routes: [
              GoRoute(
                path: '/student/history',
                builder: (_, __) => StudentHistoryScreen(testData: sampleData),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Phòng thi: PT999888'), findsOneWidget);
    expect(find.text('Chờ công bố'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

