import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../marquee/marquee_models.dart';
import '../bottom_nav_models.dart';

/// App-wide defaults for [GlobalBottomNav].
///
/// The rebrand hook: set the surface, the indicator shape and whether
/// every bar in the app floats, once, here.
@immutable
class GlobalBottomNavTheme extends ThemeExtension<GlobalBottomNavTheme> {
  const GlobalBottomNavTheme({this.style});

  final BottomNavStyle? style;

  static GlobalBottomNavTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalBottomNavTheme>();

  @override
  GlobalBottomNavTheme copyWith({BottomNavStyle? style}) =>
      GlobalBottomNavTheme(style: style ?? this.style);

  @override
  GlobalBottomNavTheme lerp(
    ThemeExtension<GlobalBottomNavTheme>? other,
    double t,
  ) {
    if (other is! GlobalBottomNavTheme) return this;
    return GlobalBottomNavTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint.
  static BottomNavStyle? _lerpStyle(
    BottomNavStyle? a,
    BottomNavStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return BottomNavStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      blur: lerpDouble(a?.blur, b?.blur, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      topBorder: BorderSide.lerp(
        a?.topBorder ?? BorderSide.none,
        b?.topBorder ?? BorderSide.none,
        t,
      ),
      topBorderWidth: lerpDouble(a?.topBorderWidth, b?.topBorderWidth, t),
      border: Border.lerp(a?.border, b?.border, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      floatingMargin: EdgeInsets.lerp(a?.floatingMargin, b?.floatingMargin, t),
      selectedColor: Color.lerp(a?.selectedColor, b?.selectedColor, t),
      unselectedColor: Color.lerp(a?.unselectedColor, b?.unselectedColor, t),
      disabledColor: Color.lerp(a?.disabledColor, b?.disabledColor, t),
      indicatorColor: Color.lerp(a?.indicatorColor, b?.indicatorColor, t),
      indicatorOpacity: lerpDouble(
        a?.indicatorOpacity,
        b?.indicatorOpacity,
        t,
      ),
      indicatorRadius: lerpDouble(a?.indicatorRadius, b?.indicatorRadius, t),
      indicatorWidth: lerpDouble(a?.indicatorWidth, b?.indicatorWidth, t),
      bottomInsetFactor: lerpDouble(
        a?.bottomInsetFactor,
        b?.bottomInsetFactor,
        t,
      ),
      indicatorBarThickness: lerpDouble(
        a?.indicatorBarThickness,
        b?.indicatorBarThickness,
        t,
      ),
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
      iconReactionScale: lerpDouble(
        a?.iconReactionScale,
        b?.iconReactionScale,
        t,
      ),
      selectedFontSize: lerpDouble(
        a?.selectedFontSize,
        b?.selectedFontSize,
        t,
      ),
      unselectedFontSize: lerpDouble(
        a?.unselectedFontSize,
        b?.unselectedFontSize,
        t,
      ),
      itemPadding: EdgeInsets.lerp(a?.itemPadding, b?.itemPadding, t),
      contentPadding: EdgeInsets.lerp(a?.contentPadding, b?.contentPadding, t),
      itemSpacing: lerpDouble(a?.itemSpacing, b?.itemSpacing, t),
      height: lerpDouble(a?.height, b?.height, t),
      notchMargin: lerpDouble(a?.notchMargin, b?.notchMargin, t),
      notchFabRadius: lerpDouble(a?.notchFabRadius, b?.notchFabRadius, t),
      notchFabSize: lerpDouble(a?.notchFabSize, b?.notchFabSize, t),
      notchLipRadius: lerpDouble(a?.notchLipRadius, b?.notchLipRadius, t),
      // Gradients, shadows, a curve and every behaviour flag have no
      // midpoint worth computing — an indicator half-pill and half-dot
      // is not a shape, and a bar that half-floats is not a layout.
      backgroundGradient: pick?.backgroundGradient,
      shadow: pick?.shadow,
      topBorderGradient: pick?.topBorderGradient,
      borderGradient: pick?.borderGradient,
      floating: pick?.floating,
      useDeviceRadius: pick?.useDeviceRadius,
      indicatorStyle: pick?.indicatorStyle,
      customIndicator: pick?.customIndicator,
      labelMode: pick?.labelMode,
      animationDuration: pick?.animationDuration,
      animationCurve: pick?.animationCurve,
      compact: pick?.compact,
      notch: pick?.notch,
      resetOnReTap: pick?.resetOnReTap,
      bounceOnTap: pick?.bounceOnTap,
      hapticFeedback: pick?.hapticFeedback,
      hideOnScroll: pick?.hideOnScroll,
      scrollable: pick?.scrollable,
      respectReducedMotion: pick?.respectReducedMotion,
      notchShape: pick?.notchShape,
      entrance: pick?.entrance,
      entranceCurve: pick?.entranceCurve,
      reverseEntranceOnExit: pick?.reverseEntranceOnExit,
      marqueeLabels: pick?.marqueeLabels,
      marqueeStyle: pick?.marqueeStyle,
      iconReaction: pick?.iconReaction,
    );
  }
}

extension BottomNavStyleResolve on BottomNavStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from the
  /// palette.
  ///
  /// The bar read `Theme.of(context).colorScheme` for its surface, its
  /// selected tint and both washed-out states — Material's scheme
  /// rather than the app's, so a rebranded palette left every
  /// navigation bar behind. The shadow was `Colors.black` and a
  /// prominent item's glyph was `Colors.white`, neither of which is a
  /// colour this app owns.
  ResolvedBottomNavStyle resolve(BuildContext context) {
    final merged = BottomNavStyle.defaults
        .mergedWith(GlobalBottomNavTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = BottomNavStyle.defaults;

    final primary = context.primaryColors;
    final text = context.textColors;
    final bg = context.backgroundColors;

    final selected = merged.selectedColor ?? primary.primary;
    final compact = merged.compact ?? floor.compact!;

    return ResolvedBottomNavStyle(
      // A bar sits ABOVE the page, so it takes the container rather
      // than the surface behind it.
      backgroundColor: merged.backgroundColor ?? bg.container,
      backgroundGradient: merged.backgroundGradient,
      blur: merged.blur ?? floor.blur!,
      borderRadius: merged.borderRadius,
      shadow:
          merged.shadow ??
          [
            BoxShadow(
              // The scrim is the palette's own "something dark over the
              // page" colour. It was `Colors.black`, which is not a
              // colour this app owns.
              color: context.overlayColors.scrim.withValues(
                alpha: BottomNavDefaults.shadowOpacity,
              ),
              blurRadius: BottomNavDefaults.shadowBlur,
              offset: BottomNavDefaults.shadowOffset,
            ),
          ],
      topBorder: merged.topBorder,
      topBorderGradient: merged.topBorderGradient,
      topBorderWidth: merged.topBorderWidth ?? floor.topBorderWidth!,
      border: merged.border,
      borderGradient: merged.borderGradient,
      borderWidth: merged.borderWidth ?? floor.borderWidth!,
      floating: merged.floating ?? floor.floating!,
      floatingMargin: merged.floatingMargin ?? floor.floatingMargin!,
      useDeviceRadius: merged.useDeviceRadius ?? floor.useDeviceRadius!,
      selectedColor: selected,
      unselectedColor:
          merged.unselectedColor ??
          text.primary.withValues(alpha: BottomNavDefaults.unselectedOpacity),
      disabledColor:
          merged.disabledColor ??
          text.primary.withValues(alpha: BottomNavDefaults.disabledOpacity),
      indicatorStyle: merged.indicatorStyle ?? floor.indicatorStyle!,
      indicatorColor: merged.indicatorColor ?? selected,
      indicatorOpacity: merged.indicatorOpacity ?? floor.indicatorOpacity!,
      indicatorRadius: merged.indicatorRadius,
      indicatorBarThickness:
          merged.indicatorBarThickness ?? floor.indicatorBarThickness!,
      customIndicator: merged.customIndicator,
      labelMode: merged.labelMode ?? floor.labelMode!,
      iconSize: merged.iconSize ?? floor.iconSize!,
      selectedFontSize: merged.selectedFontSize ?? floor.selectedFontSize!,
      unselectedFontSize:
          merged.unselectedFontSize ?? floor.unselectedFontSize!,
      itemPadding: merged.itemPadding,
      contentPadding: merged.contentPadding,
      itemSpacing: merged.itemSpacing,
      height:
          merged.height ??
          (compact
              ? BottomNavDefaults.compactHeight
              : BottomNavDefaults.height),
      animationDuration: merged.animationDuration ?? floor.animationDuration!,
      animationCurve: merged.animationCurve ?? floor.animationCurve!,
      compact: compact,
      notch: merged.notch ?? floor.notch!,
      notchMargin: merged.notchMargin ?? floor.notchMargin!,
      resetOnReTap: merged.resetOnReTap ?? floor.resetOnReTap!,
      bounceOnTap: merged.bounceOnTap ?? floor.bounceOnTap!,
      hapticFeedback: merged.hapticFeedback ?? floor.hapticFeedback!,
      hideOnScroll: merged.hideOnScroll ?? floor.hideOnScroll!,
      scrollable: merged.scrollable ?? floor.scrollable!,
      respectReducedMotion:
          merged.respectReducedMotion ?? floor.respectReducedMotion!,
      notchShape: merged.notchShape,
      entrance: merged.entrance ?? floor.entrance!,
      entranceDuration: merged.entranceDuration ?? floor.entranceDuration!,
      entranceCurve: merged.entranceCurve ?? floor.entranceCurve!,
      notchFabRadius: merged.notchFabRadius ?? floor.notchFabRadius!,
      notchFabSize: merged.notchFabSize ?? floor.notchFabSize!,
      notchLipRadius: merged.notchLipRadius ?? floor.notchLipRadius!,
      reverseEntranceOnExit:
          merged.reverseEntranceOnExit ?? floor.reverseEntranceOnExit!,
      marqueeLabels: merged.marqueeLabels ?? floor.marqueeLabels!,
      marqueeStyle: merged.marqueeStyle ?? const MarqueeStyle(),
      iconReaction: merged.iconReaction ?? floor.iconReaction!,
      iconReactionScale: merged.iconReactionScale ?? floor.iconReactionScale!,
      indicatorWidth: merged.indicatorWidth,
      bottomInsetFactor: (merged.bottomInsetFactor ?? floor.bottomInsetFactor!)
          .clamp(0.0, 1.0),
      // What reads ON the prominent fill. It was `Colors.white`, which
      // is wrong the moment the fill is a light colour.
      prominentIconColor: context.iconColors.onPrimary,
    );
  }
}
