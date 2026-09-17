import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../image_models.dart';

/// App-wide defaults for `GlobalImage`.
///
/// The rebrand hook: set the corner, the frame and the failed-to-load
/// plate of every picture in the app once here.
@immutable
class GlobalImageTheme extends ThemeExtension<GlobalImageTheme> {
  const GlobalImageTheme({this.style});

  final ImageStyle? style;

  static GlobalImageTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalImageTheme>();

  @override
  GlobalImageTheme copyWith({ImageStyle? style}) =>
      GlobalImageTheme(style: style ?? this.style);

  @override
  GlobalImageTheme lerp(ThemeExtension<GlobalImageTheme>? other, double t) {
    if (other is! GlobalImageTheme) return this;
    return GlobalImageTheme(style: _lerpStyle(style, other.style, t));
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

  /// Continuous fields interpolate; discrete ones snap at the midpoint.
  static ImageStyle? _lerpStyle(ImageStyle? a, ImageStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return ImageStyle(
      padding: EdgeInsets.lerp(a?.padding, b?.padding, t),
      borderRadius: BorderRadiusGeometry.lerp(
        a?.borderRadius,
        b?.borderRadius,
        t,
      ),
      border: BoxBorder.lerp(a?.border, b?.border, t),
      borderColor: Color.lerp(a?.borderColor, b?.borderColor, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      gradientBorderWidth: lerpDouble(
        a?.gradientBorderWidth,
        b?.gradientBorderWidth,
        t,
      ),
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      color: Color.lerp(a?.color, b?.color, t),
      boxShadow: BoxShadow.lerpList(a?.boxShadow, b?.boxShadow, t),
      innerShadow: BoxShadow.lerp(a?.innerShadow, b?.innerShadow, t),
      opacity: lerpDouble(a?.opacity, b?.opacity, t),
      errorIconColor: Color.lerp(a?.errorIconColor, b?.errorIconColor, t),
      errorPlateColor: Color.lerp(a?.errorPlateColor, b?.errorPlateColor, t),
      errorIconSize: lerpDouble(a?.errorIconSize, b?.errorIconSize, t),
      progressColor: Color.lerp(a?.progressColor, b?.progressColor, t),
      fadeDuration: _lerpDuration(a?.fadeDuration, b?.fadeDuration, t),
      alignment: AlignmentGeometry.lerp(a?.alignment, b?.alignment, t),
      // A fit, a blend and a gradient do not interpolate between two
      // different specs — snap.
      fit: pick?.fit,
      overlayBlendMode: pick?.overlayBlendMode,
      gradient: pick?.gradient,
      gradientBorder: pick?.gradientBorder,
      grayscale: pick?.grayscale,
      filterQuality: pick?.filterQuality,
      repeat: pick?.repeat,
      blurHashSheen: pick?.blurHashSheen,
      placeholderDelay: _lerpDuration(
        a?.placeholderDelay,
        b?.placeholderDelay,
        t,
      ),
      placeholderMinDuration: _lerpDuration(
        a?.placeholderMinDuration,
        b?.placeholderMinDuration,
        t,
      ),
    );
  }
}

extension ImageStyleResolve on ImageStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from
  /// `context.<group>Colors`.
  ///
  /// The corner is resolved against the AMBIENT direction here, once, so
  /// the frame, the clip and the inner shadow cannot disagree about
  /// which corners are which in Arabic. It used to be resolved against a
  /// hard-coded LTR.
  ResolvedImageStyle resolve(BuildContext context) {
    final merged = ImageStyle.defaults
        .mergedWith(GlobalImageTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = ImageStyle.defaults;

    final bg = context.backgroundColors;
    final text = context.textColors;

    return ResolvedImageStyle(
      fit: merged.fit ?? floor.fit!,
      borderRadius: (merged.borderRadius ?? floor.borderRadius!).resolve(
        Directionality.of(context),
      ),
      padding: merged.padding,
      // A caller's whole border wins; otherwise one is composed, so the
      // colour can come from the palette.
      border:
          merged.border ??
          (merged.borderColor != null || merged.borderWidth != null
              ? Border.all(
                  color: merged.borderColor ?? bg.outline,
                  width: merged.borderWidth ?? 1,
                )
              : null),
      gradientBorder: merged.gradientBorder,
      gradientBorderWidth:
          merged.gradientBorderWidth ?? floor.gradientBorderWidth!,
      backgroundColor: merged.backgroundColor,
      color: merged.color,
      overlayBlendMode: merged.overlayBlendMode ?? floor.overlayBlendMode!,
      gradient: merged.gradient,
      boxShadow: merged.boxShadow,
      innerShadow: merged.innerShadow,
      opacity: merged.opacity ?? floor.opacity!,
      grayscale: merged.grayscale ?? floor.grayscale!,
      // `Colors.grey.shade100` and `Colors.grey` before — the same two
      // greys on a white page and a black one. A picture that failed to
      // arrive is a GAP, not a warning, so it takes the quiet outline
      // rather than a status colour.
      errorIconColor: merged.errorIconColor ?? bg.outline,
      errorPlateColor:
          merged.errorPlateColor ??
          bg.container.withValues(alpha: ImageDefaults.errorPlateOpacity),
      errorIconSize: merged.errorIconSize ?? floor.errorIconSize!,
      progressColor: merged.progressColor ?? context.primaryColors.primary,
      filterQuality: merged.filterQuality ?? floor.filterQuality!,
      alignment: merged.alignment ?? floor.alignment!,
      repeat: merged.repeat ?? floor.repeat!,
      // A sweep repeats forever, which is what `disableAnimations`
      // exists to stop. The blur stays; only the motion goes.
      placeholderDelay: merged.placeholderDelay ?? floor.placeholderDelay!,
      placeholderMinDuration:
          merged.placeholderMinDuration ?? floor.placeholderMinDuration!,
      blurHashSheen:
          !MediaQuery.disableAnimationsOf(context) &&
          (merged.blurHashSheen ?? floor.blurHashSheen!),
      // Motion is decoration; the picture is the point.
      fadeDuration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : merged.fadeDuration ?? floor.fadeDuration!,
      // Fixed against EACH OTHER, not against the page: this pill sits
      // on a scrim over arbitrary imagery, where a role colour cannot be
      // relied on to stay readable.
      retryScrimColor: context.overlayColors.scrim.withValues(
        alpha: ImageDefaults.retryScrimOpacity,
      ),
      retryLabelColor: text.onPrimary,
    );
  }
}
