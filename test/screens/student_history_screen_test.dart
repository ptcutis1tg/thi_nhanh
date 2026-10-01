import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
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
}
