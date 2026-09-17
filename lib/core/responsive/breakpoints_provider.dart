import 'package:flutter/widgets.dart';

import '../utils/device/device_form_factor.dart';
import 'app_breakpoints.dart';
import 'window_size_class.dart';

/// Reads [MediaQuery] once, computes an [AppBreakpoints] snapshot, and
/// exposes it via [BreakpointsScope] so descendants can access layout
/// info without subscribing to the full MediaQuery (which rebuilds on
/// every keyboard tick / resize frame).
///
/// Place inside `MaterialApp.builder` so a MediaQuery is in scope:
///
///     builder: (context, child) => BreakpointsProvider(child: child!),
///
/// To override breakpoints inside a fixed-size container (e.g. preview
/// grid, design-time tooling) wrap that subtree in another
/// [BreakpointsProvider] with [overrideSize] set.
class BreakpointsProvider extends StatelessWidget {
  const BreakpointsProvider({
    super.key,
    required this.child,
    this.overrideSize,
  });

  final Widget child;

  /// When non-null, breakpoints are computed from this size instead of
  /// the ambient [MediaQuery]. Useful for nested previews and tests.
  final Size? overrideSize;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = overrideSize ?? mq.size;
    final orientation = size.width >= size.height
        ? Orientation.landscape
        : Orientation.portrait;

    final breakpoints = AppBreakpoints(
      windowSize: WindowSizeClass.fromWidth(size.width),
      windowHeight: WindowHeightClass.fromHeight(size.height),
      deviceType: DeviceFormFactor.fromWidth(size.width),
      size: size,
      orientation: orientation,
      safeArea: mq.padding,
      viewInsets: mq.viewInsets,
      textScaler: mq.textScaler,
      pixelRatio: mq.devicePixelRatio,
      platformBrightness: mq.platformBrightness,
    );

    return BreakpointsScope(
      breakpoints: breakpoints,
      child: child,
    );
  }
}
