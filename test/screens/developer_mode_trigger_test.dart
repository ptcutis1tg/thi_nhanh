import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onthi_community/core/providers/auth_provider.dart';
import 'package:onthi_community/core/services/developer_mode_service.dart';
import 'package:onthi_community/screens/home/home_screen.dart';
import 'package:onthi_community/screens/exam/exam_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Developer Mode Secret Trigger Tests', () {
    testWidgets('Entering 18366767 in HomeScreen toggles standard developer mode and clears input', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = AuthProvider(isSupabaseInitialized: false);
      await auth.init();

      final devService = DeveloperModeService();
      await devService.init();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<DeveloperModeService>.value(value: devService),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(devService.level, equals(DevModeLevel.none));

      // Find the join room input field
      final inputFinder = find.widgetWithText(TextField, 'Nhập mã phòng PTxxxxxx...');
      expect(inputFinder, findsOneWidget);

      // 1. Enter secret code 18366767
      await tester.enterText(inputFinder, '18366767');
      await tester.pump();

      // Tap "Vào ngay"
      final joinBtnFinder = find.text('Vào ngay');
      expect(joinBtnFinder, findsOneWidget);
      await tester.tap(joinBtnFinder);
      await tester.pump();

      // Verifications: mode activated, input cleared
      expect(devService.level, equals(DevModeLevel.standard));
      final textFieldWidget = tester.widget<TextField>(inputFinder);
      expect(textFieldWidget.controller?.text, isEmpty);

      // 2. Enter secret code again to toggle off
      await tester.enterText(inputFinder, '18366767');
      await tester.tap(joinBtnFinder);
      await tester.pump();

      expect(devService.level, equals(DevModeLevel.none));
      expect(textFieldWidget.controller?.text, isEmpty);

      // 3. Enter secret code 67676767 for verbose mode
      await tester.enterText(inputFinder, '67676767');
      await tester.tap(joinBtnFinder);
      await tester.pump();

      expect(devService.level, equals(DevModeLevel.verbose));
      expect(textFieldWidget.controller?.text, isEmpty);
    });

    testWidgets('Entering 18366767 in ExamDetailScreen toggles developer mode and clears input', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final auth = AuthProvider(isSupabaseInitialized: false);
      await auth.init();

      final devService = DeveloperModeService();
      await devService.init();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: auth),
            ChangeNotifierProvider<DeveloperModeService>.value(value: devService),
          ],
          child: const MaterialApp(
            home: ExamDetailScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(devService.level, equals(DevModeLevel.none));

      final roomInputFinder = find.widgetWithText(TextField, 'Nhập mã phòng do giáo viên cung cấp');
      expect(roomInputFinder, findsOneWidget);

      await tester.enterText(roomInputFinder, '18366767');
      await tester.pump();

      final startBtnFinder = find.text('Bắt đầu tự luyện');
      expect(startBtnFinder, findsOneWidget);
      await tester.tap(startBtnFinder);
      await tester.pumpAndSettle();

      expect(devService.level, equals(DevModeLevel.standard));
      final textFieldWidget = tester.widget<TextField>(roomInputFinder);
      expect(textFieldWidget.controller?.text, isEmpty);
    });
  });
}
