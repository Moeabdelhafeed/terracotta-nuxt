import 'dart:async';

import '../crash_reporting/crash_reporter.dart';
import '../utils/loggers/logger.dart';
import 'bootstrap_logging.dart';

/// Run the bootstrap [body] inside a guarded zone so that:
/// - plugin / framework `print(...)` calls are intercepted and routed
///   through the project logger instead of going straight to stdout.
/// - uncaught async errors are forwarded to the crash reporter.
Future<void> runInBootstrapZone(Future<void> Function() body) async {
  await runZonedGuarded(
    body,
    (error, stack) {
      Logger.m.e('Uncaught zone error', error: error, stackTrace: stack);
      CrashReporter.recordError(error, stackTrace: stack, fatal: true);
    },
    zoneSpecification: ZoneSpecification(
      // Filtered through the SAME predicate as the `debugPrint`
      // redirect. These are two doors into one log and only one of
      // them had a lock: a dependency printing a bare `null` came
      // through here untouched and rendered as a log line whose entire
      // content was the word `null`.
      print: (self, parent, zone, line) {
        if (isLogNoise(line)) return;
        Logger.m.d(line);
      },
    ),
  );
}
