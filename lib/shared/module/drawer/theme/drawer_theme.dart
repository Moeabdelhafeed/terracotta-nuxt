import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/responsive/extensions.dart';
import '../../../../core/responsive/responsive_value.dart';
import '../../../../core/tokens/extensions.dart';
import '../drawer_models.dart';

/// App-wide defaults for [GlobalDrawer].
///
/// The rebrand hook: set the drawer's shape, width and row treatment
/// once here and every navigation surface follows, instead of repeating
/// the same `DrawerStyle(...)` at each call site.
@immutable
class GlobalDrawerTheme extends ThemeExtension<GlobalDrawerTheme> {
  const GlobalDrawerTheme({this.style});

  final DrawerStyle? style;

  static GlobalDrawerTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalDrawerTheme>();

  @override
  GlobalDrawerTheme copyWith({DrawerStyle? style}) =>
      GlobalDrawerTheme(style: style ?? this.style);

  @override
  GlobalDrawerTheme lerp(ThemeExtension<GlobalDrawerTheme>? other, double t) {
    if (other is! GlobalDrawerTheme) return this;
    return GlobalDrawerTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint —
  /// half a `floating` is not a thing, and a half-swapped one would
  /// rebuild the drawer with a different shell mid-animation.
  static DrawerStyle? _lerpStyle(DrawerStyle? a, DrawerStyle? b, double t) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return DrawerStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      backgroundGradient: Gradient.lerp(
        a?.backgroundGradient,
        b?.backgroundGradient,
        t,
      ),
      width: lerpDouble(a?.width, b?.width, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      selectedColor: Color.lerp(a?.selectedColor, b?.selectedColor, t),
      selectedBgOpacity: lerpDouble(
        a?.selectedBgOpacity,
        b?.selectedBgOpacity,
        t,
      ),
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
      itemBorderRadius: BorderRadius.lerp(
        a?.itemBorderRadius,
        b?.itemBorderRadius,
        t,
      ),
      itemPadding: EdgeInsetsGeometry.lerp(a?.itemPadding, b?.itemPadding, t),
      headerPadding: EdgeInsetsGeometry.lerp(
        a?.headerPadding,
        b?.headerPadding,
        t,
      ),
      dividerIndent: lerpDouble(a?.dividerIndent, b?.dividerIndent, t),
      border: Border.lerp(a?.border, b?.border, t),
      borderGradient: Gradient.lerp(a?.borderGradient, b?.borderGradient, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      floating: pick?.floating,
      floatingMargin: EdgeInsets.lerp(a?.floatingMargin, b?.floatingMargin, t),
      useDeviceRadius: pick?.useDeviceRadius,
      sectionDivider: pick?.sectionDivider,
      animateItems: pick?.animateItems,
      entranceAnimationDuration: pick?.entranceAnimationDuration,
      expandAnimationDuration: pick?.expandAnimationDuration,
      compact: pick?.compact,
      scrimColor: Color.lerp(a?.scrimColor, b?.scrimColor, t),
      enableHaptic: pick?.enableHaptic,
    );
  }
}

extension DrawerStyleResolve on DrawerStyle {
  /// Stacks `caller > theme > defaults`, then fills colours from
  /// `context.<group>Colors` and the width from the active breakpoint,
  /// so a drawer tracks the palette, role, brightness and window size.
  ///
  /// Token lookups DEGRADE: a drawer must still render inside a bare
  /// `MaterialApp` with no `BreakpointsProvider` above it, which is what
  /// every widget test gives it.
  ResolvedDrawerStyle resolve(BuildContext context, {bool mini = false}) {
    final merged = DrawerStyle.defaults
        .mergedWith(GlobalDrawerTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = DrawerStyle.defaults;
    final hasBreakpoints = context.maybeBreakpoints != null;
    final tokens = hasBreakpoints ? context.tokens : null;

    final selected = merged.selectedColor ?? context.primaryColors.primary;
    final adaptiveWidth = hasBreakpoints
        ? const ResponsiveValue<double>(
            compact: DrawerDefaults.widthCompact,
            medium: DrawerDefaults.widthMedium,
            expanded: DrawerDefaults.widthExpanded,
            large: DrawerDefaults.widthExpanded,
            extraLarge: DrawerDefaults.widthExtraLarge,
          ).resolve(context)
        : DrawerDefaults.widthCompact;

    return ResolvedDrawerStyle(
      // The drawer sits ABOVE the page, so it takes a raised surface
      // rather than the page's own — otherwise it disappears into it.
      backgroundColor:
          merged.backgroundColor ?? context.backgroundColors.container,
      // Mini mode is a rail: its width is the module's, not the
      // caller's, since a 280dp "mini" drawer is not one.
      width: mini ? DrawerDefaults.miniWidth : (merged.width ?? adaptiveWidth),
      selectedColor: selected,
      selectedBgOpacity: merged.selectedBgOpacity ?? floor.selectedBgOpacity!,
      iconSize: merged.iconSize ?? floor.iconSize!,
      itemBorderRadius:
          merged.itemBorderRadius ??
          BorderRadius.circular(
            tokens?.radii.md ?? DrawerDefaults.itemRadius,
          ),
      itemPadding:
          merged.itemPadding ??
          const EdgeInsetsDirectional.symmetric(
            horizontal: DrawerDefaults.itemHPad,
          ),
      headerPadding:
          merged.headerPadding ??
          const EdgeInsetsDirectional.fromSTEB(
            DrawerDefaults.headerHPad,
            DrawerDefaults.headerVPad,
            DrawerDefaults.headerHPad,
            DrawerDefaults.hPad,
          ),
      dividerIndent: merged.dividerIndent ?? floor.dividerIndent!,
      borderWidth: merged.borderWidth ?? floor.borderWidth!,
      floating: merged.floating ?? floor.floating!,
      floatingMargin: merged.floatingMargin ?? floor.floatingMargin!,
      useDeviceRadius: merged.useDeviceRadius ?? floor.useDeviceRadius!,
      animateItems: merged.animateItems ?? floor.animateItems!,
      entranceAnimationDuration:
          merged.entranceAnimationDuration ?? floor.entranceAnimationDuration!,
      expandAnimationDuration:
          merged.expandAnimationDuration ?? floor.expandAnimationDuration!,
      compact: merged.compact ?? floor.compact!,
      enableHaptic: merged.enableHaptic ?? floor.enableHaptic!,
      titleColor: context.textColors.primary,
      subtitleColor: context.textColors.secondary,
      iconColor: context.iconColors.primary,
      badgeTextColor: context.textColors.onPrimary,
      searchFillColor: context.backgroundColors.inputBackground,
      backgroundGradient: merged.backgroundGradient,
      borderRadius: merged.borderRadius,
      border: merged.border,
      borderGradient: merged.borderGradient,
      sectionDivider: merged.sectionDivider,
    );
  }
}
