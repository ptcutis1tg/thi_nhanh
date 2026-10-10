import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onthi_community/shared/widgets/mobile_bottom_nav_bar.dart';

void main() {
  Widget buildTestApp({
    String initialLocation = '/home',
    void Function(String uri)? onNavigated,
  }) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Text('Home Screen'),
            bottomNavigationBar: MobileBottomNavBar(),
          ),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) {
            onNavigated?.call('/search');
            return const Scaffold(
              body: Text('Search Screen'),
              bottomNavigationBar: MobileBottomNavBar(),
            );
          },
        ),
        GoRoute(
          path: '/teacher_exams',
          builder: (context, state) {
            onNavigated?.call('/teacher_exams');
            return const Scaffold(
              body: Text('Teacher Exams Screen'),
              bottomNavigationBar: MobileBottomNavBar(),
            );
          },
        ),
        GoRoute(
          path: '/create_room',
          builder: (context, state) {
            onNavigated?.call('/create_room');
            return const Scaffold(
              body: Text('Create Room Screen'),
              bottomNavigationBar: MobileBottomNavBar(),
            );
          },
        ),
        GoRoute(
          path: '/student/history',
          builder: (context, state) {
            onNavigated?.call('/student/history');
            return const Scaffold(
              body: Text('Student History Screen'),
              bottomNavigationBar: MobileBottomNavBar(),
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      routerConfig: router,
    );
  }

  testWidgets('MobileBottomNavBar renders all 5 icon tabs on mobile', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestApp(initialLocation: '/home'));
    await tester.pumpAndSettle();

    // Verify 5 tab icons exist
    expect(find.byIcon(Icons.home_rounded), findsOneWidget);
    expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    expect(find.byIcon(Icons.add_circle_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.history_rounded), findsOneWidget);
  });

  testWidgets('Tapping tab icons in MobileBottomNavBar navigates to target routes', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    String? lastNav;
    await tester.pumpWidget(buildTestApp(
      initialLocation: '/home',
      onNavigated: (uri) => lastNav = uri,
    ));
    await tester.pumpAndSettle();

    // Tap Search tab
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();
    expect(lastNav, '/search');

    // Tap Teacher Exams tab
    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await tester.pumpAndSettle();
    expect(lastNav, '/teacher_exams');

    // Tap Create Room tab
    await tester.tap(find.byIcon(Icons.add_circle_outline_rounded));
    await tester.pumpAndSettle();
    expect(lastNav, '/create_room');

    // Tap History tab
    await tester.tap(find.byIcon(Icons.history_rounded));
    await tester.pumpAndSettle();
    expect(lastNav, '/student/history');
  });
}
