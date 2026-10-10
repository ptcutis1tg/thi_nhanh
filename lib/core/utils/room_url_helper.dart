import 'package:flutter/foundation.dart';
import 'app_error_reporter.dart';

class RoomUrlHelper {
  /// Builds a fully qualified, valid join URL for a given room code.
  /// Dynamically detects the current web origin and path so local dev, custom domains,
  /// and production deployments generate working links for camera QR scanning.
  static String buildJoinUrl(String roomCode) {
    final cleanCode = AppErrorReporter.normalizeRoomCode(roomCode);
    if (kIsWeb) {
      final base = Uri.base;
      final origin = base.origin;
      var path = base.path;
      if (path.endsWith('/')) {
        path = path.substring(0, path.length - 1);
      }
      return '$origin$path/#/join?code=$cleanCode';
    }
    return 'https://thinhành.vn/#/join?code=$cleanCode';
  }
}
