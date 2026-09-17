import 'analytics_service.dart';

/// App-wide analytics facade. Wire up an [AnalyticsService] at startup
/// and call the static helpers from anywhere — features stay decoupled
/// from the chosen vendor.
///
/// ```dart
/// // main.dart
/// Analytics.register(MultiAnalyticsService([
///   FirebaseAnalyticsAdapter(...),
///   AmplitudeAnalyticsAdapter(...),
/// ]));
///
/// // anywhere
/// Analytics.logEvent('checkout_started', {'cart_value': 49.99});
/// Analytics.setUserId(user.id);
/// ```
///
/// Defaults to [NoOpAnalyticsService] so calls are safe before
/// [register] runs.
class Analytics {
  Analytics._();

  static AnalyticsService _service = const NoOpAnalyticsService();

  /// Global on/off switch. Honored before any backend call — flip to
  /// `false` to short-circuit on debug builds, in opt-out flows, etc.
  static bool enabled = true;

  /// The active backend. Mostly useful for tests; prefer the static
  /// helpers in production code.
  static AnalyticsService get service => _service;

  /// Install [service] as the active backend. Safe to call again at
  /// runtime to swap implementations (e.g. flipping debug → prod).
  static void register(AnalyticsService service) => _service = service;

  /// Restore the no-op default. Handy in tests or when consent is
  /// withdrawn.
  static void reset() => _service = const NoOpAnalyticsService();

  // ─── Events ──────────────────────────────────────────────────────

  /// Log a named event with an optional flat parameter map.
  static Future<void> logEvent(
    String name, [
    Map<String, Object?> params = const {},
  ]) {
    if (!enabled) return Future.value();
    return _service.logEvent(AnalyticsEvent(name: name, params: params));
  }

  /// Log a pre-built [AnalyticsEvent] — preferable when you build
  /// events through factories or constants.
  static Future<void> log(AnalyticsEvent event) {
    if (!enabled) return Future.value();
    return _service.logEvent(event);
  }

  /// Log a screen view. Pass [screenClass] for SDKs that distinguish
  /// the route name from the widget class.
  static Future<void> logScreenView({
    required String name,
    String? screenClass,
    Map<String, Object?> params = const {},
  }) {
    if (!enabled) return Future.value();
    return _service.logScreenView(
      name: name,
      screenClass: screenClass,
      params: params,
    );
  }

  /// Log a non-fatal error. Crashes belong in your crash reporter, not
  /// here — analytics tracks behavior, not stack traces.
  static Future<void> logError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    if (!enabled) return Future.value();
    return _service.logError(error, stackTrace: stackTrace, context: context);
  }

  // ─── Identity ────────────────────────────────────────────────────

  static Future<void> setUserId(String? id) {
    if (!enabled) return Future.value();
    return _service.setUserId(id);
  }

  static Future<void> setUserProperty({
    required String name,
    required Object? value,
  }) {
    if (!enabled) return Future.value();
    return _service.setUserProperty(name: name, value: value);
  }

  static Future<void> setUserProperties(Map<String, Object?> properties) {
    if (!enabled) return Future.value();
    return _service.setUserProperties(properties);
  }

  static Future<void> clearUser() {
    if (!enabled) return Future.value();
    return _service.clearUser();
  }

  // ─── Lifecycle ───────────────────────────────────────────────────

  /// Flush any pending events to the network. Call before shutdown or
  /// when the app goes to background to avoid losing batched events.
  static Future<void> flush() => _service.flush();
}
