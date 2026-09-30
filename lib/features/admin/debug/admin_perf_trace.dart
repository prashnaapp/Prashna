import 'package:flutter/foundation.dart';

/// Debug-only elapsed-time log for Admin navigation and assignment flows.
///
/// Release builds skip the stopwatch and the log.
class AdminPerfTrace {
  static Future<T> span<T>(String name, Future<T> Function() action) async {
    if (!kDebugMode) return action();
    final watch = Stopwatch()..start();
    try {
      return await action();
    } finally {
      watch.stop();
      debugPrint('[admin-perf] $name ${watch.elapsedMilliseconds}ms');
    }
  }
}
