import 'package:flutter/foundation.dart';

import 'crash_reporter_service.dart';

/// App-wide crash reporting facade. Wire up a [CrashReporterService]
/// at startup; call static helpers from anywhere.
///
/// ```dart
/// // main.dart
/// CrashReporter.register(FirebaseCrashlyticsAdapter());
/// FlutterError.onError = CrashReporter.recordFlutterError;
///
/// // anywhere
/// try { ... } catch (e, st) {
///   CrashReporter.recordError(e, stackTrace: st, reason: 'checkout failed');
/// }
/// ```
///
/// Defaults to [NoOpCrashReporterService] — calls are safe before
/// [register] runs.
class CrashReporter {
  CrashReporter._();

  static CrashReporterService _service = const NoOpCrashReporterService();

  /// Global kill switch. Flip to `false` in debug builds or opt-out
  /// flows — every call short-circuits.
  static bool enabled = true;

  /// The active backend. Mostly useful for tests.
  static CrashReporterService get service => _service;

  /// Install [service] as the active backend. Safe to call again to
  /// swap implementations.
  static void register(CrashReporterService service) => _service = service;

  /// Restore the no-op default.
  static void reset() => _service = const NoOpCrashReporterService();

  // ─── Recording ─────────────────────────────────────────────────

  static Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) {
    if (!enabled) return Future.value();
    return _service.recordError(
      error,
      stackTrace: stackTrace,
      reason: reason,
      fatal: fatal,
      context: context,
    );
  }

  /// Convenience for `FlutterError.onError = CrashReporter.recordFlutterError`.
  static Future<void> recordFlutterError(FlutterErrorDetails details) {
    if (!enabled) return Future.value();
    return _service.recordFlutterError(details);
  }

  static Future<void> log(String message) {
    if (!enabled) return Future.value();
    return _service.log(message);
  }

  // ─── Identity / context ────────────────────────────────────────

  static Future<void> setUserId(String? id) {
    if (!enabled) return Future.value();
    return _service.setUserId(id);
  }

  static Future<void> setCustomKey(String key, Object? value) {
    if (!enabled) return Future.value();
    return _service.setCustomKey(key, value);
  }

  /// Dev-only — test the pipeline.
  static Future<void> crash() => _service.crash();
}
