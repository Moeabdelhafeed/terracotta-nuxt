import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import 'crash_reporter_service.dart';

/// Firebase Crashlytics adapter. Assumes `Firebase.initializeApp()`
/// has already run.
///
/// Wire in `main.dart`:
/// ```dart
/// CrashReporter.register(FirebaseCrashlyticsAdapter());
/// FlutterError.onError = CrashReporter.recordFlutterError;
/// PlatformDispatcher.instance.onError = (error, stack) {
///   CrashReporter.recordError(error, stackTrace: stack, fatal: true);
///   return true;
/// };
/// ```
///
/// Crashlytics disables collection in debug mode by default — flip
/// `setCrashlyticsCollectionEnabled(true)` on a dev build to test.
class FirebaseCrashlyticsAdapter extends CrashReporterService {
  FirebaseCrashlyticsAdapter({FirebaseCrashlytics? instance})
    : _crashlytics = instance ?? FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  /// Crashlytics has no web platform plugin — calls assert against
  /// `pluginConstants['isCrashlyticsCollectionEnabled']`. Treat all
  /// adapter methods as no-ops on web so Flutter's error sink doesn't
  /// crash on every framework error.
  bool get _supported => !kIsWeb;

  @override
  bool get enabled => _supported && _crashlytics.isCrashlyticsCollectionEnabled;

  @override
  Future<void> setEnabled(bool value) async {
    if (!_supported) return;
    await _crashlytics.setCrashlyticsCollectionEnabled(value);
  }

  @override
  Future<void> recordError(
    Object error, {
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
    Map<String, Object?> context = const {},
  }) async {
    if (!_supported) return;
    for (final entry in context.entries) {
      await _crashlytics.setCustomKey(entry.key, entry.value ?? '');
    }
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
      // The plugin's debug default dumps a raw
      // ----FIREBASE CRASHLYTICS---- block via print(), bypassing the
      // app's logger. GlobalErrorHandler / the PlatformDispatcher hook
      // already logged the error through Logger.m.
      printDetails: false,
    );
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (!_supported) return;
    // NOT _crashlytics.recordFlutterError: that helper force-calls
    // FlutterError.presentError (raw console dump, duplicating our
    // logger output) and prints the banner. Same payload, quiet path.
    await _crashlytics.recordError(
      details.exceptionAsString(),
      details.stack,
      reason: details.context
          ?.toStringDeep(minLevel: DiagnosticLevel.info)
          .trim(),
      information: details.informationCollector?.call() ?? const [],
      printDetails: false,
    );
  }

  @override
  Future<void> log(String message) async {
    if (!_supported) return;
    await _crashlytics.log(message);
  }

  @override
  Future<void> setUserId(String? id) async {
    if (!_supported) return;
    await _crashlytics.setUserIdentifier(id ?? '');
  }

  @override
  Future<void> setCustomKey(String key, Object? value) async {
    if (!_supported) return;
    await _crashlytics.setCustomKey(key, value ?? '');
  }

  @override
  Future<void> crash() async {
    if (!_supported) return;
    _crashlytics.crash();
  }
}

/// Sentry adapter stub — uncomment + add `sentry_flutter` to pubspec
/// to enable. Kept as a template because most teams multiplex between
/// Crashlytics (free, integrated with Firebase) and Sentry (richer
/// dashboards, source maps).
///
/// ```dart
/// import 'package:sentry_flutter/sentry_flutter.dart';
///
/// class SentryCrashReporterAdapter extends CrashReporterService {
///   @override
///   Future<void> recordError(Object error, {StackTrace? stackTrace, ...}) {
///     return Sentry.captureException(error, stackTrace: stackTrace);
///   }
///   // ... setUserId, setCustomKey (via Sentry.configureScope), log (Breadcrumb)
/// }
/// ```
