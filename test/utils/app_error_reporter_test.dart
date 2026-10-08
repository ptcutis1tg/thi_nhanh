import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onthi_community/core/utils/app_error_reporter.dart';

void main() {
  group('AppErrorReporter - normalizeRoomCode', () {
    test('keeps valid PT-prefixed room codes intact and uppercased', () {
      expect(AppErrorReporter.normalizeRoomCode('PT123456'), equals('PT123456'));
      expect(AppErrorReporter.normalizeRoomCode('pt123456'), equals('PT123456'));
      expect(AppErrorReporter.normalizeRoomCode('  pt892341  '), equals('PT892341'));
    });

    test('auto-normalizes pure numeric input to PT-prefixed 6-digit code', () {
      expect(AppErrorReporter.normalizeRoomCode('892341'), equals('PT892341'));
      expect(AppErrorReporter.normalizeRoomCode('67664'), equals('PT067664'));
      expect(AppErrorReporter.normalizeRoomCode('  123456  '), equals('PT123456'));
    });

    test('preserves empty or custom alphanumeric strings', () {
      expect(AppErrorReporter.normalizeRoomCode(''), equals(''));
      expect(AppErrorReporter.normalizeRoomCode('ROOMABC'), equals('ROOMABC'));
    });
  });

  group('AppErrorReporter - formatErrorMessage', () {
    test('translates PostgrestException for Room not found into friendly Vietnamese', () {
      const exception = PostgrestException(
        message: 'Room not found with code: 67664',
        code: 'P0001',
      );

      final message = AppErrorReporter.formatErrorMessage(exception, roomCode: '67664');
      expect(message, contains('Không tìm thấy phòng thi'));
      expect(message, contains('67664'));
      expect(message, isNot(contains('PostgrestException')));
      expect(message, isNot(contains('P0001')));
    });

    test('translates stringified PostgrestException gracefully', () {
      const rawString = 'PostgrestException(message: Room not found with code: 67664, code: P0001, details: , hint: null)';
      final message = AppErrorReporter.formatErrorMessage(rawString, roomCode: '67664');
      expect(message, contains('Không tìm thấy phòng thi'));
      expect(message, isNot(contains('PostgrestException')));
    });

    test('translates room closed or ended exceptions', () {
      const exception = PostgrestException(message: 'This room has already ended');
      final message = AppErrorReporter.formatErrorMessage(exception);
      expect(message, contains('Phòng thi này đã kết thúc'));
    });

    test('translates invalid room password exceptions', () {
      const exception = PostgrestException(message: 'Invalid room password');
      final message = AppErrorReporter.formatErrorMessage(exception);
      expect(message, contains('Mật khẩu phòng thi không chính xác'));
    });
  });
}
