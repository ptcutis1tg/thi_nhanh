import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onthi_community/core/services/developer_mode_service.dart';
import 'package:onthi_community/core/utils/app_error_reporter.dart';
import 'package:onthi_community/shared/widgets/developer_log_overlay.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildRootTestApp(DeveloperModeService devService) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DeveloperModeService>.value(value: devService),
      ],
      child: MaterialApp(
        builder: (context, child) {
          return Stack(
            children: [
              ?child,
              const DeveloperLogOverlay(),
            ],
          );
        },
        home: Scaffold(
          body: Builder(
            builder: (innerContext) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    AppErrorReporter.showErrorSnackBar(
                      innerContext,
                      'Không thể kết nối đến máy chủ',
                      error: 'SocketException: Connection refused',
                      stackTrace: '#0 fetchServerData (api.dart:15)',
                    );
                  },
                  child: const Text('Trigger Error'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  group('Root Developer Overlay & AppErrorReporter Tests', () {
    testWidgets('AppErrorReporter shows red SnackBar and records error to DeveloperModeService', (tester) async {
      final devService = DeveloperModeService();
      await devService.init();
      await devService.handleRoomCode('18366767'); // Activate dev mode

      await tester.pumpWidget(buildRootTestApp(devService));
      await tester.pumpAndSettle();

      // Initially empty logs
      expect(devService.logs, isEmpty);

      // Trigger error button
      await tester.tap(find.text('Trigger Error'));
      await tester.pumpAndSettle();

      // Verify SnackBar displayed
      expect(find.text('Không thể kết nối đến máy chủ'), findsWidgets);

      // Verify DeveloperModeService received the error
      expect(devService.logs.length, equals(1));
      expect(devService.logs.first.title, equals('Không thể kết nối đến máy chủ'));
      expect(devService.logs.first.details, contains('SocketException'));

      // Verify overlay auto-expanded in the root stack
      expect(find.text('Dev Console'), findsOneWidget);
      expect(find.textContaining('SocketException: Connection refused'), findsOneWidget);
    });
  });
}
