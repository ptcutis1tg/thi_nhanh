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

  testWidgets('Tapping "Bài Đang Làm" without active attempt shows snackbar and navigates to /search', (tester) async {
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

    final card = find.text('Bài Đang Làm');
    expect(card, findsOneWidget);

    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('không có bài thi nào đang làm dở dang'), findsOneWidget);
    expect(lastNav, '/search');
  });

  testWidgets('Tapping "Bài Đang Làm" with active attempt navigates to /taking_exam with attemptId & examId', (tester) async {
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

    final card = find.text('Bài Đang Làm');
    expect(card, findsOneWidget);

    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(lastNav, contains('/taking_exam?attemptId=att-123456&examId=exam-999'));
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
