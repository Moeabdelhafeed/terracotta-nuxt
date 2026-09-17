import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';
import 'window_size_class.dart';

/// Quick access to the [AppBreakpoints] snapshot from any context.
extension BreakpointsContext on BuildContext {
  /// Throws if no [BreakpointsProvider] above. Equivalent to
  /// `AppBreakpoints.of(this)`.
  AppBreakpoints get breakpoints => AppBreakpoints.of(this);

  /// Null-safe variant.
  AppBreakpoints? get maybeBreakpoints => AppBreakpoints.maybeOf(this);

  /// Shortcut for `breakpoints.windowSize`.
  WindowSizeClass get windowSize => breakpoints.windowSize;

  /// Shortcut for `breakpoints.windowHeight`.
  WindowHeightClass get windowHeight => breakpoints.windowHeight;

  bool get isCompact => windowSize.isCompact;
  bool get isMediumUp => windowSize.isMediumUp;
  bool get isExpandedUp => windowSize.isExpandedUp;
  bool get isLargeUp => windowSize.isLargeUp;
  bool get isExtraLarge => windowSize.isExtraLarge;
}
