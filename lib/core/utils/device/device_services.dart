import 'package:flutter/foundation.dart';

import '../loggers/logger.dart';
import 'device_policy.dart';

/// The app-wide layer for the device services.
///
/// Every other gold module reads its middle layer from a
/// `ThemeExtension`, and none of this can: a device service is a
/// static call from bootstrap, from a cubit, from a background
/// isolate — places with no `BuildContext` and no `Theme`. So the
/// layer is a value set ONCE, at the start, and the resolve is a
/// getter rather than a `resolve(context)`.
///
/// ```dart
/// // in bootstrap(), before anything reads a device value
/// DeviceServices.configure(const DevicePolicy(valueTtl: Duration(minutes: 1)));
/// ```
abstract final class DeviceServices {
  static DevicePolicy _policy = const DevicePolicy();
  static ResolvedDevicePolicy _resolved = const DevicePolicy().resolve();

  /// The bag as it was set. [policy] is the resolved read.
  static DevicePolicy get rawPolicy => _policy;

  /// The policy every service reads, with the floor folded in.
  static ResolvedDevicePolicy get policy => _resolved;

  /// Set the app-wide policy. Call from `bootstrap()`.
  ///
  /// It REPLACES rather than merging, so a second call is the whole
  /// answer and not an accumulation — the same contract as assigning
  /// the theme.
  static void configure(DevicePolicy policy) {
    _policy = policy;
    _resolved = policy.resolve();
    _capabilities.forEach((_, c) => c.reset());
  }

  /// Undo everything a test did — the policy AND every latched
  /// capability. Latches are process-global by design (a torch that is
  /// absent stays absent), which is exactly what leaks between tests.
  @visibleForTesting
  static void debugReset() => configure(const DevicePolicy());

  // ─── Capability latching ─────────────────────────────────

  static final Map<String, DeviceCapability> _capabilities = {};

  /// The named capability, created on first use.
  static DeviceCapability capability(String name) =>
      _capabilities.putIfAbsent(name, () => DeviceCapability._(name));
}

/// One hardware capability that may simply not be there.
///
/// A simulator has no battery API and no torch. The platform answers
/// that with a thrown `PlatformException` — every time it is asked,
/// on every rebuild, for an answer that cannot change without
/// relaunching the app. This remembers.
class DeviceCapability {
  DeviceCapability._(this.name);

  /// Used in the log line: `[Device] torch unavailable`.
  final String name;

  bool _known = true;
  bool _logged = false;

  /// False once a probe has failed and the policy latches.
  bool get isKnownAvailable => _known;

  /// Run [probe], and remember a failure.
  ///
  /// [fallback] is the answer when the capability is known absent or
  /// the probe throws — never an exception out of a device service,
  /// which is a `try/catch` at every one of a hundred call sites.
  Future<T> guard<T>(Future<T> Function() probe, {required T fallback}) async {
    if (!_known) return fallback;
    try {
      return await probe();
    } catch (e) {
      markUnavailable(e);
      return fallback;
    }
  }

  /// Record that the capability is not there.
  ///
  /// Logs ONCE, at debug level, and only when the policy asks for it.
  /// This is not a warning: the simulator having no flashlight is not
  /// news, and it used to arrive as an INFO line — through
  /// `debugPrint`, which the bootstrap zone reroutes — on every visit
  /// to a page that asked.
  void markUnavailable(Object? error) {
    if (DeviceServices.policy.latchUnavailable) _known = false;
    if (_logged || !DeviceServices.policy.logUnavailable) return;
    _logged = true;
    Logger.m.d('[Device] $name unavailable${error == null ? '' : ': $error'}');
  }

  /// Forget the latch — after a permission grant, or between tests.
  void reset() {
    _known = true;
    _logged = false;
  }
}

/// An ACTION that failed, as opposed to a capability that is absent.
///
/// Turning the torch on and having it throw is worth a warning: the
/// caller asked for something the device claimed it could do. Goes to
/// `Logger.m.w` with the app's `[Tag]` convention, where all 55 of
/// these were `debugPrint` — untagged, unlevelled, and rerouted to
/// INFO by the bootstrap zone, so a failure read like a status
/// update.
void deviceWarn(String operation, Object error, [StackTrace? stack]) =>
    Logger.m.w('[Device] $operation failed: $error', stackTrace: stack);

/// Run [action], warn on failure, and answer [fallback].
Future<T> deviceGuard<T>(
  String operation,
  Future<T> Function() action, {
  required T fallback,
}) async {
  try {
    return await action();
  } catch (e, st) {
    deviceWarn(operation, e, st);
    return fallback;
  }
}
