import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Geometry and tolerances that only change when this module changes.
/// Anything an app would rebrand lives on [BannerStyle] instead.
abstract final class BannerDefaults {
  static const animDuration = AppDurations.normal;
  static const radius = 12.0;

  /// UNIFORM. It was `horizontal: 16, vertical: 12`, which reads as a
  /// squashed box the moment the banner is more than one line tall.
  static const padding = EdgeInsets.all(16);

  static const iconSize = 22.0;
  static const iconSpacing = 12.0;
  static const iconPadding = EdgeInsets.all(6);
  static const actionSpacing = 8.0;

  /// Gap above the action row, which sits under the message.
  static const actionTopSpacing = 10.0;

  /// Actions are LINKS, and compact ones: a banner is a notice, and a
  /// full-size button inside it competes with the page's own primary
  /// action. The inset is what remains once the 48dp touch floor is
  /// off — see `GlobalBanner._buildAction` for why it is off.
  static const actionPadding = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 2,
  );
  static const actionRadius = 6.0;
  static const actionFontSize = 13.0;

  /// Inset around the two controls, which is also what gives their
  /// ripple something to be round INSIDE — a bare glyph has no
  /// container, so its splash takes the glyph's square box.
  static const controlPadding = EdgeInsets.all(6);

  static const closeIconSize = 18.0;
  static const chevronSize = 20.0;
  static const chevronSpacing = 4.0;

  /// Gap between the title and the message.
  static const messageSpacing = 4.0;

  /// How much of the status colour the surface keeps. A banner is a
  /// notice the page keeps showing, not an alert — at full strength it
  /// would out-shout the content it sits above.
  static const surfaceOpacity = 0.08;
  static const borderOpacity = 0.2;

  /// The leading glyph's own disc, and the two controls that are not
  /// the point of the banner.
  static const iconDiscOpacity = 0.1;
  static const controlOpacity = 0.5;

  /// The message reads under the title, not beside it.
  static const messageOpacity = 0.7;

  static const borderWidth = 1.0;

  /// A quarter turn: the chevron points down when expanded and at the
  /// title when collapsed.
  static const chevronCollapsedTurns = -0.25;

  /// The line that runs out as an auto-dismissing banner's time does.
  static const progressHeight = 2.0;
  static const progressTrackOpacity = 0.15;

  /// Share of the banner's width a swipe must cross to dismiss it, and
  /// the fling that skips the requirement.
  static const swipeDismissFraction = 0.35;
  static const swipeFlingVelocity = 700.0;

  /// How much of the finger's travel the banner still follows once the
  /// dismiss threshold is BEHIND it. The drag going heavy is what tells
  /// you the decision is already made — without it the only feedback is
  /// distance, which nobody is measuring.
  static const swipeResistance = 0.25;

  /// How far a fully-committed swipe fades and shrinks. It stops short
  /// of nothing on purpose: the banner has not gone yet, and a swipe
  /// released below the threshold has to look recoverable.
  static const swipeFade = 0.6;
  static const swipeShrink = 0.05;

  /// How far a dismissing banner slides as it goes.
  static const scaleFrom = 0.92;

  /// The controller's two halves. The box opens and closes over the
  /// FIRST, the banner fades/slides/scales over the SECOND, and they do
  /// not overlap — so nothing is ever painted while the height that
  /// clips it is moving. Sharing one range is what made every entrance
  /// look scissored.
  static const sizePhaseEnd = 0.5;
  static const visualPhaseBegin = 0.5;

  /// How far each line of the message slides back toward the start as
  /// it folds away.
  static const messageFunnel = 14.0;

  /// Ceiling on the message's measured lines, so a pathological string
  /// cannot turn line-splitting into an unbounded loop.
  static const maxMessageLines = 64;
}

// ---------------------------------------------------------------------------
// BannerType
// ---------------------------------------------------------------------------

/// What the banner is saying, which picks its colour and its glyph.
enum BannerType {
  info,
  success,
  warning,
  error,

  /// Neither a status nor a colour of its own — the page's surface.
  custom,
}

// ---------------------------------------------------------------------------
// BannerAction
// ---------------------------------------------------------------------------

/// One action offered by a banner.
///
/// Declared, not passed in as a `Widget`. Callers used to hand over
/// whole buttons, and every one of them had to remember `shrinkWidth`
/// (a fill-width button inside a `Row` asks for infinity and throws),
/// a small size, a compact padding and a colour that matched the
/// notice — so no two banners in the app looked alike. The banner
/// builds them now, in its own type colour.
@immutable
class BannerAction {
  const BannerAction({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;

  /// Null disables the action rather than hiding it.
  final VoidCallback? onPressed;

  /// Optional leading glyph, tinted with the label.
  final IconData? icon;
}

// ---------------------------------------------------------------------------
// BannerAnimation
// ---------------------------------------------------------------------------

/// Entrance and exit.
enum BannerAnimation {
  /// Drops in from above.
  slide,
  fade,

  /// The default — a short drop with a fade, which reads as arriving
  /// rather than as appearing.
  slideFade,

  /// Grows from slightly small, with the fade.
  scale,

  /// Unrolls: the banner's own height animates from nothing, so the
  /// page below it moves aside rather than being covered.
  expand,

  none;

  bool get isNone => this == BannerAnimation.none;

  /// Whether the banner's HEIGHT is part of the animation. The others
  /// paint inside a box that is already the full size.
  bool get animatesSize => this == BannerAnimation.expand;
}

// ---------------------------------------------------------------------------
// BannerStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for `GlobalBanner` — EVERY field nullable.
///
/// Resolution order, materialized once per build by
/// `style.resolve(context, type:)`:
/// `caller > GlobalBannerTheme.style > BannerStyle.defaults > palette`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedBannerStyle] and `GlobalBannerTheme.lerp`.
@immutable
class BannerStyle {
  const BannerStyle({
    this.backgroundColor,
    this.backgroundGradient,
    this.foregroundColor,
    this.borderColor,
    this.borderGradient,
    this.borderWidth,
    this.borderRadius,
    this.shadow,
    this.padding,
    this.iconSize,
    this.iconSpacing,
    this.titleStyle,
    this.messageStyle,
    this.actionStyle,
    this.animation,
    this.animationDuration,
    this.animationCurve,
    this.marqueeTitle,
    this.autoDismissProgress,
    this.progressHeight,
  });

  /// Compile-time floor. Colours are deliberately absent: they resolve
  /// from `context.statusColors` at build time, so a banner tracks the
  /// palette, role, brightness and saturation.
  ///
  /// They also depend on the TYPE, which the bag does not know —
  /// `resolve` takes it.
  static const BannerStyle defaults = BannerStyle(
    borderWidth: BannerDefaults.borderWidth,
    borderRadius: BorderRadius.all(
      Radius.circular(BannerDefaults.radius),
    ),
    padding: BannerDefaults.padding,
    iconSize: BannerDefaults.iconSize,
    iconSpacing: BannerDefaults.iconSpacing,
    animation: BannerAnimation.slideFade,
    animationDuration: BannerDefaults.animDuration,
    animationCurve: Curves.easeOutCubic,
    marqueeTitle: true,
    autoDismissProgress: true,
    progressHeight: BannerDefaults.progressHeight,
  );

  /// The surface. Null takes the type's status colour, washed.
  final Color? backgroundColor;

  /// Gradient surface, which wins over [backgroundColor].
  final Gradient? backgroundGradient;

  /// Text and glyph. Null takes the type's status colour at full
  /// strength.
  final Color? foregroundColor;

  /// The outline. Null takes the foreground, faded.
  final Color? borderColor;

  /// Gradient outline, which wins over [borderColor].
  final Gradient? borderGradient;

  final double? borderWidth;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadow;
  final EdgeInsets? padding;

  final double? iconSize;
  final double? iconSpacing;

  final TextStyle? titleStyle;
  final TextStyle? messageStyle;

  /// The label on an action. Null takes the foreground at full strength,
  /// so an action reads as belonging to the notice rather than to the
  /// page's button set.
  final TextStyle? actionStyle;

  final BannerAnimation? animation;
  final Duration? animationDuration;
  final Curve? animationCurve;

  /// Whether a title too long for its line scrolls instead of being
  /// ellipsised. The title shares its row with both controls, so it is
  /// the first thing to run out of room — and a cut-off notice is a
  /// notice you cannot read.
  ///
  /// ON. It was off while a scrolling title was the suspect in a
  /// UI-thread hang; that turned out to be a re-entry bug in the
  /// marquee itself and is fixed there.
  final bool? marqueeTitle;

  /// Whether an auto-dismissing banner shows its remaining time.
  final bool? autoDismissProgress;
  final double? progressHeight;

  /// Field-by-field override — anything set on [other] wins.
  BannerStyle mergedWith(BannerStyle? other) {
    if (other == null) return this;
    return BannerStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      backgroundGradient: other.backgroundGradient ?? backgroundGradient,
      foregroundColor: other.foregroundColor ?? foregroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderGradient: other.borderGradient ?? borderGradient,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      shadow: other.shadow ?? shadow,
      padding: other.padding ?? padding,
      iconSize: other.iconSize ?? iconSize,
      iconSpacing: other.iconSpacing ?? iconSpacing,
      titleStyle: other.titleStyle ?? titleStyle,
      messageStyle: other.messageStyle ?? messageStyle,
      actionStyle: other.actionStyle ?? actionStyle,
      animation: other.animation ?? animation,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      marqueeTitle: other.marqueeTitle ?? marqueeTitle,
      autoDismissProgress: other.autoDismissProgress ?? autoDismissProgress,
      progressHeight: other.progressHeight ?? progressHeight,
    );
  }

  BannerStyle copyWith({
    Color? backgroundColor,
    Gradient? backgroundGradient,
    Color? foregroundColor,
    Color? borderColor,
    Gradient? borderGradient,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadow,
    EdgeInsets? padding,
    double? iconSize,
    double? iconSpacing,
    TextStyle? titleStyle,
    TextStyle? messageStyle,
    TextStyle? actionStyle,
    BannerAnimation? animation,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? marqueeTitle,
    bool? autoDismissProgress,
    double? progressHeight,
  }) => BannerStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    foregroundColor: foregroundColor ?? this.foregroundColor,
    borderColor: borderColor ?? this.borderColor,
    borderGradient: borderGradient ?? this.borderGradient,
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    shadow: shadow ?? this.shadow,
    padding: padding ?? this.padding,
    iconSize: iconSize ?? this.iconSize,
    iconSpacing: iconSpacing ?? this.iconSpacing,
    titleStyle: titleStyle ?? this.titleStyle,
    messageStyle: messageStyle ?? this.messageStyle,
    actionStyle: actionStyle ?? this.actionStyle,
    animation: animation ?? this.animation,
    animationDuration: animationDuration ?? this.animationDuration,
    animationCurve: animationCurve ?? this.animationCurve,
    marqueeTitle: marqueeTitle ?? this.marqueeTitle,
    autoDismissProgress: autoDismissProgress ?? this.autoDismissProgress,
    progressHeight: progressHeight ?? this.progressHeight,
  );
}

// ---------------------------------------------------------------------------
// ResolvedBannerStyle
// ---------------------------------------------------------------------------

/// [BannerStyle] after `caller > theme > defaults > palette`, for ONE
/// type. Every themed field is non-null, so build code reads
/// `rs.foregroundColor` with no `??` ladder behind it.
@immutable
class ResolvedBannerStyle {
  const ResolvedBannerStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.borderRadius,
    required this.padding,
    required this.iconSize,
    required this.iconSpacing,
    required this.titleStyle,
    required this.messageStyle,
    required this.actionStyle,
    required this.animation,
    required this.animationDuration,
    required this.animationCurve,
    required this.marqueeTitle,
    required this.autoDismissProgress,
    required this.progressHeight,
    this.backgroundGradient,
    this.borderGradient,
    this.shadow,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final double iconSize;
  final double iconSpacing;
  final TextStyle titleStyle;
  final TextStyle messageStyle;
  final TextStyle actionStyle;
  final BannerAnimation animation;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool marqueeTitle;
  final bool autoDismissProgress;
  final double progressHeight;

  final Gradient? backgroundGradient;
  final Gradient? borderGradient;
  final List<BoxShadow>? shadow;

  /// The close button and the collapse chevron: present, and not the
  /// point of the banner.
  Color get controlColor =>
      foregroundColor.withValues(alpha: BannerDefaults.controlOpacity);

  /// The countdown's own track, under the part that has run out.
  Color get progressTrackColor => foregroundColor.withValues(
    alpha: BannerDefaults.progressTrackOpacity,
  );

  /// The soft disc behind the leading glyph.
  Color get iconDiscColor =>
      foregroundColor.withValues(alpha: BannerDefaults.iconDiscOpacity);
}
