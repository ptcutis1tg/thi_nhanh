import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/developer_mode_service.dart';
import '../theme/app_theme.dart';

class AppErrorReporter {
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
