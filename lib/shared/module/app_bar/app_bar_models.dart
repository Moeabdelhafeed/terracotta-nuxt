import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/constants/sizes/app_sizes.dart';
import '../buttons/button_models.dart' show LabelOverflow;
import '../marquee/marquee_models.dart';

// ---------------------------------------------------------------------------
// AppBarVariant
// ---------------------------------------------------------------------------

/// Visual style for the app bar.
enum AppBarVariant {
  /// Standard Material app bar.
  standard,

  /// Transparent with no elevation — overlays content.
  transparent,

  /// Gradient background.
  gradient,
}

// ---------------------------------------------------------------------------
// AppBarDefaults
// ---------------------------------------------------------------------------

/// Every hard-coded constant the app bar renders with.
///
/// These used to be private `_kFoo` fields duplicated across
/// `global_app_bar.dart` and `global_sliver_app_bar.dart`, where the two
/// copies were free to drift. Values that an app would REBRAND live in
/// [AppBarStyle] instead; what stays here is geometry that only changes
/// when the module itself changes.
abstract final class AppBarDefaults {
  /// Built-in back affordance.
  ///
  /// Matched to `kMinTouchTarget` on purpose. `MinTouchTarget` centres a
  /// button's PAINTED box inside a 48dp hit box, so a smaller painted
  /// box gains `(48 - size) / 2` of dead space on each side — the back
  /// button used to paint at 38 and therefore sat 9dp from the bar's
  /// edge while an unstyled action sat at 4dp, which read as mismatched
  /// padding. Same size, same gap. Override per call site via
  /// [AppBarStyle.backButtonSize] if a compact chip is wanted.
  static const double backButtonSize = 48;
  static const double backIconSize = 22;

  /// The bar's own buttons take the app's BUTTON corner, so they cannot
  /// drift from every other control. It was a standalone 10 — near
  /// enough to look deliberate, far enough to be a second number.
  static const double backButtonRadius = AppSizes.buttonRadiusMd;

  /// Leading icon rendered beside the title.
  static const double iconSize = 22;
  static const double iconSpacing = 10;

  static const double subtitleFontSize = 12;
  static const double subtitleOpacity = 0.7;

  /// Width Material reserves for the leading slot (`leadingWidth`
  /// defaults to `kToolbarHeight`), whatever widget sits in it.
  ///
  /// A centred title is centred in the band BETWEEN leading and
  /// actions, so a bar with a back button and no actions centres the
  /// title over a band that starts 56dp in — visibly off centre. The
  /// counterweight reserves the same width at the end.
  static const double leadingSlotWidth = kToolbarHeight;

  /// How far the bar's buttons sit from its edges — [actionEndPad] at
  /// the end, [leadingStartPad] at the start.
  ///
  /// THE SAME NUMBER, and a test holds them equal. Material centres the
  /// leading widget in a [leadingSlotWidth] slot, which put a 48-wide
  /// back button 4dp in while an action spacing itself off its
  /// neighbour sat at 8 — same button, same bar, two insets, and it
  /// reads as the arrow being nudged toward the edge.
  ///
  /// 48 + 8 is exactly [leadingSlotWidth], so pinning the button to the
  /// start fills the slot: neither the title's position nor the
  /// centred-title counterweight moves.
  static const double actionEndPad = 8;
  static const double leadingStartPad = actionEndPad;

  static const double leadingGap = 4;
  static const double titlePadCenter = 4;

  /// Search mode. There is deliberately no trailing pad: the field
  /// spans the whole bar so its clear button's touch box ends flush
  /// with the edge, instead of being pushed inward from where the
  /// action icons sit. No radius either — the field carries no fill and
  /// no border, so there is no shape left to round.
  static const double searchFieldPadding = 14;

  /// Dynamic-height layout (the custom one that replaces `AppBar`).
  static const double dynamicHPad = 12;
  static const double dynamicVPad = 12;
  static const double dynamicTopPadNoSafeArea = 8;

  /// Start inset for a start-aligned title with NO leading widget, in
  /// both the toolbar and the sliver's flexible space.
  ///
  /// `titleSpacing: 0` strips Material's own middle spacing so a title
  /// following a leading widget sits tight against it. With no leading
  /// there is nothing to sit against, and the title would touch the
  /// bar's edge — this is Material's 16dp put back, which also lands the
  /// text roughly under where an action's glyph sits.
  static const double titleStartPad = 16;

  /// Sliver variant.
  static const double expandedTitleFontSize = 16;
  static const double defaultExpandedHeight = 200;
  static const double titleBottomPad = 14;

  /// Collapsed background behind a light foreground (image / gradient
  /// headers), where the page surface would leave the title unreadable.
  static const Color darkCollapsedBackground = Color(0xFF1A1A2E);

  /// Luminance above which a foreground counts as light.
  static const double lightForegroundThreshold = 0.5;

  static const double elevation = 0;
  static const double borderWidth = 2;
  static const bool centerTitle = true;
  static const bool dynamicHeight = false;

  /// Multiplier turning [AppBarStyle.elevation] into a blur radius for
  /// the dynamic-height layout, which paints its own shadow.
  static const double dynamicShadowBlurFactor = 2;

  // ─── Hide-on-scroll ───────────────────────────────────────

  /// Scroll delta below which the bar holds still, so a jittery finger
  /// does not flicker it.
  /// The arrival. Longer than a control's own motion — it is a whole
  /// bar travelling.
  static const Duration entranceDuration = AppDurations.normal;
  static const Curve entranceCurve = Curves.easeOutCubic;

  /// How far above its resting place a sliding entrance starts, as a
  /// fraction of the bar's own height.
  static const double entranceSlide = 1;
  static const double entranceScaleFrom = 0.94;

  /// How much scrollable content a page needs before its bar is
  /// allowed to hide, as a multiple of the bar's own height.
  ///
  /// Hiding FREES the bar's height. On a page with barely more content
  /// than fits, that is enough to make the page unscrollable — so the
  /// bar hides, the scroll ends, and there is no gesture left that
  /// brings it back. The reader is stranded looking at a page with no
  /// chrome. Below this, the bar simply stays.
  static const double hideMinExtentFactor = 1.5;

  static const double hideOnScrollThreshold = 5;

  /// How long the bar takes to slide out and back.
  static const Duration hideOnScrollDuration = AppDurations.quick;

  /// Quiet time after the last scroll before the bar returns.
  static const Duration hideOnScrollIdleDelay = AppDurations.deliberate;
}

// ---------------------------------------------------------------------------
// AppBarStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for [GlobalAppBar] and `GlobalSliverAppBar` —
/// EVERY field nullable.
///
/// Resolution order, materialized once per build by `resolve`:
/// `caller > GlobalAppBarTheme.style > AppBarStyle.defaults > tokens`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedAppBarStyle] and `GlobalAppBarTheme.lerp`.
@immutable
class AppBarStyle {
  const AppBarStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.elevation,
    this.shadowColor,
    this.borderRadius,
    this.border,
    this.borderGradient,
    this.borderWidth,
    this.titleStyle,
    this.subtitleStyle,
    this.centerTitle,
    this.dynamicHeight,
    this.hideOnScroll,
    this.toolbarHeight,
    this.backButtonSize,
    this.backIconSize,
    this.buttonBackgroundColor,
    this.titleOverflow,
    this.marqueeTitle,
    this.balanceCenteredTitle,
  });

  /// Compile-time floor. Colors are deliberately absent: they come from
  /// `context.<group>Colors` at resolve time so they track the active
  /// palette, role and brightness.
  static const AppBarStyle defaults = AppBarStyle(
    elevation: AppBarDefaults.elevation,
    borderWidth: AppBarDefaults.borderWidth,
    centerTitle: AppBarDefaults.centerTitle,
    dynamicHeight: AppBarDefaults.dynamicHeight,
    backButtonSize: AppBarDefaults.backButtonSize,
    backIconSize: AppBarDefaults.backIconSize,
    titleOverflow: LabelOverflow.marquee,
    balanceCenteredTitle: true,
  );

  /// Null → derived from the variant (surface / transparent).
  final Color? backgroundColor;

  /// Null → derived from the variant (text primary, or white over a
  /// gradient or transparent bar).
  final Color? foregroundColor;

  /// Painted behind the bar when the variant is
  /// [AppBarVariant.gradient].
  final Gradient? gradient;

  final double? elevation;
  final Color? shadowColor;
  final BorderRadius? borderRadius;
  final Border? border;

  /// Gradient stroke. Painted as an outer container with [borderWidth]
  /// of inset, since `BoxDecoration` cannot stroke a gradient.
  final Gradient? borderGradient;
  final double? borderWidth;

  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final bool? centerTitle;

  /// Expands vertically to fit long titles/subtitles instead of
  /// truncating. Replaces Material's `AppBar` with a custom layout.
  final bool? dynamicHeight;

  /// Whether the bar RETREATS as the page is read.
  ///
  /// Null is AUTO, which means "when the window is short" — a landscape
  /// phone, where the bar is 56 points of a 402-point screen and the
  /// axis it eats is the one there is none of. `true` and `false` pin
  /// it either way for a page that knows better.
  ///
  /// Deliberately NOT part of `defaults`: a compile-time floor has no
  /// window to measure, and a `false` there would make the auto case
  /// unreachable. `resolve` is where the window is known.
  final bool? hideOnScroll;

  /// CALLER-ONLY — do not set this through [GlobalAppBarTheme].
  ///
  /// `PreferredSizeWidget.preferredSize` is a getter with no
  /// `BuildContext`, so it cannot read a theme. A theme-supplied height
  /// would change what the bar PAINTS while `preferredSize` kept
  /// reporting the old number, and the Scaffold would lay out to the
  /// wrong height. `GlobalAppBarTheme` asserts against it.
  final double? toolbarHeight;

  /// Painted size of the built-in back affordance.
  ///
  /// Defaults to the 48dp touch target so it lines up with an unstyled
  /// action button; anything smaller paints inset inside its own hit
  /// box and opens a visible gap the actions do not have.
  final double? backButtonSize;

  /// Glyph size inside the back affordance.
  final double? backIconSize;

  /// Plate painted BEHIND the bar's own leading / drawer buttons.
  ///
  /// Null leaves them bare, which is right on a bar with a surface of
  /// its own. A TRANSPARENT bar has none — its buttons sit directly on
  /// whatever the page draws there, and over an illustration a bare
  /// glyph competes with the lines behind it. Giving it the page's own
  /// colour reads as a gap in the drawing rather than a new control.
  final Color? buttonBackgroundColor;

  /// What a title or subtitle does when it does not fit.
  ///
  /// Defaults to [LabelOverflow.marquee]: an app bar has exactly one
  /// title, it is the page's name, and an ellipsis in it is unreadable
  /// with no way to see the rest. Reduced motion truncates.
  final LabelOverflow? titleOverflow;

  /// Tuning for that scroll. Null takes the marquee's own defaults.
  final MarqueeStyle? marqueeTitle;

  /// Reserves [AppBarDefaults.leadingSlotWidth] at the END when a
  /// centred title has a leading widget and no actions, so it centres on
  /// the BAR rather than on the band left over beside the back button.
  final bool? balanceCenteredTitle;

  /// Field-by-field override — [other]'s non-null fields win.
  AppBarStyle mergedWith(AppBarStyle? other) {
    if (other == null) return this;
    return AppBarStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      gradient: other.gradient ?? gradient,
      elevation: other.elevation ?? elevation,
      shadowColor: other.shadowColor ?? shadowColor,
      borderRadius: other.borderRadius ?? borderRadius,
      border: other.border ?? border,
      borderGradient: other.borderGradient ?? borderGradient,
      borderWidth: other.borderWidth ?? borderWidth,
      titleStyle: other.titleStyle ?? titleStyle,
      subtitleStyle: other.subtitleStyle ?? subtitleStyle,
      centerTitle: other.centerTitle ?? centerTitle,
      dynamicHeight: other.dynamicHeight ?? dynamicHeight,
      hideOnScroll: other.hideOnScroll ?? hideOnScroll,
      toolbarHeight: other.toolbarHeight ?? toolbarHeight,
      backButtonSize: other.backButtonSize ?? backButtonSize,
      backIconSize: other.backIconSize ?? backIconSize,
      buttonBackgroundColor:
          other.buttonBackgroundColor ?? buttonBackgroundColor,
      titleOverflow: other.titleOverflow ?? titleOverflow,
      marqueeTitle: other.marqueeTitle ?? marqueeTitle,
      balanceCenteredTitle: other.balanceCenteredTitle ?? balanceCenteredTitle,
    );
  }

  AppBarStyle copyWith({
    Color? backgroundColor,
    Color? foregroundColor,
    Gradient? gradient,
    double? elevation,
    Color? shadowColor,
    BorderRadius? borderRadius,
    Border? border,
    Gradient? borderGradient,
    double? borderWidth,
    TextStyle? titleStyle,
    TextStyle? subtitleStyle,
    bool? centerTitle,
    bool? dynamicHeight,
    bool? hideOnScroll,
    double? toolbarHeight,
    double? backButtonSize,
    double? backIconSize,
    Color? buttonBackgroundColor,
    LabelOverflow? titleOverflow,
    MarqueeStyle? marqueeTitle,
    bool? balanceCenteredTitle,
  }) => AppBarStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    gradient: gradient ?? this.gradient,
    elevation: elevation ?? this.elevation,
    shadowColor: shadowColor ?? this.shadowColor,
    borderRadius: borderRadius ?? this.borderRadius,
    border: border ?? this.border,
    borderGradient: borderGradient ?? this.borderGradient,
    borderWidth: borderWidth ?? this.borderWidth,
    titleStyle: titleStyle ?? this.titleStyle,
    subtitleStyle: subtitleStyle ?? this.subtitleStyle,
    centerTitle: centerTitle ?? this.centerTitle,
    dynamicHeight: dynamicHeight ?? this.dynamicHeight,
    hideOnScroll: hideOnScroll ?? this.hideOnScroll,
    toolbarHeight: toolbarHeight ?? this.toolbarHeight,
    backButtonSize: backButtonSize ?? this.backButtonSize,
    backIconSize: backIconSize ?? this.backIconSize,
    titleOverflow: titleOverflow ?? this.titleOverflow,
    marqueeTitle: marqueeTitle ?? this.marqueeTitle,
    balanceCenteredTitle: balanceCenteredTitle ?? this.balanceCenteredTitle,
  );

  /// The height the bar reports to the Scaffold, WITHOUT a context.
  ///
  /// See [toolbarHeight] for why the theme cannot participate here.
  double get preferredToolbarHeight => toolbarHeight ?? kToolbarHeight;
}

// ---------------------------------------------------------------------------
// ResolvedAppBarStyle
// ---------------------------------------------------------------------------

/// Materialized [AppBarStyle] — every themed field non-null.
///
/// Built once per build by `AppBarStyleResolve.resolve`, so widget code
/// reads `rs.foregroundColor` directly instead of re-deriving
/// `?? cs.onSurface` ladders at each use.
@immutable
class ResolvedAppBarStyle {
  const ResolvedAppBarStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.elevation,
    required this.borderWidth,
    required this.centerTitle,
    required this.dynamicHeight,
    required this.hideOnScroll,
    required this.backButtonSize,
    required this.backIconSize,
    required this.titleOverflow,
    required this.balanceCenteredTitle,
    this.marqueeTitle,
    this.gradient,
    this.shadowColor,
    this.borderRadius,
    this.border,
    this.borderGradient,
    this.titleStyle,
    this.subtitleStyle,
    this.toolbarHeight,
    this.buttonBackgroundColor,
  });

  final Color backgroundColor;
  final Color foregroundColor;

  /// See `AppBarStyle.buttonBackgroundColor`. Null = bare.
  final Color? buttonBackgroundColor;
  final double elevation;
  final double borderWidth;
  final bool centerTitle;
  final bool dynamicHeight;

  /// Resolved against the WINDOW, not against a compile-time floor.
  final bool hideOnScroll;
  final double backButtonSize;
  final double backIconSize;
  final LabelOverflow titleOverflow;
  final bool balanceCenteredTitle;

  // Genuinely opt-in — absent means "do not paint this at all".
  final Gradient? gradient;
  final Color? shadowColor;
  final BorderRadius? borderRadius;
  final Border? border;
  final Gradient? borderGradient;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final double? toolbarHeight;
  final MarqueeStyle? marqueeTitle;

  /// True when the bar paints its own background, so Material's `AppBar`
  /// must be handed a transparent one and the paint must happen in
  /// `flexibleSpace` — otherwise the opaque bar covers it.
  bool get paintsOwnBackground =>
      gradient != null || borderRadius != null || borderGradient != null;
}
