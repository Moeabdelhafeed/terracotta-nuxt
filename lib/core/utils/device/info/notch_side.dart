import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../device_services.dart';

/// Which physical edge of the screen the sensor housing is on.
enum NotchSide {
  /// No cutout, or the platform would not say. Both horizontal insets
  /// are then honoured as reported — never uncover a notch on a guess.
  unknown,

  /// Portrait: the housing is on an edge this app does not inset.
  none,
  left,
  right,
}

/// Where the notch actually is, for platforms that will not say plainly.
///
/// **UIKit MIRRORS the horizontal safe-area inset in landscape.**
/// `safeAreaInsets` on a notched iPhone comes back
/// `{top: 0, left: 62, bottom: 21, right: 62}` — the same number on both
/// sides, deliberately, so content stays symmetric and does not jump
/// when the device is turned over. Flutter forwards it verbatim, so
/// `MediaQuery.padding` cannot tell which edge the housing is on: it is
/// 62 either way.
///
/// That is Apple's default and it is defensible. It is also 124 points
/// of an 874-point screen given up for a housing that blocks one edge.
/// This asks iOS for the interface orientation and works the side out,
/// so the clear edge gets its points back.
///
/// **Android needs none of this.** `DisplayCutout.safeInsetLeft` /
/// `safeInsetRight` report the real side already, so the resolver
/// leaves asymmetric insets alone and this never runs there.
abstract final class DeviceNotch {
  static const _channel = MethodChannel('terracotta/notch_side');

  static final ValueNotifier<NotchSide> sideListenable = ValueNotifier(
    NotchSide.unknown,
  );

  static NotchSide get side => sideListenable.value;

  static _MetricsWatcher? _watcher;

  /// Reads the side once and keeps it current.
  ///
  /// The side changes every time the device turns over, so this also
  /// watches `didChangeMetrics` — the same callback a rotation drives.
  static Future<void> init() async {
    if (_watcher == null) {
      _watcher = _MetricsWatcher();
      WidgetsBinding.instance.addObserver(_watcher!);
    }
    await refresh();
  }

  /// Re-reads the side. Cheap, and a no-op off iOS.
  static Future<void> refresh() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      sideListenable.value = NotchSide.unknown;
      return;
    }
    try {
      final orientation = await _channel.invokeMethod<String>(
        'interfaceOrientation',
      );
      sideListenable.value = sideForInterfaceOrientation(orientation);
    } on PlatformException catch (e) {
      deviceWarn('notch.interfaceOrientation', e);
      sideListenable.value = NotchSide.unknown;
    } on MissingPluginException {
      sideListenable.value = NotchSide.unknown;
    }
  }

  /// `UIInterfaceOrientation` → the edge the housing sits on.
  ///
  /// The names are the opposite of what they sound like.
  /// `UIInterfaceOrientationLandscapeLeft` is defined as
  /// `UIDeviceOrientationLandscapeRight`, which Apple documents as "the
  /// device held upright with the home button on the LEFT side" — and
  /// the housing is at the end away from the home button, so it lands
  /// on the RIGHT.
  ///
  /// If a device ever shows the inset on the wrong edge, this pair is
  /// the one line to swap. `/device-showcase` prints both the raw
  /// orientation and the side derived from it for exactly that reason.
  @visibleForTesting
  static NotchSide sideForInterfaceOrientation(String? orientation) =>
      switch (orientation) {
        'landscapeLeft' => NotchSide.right,
        'landscapeRight' => NotchSide.left,
        'portrait' || 'portraitUpsideDown' => NotchSide.none,
        _ => NotchSide.unknown,
      };

  /// The horizontal insets a layout should actually honour.
  ///
  /// Only ever REMOVES a mirrored duplicate:
  ///
  /// - asymmetric already (Android, and iPad, and portrait) — untouched,
  ///   because the platform has told the truth;
  /// - equal and non-zero with a known side — the clear edge drops to
  ///   zero, and the housing's edge keeps every point;
  /// - equal and non-zero with an UNKNOWN side — untouched. A guess that
  ///   picks wrong puts a control under the housing, and giving back
  ///   sixty points is not worth that.
  ///
  /// The clear edge goes to zero rather than to some smaller clearance:
  /// a page's own padding is what holds content off the edge, and it is
  /// already there.
  static EdgeInsets resolve(EdgeInsets padding, [NotchSide? forSide]) {
    final s = forSide ?? side;
    if (padding.left != padding.right) return padding;
    if (padding.left == 0) return padding;
    return switch (s) {
      NotchSide.left => padding.copyWith(right: 0),
      NotchSide.right => padding.copyWith(left: 0),
      NotchSide.none || NotchSide.unknown => padding,
    };
  }

  /// Sets the side by hand, for tests.
  ///
  /// The real value comes from a platform channel, so under
  /// `flutter_test` it is always [NotchSide.unknown] and the resolver
  /// hands every inset straight back — which quietly makes any test of
  /// "what happens on a notched device" pass whatever the code does.
  @visibleForTesting
  static void debugSetSide(NotchSide value) => sideListenable.value = value;
}

class _MetricsWatcher with WidgetsBindingObserver {
  @override
  void didChangeMetrics() => DeviceNotch.refresh();
}
