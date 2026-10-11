import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/main_layout_screen.dart';
import 'package:onthi_community/shared/widgets/ai_navigation_button.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('MainLayoutScreen does not display AiNavigationButton floating button', (tester) async {
    final auth = AuthProvider(isSupabaseInitialized: false);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        ShellRoute(
          builder: (context, state, child) => MainLayoutScreen(child: child),
          routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const Scaffold(body: Text('Home Content')),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    // Verify content is rendered
    expect(find.text('Home Content'), findsOneWidget);

    // Verify AI button is completely removed
    expect(find.byType(AiNavigationButton), findsNothing);
    expect(find.text('AI'), findsNothing);
  });
}
