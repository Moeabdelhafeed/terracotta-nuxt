import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';

import '../device_services.dart';

/// Screen brightness and system volume control.
class BrightnessVolumeUtils {
  BrightnessVolumeUtils._();

  static final ScreenBrightness _screenBrightness = ScreenBrightness();
  static final VolumeController _volumeController = VolumeController.instance;

  static DeviceCapability get _brightness =>
      DeviceServices.capability('brightness');
  static DeviceCapability get _volume => DeviceServices.capability('volume');

  // ─── Brightness ───────────────────────────────────────────

  /// Current system brightness (0.0 - 1.0).
  static Future<double> getBrightness() => _brightness.guard(
    () => _screenBrightness.system,
    fallback: DeviceServices.policy.brightness,
  );

  /// Override the app's brightness. Value is clamped to 0.0-1.0.
  static Future<void> setBrightness(double value) => deviceGuard(
    'brightness.set',
    () => _screenBrightness.setApplicationScreenBrightness(
      value.clamp(0.0, 1.0),
    ),
    fallback: null,
  );

  /// Reset brightness to the system default.
  static Future<void> resetBrightness() => deviceGuard(
    'brightness.reset',
    _screenBrightness.resetApplicationScreenBrightness,
    fallback: null,
  );

  // ─── Volume ───────────────────────────────────────────────

  /// Current media volume (0.0 - 1.0).
  static Future<double> getVolume() => _volume.guard(
    _volumeController.getVolume,
    fallback: DeviceServices.policy.volume,
  );

  /// Set media volume. Value is clamped to 0.0-1.0.
  static Future<void> setVolume(double value) => deviceGuard(
    'volume.set',
    () => _volumeController.setVolume(value.clamp(0.0, 1.0)),
    fallback: null,
  );

  /// Direct access to the underlying controller for advanced use (mute, streams).
  static VolumeController get volumeController => _volumeController;
}
