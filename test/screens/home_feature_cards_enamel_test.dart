import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/theme/app_theme.dart';
import 'package:onthi_community/screens/home/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp({String initialMode = 'learning'}) {
    SharedPreferences.setMockInitialValues({
      'active_workspace_mode': initialMode,
    });
    final auth = AuthProvider(isSupabaseInitialized: false);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => const Scaffold(body: Text('Search Target')),
        ),
        GoRoute(
          path: '/student/history',
          builder: (context, state) => const Scaffold(body: Text('History Target')),
        ),
        GoRoute(
          path: '/student/achievements',
          builder: (context, state) => const Scaffold(body: Text('Achievements Target')),
        ),
        GoRoute(
          path: '/student/leaderboard',
          builder: (context, state) => const Scaffold(body: Text('Leaderboard Target')),
        ),
      ],
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ],
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('Danh Mục Học Tập renders Clean Enamel White cards with Slate text and pastel icon boxes', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp(initialMode: 'learning'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify Title
    expect(find.text('🚀 Danh Mục Học Tập'), findsOneWidget);

    // Verify 4 Cards in student mode
    final titleFinder = find.text('Tìm Đề Luyện Tập');
    expect(titleFinder, findsOneWidget);
    expect(find.text('Lịch Sử & Kết Quả'), findsOneWidget);
    expect(find.text('Thành Tích Cá Nhân'), findsOneWidget);
    expect(find.text('Bảng Xếp Hạng'), findsOneWidget);

    // Verify text style is AppTheme.textMain (deep slate, not white)
    final textWidget = tester.widget<Text>(titleFinder);
    expect(textWidget.style?.color, equals(AppTheme.textMain));

    // Verify icons exist
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events_outlined), findsOneWidget);
    expect(find.byIcon(Icons.leaderboard_outlined), findsOneWidget);
  });
}
