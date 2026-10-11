import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/auth/greeting_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('GreetingScreen creates and disposes cleanly without memory leaks', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = AuthProvider(isSupabaseInitialized: false);
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: GreetingScreen()),
      ),
    );
    await tester.pump();
    expect(find.byType(GreetingScreen), findsOneWidget);

    // Replace with empty container inside same Provider scope to trigger dispose cleanly
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(home: SizedBox.shrink()),
      ),
    );
    await tester.pump();
    expect(find.byType(GreetingScreen), findsNothing);
  });
}
