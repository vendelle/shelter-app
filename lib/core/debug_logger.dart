import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent debug logger that survives page redirects.
/// Logs are stored in SharedPreferences and can be retrieved after redirects.
class DebugLogger {
  static const String _logKey = 'debug_logs';
  static const int _maxLogs = 100;

  /// Add a log entry that persists across redirects
  static Future<void> log(String message) async {
    if (!kDebugMode) return;

    final timestamp = DateTime.now().toIso8601String();
    final entry = '[$timestamp] $message';

    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_logKey) ?? [];

      // Keep only last N logs
      if (existing.length >= _maxLogs) {
        existing.removeAt(0);
      }

      existing.add(entry);
      await prefs.setStringList(_logKey, existing);

      // Also print to console
      if (kDebugMode) print(entry);
    } catch (e) {
      if (kDebugMode) print('Error writing to debug log: $e');
    }
  }

  /// Get all persisted logs
  static Future<List<String>> getLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_logKey) ?? [];
    } catch (e) {
      if (kDebugMode) print('Error reading debug logs: $e');
      return [];
    }
  }

  /// Clear all logs
  static Future<void> clearLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_logKey);
    } catch (e) {
      if (kDebugMode) print('Error clearing debug logs: $e');
    }
  }

  /// Get logs as formatted string for display
  static Future<String> getLogsAsString() async {
    final logs = await getLogs();
    return logs.join('\n');
  }
}
