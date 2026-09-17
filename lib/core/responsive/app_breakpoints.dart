import 'package:flutter/widgets.dart';

import '../utils/device/device_form_factor.dart';
import 'window_size_class.dart';

/// Snapshot of every layout-relevant value, read once at the root and
/// fanned out via an [InheritedWidget]. Leaves call [AppBreakpoints.of]
/// (or `context.breakpoints`) instead of [MediaQuery.of] so they only
/// rebuild on bucket changes — not on every keyboard open / resize tick.
@immutable
class AppBreakpoints {
  const AppBreakpoints({
    required this.windowSize,
    required this.windowHeight,
    required this.deviceType,
    required this.size,
    required this.orientation,
    required this.safeArea,
    required this.viewInsets,
    required this.textScaler,
    required this.pixelRatio,
    required this.platformBrightness,
  });

  /// Material 3 layout-decision bucket (compact / medium / expanded / …).
  final WindowSizeClass windowSize;

  /// Material 3 height bucket. Use for short-window adaptations
  /// (landscape phones, split-screen).
  final WindowHeightClass windowHeight;

  /// Pixel-named bucket from the legacy enum. Kept for telemetry /
  /// design-time tooling — layout code should use [windowSize] instead.
  final DeviceFormFactor deviceType;

  /// Logical pixel size of the viewport.
  final Size size;

  /// Computed from [size] (not [MediaQuery.orientation]) so it matches
  /// the values [windowSize] saw — avoids edge cases where MQ reports
  /// stale orientation during rotation.
  final Orientation orientation;

  /// Status bar / notch / nav bar insets.
  final EdgeInsets safeArea;

  /// Keyboard / IME insets.
  final EdgeInsets viewInsets;

  /// User-controlled text scaling factor.
  final TextScaler textScaler;

  /// Device pixel ratio.
  final double pixelRatio;

  /// System light/dark setting (independent of app `themeMode`).
  final Brightness platformBrightness;

  bool get isLandscape => orientation == Orientation.landscape;
  bool get isPortrait => orientation == Orientation.portrait;

  /// Read the nearest [AppBreakpoints] above [context]. Throws when
  /// no [BreakpointsProvider] is present — wire it at the app root.
  static AppBreakpoints of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<BreakpointsScope>();
    assert(
      scope != null,
      'No BreakpointsProvider found above this context. '
      'Wrap MaterialApp.builder child with BreakpointsProvider.',
    );
    return scope!.breakpoints;
  }

  /// Like [of] but returns `null` instead of throwing.
  static AppBreakpoints? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<BreakpointsScope>()
        ?.breakpoints;
  }

  AppBreakpoints copyWith({
    WindowSizeClass? windowSize,
    WindowHeightClass? windowHeight,
    DeviceFormFactor? deviceType,
    Size? size,
    Orientation? orientation,
    EdgeInsets? safeArea,
    EdgeInsets? viewInsets,
    TextScaler? textScaler,
    double? pixelRatio,
    Brightness? platformBrightness,
  }) {
    return AppBreakpoints(
      windowSize: windowSize ?? this.windowSize,
      windowHeight: windowHeight ?? this.windowHeight,
      deviceType: deviceType ?? this.deviceType,
      size: size ?? this.size,
      orientation: orientation ?? this.orientation,
      safeArea: safeArea ?? this.safeArea,
      viewInsets: viewInsets ?? this.viewInsets,
      textScaler: textScaler ?? this.textScaler,
      pixelRatio: pixelRatio ?? this.pixelRatio,
      platformBrightness: platformBrightness ?? this.platformBrightness,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppBreakpoints &&
        other.windowSize == windowSize &&
        other.windowHeight == windowHeight &&
        other.deviceType == deviceType &&
        other.size == size &&
        other.orientation == orientation &&
        other.safeArea == safeArea &&
        other.viewInsets == viewInsets &&
        other.textScaler == textScaler &&
        other.pixelRatio == pixelRatio &&
        other.platformBrightness == platformBrightness;
  }

  @override
  int get hashCode => Object.hash(
    windowSize,
    windowHeight,
    deviceType,
    size,
    orientation,
    safeArea,
    viewInsets,
    textScaler,
    pixelRatio,
    platformBrightness,
  );

  @override
  String toString() =>
      'AppBreakpoints(${windowSize.label} / ${windowHeight.label} '
      '${size.width.toStringAsFixed(0)}×${size.height.toStringAsFixed(0)} '
      '${isLandscape ? "landscape" : "portrait"})';
}

/// Internal scope widget. Public so `dependOnInheritedWidgetOfExactType`
/// works from outside the file, but consumers should read via
/// [AppBreakpoints.of] / `context.breakpoints` instead of touching this
/// directly.
class BreakpointsScope extends InheritedWidget {
  const BreakpointsScope({
    super.key,
    required this.breakpoints,
    required super.child,
  });

  final AppBreakpoints breakpoints;

  @override
  bool updateShouldNotify(BreakpointsScope old) =>
      breakpoints != old.breakpoints;
}
