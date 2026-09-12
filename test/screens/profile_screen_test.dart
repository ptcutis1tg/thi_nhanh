import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/profile/profile_screen.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('profile renders 2-tab layout and personal info & security', (tester) async {
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

    // Verify 2 tabs are present
    expect(find.textContaining('Học tập & Thành tích'), findsWidgets);
    expect(find.textContaining('Đề thi & Phòng thi của tôi'), findsWidgets);

    // Verify personal info and security
    expect(find.text('Thông tin cá nhân'), findsOneWidget);
    expect(find.text('Thay đổi mật khẩu'), findsOneWidget);
    expect(find.text('Lưu thay đổi'), findsOneWidget);

    // Switch to Authoring tab
    final authorTab = find.textContaining('Đề thi & Phòng thi của tôi');
    await tester.tap(authorTab.first);
    await tester.pumpAndSettle();

    // In authoring tab, teacher sections should be visible
    expect(find.textContaining('Bộ Đề Thi Của Tôi'), findsOneWidget);
  });
}
