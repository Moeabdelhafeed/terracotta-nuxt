import 'package:flutter/widgets.dart' show Orientation;
import 'package:sensors_plus/sensors_plus.dart';

/// Motion sensor streams (accelerometer, gyroscope, magnetometer).
///
/// All streams are broadcast, so several listeners can share one
/// sensor. They emit at the platform's default rate, typically
/// 50-200Hz.
///
/// ```dart
/// final sub = SensorUtils.onAccelerometer.listen((e) => nudge(e.x, e.y));
/// ```
class SensorUtils {
  SensorUtils._();

  /// Acceleration INCLUDING gravity, in m/s². At rest, y ≈ 9.8.
  static Stream<AccelerometerEvent> get onAccelerometer =>
      accelerometerEventStream();

  /// Acceleration with gravity removed.
  static Stream<UserAccelerometerEvent> get onUserAccelerometer =>
      userAccelerometerEventStream();

  /// Rotation rate around each axis, in rad/s.
  static Stream<GyroscopeEvent> get onGyroscope => gyroscopeEventStream();

  /// Magnetic field around the device, in μT.
  static Stream<MagnetometerEvent> get onMagnetometer =>
      magnetometerEventStream();

  /// Which way up the device is, from the accelerometer — for the
  /// places `MediaQuery` cannot reach, such as a background task.
  /// **In a widget, use `MediaQuery.orientationOf(context)`.**
  ///
  /// It returns the framework's [Orientation] rather than the strings
  /// `'portrait'` / `'landscape'` it used to: a caller comparing
  /// against a misspelled literal compiles and is simply always
  /// wrong.
  static Future<Orientation> getOrientationFromSensor() async {
    final event = await accelerometerEventStream().first;
    return event.y.abs() > event.x.abs()
        ? Orientation.portrait
        : Orientation.landscape;
  }
}
