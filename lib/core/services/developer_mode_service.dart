import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DevModeLevel {
  none,
  standard,
  verbose,
}

enum DevLogLevel {
  error,
  debug,
}

class DevLogEntry {
  final String id;
  final DateTime timestamp;
  final DevLogLevel level;
  final String title;
  final String? details;
  final String? stackTrace;

  DevLogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.title,
    this.details,
    this.stackTrace,
  });

  String get formattedText {
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
    final tag = level == DevLogLevel.error ? 'ERROR' : 'DEBUG';
    final buffer = StringBuffer('[$timeStr] [$tag] $title');
    if (details != null && details!.trim().isNotEmpty) {
      buffer.write('\nDetails: ${details!.trim()}');
    }
    if (stackTrace != null && stackTrace!.trim().isNotEmpty) {
      buffer.write('\nStack trace:\n${stackTrace!.trim()}');
    }
    return buffer.toString();
  }
}

class DeveloperModeService extends ChangeNotifier {
  static const String prefKey = 'developer_mode_level';
  static const String standardCode = '18366767';
  static const String verboseCode = '67676767';

  DevModeLevel _level = DevModeLevel.none;
  bool _isExpanded = false;
  final List<DevLogEntry> _logs = [];

  DevModeLevel get level => _level;
  bool get isDevModeActive => _level != DevModeLevel.none;
  bool get isExpanded => _isExpanded;
  List<DevLogEntry> get logs => List.unmodifiable(_logs);

  Future<void> init({SharedPreferences? prefs}) async {
    final preferences = prefs ?? await SharedPreferences.getInstance();
    final savedLevelStr = preferences.getString(prefKey);
    if (savedLevelStr == 'verbose') {
      _level = DevModeLevel.verbose;
    } else if (savedLevelStr == 'standard') {
      _level = DevModeLevel.standard;
    } else {
      _level = DevModeLevel.none;
    }
    notifyListeners();
  }

  Future<bool> handleRoomCode(String rawCode) async {
    final code = rawCode.trim();
    if (code == standardCode) {
      // Toggle standard mode
      if (_level == DevModeLevel.standard) {
        await _setLevel(DevModeLevel.none);
      } else {
        await _setLevel(DevModeLevel.standard);
      }
      return true;
    } else if (code == verboseCode) {
      // Toggle verbose mode
      if (_level == DevModeLevel.verbose) {
        await _setLevel(DevModeLevel.none);
      } else {
        await _setLevel(DevModeLevel.verbose);
      }
      return true;
    }
    return false;
  }

  Future<void> _setLevel(DevModeLevel newLevel) async {
    _level = newLevel;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefKey, newLevel.name);
    } catch (_) {}
    notifyListeners();
  }

  void recordError(String title, {dynamic error, dynamic stackTrace}) {
    if (!isDevModeActive) return;

    final entry = DevLogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: DevLogLevel.error,
      title: title,
      details: error?.toString(),
      stackTrace: stackTrace?.toString(),
    );

    _logs.insert(0, entry); // newest first
    _isExpanded = true; // Auto-expand when a new error occurs
    notifyListeners();
  }

  void recordDebug(String message) {
    if (_level != DevModeLevel.verbose) return;

    final entry = DevLogEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      level: DevLogLevel.debug,
      title: message,
    );

    _logs.insert(0, entry);
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  void toggleExpanded() {
    _isExpanded = !_isExpanded;
    notifyListeners();
  }

  void setExpanded(bool expanded) {
    if (_isExpanded != expanded) {
      _isExpanded = expanded;
      notifyListeners();
    }
  }
}
