import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/developer_mode_service.dart';
import '../theme/app_theme.dart';

class AppErrorReporter {
  /// Chuẩn hóa mã phòng thi nhập từ người dùng.
  /// Nếu người dùng chỉ gõ số (VD: 892341 hoặc 67664), tự động thêm tiền tố 'PT' và pad đủ 6 số.
  static String normalizeRoomCode(String input) {
    final clean = input.trim().toUpperCase();
    if (clean.isEmpty) return clean;
    if (RegExp(r'^\d+$').hasMatch(clean)) {
      return 'PT${clean.padLeft(6, '0')}';
    }
    return clean;
  }

  /// Chuyển đổi mã lỗi kỹ thuật hoặc PostgrestException thành thông báo tiếng Việt thân thiện.
  static String formatErrorMessage(dynamic error, {String? roomCode}) {
    if (error == null) return 'Đã xảy ra lỗi không xác định.';
    String raw = '';
    if (error is PostgrestException) {
      raw = error.message;
    } else {
      raw = error.toString().replaceAll('Exception: ', '').trim();
      final match = RegExp(r'message:\s*([^,)]+)').firstMatch(raw);
      if (match != null && match.group(1) != null) {
        raw = match.group(1)!.trim();
      }
    }

    final lower = raw.toLowerCase();
    if (lower.contains('room not found') || lower.contains('không tìm thấy')) {
      final codeDisplay = (roomCode != null && roomCode.trim().isNotEmpty) ? ' với mã "$roomCode"' : '';
      return 'Không tìm thấy phòng thi$codeDisplay. Vui lòng kiểm tra lại mã phòng!';
    }
    if (lower.contains('already ended') || lower.contains('closed') || lower.contains('đã kết thúc')) {
      return 'Phòng thi này đã kết thúc hoặc không còn nhận thí sinh.';
    }
    if (lower.contains('invalid room password') || lower.contains('mật khẩu') || lower.contains('password')) {
      return 'Mật khẩu phòng thi không chính xác.';
    }
    if (lower.contains('full') || lower.contains('đầy')) {
      return 'Phòng thi đã đủ số lượng thí sinh tham gia.';
    }
    if (lower.contains('jwt') || lower.contains('pgrst301') || lower.contains('pgrst303')) {
      return 'Phiên đăng nhập đã hết hạn hoặc thời gian máy chưa đồng bộ. Vui lòng thử lại!';
    }
    return raw;
  }

  static void showErrorSnackBar(
    BuildContext context,
    String message, {
    dynamic error,
    dynamic stackTrace,
    Duration duration = const Duration(seconds: 4),
  }) {
    // 1. Forward error to DeveloperModeService if present in context
    try {
      final devService = context.read<DeveloperModeService>();
      devService.recordError(message, error: error, stackTrace: stackTrace);
    } catch (_) {}

    // 2. Show red SnackBar to the user
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.removeCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.error,
          duration: duration,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

