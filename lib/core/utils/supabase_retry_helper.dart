import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper for executing Supabase queries with resilience against transient
/// clock skew errors (PGRST303: JWT issued at future) and momentary network blips.
class SupabaseRetryHelper {
  /// Checks whether an exception is caused by clock skew between client/auth and database.
  static bool isClockSkewError(dynamic error) {
    if (error is PostgrestException) {
      if (error.code == 'PGRST303') return true;
      final msg = error.message.toLowerCase();
      if (msg.contains('jwt issued at future') ||
          msg.contains('issued in the future') ||
          (msg.contains('jwt') && msg.contains('future'))) {
        return true;
      }
    }
    final str = error.toString().toLowerCase();
    return str.contains('pgrst303') || str.contains('jwt issued at future');
  }

  /// Runs [action] with automatic retries if a clock skew error (PGRST303) occurs.
  /// [maxRetries] defaults to 2 (total 3 attempts).
  /// [initialDelay] defaults to 1.5 seconds, which allows the database server clock
  /// to catch up with the JWT's `iat` (issued at) timestamp.
  static Future<T> run<T>(
    Future<T> Function() action, {
    int maxRetries = 2,
    Duration initialDelay = const Duration(milliseconds: 1500),
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await action();
      } catch (e) {
        if (isClockSkewError(e) && attempt < maxRetries) {
          final waitDuration = initialDelay * (attempt + 1);
          debugPrint(
            'Phát hiện độ lệch đồng hồ (PGRST303: JWT issued at future). '
            'Đang đợi ${waitDuration.inMilliseconds}ms để đồng hồ máy chủ bắt kịp và thử lại (lần ${attempt + 1}/$maxRetries)...',
          );
          await Future.delayed(waitDuration);
          continue;
        }
        rethrow;
      }
    }
    return await action();
  }
}
