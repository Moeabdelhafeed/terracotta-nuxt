// ignore: unnecessary_import
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_corner_radius/screen_corner_radius.dart';

import '../device_services.dart';

/// Provides the device's physical screen corner radius.
///
/// Call [init] once at app startup (e.g. in `main.dart`). All getters are
/// O(1) after init — the `BorderRadius` objects are built once and cached.
class DeviceRadius {
  DeviceRadius._();

  static double _topLeft = 0;
  static double _topRight = 0;
  static double _bottomLeft = 0;
  static double _bottomRight = 0;
  static bool _initialized = false;

  // +1px on each padded corner — avoids sub-pixel gaps when content is
  // aligned flush with the device edge.
  static const double _kPad = 1.0;

  // Memoized BorderRadius instances. Reset to zero until [init] runs.
  static BorderRadius _borderRadius = BorderRadius.zero;
  static BorderRadius _topBorderRadius = BorderRadius.zero;
  static BorderRadius _bottomBorderRadius = BorderRadius.zero;
  static BorderRadius _uniform = BorderRadius.zero;
  static BorderRadius _borderRadiusPadded = BorderRadius.zero;
  static BorderRadius _topBorderRadiusPadded = BorderRadius.zero;
  static BorderRadius _bottomBorderRadiusPadded = BorderRadius.zero;
  static BorderRadius _uniformPadded = BorderRadius.zero;

  /// Reads the device's physical corner radius. Safe to call before
  /// `runApp`; tolerates platform errors by leaving all corners at zero.
  /// Web has no corner-radius API — skip the plugin call entirely so the
  /// `MissingPluginException` doesn't surface in logs.
  static Future<void> init() async {
    if (kIsWeb) {
      _rebuildCached();
      _initialized = true;
      return;
    }
    try {
      final radius = await ScreenCornerRadius.get();
      if (radius != null) {
        _topLeft = radius.topLeft;
        _topRight = radius.topRight;
        _bottomLeft = radius.bottomLeft;
        _bottomRight = radius.bottomRight;
      }
    } catch (e) {
      deviceWarn('screenRadius.read', e);
    } finally {
      _rebuildCached();
      _initialized = true;
    }
  }

  /// Whether the radius has been initialized.
  static bool get isInitialized => _initialized;

  /// Sets the corners by hand, for tests.
  ///
  /// The real value comes from a platform channel, so under
  /// `flutter_test` every corner is zero and `hasRoundedCorners` is
  /// false — which quietly makes any test of "what happens on a rounded
  /// device" pass whatever the code does. Pass null to put it back.
  @visibleForTesting
  static void debugSetCorners({
    double topLeft = 0,
    double topRight = 0,
    double bottomLeft = 0,
    double bottomRight = 0,
  }) {
    _topLeft = topLeft;
    _topRight = topRight;
    _bottomLeft = bottomLeft;
    _bottomRight = bottomRight;
    _rebuildCached();
  }

  /// Top-left corner radius.
  static double get topLeft => _topLeft;

  /// Top-right corner radius.
  static double get topRight => _topRight;

  /// Bottom-left corner radius.
  static double get bottomLeft => _bottomLeft;

  /// Bottom-right corner radius.
  static double get bottomRight => _bottomRight;

  /// Mean radius across all corners.
  static double get average =>
      (_topLeft + _topRight + _bottomLeft + _bottomRight) / 4;

  /// True if the device has any rounded corners at all.
  static bool get hasRoundedCorners => average > 0;

  /// Full [BorderRadius] matching every device corner.
  static BorderRadius get borderRadius => _borderRadius;

  /// Top corners only — bottom sheets, top nav bars, headers.
  static BorderRadius get topBorderRadius => _topBorderRadius;

  /// Bottom corners only — top sheets, bottom nav bars, footers.
  static BorderRadius get bottomBorderRadius => _bottomBorderRadius;

  /// Uniform radius using the [average] value. Approximate — if the
  /// device has different corner radii (e.g. phones with square bottom
  /// corners) this won't match any individual corner exactly. Prefer
  /// [borderRadius] unless uniformity is specifically required.
  static BorderRadius get uniform => _uniform;

  // ─── Padded variants (+1px to avoid sub-pixel gaps) ─────────

  /// Full [BorderRadius] with +1px padding on every corner.
  static BorderRadius get borderRadiusPadded => _borderRadiusPadded;

  /// Top corners only, with +1px padding.
  static BorderRadius get topBorderRadiusPadded => _topBorderRadiusPadded;

  /// Bottom corners only, with +1px padding.
  static BorderRadius get bottomBorderRadiusPadded => _bottomBorderRadiusPadded;

  /// Uniform padded radius using [average] + 1px.
  static BorderRadius get uniformPadded => _uniformPadded;

  static void _rebuildCached() {
    _borderRadius = BorderRadius.only(
      topLeft: Radius.circular(_topLeft),
      topRight: Radius.circular(_topRight),
      bottomLeft: Radius.circular(_bottomLeft),
      bottomRight: Radius.circular(_bottomRight),
    );
    _topBorderRadius = BorderRadius.only(
      topLeft: Radius.circular(_topLeft),
      topRight: Radius.circular(_topRight),
    );
    _bottomBorderRadius = BorderRadius.only(
      bottomLeft: Radius.circular(_bottomLeft),
      bottomRight: Radius.circular(_bottomRight),
    );
    _uniform = BorderRadius.circular(average);
    _borderRadiusPadded = BorderRadius.only(
      topLeft: Radius.circular(_topLeft + _kPad),
      topRight: Radius.circular(_topRight + _kPad),
      bottomLeft: Radius.circular(_bottomLeft + _kPad),
      bottomRight: Radius.circular(_bottomRight + _kPad),
    );
    _topBorderRadiusPadded = BorderRadius.only(
      topLeft: Radius.circular(_topLeft + _kPad),
      topRight: Radius.circular(_topRight + _kPad),
    );
    _bottomBorderRadiusPadded = BorderRadius.only(
      bottomLeft: Radius.circular(_bottomLeft + _kPad),
      bottomRight: Radius.circular(_bottomRight + _kPad),
    );
    _uniformPadded = BorderRadius.circular(average + _kPad);
  }
}
