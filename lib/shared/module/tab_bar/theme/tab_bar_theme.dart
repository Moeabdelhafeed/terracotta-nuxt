import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/responsive/extensions.dart';
import '../../../../core/tokens/extensions.dart';
import '../tab_bar_models.dart';

/// App-wide defaults for [GlobalTabBar].
///
/// The rebrand hook: set the indicator treatment, shape and density once
/// here and every tab bar in the app follows, instead of repeating the
/// same `TabBarStyle(...)` at each call site.
@immutable
class GlobalTabBarTheme extends ThemeExtension<GlobalTabBarTheme> {
  GlobalTabBarTheme({this.style})
    : assert(
        style?.height == null,
        'height cannot be themed. GlobalTabBar is a PreferredSizeWidget and '
        'preferredSize is a getter with no BuildContext, so it cannot read '
        'this theme — a themed height would change what the bar PAINTS while '
        'the Scaffold still laid out for the old one. Set it per call site.',
      );

  final TabBarStyle? style;

  static GlobalTabBarTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalTabBarTheme>();

  @override
  GlobalTabBarTheme copyWith({TabBarStyle? style}) =>
      GlobalTabBarTheme(style: style ?? this.style);

  @override
  GlobalTabBarTheme lerp(ThemeExtension<GlobalTabBarTheme>? other, double t) {
    if (other is! GlobalTabBarTheme) return this;
    return GlobalTabBarTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint —
  /// half an indicator style is not a thing, and a half-swapped one
  /// would rebuild the bar with a different decoration mid-animation.
  static TabBarStyle? _lerpStyle(TabBarStyle? a, TabBarStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return TabBarStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      backgroundGradient: Gradient.lerp(
        a?.backgroundGradient,
        b?.backgroundGradient,
        t,
      ),
      indicatorStyle: pick?.indicatorStyle,
      indicatorColor: Color.lerp(a?.indicatorColor, b?.indicatorColor, t),
      indicatorGradient: Gradient.lerp(
        a?.indicatorGradient,
        b?.indicatorGradient,
        t,
      ),
      indicatorWeight: lerpDouble(a?.indicatorWeight, b?.indicatorWeight, t),
      indicatorRadius: lerpDouble(a?.indicatorRadius, b?.indicatorRadius, t),
      pillRadius: lerpDouble(a?.pillRadius, b?.pillRadius, t),
      pillOpacity: lerpDouble(a?.pillOpacity, b?.pillOpacity, t),
      selectedColor: Color.lerp(a?.selectedColor, b?.selectedColor, t),
      unselectedColor: Color.lerp(a?.unselectedColor, b?.unselectedColor, t),
      disabledColor: Color.lerp(a?.disabledColor, b?.disabledColor, t),
      onIndicatorColor: Color.lerp(a?.onIndicatorColor, b?.onIndicatorColor, t),
      selectedFontSize: lerpDouble(a?.selectedFontSize, b?.selectedFontSize, t),
      unselectedFontSize: lerpDouble(
        a?.unselectedFontSize,
        b?.unselectedFontSize,
        t,
      ),
      selectedFontWeight: FontWeight.lerp(
        a?.selectedFontWeight,
        b?.selectedFontWeight,
        t,
      ),
      unselectedFontWeight: FontWeight.lerp(
        a?.unselectedFontWeight,
        b?.unselectedFontWeight,
        t,
      ),
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
      iconPosition: pick?.iconPosition,
      iconSpacing: lerpDouble(a?.iconSpacing, b?.iconSpacing, t),
      isScrollable: pick?.isScrollable,
      adaptiveMode: pick?.adaptiveMode,
      tabPadding: EdgeInsetsGeometry.lerp(a?.tabPadding, b?.tabPadding, t),
      border: Border.lerp(a?.border, b?.border, t),
      borderGradient: Gradient.lerp(a?.borderGradient, b?.borderGradient, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      shadow: BoxShadow.lerpList(a?.shadow, b?.shadow, t),
      dividerColor: Color.lerp(a?.dividerColor, b?.dividerColor, t),
      dividerHeight: lerpDouble(a?.dividerHeight, b?.dividerHeight, t),
      showDivider: pick?.showDivider,
      compact: pick?.compact,
      enableHaptic: pick?.enableHaptic,
      bounceOnTap: pick?.bounceOnTap,
      closeIconSize: lerpDouble(a?.closeIconSize, b?.closeIconSize, t),
      closeButtonSize: lerpDouble(a?.closeButtonSize, b?.closeButtonSize, t),
      badgeColor: Color.lerp(a?.badgeColor, b?.badgeColor, t),
      badgeTextColor: Color.lerp(a?.badgeTextColor, b?.badgeTextColor, t),
      focusColor: Color.lerp(a?.focusColor, b?.focusColor, t),
      // Deliberately not lerped — see TabBarStyle.height.
      height: pick?.height,
    );
  }
}

extension TabBarStyleResolve on TabBarStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from
  /// `context.<group>Colors` and spacing from tokens so a tab bar tracks
  /// the active palette, role, brightness and density.
  ///
  /// Token lookups DEGRADE: a tab bar can be built in a bare `MaterialApp`
  /// with no `BreakpointsProvider` above it (every widget test does), and
  /// tabs must still render.
  ResolvedTabBarStyle resolve(BuildContext context) {
    final merged = TabBarStyle.defaults
        .mergedWith(GlobalTabBarTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = TabBarStyle.defaults;
    final tokens = context.maybeBreakpoints == null ? null : context.tokens;
    final compact = merged.compact ?? floor.compact!;

    final selected = merged.selectedColor ?? context.primaryColors.primary;
    final hPad = compact
        ? TabBarDefaults.compactTabHPad
        : TabBarDefaults.tabHPad;

    return ResolvedTabBarStyle(
      indicatorStyle: merged.indicatorStyle ?? floor.indicatorStyle!,
      // The indicator IS the selection cue, so it follows the selected
      // colour unless something overrides it on purpose.
      indicatorColor: merged.indicatorColor ?? selected,
      indicatorGradient: merged.indicatorGradient,
      indicatorWeight: merged.indicatorWeight ?? floor.indicatorWeight!,
      indicatorRadius: merged.indicatorRadius ?? floor.indicatorRadius!,
      pillRadius:
          merged.pillRadius ?? (tokens?.radii.full ?? floor.pillRadius!),
      pillOpacity: merged.pillOpacity ?? floor.pillOpacity!,
      selectedColor: selected,
      unselectedColor: merged.unselectedColor ?? context.textColors.secondary,
      disabledColor: merged.disabledColor ?? context.textColors.disabled,
      onIndicatorColor: merged.onIndicatorColor ?? context.textColors.onPrimary,
      selectedFontSize: merged.selectedFontSize ?? floor.selectedFontSize!,
      unselectedFontSize:
          merged.unselectedFontSize ?? floor.unselectedFontSize!,
      selectedFontWeight:
          merged.selectedFontWeight ?? floor.selectedFontWeight!,
      unselectedFontWeight:
          merged.unselectedFontWeight ?? floor.unselectedFontWeight!,
      iconSize: merged.iconSize ?? (tokens?.iconSizes.sm ?? floor.iconSize!),
      iconPosition: merged.iconPosition ?? floor.iconPosition!,
      iconSpacing: merged.iconSpacing ?? floor.iconSpacing!,
      isScrollable: merged.isScrollable ?? floor.isScrollable!,
      adaptiveMode: merged.adaptiveMode ?? floor.adaptiveMode!,
      tabPadding:
          merged.tabPadding ??
          EdgeInsetsDirectional.symmetric(horizontal: hPad),
      borderWidth: merged.borderWidth ?? floor.borderWidth!,
      dividerColor:
          merged.dividerColor ??
          context.backgroundColors.outline.withValues(
            alpha: TabBarDefaults.dividerOpacity,
          ),
      dividerHeight: merged.dividerHeight ?? floor.dividerHeight!,
      showDivider: merged.showDivider ?? floor.showDivider!,
      compact: compact,
      enableHaptic: merged.enableHaptic ?? floor.enableHaptic!,
      bounceOnTap: merged.bounceOnTap ?? floor.bounceOnTap!,
      closeIconSize: merged.closeIconSize ?? floor.closeIconSize!,
      closeButtonSize: merged.closeButtonSize ?? floor.closeButtonSize!,
      badgeColor: merged.badgeColor ?? selected,
      badgeTextColor: merged.badgeTextColor ?? context.textColors.onPrimary,
      focusColor:
          merged.focusColor ??
          (merged.indicatorColor ?? selected).withValues(
            alpha: TabBarDefaults.focusOverlayOpacity,
          ),
      backgroundColor: merged.backgroundColor,
      backgroundGradient: merged.backgroundGradient,
      height: merged.height,
      border: merged.border,
      borderGradient: merged.borderGradient,
      borderRadius: merged.borderRadius,
      shadow: merged.shadow,
    );
  }
}
