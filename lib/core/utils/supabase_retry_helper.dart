import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper for executing Supabase queries with resilience against transient
/// clock skew errors (PGRST303: JWT issued at future), expired tokens (PGRST301),
/// and momentary network blips.
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

  /// Checks whether an exception is caused by an expired JWT token (e.g. client clock lagged behind).
  static bool isJwtExpiredError(dynamic error) {
    if (error is PostgrestException) {
      if (error.code == 'PGRST301') return true;
      final msg = error.message.toLowerCase();
      if (msg.contains('jwt expired') || msg.contains('token expired')) {
        return true;
      }
    }
    final str = error.toString().toLowerCase();
    return str.contains('pgrst301') || str.contains('jwt expired');
  }

  /// Checks whether an exception is a transient network or connection drop.
  static bool isTransientNetworkError(dynamic error) {
    if (error is SocketException) return true;
    final str = error.toString().toLowerCase();
    return str.contains('socketexception') ||
        str.contains('connection closed') ||
        str.contains('connection refused') ||
        str.contains('network is unreachable');
  }

  /// Runs [action] with automatic retries and intelligent recovery:
  /// - On clock skew (PGRST303): waits for server clock to advance past JWT iat, then retries.
  /// - On expired JWT (PGRST301): attempts to refresh the Supabase session, then retries.
  /// - On momentary network blip: waits briefly, then retries.
  static Future<T> run<T>(
    Future<T> Function() action, {
    int maxRetries = 2,
    Duration initialDelay = const Duration(milliseconds: 1500),
  }) async {
    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await action();
      } catch (e) {
        if (attempt >= maxRetries) {
          rethrow;
        }

        if (isClockSkewError(e)) {
          final waitDuration = initialDelay * (attempt + 1);
          debugPrint(
            'Phát hiện độ lệch đồng hồ (PGRST303: JWT issued at future). '
            'Đang đợi ${waitDuration.inMilliseconds}ms để đồng hồ máy chủ bắt kịp và thử lại (lần ${attempt + 1}/$maxRetries)...',
          );
          await Future.delayed(waitDuration);
          continue;
        }

        if (isJwtExpiredError(e)) {
          debugPrint(
            'Phát hiện JWT hết hạn (PGRST301). Đang thử làm mới phiên (refreshSession) và thử lại...',
          );
          try {
            await Supabase.instance.client.auth.refreshSession();
          } catch (refreshErr) {
            debugPrint('Không thể làm mới phiên: $refreshErr');
          }
          await Future.delayed(const Duration(milliseconds: 500));
          continue;
        }

        if (isTransientNetworkError(e)) {
          final waitDuration = Duration(milliseconds: 500 * (attempt + 1));
          debugPrint(
            'Phát hiện mất kết nối mạng tạm thời. Đang thử lại sau ${waitDuration.inMilliseconds}ms...',
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
