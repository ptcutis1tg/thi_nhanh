import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onthi_community/core/utils/supabase_retry_helper.dart';

void main() {
  group('SupabaseRetryHelper', () {
    test('succeeds immediately if no error', () async {
      int callCount = 0;
      final result = await SupabaseRetryHelper.run(() async {
        callCount++;
        return 'success';
      });

      expect(result, 'success');
      expect(callCount, 1);
    });

    test('retries on PGRST303 clock skew and succeeds', () async {
      int callCount = 0;
      final result = await SupabaseRetryHelper.run(
        () async {
          callCount++;
          if (callCount == 1) {
            throw const PostgrestException(
              message: 'JWT issued at future',
              code: 'PGRST303',
            );
          }
          return 'recovered';
        },
        initialDelay: const Duration(milliseconds: 10),
      );

      expect(result, 'recovered');
      expect(callCount, 2);
    });

    test('retries on PGRST301 jwt expired and succeeds', () async {
      int callCount = 0;
      final result = await SupabaseRetryHelper.run(
        () async {
          callCount++;
          if (callCount == 1) {
            throw const PostgrestException(
              message: 'JWT expired',
              code: 'PGRST301',
            );
          }
          return 'refreshed';
        },
        initialDelay: const Duration(milliseconds: 10),
      );

      expect(result, 'refreshed');
      expect(callCount, 2);
    });

    test('retries on transient socket exception and succeeds', () async {
      int callCount = 0;
      final result = await SupabaseRetryHelper.run(
        () async {
          callCount++;
          if (callCount == 1) {
            throw const SocketException('Connection reset by peer');
          }
          return 'reconnected';
        },
        initialDelay: const Duration(milliseconds: 10),
      );

      expect(result, 'reconnected');
      expect(callCount, 2);
    });

    test('rethrows if max retries exceeded', () async {
      int callCount = 0;
      expect(
        () => SupabaseRetryHelper.run(
          () async {
            callCount++;
            throw const PostgrestException(
              message: 'JWT issued at future',
              code: 'PGRST303',
            );
          },
          maxRetries: 2,
          initialDelay: const Duration(milliseconds: 10),
        ),
        throwsA(isA<PostgrestException>()),
      );
    });

    test('rethrows immediately on non-retryable PostgrestException', () async {
      int callCount = 0;
      expect(
        () => SupabaseRetryHelper.run(
          () async {
            callCount++;
            throw const PostgrestException(
              message: 'relation does not exist',
              code: '42P01',
            );
          },
          initialDelay: const Duration(milliseconds: 10),
        ),
        throwsA(isA<PostgrestException>()),
      );
      expect(callCount, 1);
    });
  });
}
