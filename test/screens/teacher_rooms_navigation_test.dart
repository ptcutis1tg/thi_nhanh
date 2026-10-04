import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/teacher/teacher_rooms_history_screen.dart';

void main() {
  testWidgets('TeacherRoomsHistoryScreen renders basic title and handles back button', (tester) async {
    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (ctx, _) => Scaffold(
            body: ElevatedButton(
              onPressed: () => ctx.push('/teacher/rooms'),
              child: const Text('Go To Rooms'),
            ),
          ),
        ),
        GoRoute(
          path: '/teacher/rooms',
          builder: (_, __) => const TeacherRoomsHistoryScreen(),
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

    await tester.tap(find.text('Go To Rooms'));
    await tester.pumpAndSettle();

    expect(find.text('🏛️ Quản Lý Phòng Thi Đã Tạo'), findsOneWidget);

    final backBtn = find.byTooltip('Quay lại');
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(find.text('Go To Rooms'), findsOneWidget);
  });
}
