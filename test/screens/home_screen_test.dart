import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/screens/home/home_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createHomeScreen({String initialMode = 'learning'}) {
    SharedPreferences.setMockInitialValues({
      'active_workspace_mode': initialMode,
    });
    final auth = AuthProvider(isSupabaseInitialized: false);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ],
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  testWidgets('HomeScreen renders Workspace Mode Switcher with learning and authoring options', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createHomeScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Học tập & Thi thử'), findsWidgets);
    expect(find.textContaining('Soạn đề & Quản lý'), findsWidgets);
    expect(find.textContaining('Tài khoản Toàn quyền'), findsOneWidget);
  });

  testWidgets('HomeScreen switches between learning mode and authoring mode on toggle tap', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createHomeScreen(initialMode: 'learning'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // In learning mode: check for learning section
    expect(find.textContaining('Danh Mục Học Tập'), findsOneWidget);

    // Tap on the authoring tab
    final authoringTab = find.textContaining('Soạn đề & Quản lý');
    expect(authoringTab, findsWidgets);
    await tester.tap(authoringTab.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Now in authoring mode
    expect(find.textContaining('Chức Năng Quản Lý'), findsOneWidget);
    expect(find.textContaining('Tạo Đề Thi Mới'), findsOneWidget);
  });
}
