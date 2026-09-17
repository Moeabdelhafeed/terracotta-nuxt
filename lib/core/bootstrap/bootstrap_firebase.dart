import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../data/services/remote_config_service.dart';
import '../../firebase_options.dart';
import '../analytics/analytics.dart';
import '../analytics/analytics_adapters.dart';
import '../crash_reporting/crash_reporter.dart';
import '../crash_reporting/crash_reporter_adapters.dart';
import '../error/error_storm.dart';
import '../flavor/flavor_config.dart';
import '../utils/loggers/logger.dart';

/// Initialize Firebase, register vendor adapters for analytics + crash
/// reporting, hook the platform error stream into the crash reporter,
/// and warm up Remote Config.
///
/// On iOS / Android the native plugin reads the per-flavor config from
/// the app bundle (`GoogleService-Info.plist` / `google-services.json`).
/// Web / desktop have no native config slot, so they ship through the
/// per-flavor generated `firebase_options_<flavor>.dart` files routed
/// by [firebaseOptionsForFlavor].
Future<void> initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: firebaseOptionsForFlavor(FlavorConfig.instance.flavor),
    );
  } else {
    await Firebase.initializeApp();
  }

  // Both facades are vendor-agnostic — swap adapters here to switch
  // backends without touching feature code.
  Analytics.register(FirebaseAnalyticsAdapter());
  CrashReporter.register(FirebaseCrashlyticsAdapter());

  PlatformDispatcher.instance.onError = (error, stack) {
    // A failing stream or a retry loop throws here as fast as it can
    // spin, so fold repeats the same way the framework hook does.
    final verdict = ErrorStorm.admit(error, stack);
    if (!verdict.log) return true;
    // This hook runs in the root zone, where the bootstrap zone's
    // print override can't reach — log explicitly so uncaught async
    // errors land in the formatted logger + LogBuffer instead of only
    // the crash backend.
    Logger.m.f(
      '[Uncaught] $error${verdict.suffix}',
      error: error,
      stackTrace: stack,
    );
    if (verdict.report) {
      CrashReporter.recordError(error, stackTrace: stack, fatal: true);
    }
    return true;
  };

  final remoteConfigInitialized = await RemoteConfigService.init();
  if (!remoteConfigInitialized) {
    Logger.m.w('Remote Config failed to initialize. Using default values.');
  }
}
