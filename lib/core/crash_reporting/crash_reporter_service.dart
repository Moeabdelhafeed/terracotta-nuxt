import 'package:flutter/foundation.dart';

/// Abstract crash / error reporter — every backend (Crashlytics,
/// Sentry, Bugsnag, custom) implements this surface so app code stays
/// vendor-agnostic. Use the [CrashReporter] facade for app-wide
/// access; only touch this class directly when writing an adapter.
///
/// ```dart
/// class MyAdapter extends CrashReporterService {
///   @override
///   Future<void> recordError(Object error, StackTrace? st, {...}) async { ... }
/// }
/// ```
abstract class CrashReporterService {
  const CrashReporterService();

  /// Whether this backend is currently capturing reports. Adapters
  /// should short-circuit when false.
  bool get enabled => true;

  /// Toggle on/off without tearing down — e.g. honor a user opt-out.
  /// Default is a no-op; adapters with a collection flag should
  /// override.
  Future<void> setEnabled(bool value) async {}

  /// Record a non-fatal error. [fatal] marks the error as a crash
  /// for backends that distinguish; most do, so set it accurately.
  /// [context] is a flat map of extra debug info attached to the
  /// report.
  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
    Map<String, Object?> context = const {},
  });

  /// Record a Flutter framework error. Default forwards to
  /// [recordError]; adapters with a dedicated Flutter path (e.g.
  /// Crashlytics' `recordFlutterError`) should override.
  Future<void> recordFlutterError(FlutterErrorDetails details) {
    return recordError(
      details.exception,
      stackTrace: details.stack,
      reason: details.context?.toString(),
    );
  }

  /// Leave a breadcrumb — short string trail shown alongside the
  /// next crash, to help reconstruct how the user got there.
  Future<void> log(String message);

  /// Attach a user identity to subsequent reports. Pass `null` on
  /// logout.
  Future<void> setUserId(String? id);

  /// Attach a custom key/value. Backends display these on the crash
  /// details page.
  Future<void> setCustomKey(String key, Object? value);

  /// Crash the process on demand. Only for testing the pipeline;
  /// release builds should wire this behind a dev-only toggle.
  Future<void> crash() async {}
}

/// Default backend — drops every call. Used before [CrashReporter]
/// is initialized or when reporting is disabled.
class NoOpCrashReporterService extends CrashReporterService {
  const NoOpCrashReporterService();

  @override
  bool get enabled => false;

  @override
  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) async {}

  @override
  Future<void> log(String message) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setCustomKey(String key, Object? value) async {}
}

/// Fan-out adapter — forwards every call to multiple backends.
/// Failures in one backend never block the others.
class MultiCrashReporterService extends CrashReporterService {
  MultiCrashReporterService(this.services, {this.onError});

  final List<CrashReporterService> services;

  /// Invoked when a child adapter throws. Default: swallow silently.
  final void Function(
    CrashReporterService service,
    Object error,
    StackTrace stackTrace,
  )?
  onError;

  Future<void> _fanOut(
    Future<void> Function(CrashReporterService) action,
  ) async {
    for (final service in services) {
      try {
        await action(service);
      } catch (e, st) {
        onError?.call(service, e, st);
      }
    }
  }

  @override
  Future<void> setEnabled(bool value) => _fanOut((s) => s.setEnabled(value));

  @override
  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) {
    return _fanOut(
      (s) => s.recordError(
        error,
        stackTrace: stackTrace,
        reason: reason,
        fatal: fatal,
        context: context,
      ),
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) {
    return _fanOut((s) => s.recordFlutterError(details));
  }

  @override
  Future<void> log(String message) => _fanOut((s) => s.log(message));

  @override
  Future<void> setUserId(String? id) => _fanOut((s) => s.setUserId(id));

  @override
  Future<void> setCustomKey(String key, Object? value) =>
      _fanOut((s) => s.setCustomKey(key, value));

  @override
  Future<void> crash() => _fanOut((s) => s.crash());
}
