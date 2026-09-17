import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../marquee/global_marquee.dart';

/// One step in the trail.
///
/// A crumb with no [route] and no [onTap] is the CURRENT page: it is
/// where the reader already is, so it takes no tap and is announced as
/// a heading rather than a link.
@immutable
class BreadcrumbItem {
  const BreadcrumbItem(
    this.label, {
    this.icon,
    this.route,
    this.extra,
    this.onTap,
    this.enabled = true,
    this.detail,
    this.tooltip,
  });

  final String label;

  /// Shown before the label. A house on the root crumb, usually.
  final IconData? icon;

  /// A GoRouter route NAME — `pushNamed`, not a path. Null makes this
  /// crumb inert unless [onTap] says otherwise.
  final String? route;

  /// Typed arguments for [route], parsed by `GoRouterStateExtras`.
  final Object? extra;

  /// Wins over [route]. For a crumb that pops rather than pushes, or
  /// one that belongs to a flow with its own idea of "back".
  final VoidCallback? onTap;

  final bool enabled;

  /// A short qualifier, shown ONLY when another crumb in the same trail
  /// carries the same label.
  ///
  /// A route pushed with its own data can appear twice — a product page
  /// reached from a related product — and two crumbs both saying
  /// "Product" name the same place as far as anyone can tell, a screen
  /// reader included. This is what tells them apart, and it costs
  /// nothing on the trails where every label is already distinct.
  final String? detail;

  /// What a hover or a long press says. For the whole name when the
  /// label had to be short.
  ///
  /// NOT a substitute for [detail]: a tooltip needs a pointer or a
  /// long press to appear, so it says nothing to a reader skimming the
  /// trail or listening to it.
  final String? tooltip;

  /// Whether this crumb goes anywhere at all.
  bool get isLink => enabled && (onTap != null || route != null);
}

/// What a trail does when it will not fit.
enum BreadcrumbsOverflow {
  /// The first crumb, an ellipsis, and the last few. The ellipsis opens
  /// a menu holding everything it swallowed — nothing is lost, only
  /// moved. What web breadcrumbs do, and the default.
  collapse,

  /// The whole trail, scrolled sideways. Nothing hidden and no menu —
  /// and the current page, the one crumb that matters, can start off
  /// the end of it.
  scroll,

  /// The whole trail, over as many lines as it needs.
  wrap,

  /// The parent alone. The least a trail can be and still say where
  /// "up" goes.
  lastOnly,
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Geometry that only changes when this module changes. Anything an app
/// would rebrand lives on [BreadcrumbsStyle] instead.
abstract final class BreadcrumbsDefaults {
  static const fontSize = 13.0;
  static const currentFontWeight = FontWeight.w600;
  static const fontWeight = FontWeight.w400;

  static const iconSize = 16.0;
  static const iconGap = 6.0;

  static const separatorSize = 16.0;
  static const separatorGap = 2.0;

  static const itemHPad = 6.0;
  static const itemVPad = 4.0;
  static const itemRadius = 6.0;

  /// How many crumbs survive a collapse, INCLUDING the first and the
  /// current one. Below four there is nothing left to collapse.
  static const maxVisible = 4;
  static const maxVisibleCompact = 3;

  /// The menu the ellipsis opens.
  static const menuWidth = 240.0;
  static const menuMaxHeight = 320.0;

  /// One row of that menu, and the surface's own padding. The menu is
  /// asked for only the height it needs; the surface shrink-wraps
  /// inside whatever it is given.
  static const menuRowHeight = 48.0;
  static const menuVPad = 16.0;

  /// How tall a menu holding [count] crumbs should be.
  static double menuHeightFor(int count) =>
      (count * menuRowHeight + menuVPad).clamp(menuRowHeight, menuMaxHeight);

  static const animationDuration = AppDurations.quick;
  static const hoverOpacity = 0.08;
  static const focusOpacity = 0.14;
  static const disabledOpacity = 0.4;

  /// A trail is a strip of text; it never needs to be taller than one
  /// row of it plus its padding.
  static const minHeight = 32.0;

  /// The fade at each end of a scrolling trail. Without it nothing on
  /// screen says the trail scrolls at all.
  static const edgeFadeSize = 20.0;

  /// The gap between the ellipsis and the count beside it.
  static const hiddenCountGap = 2.0;

  /// The qualifier and the hidden count are QUIETER than a label.
  static const detailScale = 0.9;

  /// What sits between a label and its qualifier.
  static const detailSeparator = ' · ';
}

// ---------------------------------------------------------------------------
// BreadcrumbsStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for `GlobalBreadcrumbs` — EVERY field nullable.
///
/// Resolution order, materialized once per build by
/// `style.resolve(context)`:
/// `caller > GlobalBreadcrumbsTheme.style > BreadcrumbsStyle.defaults`,
/// then colours from the palette.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedBreadcrumbsStyle] and
/// `GlobalBreadcrumbsTheme.lerp`.
@immutable
class BreadcrumbsStyle {
  const BreadcrumbsStyle({
    this.overflow,
    this.maxVisible,
    this.maxVisibleCompact,
    this.separatorIcon,
    this.separatorText,
    this.separatorSize,
    this.separatorColor,
    this.separatorGap,
    this.linkColor,
    this.currentColor,
    this.disabledColor,
    this.fontSize,
    this.fontWeight,
    this.currentFontWeight,
    this.iconSize,
    this.iconGap,
    this.itemPadding,
    this.itemRadius,
    this.hoverColor,
    this.focusColor,
    this.marqueeLabels,
    this.marqueeStyle,
    this.animationDuration,
    this.respectReducedMotion,
    this.minHeight,
    this.showHiddenCount,
    this.edgeFade,
  });

  /// Compile-time floor. Colours are deliberately absent: they resolve
  /// from the palette at build time, so a trail tracks the app's role,
  /// brightness and saturation.
  static const BreadcrumbsStyle defaults = BreadcrumbsStyle(
    overflow: BreadcrumbsOverflow.collapse,
    maxVisible: BreadcrumbsDefaults.maxVisible,
    maxVisibleCompact: BreadcrumbsDefaults.maxVisibleCompact,
    separatorIcon: Icons.chevron_right_rounded,
    separatorSize: BreadcrumbsDefaults.separatorSize,
    separatorGap: BreadcrumbsDefaults.separatorGap,
    fontSize: BreadcrumbsDefaults.fontSize,
    fontWeight: BreadcrumbsDefaults.fontWeight,
    currentFontWeight: BreadcrumbsDefaults.currentFontWeight,
    iconSize: BreadcrumbsDefaults.iconSize,
    iconGap: BreadcrumbsDefaults.iconGap,
    itemRadius: BreadcrumbsDefaults.itemRadius,
    marqueeLabels: true,
    animationDuration: BreadcrumbsDefaults.animationDuration,
    respectReducedMotion: true,
    minHeight: BreadcrumbsDefaults.minHeight,
    showHiddenCount: true,
    edgeFade: BreadcrumbsDefaults.edgeFadeSize,
  );

  final BreadcrumbsOverflow? overflow;

  /// How many crumbs survive a collapse on a medium-or-wider window,
  /// and on a compact one.
  final int? maxVisible;
  final int? maxVisibleCompact;

  /// The mark between crumbs. The icon MIRRORS in Arabic — a chevron
  /// carries `matchTextDirection`; a slash does not need to, because
  /// the `Row` has already reversed the order round it.
  final IconData? separatorIcon;

  /// Wins over [separatorIcon]. For a slash, a dot, an arrow.
  final String? separatorText;

  final double? separatorSize;
  final Color? separatorColor;
  final double? separatorGap;

  /// A crumb that goes somewhere. Null takes the palette's link colour.
  final Color? linkColor;

  /// The current page. Null takes the palette's primary TEXT — it is
  /// where you are, not somewhere to go.
  final Color? currentColor;

  final Color? disabledColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final FontWeight? currentFontWeight;
  final double? iconSize;
  final double? iconGap;
  final EdgeInsets? itemPadding;
  final double? itemRadius;
  final Color? hoverColor;
  final Color? focusColor;

  /// A label too long for its share of the row SCROLLS rather than
  /// trailing off — the same call the bottom nav's destinations make.
  final bool? marqueeLabels;
  final MarqueeStyle? marqueeStyle;

  final Duration? animationDuration;
  final bool? respectReducedMotion;
  final double? minHeight;

  /// Whether the ellipsis says HOW MANY crumbs it is holding. On: "…"
  /// alone tells a reader nothing about what is behind it, and the
  /// count is the cheapest thing that does.
  final bool? showHiddenCount;

  /// How wide the fade at each end of a SCROLLING trail is. Zero turns
  /// it off — and then nothing on screen says the trail scrolls.
  final double? edgeFade;

  /// Field-by-field override — anything set on [other] wins.
  BreadcrumbsStyle mergedWith(BreadcrumbsStyle? other) {
    if (other == null) return this;
    return BreadcrumbsStyle(
      overflow: other.overflow ?? overflow,
      maxVisible: other.maxVisible ?? maxVisible,
      maxVisibleCompact: other.maxVisibleCompact ?? maxVisibleCompact,
      separatorIcon: other.separatorIcon ?? separatorIcon,
      separatorText: other.separatorText ?? separatorText,
      separatorSize: other.separatorSize ?? separatorSize,
      separatorColor: other.separatorColor ?? separatorColor,
      separatorGap: other.separatorGap ?? separatorGap,
      linkColor: other.linkColor ?? linkColor,
      currentColor: other.currentColor ?? currentColor,
      disabledColor: other.disabledColor ?? disabledColor,
      fontSize: other.fontSize ?? fontSize,
      fontWeight: other.fontWeight ?? fontWeight,
      currentFontWeight: other.currentFontWeight ?? currentFontWeight,
      iconSize: other.iconSize ?? iconSize,
      iconGap: other.iconGap ?? iconGap,
      itemPadding: other.itemPadding ?? itemPadding,
      itemRadius: other.itemRadius ?? itemRadius,
      hoverColor: other.hoverColor ?? hoverColor,
      focusColor: other.focusColor ?? focusColor,
      marqueeLabels: other.marqueeLabels ?? marqueeLabels,
      marqueeStyle: other.marqueeStyle ?? marqueeStyle,
      animationDuration: other.animationDuration ?? animationDuration,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
      showHiddenCount: other.showHiddenCount ?? showHiddenCount,
      edgeFade: other.edgeFade ?? edgeFade,
      minHeight: other.minHeight ?? minHeight,
    );
  }

  BreadcrumbsStyle copyWith({
    BreadcrumbsOverflow? overflow,
    int? maxVisible,
    int? maxVisibleCompact,
    IconData? separatorIcon,
    String? separatorText,
    double? separatorSize,
    Color? separatorColor,
    double? separatorGap,
    Color? linkColor,
    Color? currentColor,
    Color? disabledColor,
    double? fontSize,
    FontWeight? fontWeight,
    FontWeight? currentFontWeight,
    double? iconSize,
    double? iconGap,
    EdgeInsets? itemPadding,
    double? itemRadius,
    Color? hoverColor,
    Color? focusColor,
    bool? marqueeLabels,
    MarqueeStyle? marqueeStyle,
    Duration? animationDuration,
    bool? respectReducedMotion,
    bool? showHiddenCount,
    double? edgeFade,
    double? minHeight,
  }) => BreadcrumbsStyle(
    overflow: overflow ?? this.overflow,
    maxVisible: maxVisible ?? this.maxVisible,
    maxVisibleCompact: maxVisibleCompact ?? this.maxVisibleCompact,
    separatorIcon: separatorIcon ?? this.separatorIcon,
    separatorText: separatorText ?? this.separatorText,
    separatorSize: separatorSize ?? this.separatorSize,
    separatorColor: separatorColor ?? this.separatorColor,
    separatorGap: separatorGap ?? this.separatorGap,
    linkColor: linkColor ?? this.linkColor,
    currentColor: currentColor ?? this.currentColor,
    disabledColor: disabledColor ?? this.disabledColor,
    fontSize: fontSize ?? this.fontSize,
    fontWeight: fontWeight ?? this.fontWeight,
    currentFontWeight: currentFontWeight ?? this.currentFontWeight,
    iconSize: iconSize ?? this.iconSize,
    iconGap: iconGap ?? this.iconGap,
    itemPadding: itemPadding ?? this.itemPadding,
    itemRadius: itemRadius ?? this.itemRadius,
    hoverColor: hoverColor ?? this.hoverColor,
    focusColor: focusColor ?? this.focusColor,
    marqueeLabels: marqueeLabels ?? this.marqueeLabels,
    marqueeStyle: marqueeStyle ?? this.marqueeStyle,
    animationDuration: animationDuration ?? this.animationDuration,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
    showHiddenCount: showHiddenCount ?? this.showHiddenCount,
    edgeFade: edgeFade ?? this.edgeFade,
    minHeight: minHeight ?? this.minHeight,
  );
}

// ---------------------------------------------------------------------------
// ResolvedBreadcrumbsStyle
// ---------------------------------------------------------------------------

/// [BreadcrumbsStyle] after `caller > theme > defaults > palette`. Every
/// themed field is non-null, so build code reads `rs.linkColor` with no
/// `??` ladder behind it.
@immutable
class ResolvedBreadcrumbsStyle {
  const ResolvedBreadcrumbsStyle({
    required this.overflow,
    required this.maxVisible,
    required this.maxVisibleCompact,
    required this.separatorIcon,
    required this.separatorText,
    required this.separatorSize,
    required this.separatorColor,
    required this.separatorGap,
    required this.linkColor,
    required this.currentColor,
    required this.disabledColor,
    required this.fontSize,
    required this.fontWeight,
    required this.currentFontWeight,
    required this.iconSize,
    required this.iconGap,
    required this.itemPadding,
    required this.itemRadius,
    required this.hoverColor,
    required this.focusColor,
    required this.marqueeLabels,
    required this.marqueeStyle,
    required this.animationDuration,
    required this.respectReducedMotion,
    required this.minHeight,
    required this.showHiddenCount,
    required this.edgeFade,
  });

  final BreadcrumbsOverflow overflow;
  final int maxVisible;
  final int maxVisibleCompact;

  /// Null when [separatorText] is set — a mark is one or the other.
  final IconData? separatorIcon;
  final String? separatorText;

  final double separatorSize;
  final Color separatorColor;
  final double separatorGap;
  final Color linkColor;
  final Color currentColor;
  final Color disabledColor;
  final double fontSize;
  final FontWeight fontWeight;
  final FontWeight currentFontWeight;
  final double iconSize;
  final double iconGap;
  final EdgeInsets itemPadding;
  final double itemRadius;
  final Color hoverColor;
  final Color focusColor;
  final bool marqueeLabels;
  final MarqueeStyle marqueeStyle;
  final Duration animationDuration;
  final bool respectReducedMotion;
  final double minHeight;
  final bool showHiddenCount;
  final double edgeFade;

  /// How many crumbs survive a collapse in THIS window.
  int visibleFor({required bool compact}) =>
      compact ? maxVisibleCompact : maxVisible;
}
