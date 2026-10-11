import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/auth/greeting_screen.dart';

Widget _buildScreen() {
  return ChangeNotifierProvider<AuthProvider>(
    create: (_) => AuthProvider(isSupabaseInitialized: false),
    child: const MaterialApp(home: GreetingScreen()),
  );
}

void main() {
  testWidgets('login shell renders the core authentication controls', (tester) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('PAROVA'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(find.byKey(const Key('google-login-button')), findsOneWidget);
    expect(find.byKey(const Key('login-email-field')), findsOneWidget);
    expect(find.byKey(const Key('login-password-field')), findsOneWidget);
    expect(find.byKey(const Key('email-auth-submit-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('login shell remains usable on a narrow mobile viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Trợ giúp'), findsOneWidget);
    expect(find.text('Hỗ trợ kỹ thuật'), findsNothing);
    expect(find.byKey(const Key('email-auth-submit-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
