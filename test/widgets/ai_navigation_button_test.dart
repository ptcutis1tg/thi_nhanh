import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:onthi_community/core/services/ai_navigation_service.dart';
import 'package:onthi_community/shared/widgets/ai_navigation_button.dart';

void main() {
  testWidgets('AI home function call navigates to /home', (tester) async {
    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/search',
          builder: (_, __) => Scaffold(
            body: const Text('Search'),
            floatingActionButton: AiNavigationButton(
              interpretCommand: (_) async => AiNavigationAction.goHome,
            ),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('Home page')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('AI'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Đưa tôi về home');
    await tester.tap(find.text('Gửi'));
    await tester.pumpAndSettle();

    expect(find.text('Home page'), findsOneWidget);
  });
}
