import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/responsive/window_size_class.dart';
import '../app_bar_models.dart';

/// App-wide defaults for [GlobalAppBar] and [GlobalSliverAppBar].
///
/// The rebrand hook: set the bar's shape, elevation and title treatment
/// once here and every screen follows, instead of repeating the same
/// `AppBarStyle(...)` at each call site.
@immutable
class GlobalAppBarTheme extends ThemeExtension<GlobalAppBarTheme> {
  GlobalAppBarTheme({this.style})
    : assert(
        style?.toolbarHeight == null,
        'toolbarHeight cannot be themed. PreferredSizeWidget.preferredSize '
        'is a getter with no BuildContext, so it cannot read this theme — a '
        'themed height would change what the bar PAINTS while the Scaffold '
        'still laid out for the old one. Set it per call site instead.',
      );

  final AppBarStyle? style;

  static GlobalAppBarTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalAppBarTheme>();

  @override
  GlobalAppBarTheme copyWith({AppBarStyle? style}) =>
      GlobalAppBarTheme(style: style ?? this.style);

  @override
  GlobalAppBarTheme lerp(ThemeExtension<GlobalAppBarTheme>? other, double t) {
    if (other is! GlobalAppBarTheme) return this;
    return GlobalAppBarTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint —
  /// half a `centerTitle` is not a thing, and a half-swapped layout mode
  /// would rebuild the bar with a different widget tree mid-animation.
  static AppBarStyle? _lerpStyle(AppBarStyle? a, AppBarStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return AppBarStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      foregroundColor: Color.lerp(a?.foregroundColor, b?.foregroundColor, t),
      gradient: Gradient.lerp(a?.gradient, b?.gradient, t),
      elevation: lerpDouble(a?.elevation, b?.elevation, t),
      shadowColor: Color.lerp(a?.shadowColor, b?.shadowColor, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      border: Border.lerp(a?.border, b?.border, t),
      borderGradient: Gradient.lerp(a?.borderGradient, b?.borderGradient, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      titleStyle: TextStyle.lerp(a?.titleStyle, b?.titleStyle, t),
      subtitleStyle: TextStyle.lerp(a?.subtitleStyle, b?.subtitleStyle, t),
      centerTitle: pick?.centerTitle,
      dynamicHeight: pick?.dynamicHeight,
      hideOnScroll: pick?.hideOnScroll,
      backButtonSize: lerpDouble(a?.backButtonSize, b?.backButtonSize, t),
      backIconSize: lerpDouble(a?.backIconSize, b?.backIconSize, t),
      buttonBackgroundColor: Color.lerp(
        a?.buttonBackgroundColor,
        b?.buttonBackgroundColor,
        t,
      ),
      titleOverflow: pick?.titleOverflow,
      marqueeTitle: pick?.marqueeTitle,
      balanceCenteredTitle: pick?.balanceCenteredTitle,
      // Deliberately not lerped — see AppBarStyle.toolbarHeight.
      toolbarHeight: pick?.toolbarHeight,
    );
  }
}

extension AppBarStyleResolve on AppBarStyle {
  /// Stacks `caller > theme > defaults`, then fills colors from
  /// `context.<group>Colors` so they track the active palette, role and
  /// brightness.
  ///
  /// [variant] participates because two of the fields are variant-derived
  /// rather than merely defaulted: a transparent or gradient bar has no
  /// surface behind it, so its background is transparent and its
  /// foreground is white regardless of the palette.
  ResolvedAppBarStyle resolve(
    BuildContext context, {
    AppBarVariant variant = AppBarVariant.standard,
  }) {
    final merged = AppBarStyle.defaults
        .mergedWith(GlobalAppBarTheme.maybeOf(context)?.style)
        .mergedWith(this);
    final overlays =
        variant == AppBarVariant.transparent ||
        variant == AppBarVariant.gradient;
    const floor = AppBarStyle.defaults;

    return ResolvedAppBarStyle(
      backgroundColor:
          merged.backgroundColor ??
          (overlays ? Colors.transparent : context.backgroundColors.surface),
      foregroundColor:
          merged.foregroundColor ??
          (overlays ? Colors.white : context.textColors.primary),
      elevation: merged.elevation ?? floor.elevation!,
      borderWidth: merged.borderWidth ?? floor.borderWidth!,
      centerTitle: merged.centerTitle ?? floor.centerTitle!,
      dynamicHeight: merged.dynamicHeight ?? floor.dynamicHeight!,
      // AUTO when nobody said. A landscape phone gives the bar 56 of a
      // 402-point screen — fourteen per cent of the axis there is none
      // of — and `WindowHeightClass` exists to name exactly that case.
      // Read off `MediaQuery` rather than `context.breakpoints` so the
      // bar does not require a `BreakpointsProvider` to lay itself out.
      hideOnScroll:
          merged.hideOnScroll ??
          WindowHeightClass.fromHeight(
            MediaQuery.sizeOf(context).height,
          ).isCompact,
      backButtonSize: merged.backButtonSize ?? floor.backButtonSize!,
      backIconSize: merged.backIconSize ?? floor.backIconSize!,
      buttonBackgroundColor: merged.buttonBackgroundColor,
      titleOverflow: merged.titleOverflow ?? floor.titleOverflow!,
      balanceCenteredTitle:
          merged.balanceCenteredTitle ?? floor.balanceCenteredTitle!,
      marqueeTitle: merged.marqueeTitle,
      gradient: merged.gradient,
      shadowColor: merged.shadowColor,
      borderRadius: merged.borderRadius,
      border: merged.border,
      borderGradient: merged.borderGradient,
      titleStyle: merged.titleStyle,
      subtitleStyle: merged.subtitleStyle,
      toolbarHeight: merged.toolbarHeight,
    );
  }
}
