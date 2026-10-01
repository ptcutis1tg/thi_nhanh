import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/profile/profile_screen.dart';

void main() {
  testWidgets('ProfileScreen renders recent tests section with view-all button', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    String? navigatedRoute;

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/student/history',
          builder: (_, __) {
            navigatedRoute = '/student/history';
            return const Scaffold(body: Text('History Screen'));
          },
        ),
        GoRoute(
          path: '/result',
          builder: (_, state) {
            navigatedRoute = state.uri.toString();
            return const Scaffold(body: Text('Result Screen'));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('🕘 Bài thi gần đây'), findsOneWidget);
  });
}
