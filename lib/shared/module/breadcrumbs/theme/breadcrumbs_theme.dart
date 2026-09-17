import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../marquee/global_marquee.dart';
import '../breadcrumbs_models.dart';

/// App-wide defaults for `GlobalBreadcrumbs`.
///
/// The rebrand hook: set the separator, the type and the collapse
/// budget of every trail in the app once, here.
@immutable
class GlobalBreadcrumbsTheme extends ThemeExtension<GlobalBreadcrumbsTheme> {
  const GlobalBreadcrumbsTheme({this.style});

  final BreadcrumbsStyle? style;

  static GlobalBreadcrumbsTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<GlobalBreadcrumbsTheme>();

  @override
  GlobalBreadcrumbsTheme copyWith({BreadcrumbsStyle? style}) =>
      GlobalBreadcrumbsTheme(style: style ?? this.style);

  @override
  GlobalBreadcrumbsTheme lerp(
    ThemeExtension<GlobalBreadcrumbsTheme>? other,
    double t,
  ) {
    if (other is! GlobalBreadcrumbsTheme) return this;
    return GlobalBreadcrumbsTheme(style: _lerpStyle(style, other.style, t));
  }

  /// Continuous fields interpolate; discrete ones snap at the midpoint.
  ///
  /// A trail half-collapsed and half-scrolled is not a layout, and a
  /// separator half-chevron and half-slash is not a mark — those are
  /// picked, not blended. The COUNT is picked too: two and a half
  /// crumbs is not a number of crumbs.
  static BreadcrumbsStyle? _lerpStyle(
    BreadcrumbsStyle? a,
    BreadcrumbsStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    final pick = t < 0.5 ? a : b;
    return BreadcrumbsStyle(
      separatorSize: lerpDouble(a?.separatorSize, b?.separatorSize, t),
      separatorColor: Color.lerp(a?.separatorColor, b?.separatorColor, t),
      separatorGap: lerpDouble(a?.separatorGap, b?.separatorGap, t),
      linkColor: Color.lerp(a?.linkColor, b?.linkColor, t),
      currentColor: Color.lerp(a?.currentColor, b?.currentColor, t),
      disabledColor: Color.lerp(a?.disabledColor, b?.disabledColor, t),
      fontSize: lerpDouble(a?.fontSize, b?.fontSize, t),
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
      iconGap: lerpDouble(a?.iconGap, b?.iconGap, t),
      itemPadding: EdgeInsets.lerp(a?.itemPadding, b?.itemPadding, t),
      itemRadius: lerpDouble(a?.itemRadius, b?.itemRadius, t),
      hoverColor: Color.lerp(a?.hoverColor, b?.hoverColor, t),
      focusColor: Color.lerp(a?.focusColor, b?.focusColor, t),
      minHeight: lerpDouble(a?.minHeight, b?.minHeight, t),
      edgeFade: lerpDouble(a?.edgeFade, b?.edgeFade, t),
      showHiddenCount: pick?.showHiddenCount,
      overflow: pick?.overflow,
      maxVisible: pick?.maxVisible,
      maxVisibleCompact: pick?.maxVisibleCompact,
      separatorIcon: pick?.separatorIcon,
      separatorText: pick?.separatorText,
      fontWeight: pick?.fontWeight,
      currentFontWeight: pick?.currentFontWeight,
      marqueeLabels: pick?.marqueeLabels,
      marqueeStyle: pick?.marqueeStyle,
      animationDuration: pick?.animationDuration,
      respectReducedMotion: pick?.respectReducedMotion,
    );
  }
}

/// `caller > theme > defaults`, then colours from the palette.
extension BreadcrumbsStyleResolve on BreadcrumbsStyle {
  ResolvedBreadcrumbsStyle resolve(BuildContext context) {
    final merged = BreadcrumbsStyle.defaults
        .mergedWith(GlobalBreadcrumbsTheme.maybeOf(context)?.style)
        .mergedWith(this);
    const floor = BreadcrumbsStyle.defaults;

    final text = context.textColors;
    final primary = context.primaryColors;

    return ResolvedBreadcrumbsStyle(
      overflow: merged.overflow ?? floor.overflow!,
      maxVisible: merged.maxVisible ?? floor.maxVisible!,
      maxVisibleCompact: merged.maxVisibleCompact ?? floor.maxVisibleCompact!,
      // A mark is one or the other. Text WINS, and blanks the icon, so
      // build code never has to decide which of two non-null fields it
      // is looking at.
      separatorIcon: merged.separatorText != null
          ? null
          : merged.separatorIcon ?? floor.separatorIcon,
      separatorText: merged.separatorText,
      separatorSize: merged.separatorSize ?? floor.separatorSize!,
      // Quieter than either crumb: it is punctuation, not content.
      separatorColor: merged.separatorColor ?? text.disabled,
      separatorGap: merged.separatorGap ?? floor.separatorGap!,
      // A crumb that goes somewhere is a LINK, and the palette has a
      // colour for exactly that.
      linkColor: merged.linkColor ?? text.link,
      // The current page is where you ARE, not somewhere to go — so it
      // takes the ordinary text colour and carries its weight instead.
      currentColor: merged.currentColor ?? text.primary,
      disabledColor: merged.disabledColor ?? text.disabled,
      fontSize: merged.fontSize ?? floor.fontSize!,
      fontWeight: merged.fontWeight ?? floor.fontWeight!,
      currentFontWeight: merged.currentFontWeight ?? floor.currentFontWeight!,
      iconSize: merged.iconSize ?? floor.iconSize!,
      iconGap: merged.iconGap ?? floor.iconGap!,
      itemPadding:
          merged.itemPadding ??
          const EdgeInsets.symmetric(
            horizontal: BreadcrumbsDefaults.itemHPad,
            vertical: BreadcrumbsDefaults.itemVPad,
          ),
      itemRadius: merged.itemRadius ?? floor.itemRadius!,
      hoverColor:
          merged.hoverColor ??
          primary.primary.withValues(alpha: BreadcrumbsDefaults.hoverOpacity),
      focusColor:
          merged.focusColor ??
          primary.primary.withValues(alpha: BreadcrumbsDefaults.focusOpacity),
      marqueeLabels: merged.marqueeLabels ?? floor.marqueeLabels!,
      marqueeStyle: merged.marqueeStyle ?? const MarqueeStyle(),
      animationDuration: merged.animationDuration ?? floor.animationDuration!,
      respectReducedMotion:
          merged.respectReducedMotion ?? floor.respectReducedMotion!,
      minHeight: merged.minHeight ?? floor.minHeight!,
      showHiddenCount: merged.showHiddenCount ?? floor.showHiddenCount!,
      edgeFade: merged.edgeFade ?? floor.edgeFade!,
    );
  }
}
