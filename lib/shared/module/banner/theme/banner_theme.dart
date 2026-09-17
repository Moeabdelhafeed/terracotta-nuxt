import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../banner_models.dart';

/// App-wide defaults for `GlobalBanner`.
///
/// The rebrand hook: set the corner, the inset and the motion of every
/// notice in the app once here.
@immutable
class GlobalBannerTheme extends ThemeExtension<GlobalBannerTheme> {
  const GlobalBannerTheme({this.style});

  final BannerStyle? style;

  static GlobalBannerTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalBannerTheme>();

  @override
  GlobalBannerTheme copyWith({BannerStyle? style}) =>
      GlobalBannerTheme(style: style ?? this.style);

  @override
  GlobalBannerTheme lerp(ThemeExtension<GlobalBannerTheme>? other, double t) {
    if (other is! GlobalBannerTheme) return this;
    return GlobalBannerTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint.
  static BannerStyle? _lerpStyle(BannerStyle? a, BannerStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return BannerStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      foregroundColor: Color.lerp(a?.foregroundColor, b?.foregroundColor, t),
      borderColor: Color.lerp(a?.borderColor, b?.borderColor, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      shadow: BoxShadow.lerpList(a?.shadow, b?.shadow, t),
      padding: EdgeInsets.lerp(a?.padding, b?.padding, t),
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
      iconSpacing: lerpDouble(a?.iconSpacing, b?.iconSpacing, t),
      progressHeight: lerpDouble(a?.progressHeight, b?.progressHeight, t),
      titleStyle: TextStyle.lerp(a?.titleStyle, b?.titleStyle, t),
      messageStyle: TextStyle.lerp(a?.messageStyle, b?.messageStyle, t),
      actionStyle: TextStyle.lerp(a?.actionStyle, b?.actionStyle, t),
      animationDuration: _lerpDuration(
        a?.animationDuration,
        b?.animationDuration,
        t,
      ),
      // Gradients and motion kinds do not interpolate between two
      // different specs — snap.
      backgroundGradient: pick?.backgroundGradient,
      borderGradient: pick?.borderGradient,
      animation: pick?.animation,
      animationCurve: pick?.animationCurve,
      marqueeTitle: pick?.marqueeTitle,
      autoDismissProgress: pick?.autoDismissProgress,
    );
  }

  /// Null-tolerant duration lerp — `lerpDuration` requires both sides.
  static Duration? _lerpDuration(Duration? a, Duration? b, double t) {
    if (a == null && b == null) return null;
    if (a == null || b == null) return t < 0.5 ? a : b;
    return Duration(
      microseconds:
          (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
              .round(),
    );
  }
}

extension BannerStyleResolve on BannerStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from
  /// `context.statusColors` for the [type].
  ///
  /// The type is an argument because the bag cannot know it and three
  /// colours depend on it. That is also why `defaults` carries none: a
  /// compile-time colour would have to pick one type and be wrong for
  /// the other four.
  ///
  /// [disableAnimations] resolves the motion to `none` rather than
  /// shortening it — an entrance is decoration; the notice is the
  /// point.
  ResolvedBannerStyle resolve(
    BuildContext context, {
    required BannerType type,
    bool disableAnimations = false,
  }) {
    final merged = BannerStyle.defaults
        .mergedWith(GlobalBannerTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = BannerStyle.defaults;

    final status = context.statusColors;
    final text = context.textColors;

    // `Color(0xFF4CAF50)`, `Color(0xFFFF9800)`, `Color(0xFF2E7D32)` and
    // `Color(0xFFE65100)` were written here — Material's own green and
    // orange, fixed, so a success banner stayed Material green on a
    // rebranded palette and in dark mode both. The other two came from
    // `Theme.of(context).colorScheme`, which is at least themed but is
    // not the app's status set.
    final accent = switch (type) {
      BannerType.info => status.info,
      BannerType.success => status.success,
      BannerType.warning => status.warning,
      BannerType.error => status.error,
      BannerType.custom => text.primary,
    };

    final foreground = merged.foregroundColor ?? accent;

    return ResolvedBannerStyle(
      backgroundColor:
          merged.backgroundColor ??
          (type == BannerType.custom
              ? context.backgroundColors.container
              : accent.withValues(alpha: BannerDefaults.surfaceOpacity)),
      backgroundGradient: merged.backgroundGradient,
      foregroundColor: foreground,
      borderColor:
          merged.borderColor ??
          foreground.withValues(alpha: BannerDefaults.borderOpacity),
      borderGradient: merged.borderGradient,
      borderWidth: merged.borderWidth ?? floor.borderWidth!,
      borderRadius: merged.borderRadius ?? floor.borderRadius!,
      shadow: merged.shadow,
      padding: merged.padding ?? floor.padding!,
      iconSize: merged.iconSize ?? floor.iconSize!,
      iconSpacing: merged.iconSpacing ?? floor.iconSpacing!,
      titleStyle:
          merged.titleStyle ??
          (context.textTheme.titleSmall ?? const TextStyle()).copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
      messageStyle:
          merged.messageStyle ??
          (context.textTheme.bodySmall ?? const TextStyle()).copyWith(
            color: foreground.withValues(
              alpha: BannerDefaults.messageOpacity,
            ),
          ),
      actionStyle:
          merged.actionStyle ??
          (context.textTheme.labelLarge ?? const TextStyle()).copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
            fontSize: BannerDefaults.actionFontSize,
          ),
      animation: disableAnimations
          ? BannerAnimation.none
          : merged.animation ?? floor.animation!,
      animationDuration: merged.animationDuration ?? floor.animationDuration!,
      animationCurve: merged.animationCurve ?? floor.animationCurve!,
      marqueeTitle: merged.marqueeTitle ?? floor.marqueeTitle!,
      autoDismissProgress:
          merged.autoDismissProgress ?? floor.autoDismissProgress!,
      progressHeight: merged.progressHeight ?? floor.progressHeight!,
    );
  }
}
