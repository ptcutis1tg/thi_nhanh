import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/shared/widgets/top_nav_bar.dart';

void main() {
  testWidgets('TopNavBar displays all 4 core hot bar items for all users', (tester) async {
    final authProvider = AuthProvider(isSupabaseInitialized: false);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: authProvider,
        child: const MaterialApp(
          home: Scaffold(
            appBar: TopNavBar(),
          ),
        ),
      ),
    );

    // Verify all 4 core items are present regardless of role
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Tìm kiếm'), findsOneWidget);
    expect(find.text('Quản lí đề'), findsOneWidget);
    expect(find.text('Tạo phòng thi'), findsOneWidget);

    // Verify replaced / removed items are not present
    expect(find.text('Tạo đề thi'), findsNothing);
    expect(find.text('Đề của tôi'), findsNothing);
  });

  testWidgets('TopNavBar avatar shows popup menu with Profile, History, and Logout options', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({'active_user_email': 'student@example.com'});
    final auth = AuthProvider(isSupabaseInitialized: false);
    await auth.init();

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>.value(
        value: auth,
        child: const MaterialApp(
          home: Scaffold(
            appBar: TopNavBar(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap avatar
    final avatarFinder = find.byType(CircleAvatar);
    expect(avatarFinder, findsOneWidget);

    await tester.tap(avatarFinder);
    await tester.pumpAndSettle();

    // Verify popup menu items
    expect(find.text('Hồ sơ cá nhân'), findsOneWidget);
    expect(find.text('Lịch sử làm bài'), findsOneWidget);
    expect(find.text('Đăng xuất'), findsOneWidget);
  });
}
