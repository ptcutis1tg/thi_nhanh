import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onthi_community/core/services/developer_mode_service.dart';
import 'package:onthi_community/shared/widgets/developer_log_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget(DeveloperModeService service) {
    return MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<DeveloperModeService>.value(
          value: service,
          child: const Stack(
            children: [
              Center(child: Text('Main Screen Content')),
              DeveloperLogOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  group('DeveloperLogOverlay Widget Tests', () {
    testWidgets('renders nothing when developer mode is inactive (none)', (tester) async {
      final service = DeveloperModeService();
      await service.init();

      await tester.pumpWidget(buildTestWidget(service));
      await tester.pumpAndSettle();

      expect(find.text('Dev'), findsNothing);
      expect(find.text('Dev Console'), findsNothing);
    });

    testWidgets('renders collapsed badge at bottom-right when developer mode is active', (tester) async {
      final service = DeveloperModeService();
      await service.init();
      await service.handleRoomCode('18366767');
      service.setExpanded(false);

      await tester.pumpWidget(buildTestWidget(service));
      await tester.pumpAndSettle();

      expect(find.textContaining('Dev (0)'), findsOneWidget);
      expect(find.byIcon(Icons.pest_control), findsOneWidget);
      expect(find.text('Dev Console'), findsNothing);
    });

    testWidgets('tapping collapsed badge expands the log console', (tester) async {
      final service = DeveloperModeService();
      await service.init();
      await service.handleRoomCode('18366767');
      service.setExpanded(false);

      await tester.pumpWidget(buildTestWidget(service));
      await tester.pumpAndSettle();

      // Tap on the badge
      await tester.tap(find.textContaining('Dev (0)'));
      await tester.pumpAndSettle();

      expect(find.text('Dev Console'), findsOneWidget);
      expect(find.text('Chưa có log lỗi nào được ghi nhận.'), findsOneWidget);
      expect(find.byKey(const Key('dev_copy_all_btn')), findsOneWidget);
      expect(find.byKey(const Key('dev_clear_logs_btn')), findsOneWidget);
      expect(find.byKey(const Key('dev_minimize_btn')), findsOneWidget);
    });

    testWidgets('renders log entries with details, copy action, clear action, and minimize action', (tester) async {
      // Mock clipboard
      String? copiedClipboardText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'Clipboard.setData') {
            copiedClipboardText = (methodCall.arguments as Map)['text'] as String?;
            return null;
          }
          return null;
        },
      );

      final service = DeveloperModeService();
      await service.init();
      await service.handleRoomCode('18366767');

      // Add sample error
      service.recordError(
        'Lỗi tải phòng thi',
        error: 'TimeoutException after 5000ms',
        stackTrace: '#0 RoomRepository.dashboard (room_repo.dart:45)',
      );

      await tester.pumpWidget(buildTestWidget(service));
      await tester.pumpAndSettle();

      // Should auto-expand
      expect(find.text('Dev Console'), findsOneWidget);
      expect(find.text('Lỗi tải phòng thi'), findsOneWidget);
      expect(find.textContaining('TimeoutException after 5000ms'), findsOneWidget);
      expect(find.textContaining('RoomRepository.dashboard'), findsOneWidget);

      // Test single item copy
      final singleCopyBtn = find.byKey(const Key('dev_copy_single_log_btn'));
      expect(singleCopyBtn, findsOneWidget);
      await tester.tap(singleCopyBtn);
      await tester.pump();

      expect(copiedClipboardText, isNotNull);
      expect(copiedClipboardText, contains('Lỗi tải phòng thi'));
      expect(copiedClipboardText, contains('TimeoutException'));

      // Test copy all
      copiedClipboardText = null;
      await tester.tap(find.byKey(const Key('dev_copy_all_btn')));
      await tester.pump();
      expect(copiedClipboardText, contains('Lỗi tải phòng thi'));

      // Test clear logs
      await tester.tap(find.byKey(const Key('dev_clear_logs_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Lỗi tải phòng thi'), findsNothing);
      expect(find.text('Chưa có log lỗi nào được ghi nhận.'), findsOneWidget);

      // Test minimize
      await tester.tap(find.byKey(const Key('dev_minimize_btn')));
      await tester.pumpAndSettle();
      expect(find.text('Dev Console'), findsNothing);
      expect(find.textContaining('Dev (0)'), findsOneWidget);
    });

    testWidgets('safe from focus traversal and view focus changes without RenderBox layout error', (tester) async {
      final service = DeveloperModeService();
      await service.init();
      await service.handleRoomCode('18366767');

      service.recordError(
        'Lỗi thử nghiệm layout',
        error: 'StateError: Test layout state',
        stackTrace: '#0 Test (test.dart:1)',
      );

      await tester.pumpWidget(buildTestWidget(service));
      await tester.pumpAndSettle();

      // Simulate focus traversal across all nodes in the scope
      final element = tester.element(find.byType(MaterialApp));
      final policy = FocusTraversalGroup.maybeOf(element) ?? ReadingOrderTraversalPolicy();
      final focusScope = FocusScope.of(element);
      expect(() {
        policy.findFirstFocusInDirection(
          focusScope,
          TraversalDirection.down,
        );
        focusScope.nextFocus();
        focusScope.previousFocus();
      }, returnsNormally);

      // Minimize and traverse again
      await tester.tap(find.byKey(const Key('dev_minimize_btn')));
      await tester.pumpAndSettle();

      expect(() {
        policy.findFirstFocusInDirection(
          focusScope,
          TraversalDirection.down,
        );
        focusScope.nextFocus();
        focusScope.previousFocus();
      }, returnsNormally);
    });
  });
}
