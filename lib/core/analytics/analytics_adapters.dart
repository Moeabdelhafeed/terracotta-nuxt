import 'package:firebase_analytics/firebase_analytics.dart';

import 'analytics_service.dart';

/// ─── Adapter stubs for the major SaaS analytics SDKs ────────────────────
///
/// Each adapter below is a no-op skeleton. The methods are wired through
/// to [AnalyticsService], the dartdoc on each class lists the pubspec
/// dependency to add and the SDK calls that go inside the method bodies.
///
/// Why no-ops by default? Adding `firebase_analytics`, `amplitude_flutter`,
/// or `mixpanel_flutter` to the template would force every consumer to
/// pay the install cost regardless of which vendor they pick. Pick one,
/// add its dep, drop the SDK calls into the body, ship.
///
/// All three implement the same interface, so swapping vendors — or
/// running them side-by-side via [MultiAnalyticsService] — never
/// requires touching feature code.
///
/// ```dart
/// // main.dart
/// Analytics.register(MultiAnalyticsService([
///   FirebaseAnalyticsAdapter(),   // marketing attribution
///   AmplitudeAnalyticsAdapter(),  // product behavior
/// ]));
/// ```

// ─── Firebase Analytics ─────────────────────────────────────────────────

/// Adapter for [`firebase_analytics`](https://pub.dev/packages/firebase_analytics).
///
/// Required dependency:
/// ```yaml
/// firebase_analytics: ^x.y.z
/// ```
///
/// Wire-up — replace each method body with the corresponding SDK call:
///
/// ```dart
/// final _fa = FirebaseAnalytics.instance;
///
/// @override
/// Future<void> logEvent(AnalyticsEvent event) =>
///   _fa.logEvent(name: event.name, parameters: event.params.cast<String, Object>());
///
/// @override
/// Future<void> setUserId(String? id) => _fa.setUserId(id: id);
///
/// @override
/// Future<void> setUserProperty({required String name, required Object? value}) =>
///   _fa.setUserProperty(name: name, value: value?.toString());
///
/// @override
/// Future<void> logScreenView({required String name, String? screenClass, ...}) =>
///   _fa.logScreenView(screenName: name, screenClass: screenClass);
/// ```
///
/// Errors don't have a first-class API in Firebase Analytics — log them
/// as a custom `non_fatal_error` event, or route them to Crashlytics
/// directly via your error reporter.
class FirebaseAnalyticsAdapter extends AnalyticsService {
  FirebaseAnalyticsAdapter({FirebaseAnalytics? instance})
    : _fa = instance ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _fa;

  @override
  Future<void> setEnabled(bool value) =>
      _fa.setAnalyticsCollectionEnabled(value);

  @override
  Future<void> logEvent(AnalyticsEvent event) {
    return _fa.logEvent(
      name: event.name,
      parameters: _sanitize(event.params),
    );
  }

  @override
  Future<void> logScreenView({
    required String name,
    String? screenClass,
    Map<String, Object?> params = const {},
  }) {
    return _fa.logScreenView(
      screenName: name,
      screenClass: screenClass,
      parameters: _sanitize(params),
    );
  }

  @override
  Future<void> setUserId(String? id) => _fa.setUserId(id: id);

  @override
  Future<void> setUserProperty({required String name, required Object? value}) {
    return _fa.setUserProperty(name: name, value: value?.toString());
  }

  @override
  Future<void> logError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) {
    // Firebase Analytics has no first-class error surface — log it as
    // a normal event. Route actual crashes through `CrashReporter`.
    return _fa.logEvent(
      name: 'non_fatal_error',
      parameters: _sanitize({'message': error.toString(), ...context}),
    );
  }

  /// Firebase Analytics rejects null values and only accepts
  /// `String`/`num` params — drop nulls, stringify anything else.
  Map<String, Object>? _sanitize(Map<String, Object?> params) {
    if (params.isEmpty) return null;
    final out = <String, Object>{};
    for (final entry in params.entries) {
      final v = entry.value;
      if (v == null) continue;
      out[entry.key] = v is num || v is String ? v : v.toString();
    }
    return out.isEmpty ? null : out;
  }
}

// ─── Amplitude ──────────────────────────────────────────────────────────

/// Adapter for [`amplitude_flutter`](https://pub.dev/packages/amplitude_flutter).
///
/// Required dependency:
/// ```yaml
/// amplitude_flutter: ^x.y.z
/// ```
///
/// Construct with your project API key, then drop the SDK calls into the
/// method bodies:
///
/// ```dart
/// final _amp = Amplitude.getInstance(instanceName: 'project');
/// await _amp.init(apiKey);
///
/// @override
/// Future<void> logEvent(AnalyticsEvent event) =>
///   _amp.logEvent(event.name, eventProperties: event.params);
///
/// @override
/// Future<void> setUserId(String? id) => _amp.setUserId(id);
///
/// @override
/// Future<void> setUserProperty({required String name, required Object? value}) =>
///   _amp.setUserProperties({name: value});
///
/// @override
/// Future<void> flush() => _amp.uploadEvents();
/// ```
class AmplitudeAnalyticsAdapter extends AnalyticsService {
  AmplitudeAnalyticsAdapter({required this.apiKey});

  /// Amplitude project API key. Pull from `AppConfig` per-environment.
  final String apiKey;

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    // TODO(template): Amplitude.getInstance().logEvent(event.name, eventProperties: event.params)
  }

  @override
  Future<void> setUserId(String? id) async {
    // TODO(template): Amplitude.getInstance().setUserId(id)
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required Object? value,
  }) async {
    // TODO(template): Amplitude.getInstance().setUserProperties({name: value})
  }

  @override
  Future<void> logError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) async {
    // TODO(template): Amplitude.getInstance().logEvent('non_fatal_error', eventProperties: {'message': '$error', ...context})
  }

  @override
  Future<void> flush() async {
    // TODO(template): Amplitude.getInstance().uploadEvents()
  }
}

// ─── Mixpanel ───────────────────────────────────────────────────────────

/// Adapter for [`mixpanel_flutter`](https://pub.dev/packages/mixpanel_flutter).
///
/// Required dependency:
/// ```yaml
/// mixpanel_flutter: ^x.y.z
/// ```
///
/// Mixpanel's API is async-init — instantiate the SDK once and store the
/// reference, then route each method through it:
///
/// ```dart
/// late final Mixpanel _mp;
/// Future<void> init() async {
///   _mp = await Mixpanel.init(token, trackAutomaticEvents: false);
/// }
///
/// @override
/// Future<void> logEvent(AnalyticsEvent event) async =>
///   _mp.track(event.name, properties: event.params);
///
/// @override
/// Future<void> setUserId(String? id) async {
///   if (id != null) _mp.identify(id); else _mp.reset();
/// }
///
/// @override
/// Future<void> setUserProperty({required String name, required Object? value}) async =>
///   _mp.getPeople().set(name, value);
///
/// @override
/// Future<void> flush() async => _mp.flush();
/// ```
class MixpanelAnalyticsAdapter extends AnalyticsService {
  MixpanelAnalyticsAdapter({required this.token});

  /// Mixpanel project token. Pull from `AppConfig` per-environment.
  final String token;

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    // TODO(template): _mp.track(event.name, properties: event.params)
  }

  @override
  Future<void> setUserId(String? id) async {
    // TODO(template): id != null ? _mp.identify(id) : _mp.reset()
  }

  @override
  Future<void> setUserProperty({
    required String name,
    required Object? value,
  }) async {
    // TODO(template): _mp.getPeople().set(name, value)
  }

  @override
  Future<void> logError(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?> context = const {},
  }) async {
    // TODO(template): _mp.track('non_fatal_error', properties: {'message': '$error', ...context})
  }

  @override
  Future<void> flush() async {
    // TODO(template): _mp.flush()
  }
}
