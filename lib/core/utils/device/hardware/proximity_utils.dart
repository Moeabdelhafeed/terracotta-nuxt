import 'package:proximity_sensor/proximity_sensor.dart';

import '../device_services.dart';

/// Proximity sensor — near-ear detection on phones.
///
/// For call-like UIs that dim the screen when the phone is held to an
/// ear. Emits `true` when something is near (typically under 5cm).
///
/// ```dart
/// final sub = ProximityUtils.onChange.listen(
///   (isNear) => isNear ? dimScreen() : restoreScreen(),
/// );
/// ```
class ProximityUtils {
  ProximityUtils._();

  static DeviceCapability get _cap => DeviceServices.capability('proximity');

  /// Proximity events — `true` when an object is near. Event-based:
  /// it emits on TRANSITIONS, not continuously.
  ///
  /// A device with no proximity sensor errors the stream rather than
  /// refusing the subscription, and an unhandled error on a broadcast
  /// stream takes the zone down. It is swallowed into the capability
  /// latch instead — a listener on a tablet simply hears nothing.
  static Stream<bool> get onChange => ProximitySensor.events
      .map((event) => event > 0)
      .handleError((Object e) => _cap.markUnavailable(e));

  /// Let the SYSTEM turn the screen off on proximity — Android only,
  /// for call apps. iOS does this itself during a call.
  static Future<bool> enableScreenOff() => deviceGuard(
    'proximity.enableScreenOff',
    () async {
      await ProximitySensor.setProximityScreenOff(true);
      return true;
    },
    fallback: false,
  );

  static Future<bool> disableScreenOff() => deviceGuard(
    'proximity.disableScreenOff',
    () async {
      await ProximitySensor.setProximityScreenOff(false);
      return true;
    },
    fallback: false,
  );
}
