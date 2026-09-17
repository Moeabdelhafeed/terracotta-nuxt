import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// DrawerItem
// ---------------------------------------------------------------------------

/// A single row in the drawer's navigation.
@immutable
class DrawerItem {
  const DrawerItem({
    required this.title,
    this.icon,
    this.trailing,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.badge,
    this.subtitle,
    this.children,
    this.initiallyExpanded = false,
    this.showDot = false,
    this.dotColor,
    this.avatar,
    this.pinned = false,
    this.swipeActions,
    this.semanticLabel,
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  /// Text badge ("5", "NEW").
  final String? badge;
  final String? subtitle;

  /// Sub-items for an expandable tree menu.
  final List<DrawerItem>? children;

  /// Whether those children start expanded.
  final bool initiallyExpanded;

  /// Small unread dot. Ignored when [badge] is set — they occupy the
  /// same corner and a badge already says everything a dot would.
  final bool showDot;

  /// Colour for that dot. Null takes the selected colour.
  final Color? dotColor;

  /// Leading avatar/image instead of [icon]. Takes priority over it.
  final Widget? avatar;

  /// Stays at the top of the scroll area.
  final bool pinned;

  /// Actions revealed by swiping the row sideways.
  final List<DrawerSwipeAction>? swipeActions;

  /// Spoken label. Null builds one from [title] plus what the row
  /// carries — the subtitle, the badge and the unread dot are all
  /// visible to a sighted user and have to be spoken to everyone else.
  final String? semanticLabel;

  bool get hasChildren => children != null && children!.isNotEmpty;
  bool get hasSwipeActions => swipeActions != null && swipeActions!.isNotEmpty;

  /// Everything the row shows, as one string.
  String spokenLabel() {
    final parts = <String>[title];
    if (subtitle != null) parts.add(subtitle!);
    if (badge != null) parts.add(badge!);
    return parts.join(', ');
  }
}

/// An action revealed when a drawer row is swiped.
@immutable
class DrawerSwipeAction {
  const DrawerSwipeAction({
    required this.icon,
    required this.color,
    this.onTap,
    this.label,
  });

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  /// Shown under the glyph, and spoken. Without it the action is a
  /// coloured square to a screen reader.
  final String? label;
}

/// A titled group of rows.
@immutable
class DrawerSection {
  const DrawerSection({
    this.title,
    this.items = const [],
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.divider,
    this.showItemCount = false,
  });

  final String? title;
  final List<DrawerItem> items;

  /// Tapping the title collapses/expands the group.
  final bool collapsible;

  /// Whether a collapsible group starts expanded.
  final bool initiallyExpanded;

  /// Divider above this section, overriding
  /// [DrawerStyle.sectionDivider].
  final Widget? divider;

  /// Shows "(3)" beside the title.
  final bool showItemCount;
}

/// An entry in the account switcher header.
@immutable
class DrawerAccount {
  const DrawerAccount({
    required this.name,
    this.email,
    this.avatar,
    this.onTap,
    this.selected = false,
  });

  final String name;
  final String? email;
  final ImageProvider? avatar;
  final VoidCallback? onTap;
  final bool selected;
}

// ---------------------------------------------------------------------------
// DrawerDefaults
// ---------------------------------------------------------------------------

/// Every hard-coded number the drawer paints with.
///
/// These were 45 private `_k` constants declared INSIDE `GlobalDrawer`
/// and referenced as `GlobalDrawer._kFoo` from every helper — invisible
/// to the style bag, unreachable from a test, and impossible to override.
/// Values an app would REBRAND live in [DrawerStyle]; what stays here is
/// geometry that only changes when the module itself changes.
abstract final class DrawerDefaults {
  // ─── Shell ────────────────────────────────────────────────
  static const double miniWidth = 72;
  static const double hPad = 12;
  static const double fallbackRadius = 16;
  static const double borderWidth = 2;
  static const EdgeInsets floatingMargin = EdgeInsets.all(12);

  /// Width per breakpoint when [DrawerStyle.width] is null. Phones get a
  /// tighter drawer; tablets and laptops widen for readability and to
  /// mirror the rail feel `GlobalScaffold` uses at those sizes.
  static const double widthCompact = 280;
  static const double widthMedium = 320;
  static const double widthExpanded = 360;
  static const double widthExtraLarge = 400;

  // ─── Header ───────────────────────────────────────────────
  static const double headerHPad = 20;
  static const double headerVPad = 24;

  // ─── Rows ─────────────────────────────────────────────────
  static const double itemVPad = 4;
  static const double itemHPad = 14;
  static const double itemRadius = 12;
  static const double iconSize = 22;
  static const double iconSpacing = 14;
  static const double childIndent = 40;
  static const double chevronSize = 18;
  static const double selectedBgOpacity = 0.1;
  static const double subtitleFontSize = 12;
  static const double subtitleOpacity = 0.6;
  static const double compactVPad = 2;
  static const double compactItemVPad = 6;

  // ─── Section headers ──────────────────────────────────────
  static const double sectionTitlePad = 12;
  static const double sectionTitleFontSize = 11;
  static const double collapseChevronSize = 16;
  static const double dividerHeight = 24;
  static const double dividerIndent = 16;
  static const double itemCountFontSize = 10;
  static const double itemCountOpacity = 0.35;
  static const double itemCountGap = 6;
  static const double sectionHeaderRadius = 8;

  /// Gap before a row's trailing widget.
  static const double trailingGap = 8;

  // ─── Rail corner offsets ──────────────────────────────────
  //
  // The badge's own geometry — font, radius, padding, dot size — lives
  // in `GlobalBadge` now. What stays here is where the rail hangs one.
  static const double miniDotOffset = -2;
  static const double miniBadgeTopOffset = -4;
  static const double miniBadgeEndOffset = -8;

  /// Opacity of a section header, and of the collapse chevron beside it.
  static const double sectionTitleOpacity = 0.4;
  static const double chevronOpacity = 0.3;

  // ─── Shadow (floating mode) ───────────────────────────────
  static const double shadowOpacityDark = 0.4;
  static const double shadowOpacityLight = 0.15;
  static const double shadowBlur = 20;

  // ─── Avatars ──────────────────────────────────────────────
  static const double accountRingWidth = 2;
  static const double avatarSize = 32;
  static const double avatarSpacing = 12;
  static const double accountAvatarSize = 40;
  static const double accountSmallAvatarSize = 32;
  static const double accountSwitcherSpacing = 8;

  // ─── Search ───────────────────────────────────────────────
  static const double searchPad = 12;
  static const double searchRadius = 10;
  static const double searchEmptyGap = 4;

  // ─── Swipe actions ────────────────────────────────────────
  static const double swipeActionWidth = 64;

  /// Fraction of the revealed width a drag must cross to stay open.
  static const double swipeThreshold = 0.3;

  static const double actionIconSize = 20;
  static const double actionLabelSize = 10;
  static const double actionLabelGap = 2;

  /// Open/close of the swipe tray, and the expand/collapse chevron.
  static const Duration animDuration = AppDurations.quick;

  // ─── Mini / rail ──────────────────────────────────────────
  static const double miniIconPad = 16;
  static const Duration miniTooltipWait = Duration(milliseconds: 500);

  // ─── Loading skeleton ─────────────────────────────────────
  static const int skeletonItems = 6;
  static const double skeletonTitleWidth = 120;
  static const double skeletonSubtitleWidth = 80;
  static const double skeletonIconSize = 24;
  static const double skeletonItemHeight = 16;
  static const double skeletonSubHeight = 12;
  static const double skeletonGap = 6;

  // ─── Empty state ──────────────────────────────────────────
  static const double emptyIconSize = 48;
  static const double emptyIconOpacity = 0.3;
  static const double emptyTextOpacity = 0.5;
  static const double emptySubtextOpacity = 0.35;
  static const double emptySpacing = 12;

  // ─── Footer ───────────────────────────────────────────────
  static const double footerActionsSpacing = 8;
  static const double footerActionsPad = 12;

  // ─── Motion ───────────────────────────────────────────────
  static const Duration entranceDuration = AppDurations.slow;
  static const Duration expandDuration = AppDurations.quick;
  static const Duration accountAnimDuration = AppDurations.quick;

  /// Share of the entrance each row is delayed by, so they arrive in
  /// sequence rather than together.
  static const double entranceStaggerFraction = 0.15;
}

// ---------------------------------------------------------------------------
// DrawerStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for [GlobalDrawer] — EVERY field nullable.
///
/// Resolution order, materialized once per build by `resolve`:
/// `caller > GlobalDrawerTheme.style > DrawerStyle.defaults > tokens`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], `ResolvedDrawerStyle` and `GlobalDrawerTheme.lerp`.
@immutable
class DrawerStyle {
  const DrawerStyle({
    this.backgroundColor,
    this.backgroundGradient,
    this.width,
    this.borderRadius,
    this.selectedColor,
    this.selectedBgOpacity,
    this.iconSize,
    this.itemBorderRadius,
    this.itemPadding,
    this.headerPadding,
    this.dividerIndent,
    this.border,
    this.borderGradient,
    this.borderWidth,
    this.floating,
    this.floatingMargin,
    this.useDeviceRadius,
    this.sectionDivider,
    this.animateItems,
    this.entranceAnimationDuration,
    this.expandAnimationDuration,
    this.compact,
    this.scrimColor,
    this.enableHaptic,
  });

  /// Compile-time floor. Colours are deliberately absent: they come from
  /// `context.<group>Colors` at resolve time so the drawer tracks the
  /// active palette, role, brightness and saturation.
  static const DrawerStyle defaults = DrawerStyle(
    selectedBgOpacity: DrawerDefaults.selectedBgOpacity,
    iconSize: DrawerDefaults.iconSize,
    dividerIndent: DrawerDefaults.dividerIndent,
    borderWidth: DrawerDefaults.borderWidth,
    floating: false,
    floatingMargin: DrawerDefaults.floatingMargin,
    useDeviceRadius: true,
    animateItems: false,
    entranceAnimationDuration: DrawerDefaults.entranceDuration,
    expandAnimationDuration: DrawerDefaults.expandDuration,
    compact: false,
    enableHaptic: true,
  );

  final Color? backgroundColor;
  final Gradient? backgroundGradient;

  /// Null takes a bucket-aware width — see `DrawerDefaults.widthCompact`
  /// and friends.
  final double? width;

  final BorderRadius? borderRadius;
  final Color? selectedColor;
  final double? selectedBgOpacity;
  final double? iconSize;
  final BorderRadius? itemBorderRadius;
  final EdgeInsetsGeometry? itemPadding;
  final EdgeInsetsGeometry? headerPadding;
  final double? dividerIndent;

  final Border? border;

  /// Gradient stroke. Painted as an outer box with [borderWidth] of
  /// inset, since `BoxDecoration` cannot stroke a gradient.
  final Gradient? borderGradient;
  final double? borderWidth;

  /// Floats clear of the screen edges by [floatingMargin].
  final bool? floating;
  final EdgeInsets? floatingMargin;

  /// With no explicit [borderRadius], follows the device's own screen
  /// corner radius.
  final bool? useDeviceRadius;

  /// Divider between sections, overridable per section.
  final Widget? sectionDivider;

  /// Rows arrive in a staggered sequence when the drawer opens.
  /// Skipped under reduced motion.
  final bool? animateItems;

  final Duration? entranceAnimationDuration;
  final Duration? expandAnimationDuration;

  /// Tighter row padding for dense menus.
  final bool? compact;

  /// Backdrop behind the open drawer.
  ///
  /// CALLER-APPLIED, like `AppBarStyle.toolbarHeight`. The backdrop is
  /// `Scaffold.drawerScrimColor` — the `Scaffold` paints it, not the
  /// `Drawer` — so this bag can carry the value but cannot install it.
  /// It rode along unread for a long time because nothing said so.
  ///
  /// Hand it over with `GlobalDrawer.scrimOf`:
  ///
  /// ```dart
  /// Scaffold(
  ///   drawerScrimColor: GlobalDrawer.scrimOf(myDrawer),
  ///   drawer: myDrawer,
  /// )
  /// ```
  final Color? scrimColor;

  /// Haptic on row selection. Per-call > theme > true, matching every
  /// other module.
  final bool? enableHaptic;

  /// Field-by-field override — [other]'s non-null fields win.
  DrawerStyle mergedWith(DrawerStyle? other) {
    if (other == null) return this;
    return DrawerStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      backgroundGradient: other.backgroundGradient ?? backgroundGradient,
      width: other.width ?? width,
      borderRadius: other.borderRadius ?? borderRadius,
      selectedColor: other.selectedColor ?? selectedColor,
      selectedBgOpacity: other.selectedBgOpacity ?? selectedBgOpacity,
      iconSize: other.iconSize ?? iconSize,
      itemBorderRadius: other.itemBorderRadius ?? itemBorderRadius,
      itemPadding: other.itemPadding ?? itemPadding,
      headerPadding: other.headerPadding ?? headerPadding,
      dividerIndent: other.dividerIndent ?? dividerIndent,
      border: other.border ?? border,
      borderGradient: other.borderGradient ?? borderGradient,
      borderWidth: other.borderWidth ?? borderWidth,
      floating: other.floating ?? floating,
      floatingMargin: other.floatingMargin ?? floatingMargin,
      useDeviceRadius: other.useDeviceRadius ?? useDeviceRadius,
      sectionDivider: other.sectionDivider ?? sectionDivider,
      animateItems: other.animateItems ?? animateItems,
      entranceAnimationDuration:
          other.entranceAnimationDuration ?? entranceAnimationDuration,
      expandAnimationDuration:
          other.expandAnimationDuration ?? expandAnimationDuration,
      compact: other.compact ?? compact,
      scrimColor: other.scrimColor ?? scrimColor,
      enableHaptic: other.enableHaptic ?? enableHaptic,
    );
  }

  DrawerStyle copyWith({
    Color? backgroundColor,
    Gradient? backgroundGradient,
    double? width,
    BorderRadius? borderRadius,
    Color? selectedColor,
    double? selectedBgOpacity,
    double? iconSize,
    BorderRadius? itemBorderRadius,
    EdgeInsetsGeometry? itemPadding,
    EdgeInsetsGeometry? headerPadding,
    double? dividerIndent,
    Border? border,
    Gradient? borderGradient,
    double? borderWidth,
    bool? floating,
    EdgeInsets? floatingMargin,
    bool? useDeviceRadius,
    Widget? sectionDivider,
    bool? animateItems,
    Duration? entranceAnimationDuration,
    Duration? expandAnimationDuration,
    bool? compact,
    Color? scrimColor,
    bool? enableHaptic,
  }) => DrawerStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    width: width ?? this.width,
    borderRadius: borderRadius ?? this.borderRadius,
    selectedColor: selectedColor ?? this.selectedColor,
    selectedBgOpacity: selectedBgOpacity ?? this.selectedBgOpacity,
    iconSize: iconSize ?? this.iconSize,
    itemBorderRadius: itemBorderRadius ?? this.itemBorderRadius,
    itemPadding: itemPadding ?? this.itemPadding,
    headerPadding: headerPadding ?? this.headerPadding,
    dividerIndent: dividerIndent ?? this.dividerIndent,
    border: border ?? this.border,
    borderGradient: borderGradient ?? this.borderGradient,
    borderWidth: borderWidth ?? this.borderWidth,
    floating: floating ?? this.floating,
    floatingMargin: floatingMargin ?? this.floatingMargin,
    useDeviceRadius: useDeviceRadius ?? this.useDeviceRadius,
    sectionDivider: sectionDivider ?? this.sectionDivider,
    animateItems: animateItems ?? this.animateItems,
    entranceAnimationDuration:
        entranceAnimationDuration ?? this.entranceAnimationDuration,
    expandAnimationDuration:
        expandAnimationDuration ?? this.expandAnimationDuration,
    compact: compact ?? this.compact,
    scrimColor: scrimColor ?? this.scrimColor,
    enableHaptic: enableHaptic ?? this.enableHaptic,
  );
}

/// Luminance above which a swipe action's tile counts as light.
const double _kOnActionLuminance = 0.5;

// ---------------------------------------------------------------------------
// ResolvedDrawerStyle
// ---------------------------------------------------------------------------

/// Materialized [DrawerStyle] — every themed field non-null.
///
/// Built once per build by `DrawerStyleResolve.resolve`, so widget code
/// reads `rs.selectedColor` directly instead of re-deriving
/// `?? cs.primary` ladders at each of a hundred use sites.
@immutable
class ResolvedDrawerStyle {
  const ResolvedDrawerStyle({
    required this.backgroundColor,
    required this.width,
    required this.selectedColor,
    required this.selectedBgOpacity,
    required this.iconSize,
    required this.itemBorderRadius,
    required this.itemPadding,
    required this.headerPadding,
    required this.dividerIndent,
    required this.borderWidth,
    required this.floating,
    required this.floatingMargin,
    required this.useDeviceRadius,
    required this.animateItems,
    required this.entranceAnimationDuration,
    required this.expandAnimationDuration,
    required this.compact,
    required this.enableHaptic,
    required this.titleColor,
    required this.subtitleColor,
    required this.iconColor,
    required this.badgeTextColor,
    required this.searchFillColor,
    this.backgroundGradient,
    this.borderRadius,
    this.border,
    this.borderGradient,
    this.sectionDivider,
  });

  final Color backgroundColor;
  final double width;
  final Color selectedColor;
  final double selectedBgOpacity;
  final double iconSize;
  final BorderRadius itemBorderRadius;
  final EdgeInsetsGeometry itemPadding;
  final EdgeInsetsGeometry headerPadding;
  final double dividerIndent;
  final double borderWidth;
  final bool floating;
  final EdgeInsets floatingMargin;
  final bool useDeviceRadius;
  final bool animateItems;
  final Duration entranceAnimationDuration;
  final Duration expandAnimationDuration;
  final bool compact;
  final bool enableHaptic;

  /// Foregrounds, resolved from the palette rather than derived from
  /// `ColorScheme` at each use site.
  final Color titleColor;
  final Color subtitleColor;
  final Color iconColor;
  final Color badgeTextColor;

  /// Fill behind the search field. A drawer already sits on a raised
  /// surface, so the field needs one raised again or it disappears.
  final Color searchFillColor;

  /// Muted foreground for section headers, counts and empty states.
  ///
  /// One derivation instead of the seven different
  /// `onSurface.withValues(alpha: …)` literals that used to be scattered
  /// through the file, each a slightly different grey.
  Color muted(double opacity) => titleColor.withValues(alpha: opacity);

  /// Foreground for a caller-supplied surface of arbitrary colour — a
  /// swipe action's tile. White is right on a saturated action and
  /// invisible on a pale one, so it follows the surface's luminance
  /// rather than assuming.
  Color onAction(Color surface) =>
      surface.computeLuminance() > _kOnActionLuminance
      ? titleColor
      : badgeTextColor;

  // Genuinely opt-in — absent means "do not paint this at all".
  final Gradient? backgroundGradient;
  final BorderRadius? borderRadius;
  final Border? border;
  final Gradient? borderGradient;
  final Widget? sectionDivider;

  /// Tint behind the selected row.
  Color get selectedBackground =>
      selectedColor.withValues(alpha: selectedBgOpacity);

  /// True when the drawer needs a decorated container of its own.
  bool get paintsOwnBackground =>
      backgroundGradient != null || border != null || borderGradient != null;
}
