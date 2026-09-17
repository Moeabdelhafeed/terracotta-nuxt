import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// GlobalTabItem
// ---------------------------------------------------------------------------

/// A single tab.
@immutable
class GlobalTabItem {
  const GlobalTabItem({
    required this.label,
    this.icon,
    this.activeIcon,
    this.customIcon,
    this.activeCustomIcon,
    this.badge,
    this.showDot = false,
    this.dotColor,
    this.disabled = false,
    this.onDisabledTap,
    this.closeable = false,
    this.onClose,
    this.count,
    this.semanticLabel,
  });

  /// Tab label text.
  final String label;

  /// Icon shown beside or above the label.
  final IconData? icon;

  /// Icon shown while this tab is selected. Falls back to [icon].
  final IconData? activeIcon;

  /// Arbitrary widget in place of [icon] (image, avatar, …).
  final Widget? customIcon;

  /// Arbitrary widget shown while selected. Falls back to [customIcon].
  final Widget? activeCustomIcon;

  /// Badge text ("5", "NEW").
  final String? badge;

  /// Small unread dot. Ignored when [badge] is set — they occupy the
  /// same corner, and a badge already says everything a dot would.
  final bool showDot;

  /// Colour for that dot. Null takes the indicator colour.
  final Color? dotColor;

  /// Greyed out, and never becomes the selection.
  final bool disabled;

  /// Runs when a [disabled] tab is tapped.
  ///
  /// The tab still refuses to be selected — this is the hook for saying
  /// WHY, which is usually the more useful answer: a paywall sheet, an
  /// upgrade prompt, a toast explaining what unlocks it. A locked tab
  /// that silently ignores you is a dead end, and users tap it twice
  /// before deciding the app is broken.
  ///
  /// Mirrors `GlobalIconButton.onDisabledPressed`. The tab stays
  /// disabled to assistive tech: it is genuinely not selectable, and
  /// saying otherwise would promise a page that never arrives.
  final VoidCallback? onDisabledTap;

  /// Renders a close affordance on the tab.
  final bool closeable;

  /// Called when that affordance is used.
  final VoidCallback? onClose;

  /// Small count rendered after the label ("Inbox 12").
  final int? count;

  /// Spoken label. Null builds one from [label] plus whatever the tab
  /// carries — the badge, the count and the disabled state are all
  /// visible to a sighted user and must be spoken to everyone else.
  final String? semanticLabel;

  /// Icon for the given selection state, with the documented fallback.
  ///
  /// Both active forms used to be dead: the tab was built once as a
  /// static widget handed to `TabBar`, which knows nothing about
  /// selection, so `activeIcon` never rendered anywhere and
  /// `activeCustomIcon` was not read at all.
  Widget? iconFor({required bool selected, required double size}) {
    if (customIcon != null) {
      return selected ? (activeCustomIcon ?? customIcon) : customIcon;
    }
    final data = selected ? (activeIcon ?? icon) : icon;
    return data == null ? null : Icon(data, size: size);
  }
}

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

/// Indicator painted for the selected tab.
enum TabIndicatorStyle {
  /// Underline below the tab.
  underline,

  /// Pill-shaped tint behind the tab.
  pill,

  /// Solid rounded rectangle filling the tab.
  filled,

  /// Small dot below the tab.
  dot,

  /// No indicator — colour change only.
  none,

  /// Gradient underline.
  gradientUnderline,
}

/// Icon placement relative to the label.
enum TabIconPosition {
  /// Icon at the reading start of the label.
  start,

  /// Icon above the label.
  top,
}

/// How the effective `isScrollable` is chosen for the active
/// `WindowSizeClass`.
enum TabAdaptiveMode {
  /// Honour [TabBarStyle.isScrollable] verbatim.
  manual,

  /// Scrollable on compact buckets; full-width fixed tabs above.
  scrollOnNarrow,
}

// ---------------------------------------------------------------------------
// TabBarDefaults
// ---------------------------------------------------------------------------

/// Every hard-coded number the tab bar paints with.
///
/// Values an app would REBRAND live in [TabBarStyle]; what stays here is
/// geometry that only changes when the module itself changes.
abstract final class TabBarDefaults {
  static const double height = 48;
  static const double compactHeight = 38;

  /// Material's `_kTabHeight` — the floor for a text-only tab.
  static const double textOnlyHeight = 46;

  /// Multiplier turning a label's font size into its line height, for
  /// the one layout whose height the module has to predict without a
  /// `BuildContext` (see `TabBarStyle.preferredHeightFor`).
  static const double labelLineFactor = 1.3;

  /// Breathing room above the icon and below the label in that layout.
  static const double stackedVerticalPad = 2;

  static const double tabHPad = 16;
  static const double compactTabHPad = 10;

  static const double iconSize = 20;
  static const double iconSpacing = 8;

  static const double selectedFontSize = 14;
  static const double unselectedFontSize = 14;
  static const FontWeight selectedFontWeight = FontWeight.w600;
  static const FontWeight unselectedFontWeight = FontWeight.w400;

  static const double indicatorWeight = 3;
  static const double indicatorRadius = 3;
  static const double pillRadius = 20;
  static const double pillOpacity = 0.1;

  static const double filledRadius = 8;
  static const double filledVPad = 6;
  static const double filledHPad = 14;

  static const double dotIndicatorSize = 5;
  static const double dotIndicatorMargin = 4;

  // ─── Badge + dot: where the tab HANGS one ─────────────────
  //
  // The badge's own geometry — font, radius, padding, dot size — lives
  // in `GlobalBadge`. Only the corner offsets are the tab bar's.
  static const double badgeTopOffset = -8;
  static const double badgeEndOffset = -12;

  /// Room reclaimed at the tab's end so a corner badge does not overlap
  /// the next tab's label.
  static const double badgeGutter = 8;

  static const double dotTopOffset = -4;
  static const double dotEndOffset = -8;

  // ─── Close affordance ─────────────────────────────────────

  /// Painted glyph.
  static const double closeIconSize = 16;

  /// Hit box around it.
  ///
  /// Deliberately NOT the app's 48dp target: a 48dp control inside a
  /// 48dp-tall tab is the tab, and every closeable tab would be forced
  /// wide enough to hold one. 32 clears WCAG 2.5.8 (24×24 minimum) with
  /// room to spare, against the 16dp bare `GestureDetector` this
  /// replaced — which cleared nothing. [TabBarStyle.closeButtonSize]
  /// raises it per call site.
  static const double closeButtonSize = 32;
  static const double closeGap = 2;

  static const double countFontSize = 11;
  static const double countGap = 4;
  static const double countOpacity = 0.45;

  // ─── Interaction overlays ─────────────────────────────────

  /// Focus is the strongest of the three on purpose: Material's ~10%
  /// default vanished on a tab, which is a transparent surface with an
  /// indicator already pulling the eye.
  static const double focusOverlayOpacity = 0.24;
  static const double pressedOverlayOpacity = 0.12;
  static const double hoverOverlayOpacity = 0.08;

  static const double disabledOpacity = 0.4;
  static const double dividerOpacity = 0.25;
  static const double dividerHeight = 1;

  static const double borderWidth = 2;
  static const double leadingTrailingPad = 8;

  /// Scale an icon shrinks to at the bottom of a [TabBarStyle.bounceOnTap]
  /// press, and how long the whole bounce lasts.
  static const double bounceScale = 0.88;
  static const Duration bounceDuration = AppDurations.micro;
}

// ---------------------------------------------------------------------------
// TabBarStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for [GlobalTabBar] — EVERY field nullable.
///
/// Resolution order, materialized once per build by `resolve`:
/// `caller > GlobalTabBarTheme.style > TabBarStyle.defaults > tokens`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], `ResolvedTabBarStyle` and `GlobalTabBarTheme.lerp`.
@immutable
class TabBarStyle {
  const TabBarStyle({
    this.backgroundColor,
    this.backgroundGradient,
    this.indicatorStyle,
    this.indicatorColor,
    this.indicatorGradient,
    this.indicatorWeight,
    this.indicatorRadius,
    this.pillRadius,
    this.pillOpacity,
    this.selectedColor,
    this.unselectedColor,
    this.disabledColor,
    this.onIndicatorColor,
    this.selectedFontSize,
    this.unselectedFontSize,
    this.selectedFontWeight,
    this.unselectedFontWeight,
    this.iconSize,
    this.iconPosition,
    this.iconSpacing,
    this.isScrollable,
    this.adaptiveMode,
    this.tabPadding,
    this.height,
    this.border,
    this.borderGradient,
    this.borderWidth,
    this.borderRadius,
    this.shadow,
    this.dividerColor,
    this.dividerHeight,
    this.showDivider,
    this.compact,
    this.enableHaptic,
    this.bounceOnTap,
    this.closeIconSize,
    this.closeButtonSize,
    this.badgeColor,
    this.badgeTextColor,
    this.focusColor,
  });

  /// Compile-time floor. Colours are deliberately absent: they come from
  /// `context.<group>Colors` at resolve time so the bar tracks the
  /// active palette, role, brightness and saturation.
  static const TabBarStyle defaults = TabBarStyle(
    indicatorStyle: TabIndicatorStyle.underline,
    indicatorWeight: TabBarDefaults.indicatorWeight,
    indicatorRadius: TabBarDefaults.indicatorRadius,
    pillRadius: TabBarDefaults.pillRadius,
    pillOpacity: TabBarDefaults.pillOpacity,
    selectedFontSize: TabBarDefaults.selectedFontSize,
    unselectedFontSize: TabBarDefaults.unselectedFontSize,
    selectedFontWeight: TabBarDefaults.selectedFontWeight,
    unselectedFontWeight: TabBarDefaults.unselectedFontWeight,
    iconSize: TabBarDefaults.iconSize,
    iconPosition: TabIconPosition.start,
    iconSpacing: TabBarDefaults.iconSpacing,
    isScrollable: false,
    adaptiveMode: TabAdaptiveMode.manual,
    borderWidth: TabBarDefaults.borderWidth,
    dividerHeight: TabBarDefaults.dividerHeight,
    showDivider: false,
    compact: false,
    enableHaptic: true,
    bounceOnTap: false,
    closeIconSize: TabBarDefaults.closeIconSize,
    closeButtonSize: TabBarDefaults.closeButtonSize,
  );

  /// Null paints no background at all — the bar sits on whatever is
  /// behind it, which is what an `AppBar.bottom` wants.
  final Color? backgroundColor;
  final Gradient? backgroundGradient;

  final TabIndicatorStyle? indicatorStyle;

  /// Null takes [selectedColor].
  final Color? indicatorColor;

  /// Only read by [TabIndicatorStyle.gradientUnderline].
  final Gradient? indicatorGradient;

  final double? indicatorWeight;
  final double? indicatorRadius;
  final double? pillRadius;
  final double? pillOpacity;

  final Color? selectedColor;
  final Color? unselectedColor;

  /// Label + glyph colour for a disabled tab. Null takes
  /// `textColors.disabled`.
  final Color? disabledColor;

  /// Label colour ON TOP of a [TabIndicatorStyle.filled] indicator,
  /// whose whole surface is [indicatorColor]. Null takes
  /// `textColors.onPrimary` — this used to be a hard-coded
  /// `Colors.white`, which is wrong for any light-primary brand.
  final Color? onIndicatorColor;

  final double? selectedFontSize;
  final double? unselectedFontSize;
  final FontWeight? selectedFontWeight;
  final FontWeight? unselectedFontWeight;

  final double? iconSize;
  final TabIconPosition? iconPosition;
  final double? iconSpacing;

  final bool? isScrollable;
  final TabAdaptiveMode? adaptiveMode;

  /// Around each tab's content. Directional so RTL mirrors it.
  final EdgeInsetsGeometry? tabPadding;

  /// CALLER-ONLY — do not set this through `GlobalTabBarTheme`.
  ///
  /// [GlobalTabBar] is a `PreferredSizeWidget`, and
  /// `PreferredSizeWidget.preferredSize` is a getter with no
  /// `BuildContext`, so it cannot read a theme. A themed height would
  /// change what the bar PAINTS while `preferredSize` kept reporting the
  /// old number, and the Scaffold would lay out to the wrong one.
  /// `GlobalTabBarTheme` asserts against it.
  final double? height;

  final Border? border;

  /// Gradient stroke. Painted as an outer box with [borderWidth] of
  /// inset, since `BoxDecoration` cannot stroke a gradient.
  final Gradient? borderGradient;
  final double? borderWidth;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadow;

  final Color? dividerColor;
  final double? dividerHeight;
  final bool? showDivider;

  /// Tighter row height and horizontal padding.
  final bool? compact;

  // There is deliberately no animationDuration / animationCurve here.
  // How long a tab change takes belongs to `TabController`
  // (`TabController(animationDuration:)`, default `kTabScrollDuration`),
  // which the CALLER owns — the bar is handed one and cannot change it.
  // Both fields existed on this bag for a while, merged and lerped and
  // resolved, and were never read by anything: the same dead-knob defect
  // this module's rewrite set out to remove. `GlobalTabView` has its own
  // `animationDuration` / `animationCurve`, which it does honour.

  /// Haptic on tab change. Per-call > theme > true, matching every other
  /// module — it used to default to OFF and be named `hapticFeedback`,
  /// so the app's `enableHaptic` preference did not reach it.
  final bool? enableHaptic;

  /// Scale-bounces the selected tab's icon on tap. Skipped under reduced
  /// motion.
  final bool? bounceOnTap;

  final double? closeIconSize;
  final double? closeButtonSize;

  final Color? badgeColor;
  final Color? badgeTextColor;

  /// Ink overlay while a tab holds KEYBOARD focus.
  ///
  /// Null derives it from the indicator colour at
  /// [TabBarDefaults.focusOverlayOpacity]. One value for every tab, so
  /// focus does not look different depending on which tab holds it.
  final Color? focusColor;

  /// Field-by-field override — [other]'s non-null fields win.
  TabBarStyle mergedWith(TabBarStyle? other) {
    if (other == null) return this;
    return TabBarStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      backgroundGradient: other.backgroundGradient ?? backgroundGradient,
      indicatorStyle: other.indicatorStyle ?? indicatorStyle,
      indicatorColor: other.indicatorColor ?? indicatorColor,
      indicatorGradient: other.indicatorGradient ?? indicatorGradient,
      indicatorWeight: other.indicatorWeight ?? indicatorWeight,
      indicatorRadius: other.indicatorRadius ?? indicatorRadius,
      pillRadius: other.pillRadius ?? pillRadius,
      pillOpacity: other.pillOpacity ?? pillOpacity,
      selectedColor: other.selectedColor ?? selectedColor,
      unselectedColor: other.unselectedColor ?? unselectedColor,
      disabledColor: other.disabledColor ?? disabledColor,
      onIndicatorColor: other.onIndicatorColor ?? onIndicatorColor,
      selectedFontSize: other.selectedFontSize ?? selectedFontSize,
      unselectedFontSize: other.unselectedFontSize ?? unselectedFontSize,
      selectedFontWeight: other.selectedFontWeight ?? selectedFontWeight,
      unselectedFontWeight: other.unselectedFontWeight ?? unselectedFontWeight,
      iconSize: other.iconSize ?? iconSize,
      iconPosition: other.iconPosition ?? iconPosition,
      iconSpacing: other.iconSpacing ?? iconSpacing,
      isScrollable: other.isScrollable ?? isScrollable,
      adaptiveMode: other.adaptiveMode ?? adaptiveMode,
      tabPadding: other.tabPadding ?? tabPadding,
      height: other.height ?? height,
      border: other.border ?? border,
      borderGradient: other.borderGradient ?? borderGradient,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      shadow: other.shadow ?? shadow,
      dividerColor: other.dividerColor ?? dividerColor,
      dividerHeight: other.dividerHeight ?? dividerHeight,
      showDivider: other.showDivider ?? showDivider,
      compact: other.compact ?? compact,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      bounceOnTap: other.bounceOnTap ?? bounceOnTap,
      closeIconSize: other.closeIconSize ?? closeIconSize,
      closeButtonSize: other.closeButtonSize ?? closeButtonSize,
      badgeColor: other.badgeColor ?? badgeColor,
      badgeTextColor: other.badgeTextColor ?? badgeTextColor,
      focusColor: other.focusColor ?? focusColor,
    );
  }

  TabBarStyle copyWith({
    Color? backgroundColor,
    Gradient? backgroundGradient,
    TabIndicatorStyle? indicatorStyle,
    Color? indicatorColor,
    Gradient? indicatorGradient,
    double? indicatorWeight,
    double? indicatorRadius,
    double? pillRadius,
    double? pillOpacity,
    Color? selectedColor,
    Color? unselectedColor,
    Color? disabledColor,
    Color? onIndicatorColor,
    double? selectedFontSize,
    double? unselectedFontSize,
    FontWeight? selectedFontWeight,
    FontWeight? unselectedFontWeight,
    double? iconSize,
    TabIconPosition? iconPosition,
    double? iconSpacing,
    bool? isScrollable,
    TabAdaptiveMode? adaptiveMode,
    EdgeInsetsGeometry? tabPadding,
    double? height,
    Border? border,
    Gradient? borderGradient,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadow,
    Color? dividerColor,
    double? dividerHeight,
    bool? showDivider,
    bool? compact,
    bool? enableHaptic,
    bool? bounceOnTap,
    double? closeIconSize,
    double? closeButtonSize,
    Color? badgeColor,
    Color? badgeTextColor,
    Color? focusColor,
  }) => TabBarStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    indicatorStyle: indicatorStyle ?? this.indicatorStyle,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    indicatorGradient: indicatorGradient ?? this.indicatorGradient,
    indicatorWeight: indicatorWeight ?? this.indicatorWeight,
    indicatorRadius: indicatorRadius ?? this.indicatorRadius,
    pillRadius: pillRadius ?? this.pillRadius,
    pillOpacity: pillOpacity ?? this.pillOpacity,
    selectedColor: selectedColor ?? this.selectedColor,
    unselectedColor: unselectedColor ?? this.unselectedColor,
    disabledColor: disabledColor ?? this.disabledColor,
    onIndicatorColor: onIndicatorColor ?? this.onIndicatorColor,
    selectedFontSize: selectedFontSize ?? this.selectedFontSize,
    unselectedFontSize: unselectedFontSize ?? this.unselectedFontSize,
    selectedFontWeight: selectedFontWeight ?? this.selectedFontWeight,
    unselectedFontWeight: unselectedFontWeight ?? this.unselectedFontWeight,
    iconSize: iconSize ?? this.iconSize,
    iconPosition: iconPosition ?? this.iconPosition,
    iconSpacing: iconSpacing ?? this.iconSpacing,
    isScrollable: isScrollable ?? this.isScrollable,
    adaptiveMode: adaptiveMode ?? this.adaptiveMode,
    tabPadding: tabPadding ?? this.tabPadding,
    height: height ?? this.height,
    border: border ?? this.border,
    borderGradient: borderGradient ?? this.borderGradient,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    shadow: shadow ?? this.shadow,
    dividerColor: dividerColor ?? this.dividerColor,
    dividerHeight: dividerHeight ?? this.dividerHeight,
    showDivider: showDivider ?? this.showDivider,
    compact: compact ?? this.compact,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    bounceOnTap: bounceOnTap ?? this.bounceOnTap,
    closeIconSize: closeIconSize ?? this.closeIconSize,
    closeButtonSize: closeButtonSize ?? this.closeButtonSize,
    badgeColor: badgeColor ?? this.badgeColor,
    badgeTextColor: badgeTextColor ?? this.badgeTextColor,
    focusColor: focusColor ?? this.focusColor,
  );

  /// The height the bar reports to the Scaffold, WITHOUT a context.
  ///
  /// See [height] for why the theme cannot participate. [tabs] decides
  /// the stacked-icon case, which is the one layout whose height depends
  /// on the content rather than the style.
  /// Height of a tab that stacks its icon over its label.
  ///
  /// DERIVED, not a constant. `TabBar` lays this row out at its content
  /// height and simply ignores whatever the enclosing widget reported —
  /// so a fixed number could only ever be wrong in one of two ways: too
  /// small and the label paints past the bar's bottom edge, too large
  /// and the bar reserves a band of dead space above the icons. A frozen
  /// 68 was doing the first; Material's own 72 would do the second.
  ///
  /// Tracks the style, since every term is a style field.
  double get stackedHeight =>
      (iconSize ?? defaults.iconSize!) +
      (iconSpacing ?? defaults.iconSpacing!) +
      (selectedFontSize ?? defaults.selectedFontSize!) *
          TabBarDefaults.labelLineFactor +
      TabBarDefaults.stackedVerticalPad;

  double preferredHeightFor(List<GlobalTabItem> tabs) {
    // A shown divider is painted INSIDE the bar's box, so the space it
    // takes has to be reserved or it eats into the tabs.
    final divider = (showDivider ?? defaults.showDivider!)
        ? (dividerHeight ?? defaults.dividerHeight!)
        : 0.0;
    if (height != null) return height! + divider;

    final stacked =
        (iconPosition ?? defaults.iconPosition) == TabIconPosition.top;
    if (stacked && tabs.any((t) => t.icon != null || t.customIcon != null)) {
      return stackedHeight + divider;
    }
    return ((compact ?? defaults.compact!)
            ? TabBarDefaults.compactHeight
            : TabBarDefaults.height) +
        divider;
  }
}

// ---------------------------------------------------------------------------
// ResolvedTabBarStyle
// ---------------------------------------------------------------------------

/// Materialized [TabBarStyle] — every themed field non-null.
///
/// Built once per build by `TabBarStyleResolve.resolve`, so widget code
/// reads `rs.selectedColor` directly instead of re-deriving
/// `?? cs.primary` ladders at each use.
@immutable
class ResolvedTabBarStyle {
  const ResolvedTabBarStyle({
    required this.indicatorStyle,
    required this.indicatorColor,
    required this.indicatorWeight,
    required this.indicatorRadius,
    required this.pillRadius,
    required this.pillOpacity,
    required this.selectedColor,
    required this.unselectedColor,
    required this.disabledColor,
    required this.onIndicatorColor,
    required this.selectedFontSize,
    required this.unselectedFontSize,
    required this.selectedFontWeight,
    required this.unselectedFontWeight,
    required this.iconSize,
    required this.iconPosition,
    required this.iconSpacing,
    required this.isScrollable,
    required this.adaptiveMode,
    required this.tabPadding,
    required this.borderWidth,
    required this.dividerColor,
    required this.dividerHeight,
    required this.showDivider,
    required this.compact,
    required this.enableHaptic,
    required this.bounceOnTap,
    required this.closeIconSize,
    required this.closeButtonSize,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.focusColor,
    this.backgroundColor,
    this.backgroundGradient,
    this.indicatorGradient,
    this.height,
    this.border,
    this.borderGradient,
    this.borderRadius,
    this.shadow,
  });

  final TabIndicatorStyle indicatorStyle;
  final Color indicatorColor;
  final double indicatorWeight;
  final double indicatorRadius;
  final double pillRadius;
  final double pillOpacity;
  final Color selectedColor;
  final Color unselectedColor;
  final Color disabledColor;
  final Color onIndicatorColor;
  final double selectedFontSize;
  final double unselectedFontSize;
  final FontWeight selectedFontWeight;
  final FontWeight unselectedFontWeight;
  final double iconSize;
  final TabIconPosition iconPosition;
  final double iconSpacing;
  final bool isScrollable;
  final TabAdaptiveMode adaptiveMode;
  final EdgeInsetsGeometry tabPadding;
  final double borderWidth;
  final Color dividerColor;
  final double dividerHeight;
  final bool showDivider;
  final bool compact;
  final bool enableHaptic;
  final bool bounceOnTap;
  final double closeIconSize;
  final double closeButtonSize;
  final Color badgeColor;
  final Color badgeTextColor;
  final Color focusColor;

  // Genuinely opt-in — absent means "do not paint this at all".
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final Gradient? indicatorGradient;
  final double? height;
  final Border? border;
  final Gradient? borderGradient;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadow;

  /// True when the bar needs a decorated container of its own around the
  /// `TabBar`. Nothing set means nothing to paint, and the extra
  /// `Container` is skipped entirely.
  bool get paintsOwnBackground =>
      backgroundColor != null ||
      backgroundGradient != null ||
      borderRadius != null ||
      border != null ||
      borderGradient != null ||
      shadow != null;

  /// Height of a tab that stacks its icon over its label. See
  /// [TabBarStyle.stackedHeight] — same derivation, resolved values.
  double get stackedHeight =>
      iconSize +
      iconSpacing +
      selectedFontSize * TabBarDefaults.labelLineFactor +
      TabBarDefaults.stackedVerticalPad;

  /// The label sits ON the indicator, so the indicator's own foreground
  /// wins over the selected colour.
  Color get selectedLabelColor => indicatorStyle == TabIndicatorStyle.filled
      ? onIndicatorColor
      : selectedColor;
}
