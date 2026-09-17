import 'package:torch_light/torch_light.dart';

import '../device_services.dart';

/// Camera flashlight (torch).
///
/// Requires camera permission on Android — request before using. On
/// iOS none is needed, but the camera must not be held by another app.
class TorchUtils {
  TorchUtils._();

  static DeviceCapability get _cap => DeviceServices.capability('torch');

  /// True if the device has a flashlight.
  ///
  /// The answer is CACHED, where it used to be a platform call every
  /// time. A device does not grow a torch while the app is running,
  /// and on a simulator the probe throws — which is how a page that
  /// merely asked produced a log line on every single visit.
  static Future<bool> isAvailable() async {
    if (!_cap.isKnownAvailable) return false;
    final available = await _cap.guard(
      TorchLight.isTorchAvailable,
      fallback: false,
    );
    // A device that ANSWERS "no torch" is as settled as one that
    // throws — latch it the same way so the next caller is free.
    if (!available) _cap.markUnavailable(null);
    return available;
  }

  /// Turn the torch on. False if it could not be done.
  static Future<bool> turnOn() => deviceGuard(
    'torch.turnOn',
    () async {
      await TorchLight.enableTorch();
      return true;
    },
    fallback: false,
  );

  static Future<bool> turnOff() => deviceGuard(
    'torch.turnOff',
    () async {
      await TorchLight.disableTorch();
      return true;
    },
    fallback: false,
  );
}
