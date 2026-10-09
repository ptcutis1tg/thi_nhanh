import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/home/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp({
    String? attemptId,
    String? examId,
    String? liveRoomCode,
    String initialMode = 'learning',
    void Function(String uri)? onNavigated,
  }) {
    SharedPreferences.setMockInitialValues({
      'active_workspace_mode': initialMode,
    });
    final auth = AuthProvider(isSupabaseInitialized: false);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(
            initialActiveAttemptId: attemptId,
            initialActiveExamId: examId,
            initialActiveLiveRoomCode: liveRoomCode,
          ),
        ),
        GoRoute(
          path: '/taking_exam',
          builder: (context, state) {
            onNavigated?.call(state.uri.toString());
            return const Scaffold(body: Text('Taking Exam Target'));
          },
        ),
        GoRoute(
          path: '/student/history',
          builder: (context, state) {
            onNavigated?.call(state.uri.toString());
            return Scaffold(body: Text('History Target: ${state.uri.queryParameters['tab']}'));
          },
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) {
            onNavigated?.call(state.uri.toString());
            return const Scaffold(body: Text('Search Target'));
          },
        ),
        GoRoute(
          path: '/live_dashboard',
          builder: (context, state) {
            onNavigated?.call(state.uri.toString());
            return const Scaffold(body: Text('Live Dashboard Target'));
          },
        ),
        GoRoute(
          path: '/create_room',
          builder: (context, state) {
            onNavigated?.call(state.uri.toString());
            return const Scaffold(body: Text('Create Room Target'));
          },
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

  testWidgets('Danh Mục Học Tập excludes "Vào Phòng Thi" & "Bài Đang Làm" and active attempt card navigates to /search when no attempt', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? lastNav;
    await tester.pumpWidget(buildTestApp(
      attemptId: null,
      onNavigated: (uri) => lastNav = uri,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify "Vào Phòng Thi" and "Bài Đang Làm" are completely removed from Danh Mục Học Tập
    expect(find.text('Vào Phòng Thi'), findsNothing);
    expect(find.text('Bài Đang Làm'), findsNothing);

    // Verify the 4 remaining learning category cards are present
    expect(find.text('Tìm Đề Luyện Tập'), findsOneWidget);
    expect(find.text('Lịch Sử & Kết Quả'), findsOneWidget);
    expect(find.text('Thành Tích Cá Nhân'), findsOneWidget);
    expect(find.text('Bảng Xếp Hạng'), findsOneWidget);

    // Verify smart nav card action when no active attempt
    final cardBtn = find.text('Khám phá đề thi');
    expect(cardBtn, findsOneWidget);

    await tester.tap(cardBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('không có bài thi nào đang làm dở dang'), findsOneWidget);
    expect(lastNav, '/search');
  });

  testWidgets('Tapping active attempt card with active attempt navigates to /student/history?tab=in_progress', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? lastNav;
    await tester.pumpWidget(buildTestApp(
      attemptId: 'att-123456',
      examId: 'exam-999',
      onNavigated: (uri) => lastNav = uri,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('BÀI THI CHƯA HOÀN TẤT (1)'), findsOneWidget);
    expect(find.text('Bạn đang có bài thi chưa nộp'), findsOneWidget);

    final cardBtn = find.text('Xem bài dở dang');
    expect(cardBtn, findsOneWidget);

    await tester.tap(cardBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(lastNav, '/student/history?tab=in_progress');
  });

  testWidgets('Tapping "Phòng Đang Diễn Ra" without active room shows snackbar and navigates to /create_room', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? lastNav;
    await tester.pumpWidget(buildTestApp(
      initialMode: 'authoring',
      liveRoomCode: null,
      onNavigated: (uri) => lastNav = uri,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final card = find.text('Phòng Đang Diễn Ra');
    expect(card, findsOneWidget);

    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('không có phòng thi nào'), findsOneWidget);
    expect(lastNav, '/create_room');
  });

  testWidgets('Tapping "Phòng Đang Diễn Ra" with active room navigates to /live_dashboard with room code', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? lastNav;
    await tester.pumpWidget(buildTestApp(
      initialMode: 'authoring',
      liveRoomCode: 'PT998877',
      onNavigated: (uri) => lastNav = uri,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final card = find.text('Phòng Đang Diễn Ra');
    expect(card, findsOneWidget);

    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(lastNav, contains('/live_dashboard?code=PT998877'));
  });
}
