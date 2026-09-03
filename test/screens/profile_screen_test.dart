import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/profile/profile_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('profile renders personal info, security, and dashboard sections', (tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final auth = AuthProvider(isSupabaseInitialized: false);
    await auth.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: auth,
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Phòng thi'), findsOneWidget);
    expect(find.text('Lượt tham gia'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
  });
}
