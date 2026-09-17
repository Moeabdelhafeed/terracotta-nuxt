import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../feedback_style.dart';

/// App-wide defaults for `FeedbackScreen`.
@immutable
class GlobalFeedbackTheme extends ThemeExtension<GlobalFeedbackTheme> {
  const GlobalFeedbackTheme({this.style});

  final FeedbackStyle? style;

  static GlobalFeedbackTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalFeedbackTheme>();

  @override
  GlobalFeedbackTheme copyWith({FeedbackStyle? style}) =>
      GlobalFeedbackTheme(style: style ?? this.style);

  @override
  GlobalFeedbackTheme lerp(
    ThemeExtension<GlobalFeedbackTheme>? other,
    double t,
  ) {
    if (other is! GlobalFeedbackTheme) return this;
    return GlobalFeedbackTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Every field here is a measurement, so every field interpolates.
  static FeedbackStyle? _lerpStyle(
    FeedbackStyle? a,
    FeedbackStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    return FeedbackStyle(
      sectionGap: lerpDouble(a?.sectionGap, b?.sectionGap, t),
      labelGap: lerpDouble(a?.labelGap, b?.labelGap, t),
      contentPadding: EdgeInsets.lerp(a?.contentPadding, b?.contentPadding, t),
      thumbSize: lerpDouble(a?.thumbSize, b?.thumbSize, t),
      thumbRadius: lerpDouble(a?.thumbRadius, b?.thumbRadius, t),
      thumbSpacing: lerpDouble(a?.thumbSpacing, b?.thumbSpacing, t),
      removeScrimOpacity: lerpDouble(
        a?.removeScrimOpacity,
        b?.removeScrimOpacity,
        t,
      ),
      removeIconSize: lerpDouble(a?.removeIconSize, b?.removeIconSize, t),
    );
  }
}

extension FeedbackStyleResolve on FeedbackStyle {
  /// Stacks `caller > GlobalFeedbackTheme.style > FeedbackStyle.defaults`.
  ResolvedFeedbackStyle resolve(BuildContext context) {
    final merged = FeedbackStyle.defaults
        .mergedWith(GlobalFeedbackTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = FeedbackStyle.defaults;

    return ResolvedFeedbackStyle(
      sectionGap: merged.sectionGap ?? floor.sectionGap!,
      labelGap: merged.labelGap ?? floor.labelGap!,
      contentPadding: merged.contentPadding ?? floor.contentPadding!,
      thumbSize: merged.thumbSize ?? floor.thumbSize!,
      thumbRadius: merged.thumbRadius ?? floor.thumbRadius!,
      thumbSpacing: merged.thumbSpacing ?? floor.thumbSpacing!,
      removeScrimOpacity:
          merged.removeScrimOpacity ?? floor.removeScrimOpacity!,
      removeIconSize: merged.removeIconSize ?? floor.removeIconSize!,
    );
  }
}
