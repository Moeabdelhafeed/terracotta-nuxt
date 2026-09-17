import 'package:flutter/foundation.dart';

/// Abstract analytics interface — every backend (Firebase, Amplitude,
/// Mixpanel, custom) implements this single surface so the rest of the
/// app stays vendor-agnostic.
///
/// Use the [Analytics] facade for app-wide access; only touch this class
/// directly when writing a new adapter.
///
/// ```dart
/// class MyAdapter extends AnalyticsService {
///   @override
///   Future<void> logEvent(AnalyticsEvent event) async { ... }
///   // override the rest as needed
/// }
/// ```
abstract class AnalyticsService {
  const AnalyticsService();

  /// Whether this backend is currently capturing events. Adapters should
  /// short-circuit when false. The [Analytics] facade gates everything
  /// once globally, so override this only for backend-specific kill
  /// switches (e.g. consent rejected for one vendor only).
  bool get enabled => true;

  /// Toggle this backend on/off without tearing it down. Default is a
  /// no-op — adapters that need to honor the flag should override.
  Future<void> setEnabled(bool value) async {}

  /// Record a single event. Implementations should normalize parameter
  /// values to types the SDK accepts (string / num / bool / list).
  Future<void> logEvent(AnalyticsEvent event);

  /// Record a screen view. Default routes through [logEvent] using the
  /// reserved `screen_view` name; SDKs with a first-class screen API
  /// should override.
  Future<void> logScreenView({
    required String name,
    String? screenClass,
    Map<String, Object?> params = const {},
  }) {
    return logEvent(
      AnalyticsEvent(
        name: 'screen_view',
        params: {
          'screen_name': name,
          if (screenClass != null) 'screen_class': screenClass,
          ...params,
        },
      ),
    );
  }

  /// Bind subsequent events to a user identity. Pass `null` to clear
  /// (or call [clearUser] for explicit intent).
  Future<void> setUserId(String? id);

  /// Set a single user property — analytics dashboards segment users by
  /// these (plan tier, locale, role, …).
  Future<void> setUserProperty({required String name, required Object? value});

  /// Bulk variant of [setUserProperty]. Default loops; override for
  /// SDKs with a batched call.
  Future<void> setUserProperties(Map<String, Object?> properties) async {
    for (final entry in properties.entries) {
      await setUserProperty(name: entry.key, value: entry.value);
    }
  }

  /// Forget the current user identity and properties. Adapters should
  /// also reset the device ID where the SDK supports it.
  Future<void> clearUser() => setUserId(null);

  /// Record a non-fatal error (caught exception, validation failure, …).
  /// For crashes, use the platform's crash reporter directly — analytics
  /// is for product behavior, not stack traces.
  Future<void> logError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  });

  /// Optional: flush any in-memory queue to the network. SDKs that batch
  /// (Amplitude, Mixpanel) should implement this; fire-and-forget
  /// backends can leave the no-op default.
  Future<void> flush() async {}
}

/// Immutable record of a user-facing analytics event.
///
/// Parameter values should be primitives (`String`, `num`, `bool`) or
/// lists of primitives — anything else is at the mercy of the underlying
/// SDK's serializer. Adapters are free to drop unsupported types.
@immutable
class AnalyticsEvent {
  const AnalyticsEvent({required this.name, this.params = const {}});

  /// Event name. Stick to `snake_case`; some SDKs reject characters
  /// outside `[a-zA-Z0-9_]`.
  final String name;

  /// Flat map of parameter values. Nested objects are not portable
  /// across vendors — flatten to dotted keys at the call site.
  final Map<String, Object?> params;

  AnalyticsEvent copyWith({String? name, Map<String, Object?>? params}) {
    return AnalyticsEvent(
      name: name ?? this.name,
      params: params ?? this.params,
    );
  }

  @override
  String toString() => 'AnalyticsEvent($name, $params)';
}

/// Default backend — drops every call. Used when [Analytics] hasn't been
/// initialized or when analytics is disabled (debug builds, opt-out).
class NoOpAnalyticsService extends AnalyticsService {
  const NoOpAnalyticsService();

  @override
  bool get enabled => false;

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}

  @override
  Future<void> setUserId(String? id) async {}

  @override
  Future<void> setUserProperty({
    required String name,
    required Object? value,
  }) async {}

  @override
  Future<void> logError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) async {}
}

/// Fan-out adapter — forwards every call to a list of backends in
/// registration order. Use this when you ship to multiple vendors at
/// once (e.g. Firebase for marketing + Amplitude for product).
///
/// Failures in one backend never block the others — each call is
/// awaited individually inside a try/catch. Optionally pass an
/// [onError] hook to surface failures to your error reporter.
class MultiAnalyticsService extends AnalyticsService {
  MultiAnalyticsService(this.services, {this.onError});

  final List<AnalyticsService> services;

  /// Invoked when a child backend throws. Default: silently swallow.
  final void Function(
    AnalyticsService service,
    Object error,
    StackTrace stackTrace,
  )?
  onError;

  Future<void> _fanOut(Future<void> Function(AnalyticsService) action) async {
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
  Future<void> logEvent(AnalyticsEvent event) =>
      _fanOut((s) => s.logEvent(event));

  @override
  Future<void> logScreenView({
    required String name,
    String? screenClass,
    Map<String, Object?> params = const {},
  }) {
    return _fanOut(
      (s) =>
          s.logScreenView(name: name, screenClass: screenClass, params: params),
    );
  }

  @override
  Future<void> setUserId(String? id) => _fanOut((s) => s.setUserId(id));

  @override
  Future<void> setUserProperty({required String name, required Object? value}) {
    return _fanOut((s) => s.setUserProperty(name: name, value: value));
  }

  @override
  Future<void> setUserProperties(Map<String, Object?> properties) {
    return _fanOut((s) => s.setUserProperties(properties));
  }

  @override
  Future<void> clearUser() => _fanOut((s) => s.clearUser());

  @override
  Future<void> logError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    return _fanOut(
      (s) => s.logError(error, stackTrace: stackTrace, context: context),
    );
  }

  @override
  Future<void> flush() => _fanOut((s) => s.flush());
}
