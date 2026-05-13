import 'package:shared_preferences/shared_preferences.dart';

/// Persistent debug logger that survives page redirects.
/// Logs are stored in SharedPreferences and can be retrieved after redirects.
/// Works in both debug AND release builds.
class DebugLogger {
  static const String _logKey = 'debug_logs';
  static const int _maxLogs = 200;

  /// Add a log entry that persists across redirects (fire-and-forget)
  static void log(String message) {
    final timestamp = DateTime.now().toIso8601String();
    final entry = '[$timestamp] $message';

    // Print to console always (helps in dev)
    print(entry);

    // Try to persist to SharedPreferences (fire and forget)
    _persistLog(entry);
  }

  /// Private method to persist logs
  static Future<void> _persistLog(String entry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_logKey) ?? [];

      // Keep only last N logs
      if (existing.length >= _maxLogs) {
        existing.removeRange(0, existing.length - _maxLogs + 1);
      }

      existing.add(entry);
      await prefs.setStringList(_logKey, existing);
    } catch (e) {
      print('ERROR: Failed to write debug log: $e');
    }
  }

  /// Get all persisted logs
  static Future<List<String>> getLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_logKey) ?? [];
    } catch (e) {
      print('ERROR: Failed to read debug logs: $e');
      return [];
    }
  }

  /// Clear all logs
  static Future<void> clearLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_logKey);
    } catch (e) {
      print('ERROR: Failed to clear debug logs: $e');
    }
  }

  /// Get logs as formatted string for display
  static Future<String> getLogsAsString() async {
    final logs = await getLogs();
    return logs.join('\n');
  }
}
