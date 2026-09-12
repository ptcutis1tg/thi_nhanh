import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onthi_community/core/services/developer_mode_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('DeveloperModeService Tests', () {
    test('initial state defaults to none and empty logs', () async {
      final service = DeveloperModeService();
      await service.init();

      expect(service.level, equals(DevModeLevel.none));
      expect(service.isDevModeActive, isFalse);
      expect(service.logs, isEmpty);
      expect(service.isExpanded, isFalse);
    });

    test('handleRoomCode 18366767 toggles standard mode on and off', () async {
      final service = DeveloperModeService();
      await service.init();

      // 1st time: activate standard
      final handled1 = await service.handleRoomCode('18366767');
      expect(handled1, isTrue);
      expect(service.level, equals(DevModeLevel.standard));
      expect(service.isDevModeActive, isTrue);

      // Verify SharedPreferences persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('developer_mode_level'), equals('standard'));

      // 2nd time: toggle off
      final handled2 = await service.handleRoomCode('18366767');
      expect(handled2, isTrue);
      expect(service.level, equals(DevModeLevel.none));
      expect(service.isDevModeActive, isFalse);
      expect(prefs.getString('developer_mode_level'), equals('none'));
    });

    test('handleRoomCode 67676767 toggles verbose mode on and off', () async {
      final service = DeveloperModeService();
      await service.init();

      // Activate verbose
      final handled1 = await service.handleRoomCode('67676767');
      expect(handled1, isTrue);
      expect(service.level, equals(DevModeLevel.verbose));
      expect(service.isDevModeActive, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('developer_mode_level'), equals('verbose'));

      // Toggle off
      final handled2 = await service.handleRoomCode('67676767');
      expect(handled2, isTrue);
      expect(service.level, equals(DevModeLevel.none));
      expect(service.isDevModeActive, isFalse);
      expect(prefs.getString('developer_mode_level'), equals('none'));
    });

    test('handleRoomCode switches between standard and verbose', () async {
      final service = DeveloperModeService();
      await service.init();

      await service.handleRoomCode('18366767');
      expect(service.level, equals(DevModeLevel.standard));

      await service.handleRoomCode('67676767');
      expect(service.level, equals(DevModeLevel.verbose));

      await service.handleRoomCode('18366767');
      expect(service.level, equals(DevModeLevel.standard));
    });

    test('unrecognized room code returns false without altering mode', () async {
      final service = DeveloperModeService();
      await service.init();

      final handled = await service.handleRoomCode('PT123456');
      expect(handled, isFalse);
      expect(service.level, equals(DevModeLevel.none));
    });

    test('init restores previously saved developer mode level', () async {
      SharedPreferences.setMockInitialValues({
        'developer_mode_level': 'standard',
      });

      final service = DeveloperModeService();
      await service.init();

      expect(service.level, equals(DevModeLevel.standard));
      expect(service.isDevModeActive, isTrue);
    });

    test('recordError records error entries and auto-expands console', () async {
      final service = DeveloperModeService();
      await service.init();
      await service.handleRoomCode('18366767');

      expect(service.isExpanded, isFalse);

      service.recordError(
        'Lỗi nạp bài thi',
        error: 'SocketException: Connection refused',
        stackTrace: StackTrace.fromString('#0 main() in test.dart:12'),
      );

      expect(service.logs.length, equals(1));
      final entry = service.logs.first;
      expect(entry.level, equals(DevLogLevel.error));
      expect(entry.title, equals('Lỗi nạp bài thi'));
      expect(entry.details, contains('SocketException'));
      expect(entry.stackTrace, contains('test.dart:12'));
      expect(service.isExpanded, isTrue); // Auto-expands on error

      final formatted = entry.formattedText;
      expect(formatted, contains('[ERROR] Lỗi nạp bài thi'));
      expect(formatted, contains('SocketException'));
    });

    test('recordDebug records debug logs in verbose mode, but ignores them in standard mode', () async {
      final service = DeveloperModeService();
      await service.init();

      // Standard mode
      await service.handleRoomCode('18366767');
      service.recordDebug('Gửi request lấy danh sách đề thi');
      expect(service.logs, isEmpty);

      // Switch to verbose mode
      await service.handleRoomCode('67676767');
      service.recordDebug('Gửi request lấy danh sách đề thi');
      expect(service.logs.length, equals(1));
      expect(service.logs.first.level, equals(DevLogLevel.debug));
      expect(service.logs.first.title, equals('Gửi request lấy danh sách đề thi'));
    });

    test('clearLogs removes all accumulated logs', () async {
      final service = DeveloperModeService();
      await service.init();
      await service.handleRoomCode('18366767');

      service.recordError('Lỗi 1');
      service.recordError('Lỗi 2');
      expect(service.logs.length, equals(2));

      service.clearLogs();
      expect(service.logs, isEmpty);
    });

    test('toggleExpanded and setExpanded manipulate overlay visibility', () async {
      final service = DeveloperModeService();
      expect(service.isExpanded, isFalse);

      service.toggleExpanded();
      expect(service.isExpanded, isTrue);

      service.setExpanded(false);
      expect(service.isExpanded, isFalse);
    });
  });
}
