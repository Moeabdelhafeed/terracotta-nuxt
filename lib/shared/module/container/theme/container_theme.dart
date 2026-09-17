import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../container_models.dart';

/// App-wide defaults for `GlobalContainer`.
///
/// The rebrand hook: set the corner, the fill, the shadow and the border
/// of every styled box in the app once, here.
@immutable
class GlobalContainerTheme extends ThemeExtension<GlobalContainerTheme> {
  const GlobalContainerTheme({this.style});

  final ContainerStyle? style;

  static GlobalContainerTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalContainerTheme>();

  @override
  GlobalContainerTheme copyWith({ContainerStyle? style}) =>
      GlobalContainerTheme(style: style ?? this.style);

  @override
  GlobalContainerTheme lerp(
    ThemeExtension<GlobalContainerTheme>? other,
    double t,
  ) {
    if (other is! GlobalContainerTheme) return this;
    return GlobalContainerTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint.
  ///
  /// A container half-clipped and half-not is not a clip, and a border
  /// half-dashed and half-waved is not a line — those are picked, not
  /// blended.
  static ContainerStyle? _lerpStyle(
    ContainerStyle? a,
    ContainerStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return ContainerStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      backgroundGradient: Gradient.lerp(
        a?.backgroundGradient,
        b?.backgroundGradient,
        t,
      ),
      backgroundImageOpacity: lerpDouble(
        a?.backgroundImageOpacity,
        b?.backgroundImageOpacity,
        t,
      ),
      imageScrimOpacity: lerpDouble(
        a?.imageScrimOpacity,
        b?.imageScrimOpacity,
        t,
      ),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      border: Border.lerp(a?.border, b?.border, t),
      borderGradient: Gradient.lerp(a?.borderGradient, b?.borderGradient, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      borderColor: Color.lerp(a?.borderColor, b?.borderColor, t),
      borderDashWidth: lerpDouble(a?.borderDashWidth, b?.borderDashWidth, t),
      borderDashGap: lerpDouble(a?.borderDashGap, b?.borderDashGap, t),
      borderWaveAmplitude: lerpDouble(
        a?.borderWaveAmplitude,
        b?.borderWaveAmplitude,
        t,
      ),
      borderWaveFrequency: lerpDouble(
        a?.borderWaveFrequency,
        b?.borderWaveFrequency,
        t,
      ),
      shadow: BoxShadow.lerpList(a?.shadow, b?.shadow, t),
      innerShadow: BoxShadow.lerpList(a?.innerShadow, b?.innerShadow, t),
      blur: lerpDouble(a?.blur, b?.blur, t),
      blurBackgroundOpacity: lerpDouble(
        a?.blurBackgroundOpacity,
        b?.blurBackgroundOpacity,
        t,
      ),
      padding: EdgeInsets.lerp(a?.padding, b?.padding, t),
      margin: EdgeInsets.lerp(a?.margin, b?.margin, t),
      width: lerpDouble(a?.width, b?.width, t),
      height: lerpDouble(a?.height, b?.height, t),
      minHeight: lerpDouble(a?.minHeight, b?.minHeight, t),
      maxHeight: lerpDouble(a?.maxHeight, b?.maxHeight, t),
      minWidth: lerpDouble(a?.minWidth, b?.minWidth, t),
      maxWidth: lerpDouble(a?.maxWidth, b?.maxWidth, t),
      // Gradients, an image, a line style, a clip and every behaviour
      // flag have no midpoint worth computing.
      backgroundImage: pick?.backgroundImage,
      backgroundImageFit: pick?.backgroundImageFit,
      borderLineStyle: pick?.borderLineStyle,
      innerShadowGradient: pick?.innerShadowGradient,
      useDeviceRadius: pick?.useDeviceRadius,
      clipBehavior: pick?.clipBehavior,
      animationDuration: pick?.animationDuration,
      animationCurve: pick?.animationCurve,
      respectReducedMotion: pick?.respectReducedMotion,
      dense: pick?.dense,
      focusColor: Color.lerp(a?.focusColor, b?.focusColor, t),
      focusRingWidth: lerpDouble(a?.focusRingWidth, b?.focusRingWidth, t),
      enableHaptic: pick?.enableHaptic,
      pressScale: lerpDouble(a?.pressScale, b?.pressScale, t),
      tileMinHeight: lerpDouble(a?.tileMinHeight, b?.tileMinHeight, t),
      slotSize: lerpDouble(a?.slotSize, b?.slotSize, t),
    );
  }
}

/// `caller > theme > defaults`, then colours from the palette.
extension ContainerStyleResolve on ContainerStyle {
  ResolvedContainerStyle resolve(BuildContext context) {
    final merged = ContainerStyle.defaults
        .mergedWith(GlobalContainerTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = ContainerStyle.defaults;

    final bg = context.backgroundColors;
    final scrim = context.overlayColors.scrim;

    return ResolvedContainerStyle(
      // A container sits ABOVE the page, so it takes the palette's
      // container role rather than the page's own surface. It was
      // `isDark ? cs.surfaceContainerHigh : cs.surface` — Material's
      // scheme, and a brightness branch the palette already does.
      backgroundColor: merged.backgroundColor ?? bg.container,
      backgroundGradient: merged.backgroundGradient,
      backgroundImage: merged.backgroundImage,
      backgroundImageFit:
          merged.backgroundImageFit ?? floor.backgroundImageFit!,
      backgroundImageOpacity:
          merged.backgroundImageOpacity ?? floor.backgroundImageOpacity!,
      imageScrimOpacity: merged.imageScrimOpacity ?? floor.imageScrimOpacity!,
      // NULL is meaningful: the widget then asks the device for its own
      // screen corner, which is only known asynchronously.
      borderRadius: merged.borderRadius,
      border: merged.border,
      borderGradient: merged.borderGradient,
      borderWidth: merged.borderWidth ?? floor.borderWidth!,
      borderLineStyle: merged.borderLineStyle,
      borderColor: merged.borderColor ?? bg.outline,
      borderDashWidth: merged.borderDashWidth ?? floor.borderDashWidth!,
      borderDashGap: merged.borderDashGap ?? floor.borderDashGap!,
      borderWaveAmplitude:
          merged.borderWaveAmplitude ?? floor.borderWaveAmplitude!,
      borderWaveFrequency:
          merged.borderWaveFrequency ?? floor.borderWaveFrequency!,
      // `const []` is a FLAT container and is not the same as null.
      shadow:
          merged.shadow ??
          [
            BoxShadow(
              color: scrim.withValues(alpha: ContainerDefaults.shadowOpacity),
              blurRadius: ContainerDefaults.shadowBlur,
              offset: ContainerDefaults.shadowOffset,
            ),
          ],
      innerShadow: merged.innerShadow,
      innerShadowGradient: merged.innerShadowGradient,
      blur: merged.blur ?? floor.blur!,
      blurBackgroundOpacity:
          merged.blurBackgroundOpacity ?? floor.blurBackgroundOpacity!,
      padding:
          merged.padding ?? const EdgeInsets.all(ContainerDefaults.padding),
      margin: merged.margin,
      width: merged.width,
      height: merged.height,
      minHeight: merged.minHeight,
      maxHeight: merged.maxHeight,
      minWidth: merged.minWidth,
      maxWidth: merged.maxWidth,
      useDeviceRadius: merged.useDeviceRadius ?? floor.useDeviceRadius!,
      clipBehavior: merged.clipBehavior ?? floor.clipBehavior!,
      animationDuration: merged.animationDuration ?? floor.animationDuration!,
      animationCurve: merged.animationCurve ?? floor.animationCurve!,
      respectReducedMotion:
          merged.respectReducedMotion ?? floor.respectReducedMotion!,
      dense: merged.dense ?? floor.dense!,
      enableHaptic: merged.enableHaptic ?? floor.enableHaptic!,
      pressScale: merged.pressScale ?? floor.pressScale!,
      tileMinHeight:
          merged.tileMinHeight ??
          ((merged.dense ?? false)
              ? ContainerDefaults.tileDenseMinHeight
              : ContainerDefaults.tileMinHeight),
      slotSize:
          merged.slotSize ??
          ((merged.dense ?? false)
              ? ContainerDefaults.tileDenseSlotSize
              : ContainerDefaults.tileSlotSize),
      focusColor: merged.focusColor ?? context.primaryColors.primary,
      focusRingWidth: merged.focusRingWidth ?? floor.focusRingWidth!,
      scrimColor: scrim,
      onSurfaceColor: context.textColors.primary,
      secondaryTextColor: context.textColors.secondary,
      badgeColor: context.statusColors.error,
      onBadgeColor: context.textColors.onAccent,
    );
  }
}
