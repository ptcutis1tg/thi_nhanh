import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/repositories/room_repository.dart';
import 'package:onthi_community/screens/home/home_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('HomeScreen renders without overflow on mobile 360px viewport', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final auth = AuthProvider(isSupabaseInitialized: false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify user greeting
    expect(find.textContaining('Xin chào'), findsOneWidget);

    // Verify workspace switch pill
    expect(find.textContaining('Học tập'), findsWidgets);
    expect(find.textContaining('Soạn đề'), findsWidgets);

    // Verify quick room PIN input is present
    expect(find.byType(TextField), findsOneWidget);
  });
}
