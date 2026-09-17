import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../share_models.dart';

/// App-wide defaults for [GlobalShareButton].
@immutable
class GlobalShareTheme extends ThemeExtension<GlobalShareTheme> {
  const GlobalShareTheme({this.style});

  final ShareButtonStyle? style;

  static GlobalShareTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalShareTheme>();

  @override
  GlobalShareTheme copyWith({ShareButtonStyle? style}) =>
      GlobalShareTheme(style: style ?? this.style);

  @override
  GlobalShareTheme lerp(ThemeExtension<GlobalShareTheme>? other, double t) {
    if (other is! GlobalShareTheme) return this;
    return GlobalShareTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Sizes and colours interpolate; the GLYPH snaps at the halfway
  /// mark, because half of one icon and half of another is neither.
  static ShareButtonStyle? _lerpStyle(
    ShareButtonStyle? a,
    ShareButtonStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return ShareButtonStyle(
      icon: pick?.icon,
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
      foregroundColor: Color.lerp(a?.foregroundColor, b?.foregroundColor, t),
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      enableHaptic: pick?.enableHaptic,
      fabElevation: lerpDouble(a?.fabElevation, b?.fabElevation, t),
    );
  }
}

extension ShareButtonStyleResolve on ShareButtonStyle {
  /// Stacks `caller > GlobalShareTheme.style > ShareButtonStyle.defaults`.
  ResolvedShareButtonStyle resolve(BuildContext context) {
    final merged = ShareButtonStyle.defaults
        .mergedWith(GlobalShareTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = ShareButtonStyle.defaults;

    return ResolvedShareButtonStyle(
      icon: merged.icon ?? floor.icon!,
      iconSize: merged.iconSize ?? floor.iconSize!,
      // Left UNANSWERED when nobody set it — each variant picks its
      // own fallback, because a FAB's is not an icon button's.
      foregroundColor: merged.foregroundColor,
      backgroundColor: merged.backgroundColor,
      enableHaptic: merged.enableHaptic ?? floor.enableHaptic!,
      fabElevation: merged.fabElevation ?? floor.fabElevation!,
    );
  }
}
