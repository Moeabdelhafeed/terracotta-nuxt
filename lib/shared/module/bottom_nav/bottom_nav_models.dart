import 'package:flutter/material.dart';

import '../../../core/animations/animation_presets.dart';
import '../../../core/animations/entrance.dart';
import '../marquee/marquee_models.dart';

/// A single item in the bottom navigation bar.
class BottomNavItem {
  const BottomNavItem({
    this.icon,
    required this.label,
    this.route,
    this.activeIcon,
    this.badge,
    this.showDot = false,
    this.dotColor,
    this.onTap,
    this.onLongPress,
    this.customIcon,
    this.activeCustomIcon,
    this.disabled = false,
    this.tooltip,
    this.prominent = false,
    this.prominentColor,
    this.prominentSize,
    this.iconGradient,
    this.lottieAsset,
    this.animatedIcon,
    this.animatedIconTrigger,
    this.lottieRepeat = false,
  });

  /// Default icon. Either [icon] or [customIcon] must be provided.
  final IconData? icon;

  /// Icon shown when selected. Falls back to [icon].
  final IconData? activeIcon;

  /// Custom widget for icon (e.g. Image, CircleAvatar). Takes priority over [icon].
  final Widget? customIcon;

  /// Custom widget shown when selected. Falls back to [customIcon].
  final Widget? activeCustomIcon;

  /// Display label.
  final String label;

  /// GoRouter route path (e.g. '/home').
  final String? route;

  /// Badge text (e.g. "5", "NEW").
  final String? badge;

  /// Shows a small notification dot.
  final bool showDot;

  /// Color for the notification dot.
  final Color? dotColor;

  /// Custom tap callback.
  final VoidCallback? onTap;

  /// Long press callback.
  final VoidCallback? onLongPress;

  /// When true, item is greyed out and non-tappable.
  final bool disabled;

  /// Tooltip shown on long press.
  final String? tooltip;

  /// When true, this item is larger/elevated (like Instagram's create button).
  final bool prominent;

  /// Background color for prominent item. Defaults to primary.
  final Color? prominentColor;

  /// Size override for prominent item circle. Defaults to 48.
  final double? prominentSize;

  /// Gradient fill on the icon via ShaderMask when selected.
  final Gradient? iconGradient;

  /// A Material `AnimatedIcon` — a glyph that MORPHS rather than one
  /// that is nudged.
  ///
  /// `iconReaction` moves a static glyph about; this plays an actual
  /// animation, and [animatedIconTrigger] says what drives it. Takes
  /// priority over [icon], and pairs with [activeIcon] doing nothing:
  /// the morph IS the selected state.
  final AnimatedIconData? animatedIcon;

  /// What drives [animatedIcon].
  final BottomNavIconTrigger? animatedIconTrigger;

  /// An animated ASSET — a Lottie `.json` or a dotLottie `.lottie`.
  ///
  /// A designed animation rather than a Material morph, driven by the
  /// same [animatedIconTrigger]. It used to render only while the
  /// destination was selected and play once, so it had no way to
  /// answer a press or a hover and nothing to show when it was not
  /// selected.
  final String? lottieAsset;

  /// Whether the asset LOOPS while its trigger is held.
  ///
  /// Off. A loop under a finger is a spinner, not feedback — the whole
  /// point of a morph is that it has somewhere to arrive.
  final bool lottieRepeat;
}

/// Indicator style for the selected tab.
enum BottomNavIndicatorStyle {
  /// No indicator — only color change.
  none,

  /// Pill-shaped background behind the selected item.
  pill,

  /// Small dot below the icon.
  dot,

  /// Horizontal bar above the item.
  topBar,

  /// Horizontal bar below the item.
  bottomBar,

  /// Animated sliding indicator that moves between tabs.
  sliding,

  /// Custom widget as indicator. Set via [BottomNavStyle.customIndicator].
  custom,
}

/// How the bar arrives when its page opens.
///
/// The shared [EntranceKind], so the app bar and the bottom nav can be
/// told to arrive the same way and "staggered" means one thing in the
/// codebase rather than two.
typedef BottomNavEntrance = EntranceKind;

/// What plays a destination's [BottomNavItem.animatedIcon].
///
/// A morph is a one-way trip with a state at each end, so what it means
/// depends entirely on what moves it: selection is a state that lasts,
/// a press is a moment.
enum BottomNavIconTrigger {
  /// Forward when the destination is selected, back when it is not.
  /// The morph IS the selected state.
  selection,

  /// Forward while pressed. A momentary flourish.
  press,

  /// Forward while hovered or focused — a pointer thing, so it does
  /// nothing on a touch screen without a keyboard.
  hover,
}

/// How a destination's glyph REACTS to being touched, focused or
/// hovered.
///
/// Distinct from the selection change, which is what the indicator is
/// for. This is the feedback a control gives while a finger or a
/// pointer is on it — the thing that makes it feel like a button rather
/// than a picture.
enum BottomNavIconReaction {
  /// Nothing. The glyph is a picture.
  none,

  /// Grows a little, and settles back.
  grow,

  /// Shrinks under the press, the way a physical key gives.
  press,

  /// A quarter-turn wobble.
  tilt,

  /// Lifts, as if coming toward the reader.
  lift,
}

/// Label display mode.
enum BottomNavLabelMode {
  /// Always show labels.
  always,

  /// Only show label for selected item.
  selectedOnly,

  /// Never show labels.
  never,
}

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

/// Geometry and tolerances that only change when this module changes.
/// Anything an app would rebrand lives on [BottomNavStyle] instead.
abstract final class BottomNavDefaults {
  static const height = 64.0;
  static const compactHeight = 52.0;

  static const iconSize = 24.0;
  static const selectedFontSize = 12.0;

  /// The SAME as selected. A label that changes size on selection
  /// re-measures, which the marquee then re-measures, so the text
  /// visibly re-clips while the pill is still easing. Weight and colour
  /// carry the selection instead — which is what Material's own
  /// navigation bar does.
  static const unselectedFontSize = 12.0;
  static const labelSelectedWeight = FontWeight.w600;
  static const labelUnselectedWeight = FontWeight.w400;

  static const itemHPad = 12.0;
  static const itemVPad = 6.0;
  static const compactItemVPad = 4.0;
  static const iconLabelGap = 3.0;

  /// Compact has 52dp to hold a 24dp glyph, a gap and a label. At the
  /// roomy paddings that came to 53, and a `Column` one pixel over its
  /// box is a RenderFlex overflow on every frame.
  static const compactIconLabelGap = 1.0;
  static const compactPillVPad = 2.0;

  static const floatingRadius = 24.0;
  static const floatingMargin = EdgeInsets.fromLTRB(12, 0, 12, 12);

  static const indicatorOpacity = 0.1;
  static const indicatorBarThickness = 3.0;
  static const fallbackIndicatorRadius = 20.0;
  static const indicatorMargin = 4.0;
  static const pillHPad = 16.0;
  static const pillVPad = 6.0;
  static const barIndicatorWidth = 24.0;

  /// How wide a pill is, for every destination alike.
  ///
  /// Content-width pills are as wide as their label, so "Search" came
  /// out ten points wider than "Home" — and the press highlight, which
  /// matches the pill exactly, inherited the unevenness. Material's own
  /// navigation bar sizes its indicator once and leaves it.
  static const indicatorWidth = 72.0;

  /// How much of the home-indicator inset the bar honours. The full 34
  /// points is the system's, and correct, and also a lot of empty bar
  /// under the labels — the indicator itself is a thin line.
  static const bottomInsetFactor = 0.6;

  /// How much of a destination's cell the ripple covers. The ink used
  /// to fill the whole cell corner to corner — a slab far wider than
  /// the pill it was meant to sit inside.
  static const inkWidthFraction = 0.82;
  static const inkMinInset = 4.0;
  static const dotIndicatorSize = 5.0;
  static const slidingIndicatorHeight = 3.0;
  static const slidingIndicatorWidth = 32.0;

  /// How far a badge sits OUTSIDE the glyph's box. At -4 the pill
  /// covered a third of the icon; it hangs off the corner now, which is
  /// what a badge is meant to do.
  static const badgeOffset = -10.0;
  static const dotOffset = -4.0;

  /// How far the unselected and disabled tints are washed out of the
  /// palette's primary text colour.
  static const unselectedOpacity = 0.5;
  static const disabledOpacity = 0.4;

  static const shadowBlur = 8.0;
  static const shadowOffset = Offset(0, -2);
  static const shadowOpacity = 0.1;

  static const blurBgOpacity = 0.7;
  static const notchMargin = 8.0;
  static const notchFabGap = 56.0;
  static const notchRadius = 28.0;

  /// Material 3's default FAB corner. Its regular FAB is a ROUNDED
  /// SQUARE, so a circular notch leaves a round hole under a squircle
  /// button on every M3 app that does not say otherwise.
  static const m3FabRadius = 16.0;

  /// The button's own width, which is what the cutout is sized around.
  static const fabSize = 56.0;

  /// How rounded the two LIPS are — where the cutout meets the bar's
  /// top edge. Zero is a sharp corner.
  static const notchLipRadius = 10.0;
  static const notchCurveDepth = 0.6;

  static const bounceScale = 1.15;

  /// How far a glyph moves when a pointer is on it. Small: a reaction
  /// that has to be looked for is not feedback, and one that has to be
  /// stepped around is a distraction.
  static const iconReactionScale = 0.12;
  static const iconReactionTilt = 0.06;
  static const iconReactionLift = 2.0;
  static const iconReactionDuration = AppDurations.fast;
  static const prominentSize = 48.0;

  /// How tall a line of label is, as a multiple of its font size —
  /// enough to reserve room for it without measuring text.
  static const labelLineFactor = 1.6;
  static const prominentBlur = 8.0;
  static const prominentOffset = -12.0;
  static const prominentLabelTopPad = 2.0;
  static const lottieSize = 28.0;
  static const scrollItemWidth = 72.0;

  static const borderWidth = 2.0;
  static const topBorderWidth = 1.0;

  /// The bar hides once a scroll passes this, and comes back when the
  /// page has been still this long.
  /// How much scrollable content a page needs before its bar is
  /// allowed to hide, as a multiple of the bar's own height.
  ///
  /// Hiding FREES the bar's height. On a page with barely more content
  /// than fits, that is enough to make the page unscrollable — so the
  /// bar hides, the scroll ends, and no gesture remains that brings it
  /// back.
  static const hideMinExtentFactor = 1.5;

  static const hideScrollThreshold = 5.0;
  static const hideAnimDuration = AppDurations.quick;
  static const scrollIdleDelay = AppDurations.deliberate;

  static const animationDuration = AppDurations.quick;

  /// The arrival. Longer than a selection change — it is a whole bar
  /// travelling, not a pill sliding one seat over.
  static const entranceDuration = AppDurations.normal;
  static const entranceCurve = Curves.easeOutCubic;

  /// How far into the entrance the LAST destination starts. Past this
  /// and the tail of a five-item bar arrives after the page has settled.
  static const staggerSpread = 0.5;

  /// How much of a `slideFadeStaggered` entrance the BAR ITSELF takes.
  ///
  /// The two used to share the whole window, and the bar won: the
  /// surface faded up from nothing over the same 300ms its
  /// destinations were staggering across, so every item was multiplied
  /// by the same rising opacity and the stagger — which was really
  /// there, and measurable — could not be seen. The bar now arrives in
  /// the first part of the window and the items follow it across the
  /// rest.
  static const staggerBarWindow = 0.45;

  /// Where the FIRST destination starts, once the bar is most of the
  /// way in. Later items are spread from here to the end.
  static const staggerItemStart = 0.35;

  /// Marks the BAR's own entrance transform.
  ///
  /// A `Scaffold` and its safe areas put several `FractionalTranslation`
  /// widgets in the tree that never move, so "the first one" is not the
  /// bar's — a test written that way reads a constant zero and passes
  /// whatever the entrance does. The same reason `IllustratedHeader`
  /// keys its mirror.
  static const entranceKey = ValueKey<String>('bottom-nav-entrance');

  /// How far a sliding entrance starts below its resting place, as a
  /// fraction of its own height.
  static const entranceSlide = 1.0;
  static const entranceScaleFrom = 0.92;
  static const animationCurve = Curves.easeInOut;
}

// ---------------------------------------------------------------------------
// BottomNavStyle
// ---------------------------------------------------------------------------

/// Themeable styling bag for [GlobalBottomNav] — EVERY field nullable.
///
/// Resolution order, materialized once per build by
/// `style.resolve(context)`:
/// `caller > GlobalBottomNavTheme.style > BottomNavStyle.defaults > palette`.
///
/// Adding a themed field means touching five places: here, [mergedWith],
/// [copyWith], [ResolvedBottomNavStyle] and `GlobalBottomNavTheme.lerp`.
@immutable
class BottomNavStyle {
  const BottomNavStyle({
    this.backgroundColor,
    this.backgroundGradient,
    this.blur,
    this.borderRadius,
    this.shadow,
    this.topBorder,
    this.topBorderGradient,
    this.topBorderWidth,
    this.border,
    this.borderGradient,
    this.borderWidth,
    this.floating,
    this.floatingMargin,
    this.useDeviceRadius,
    this.selectedColor,
    this.unselectedColor,
    this.disabledColor,
    this.indicatorStyle,
    this.indicatorColor,
    this.indicatorOpacity,
    this.indicatorRadius,
    this.indicatorBarThickness,
    this.customIndicator,
    this.labelMode,
    this.iconSize,
    this.selectedFontSize,
    this.unselectedFontSize,
    this.itemPadding,
    this.contentPadding,
    this.itemSpacing,
    this.height,
    this.animationDuration,
    this.animationCurve,
    this.compact,
    this.notch,
    this.notchMargin,
    this.resetOnReTap,
    this.bounceOnTap,
    this.hapticFeedback,
    this.hideOnScroll,
    this.scrollable,
    this.respectReducedMotion,
    this.notchShape,
    this.entrance,
    this.entranceDuration,
    this.entranceCurve,
    this.notchFabRadius,
    this.notchFabSize,
    this.notchLipRadius,
    this.reverseEntranceOnExit,
    this.marqueeLabels,
    this.marqueeStyle,
    this.iconReaction,
    this.iconReactionScale,
    this.indicatorWidth,
    this.bottomInsetFactor,
  });

  /// Compile-time floor. Colours are deliberately absent: they resolve
  /// from the palette at build time, so a bar tracks the app's role,
  /// brightness and saturation.
  static const BottomNavStyle defaults = BottomNavStyle(
    blur: 0,
    topBorderWidth: BottomNavDefaults.topBorderWidth,
    borderWidth: BottomNavDefaults.borderWidth,
    floating: false,
    floatingMargin: BottomNavDefaults.floatingMargin,
    useDeviceRadius: true,
    indicatorStyle: BottomNavIndicatorStyle.pill,
    indicatorOpacity: BottomNavDefaults.indicatorOpacity,
    indicatorBarThickness: BottomNavDefaults.indicatorBarThickness,
    labelMode: BottomNavLabelMode.always,
    iconSize: BottomNavDefaults.iconSize,
    selectedFontSize: BottomNavDefaults.selectedFontSize,
    unselectedFontSize: BottomNavDefaults.unselectedFontSize,
    animationDuration: BottomNavDefaults.animationDuration,
    animationCurve: BottomNavDefaults.animationCurve,
    compact: false,
    notch: false,
    notchMargin: BottomNavDefaults.notchMargin,
    resetOnReTap: false,
    bounceOnTap: false,
    hapticFeedback: false,
    hideOnScroll: false,
    scrollable: false,
    respectReducedMotion: true,
    entrance: BottomNavEntrance.none,
    entranceDuration: BottomNavDefaults.entranceDuration,
    entranceCurve: BottomNavDefaults.entranceCurve,
    notchFabRadius: BottomNavDefaults.m3FabRadius,
    notchFabSize: BottomNavDefaults.fabSize,
    notchLipRadius: BottomNavDefaults.notchLipRadius,
    reverseEntranceOnExit: true,
    marqueeLabels: true,
    iconReaction: BottomNavIconReaction.grow,
    iconReactionScale: BottomNavDefaults.iconReactionScale,
    indicatorWidth: BottomNavDefaults.indicatorWidth,
    bottomInsetFactor: BottomNavDefaults.bottomInsetFactor,
  );

  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final double? blur;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadow;
  final BorderSide? topBorder;
  final Gradient? topBorderGradient;
  final double? topBorderWidth;
  final Border? border;
  final Gradient? borderGradient;
  final double? borderWidth;
  final bool? floating;
  final EdgeInsets? floatingMargin;
  final bool? useDeviceRadius;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? disabledColor;
  final BottomNavIndicatorStyle? indicatorStyle;
  final Color? indicatorColor;
  final double? indicatorOpacity;
  final double? indicatorRadius;
  final double? indicatorBarThickness;

  /// Used when [indicatorStyle] is [BottomNavIndicatorStyle.custom].
  final Widget? customIndicator;

  final BottomNavLabelMode? labelMode;
  final double? iconSize;
  final double? selectedFontSize;
  final double? unselectedFontSize;
  final EdgeInsets? itemPadding;

  /// The gap BETWEEN one destination and the next.
  ///
  /// Only visible once a destination has a surface of its own — an
  /// indicator that fills its cell touches its neighbours, and the row
  /// reads as one long strip rather than as five things. Zero by
  /// default, which is what a bare-glyph bar wants.
  final double? itemSpacing;

  /// Inset between the BAR's edge and the row of destinations.
  ///
  /// [itemPadding] is the space around one glyph; this is the space
  /// around all of them. A floating bar drawn to a design is usually
  /// snug — the surface is only as big as its contents plus a margin —
  /// and without this the row simply centred itself in whatever
  /// [height] said, which put an arbitrary gap above and below it.
  final EdgeInsets? contentPadding;
  final double? height;
  final Duration? animationDuration;
  final Curve? animationCurve;
  final bool? compact;
  final bool? notch;
  final double? notchMargin;
  final bool? resetOnReTap;
  final bool? bounceOnTap;
  final bool? hapticFeedback;
  final bool? hideOnScroll;

  /// Items scroll horizontally, for six or more.
  final bool? scrollable;

  /// The BUTTON's corner radius, which the cutout is derived from.
  ///
  /// The cutout's own corner is this PLUS the gap — concentric shapes
  /// share a centre, so the outer radius is the inner radius plus the
  /// distance between them. Matching the two makes the cutout look too
  /// tight at the corners against the button sitting in it.
  final double? notchFabRadius;

  /// The button's width. The cutout is this plus twice the gap.
  final double? notchFabSize;

  /// How rounded the LIPS are — the two places the cutout meets the
  /// bar's top edge. Zero is a sharp corner, which is what a plain
  /// subtraction gives.
  final double? notchLipRadius;

  /// How the bar arrives when its page opens.
  ///
  /// [BottomNavEntrance.none] by default. A bar that animates in on
  /// every route change is a bar that is late on every route change —
  /// this is for the one screen where the arrival is the point.
  final BottomNavEntrance? entrance;

  final Duration? entranceDuration;
  final Curve? entranceCurve;

  /// How much of the home-indicator inset the bar honours, 0 to 1.
  ///
  /// The inset is the SYSTEM's — 34 points on an iPhone with a home
  /// indicator, and nothing this app chose. Honouring all of it is
  /// correct and also leaves a lot of empty bar under the labels,
  /// because the indicator is a thin line rather than 34 points of
  /// hardware. Material's own navigation bar sits closer than that.
  ///
  /// 1 keeps the full inset. Below about 0.5 the labels start sitting
  /// on the indicator, so this is a taste knob with a floor, not a way
  /// to reclaim the space entirely.
  final double? bottomInsetFactor;

  /// How wide the pill is, for every destination alike.
  ///
  /// Null sizes it to its CONTENT, which makes each destination's pill
  /// as wide as its own label — and the press highlight matches the
  /// pill exactly, so the unevenness shows up twice. A constant is the
  /// default for that reason; it is clamped to the destination, so a
  /// narrow bar still fits.
  final double? indicatorWidth;

  /// How a glyph reacts to a press, a focus or a hover.
  ///
  /// [BottomNavIconReaction.grow] by default — the smallest thing that
  /// makes a destination feel like a control. Separate from the tap
  /// BOUNCE, which fires once on selection; this one tracks the
  /// pointer's state for as long as it is there.
  final BottomNavIconReaction? iconReaction;

  /// How far [iconReaction] moves. A reaction that has to be looked for
  /// is not feedback.
  final double? iconReactionScale;

  /// Whether a label too long for its destination SCROLLS.
  ///
  /// ON. A destination is a fifth of the screen wide, so a label that
  /// does not fit is the ordinary case, and an ellipsis on a two-word
  /// label leaves something that names nothing. Only labels that
  /// actually overflow scroll.
  final bool? marqueeLabels;

  /// How that scrolling looks. Null takes the marquee module's own.
  final MarqueeStyle? marqueeStyle;

  /// Whether the entrance plays BACKWARDS as the page leaves.
  ///
  /// ON when there is an entrance at all. A bar that makes a point of
  /// arriving and then simply vanishes with its page reads as a cut.
  final bool? reverseEntranceOnExit;

  /// The shape the notch is cut to.
  ///
  /// Null means: take it from the floating action button itself when it
  /// declares one, and fall back to a circle. A squircle FAB over a
  /// round hole is the mismatch this exists to fix —
  /// `AutomaticNotchedShape(host, guest)` traces whatever border the
  /// button actually has.
  final NotchedShape? notchShape;

  /// Whether "reduce motion" drops the indicator slide, the tap bounce
  /// and the hide-on-scroll slide.
  ///
  /// ON. A navigation bar is chrome, and chrome that moves is the first
  /// thing the setting is meant to quiet. The selection still changes —
  /// it just arrives rather than travelling.
  final bool? respectReducedMotion;

  /// Field-by-field override — anything set on [other] wins.
  BottomNavStyle mergedWith(BottomNavStyle? other) {
    if (other == null) return this;
    return BottomNavStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      backgroundGradient: other.backgroundGradient ?? backgroundGradient,
      blur: other.blur ?? blur,
      borderRadius: other.borderRadius ?? borderRadius,
      shadow: other.shadow ?? shadow,
      topBorder: other.topBorder ?? topBorder,
      topBorderGradient: other.topBorderGradient ?? topBorderGradient,
      topBorderWidth: other.topBorderWidth ?? topBorderWidth,
      border: other.border ?? border,
      borderGradient: other.borderGradient ?? borderGradient,
      borderWidth: other.borderWidth ?? borderWidth,
      floating: other.floating ?? floating,
      floatingMargin: other.floatingMargin ?? floatingMargin,
      useDeviceRadius: other.useDeviceRadius ?? useDeviceRadius,
      selectedColor: other.selectedColor ?? selectedColor,
      unselectedColor: other.unselectedColor ?? unselectedColor,
      disabledColor: other.disabledColor ?? disabledColor,
      indicatorStyle: other.indicatorStyle ?? indicatorStyle,
      indicatorColor: other.indicatorColor ?? indicatorColor,
      indicatorOpacity: other.indicatorOpacity ?? indicatorOpacity,
      indicatorRadius: other.indicatorRadius ?? indicatorRadius,
      indicatorBarThickness:
          other.indicatorBarThickness ?? indicatorBarThickness,
      customIndicator: other.customIndicator ?? customIndicator,
      labelMode: other.labelMode ?? labelMode,
      iconSize: other.iconSize ?? iconSize,
      selectedFontSize: other.selectedFontSize ?? selectedFontSize,
      unselectedFontSize: other.unselectedFontSize ?? unselectedFontSize,
      itemPadding: other.itemPadding ?? itemPadding,
      contentPadding: other.contentPadding ?? contentPadding,
      itemSpacing: other.itemSpacing ?? itemSpacing,
      height: other.height ?? height,
      animationDuration: other.animationDuration ?? animationDuration,
      animationCurve: other.animationCurve ?? animationCurve,
      compact: other.compact ?? compact,
      notch: other.notch ?? notch,
      notchMargin: other.notchMargin ?? notchMargin,
      resetOnReTap: other.resetOnReTap ?? resetOnReTap,
      bounceOnTap: other.bounceOnTap ?? bounceOnTap,
      hapticFeedback: other.hapticFeedback ?? hapticFeedback,
      hideOnScroll: other.hideOnScroll ?? hideOnScroll,
      scrollable: other.scrollable ?? scrollable,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
      notchShape: other.notchShape ?? notchShape,
      entrance: other.entrance ?? entrance,
      entranceDuration: other.entranceDuration ?? entranceDuration,
      entranceCurve: other.entranceCurve ?? entranceCurve,
      notchFabRadius: other.notchFabRadius ?? notchFabRadius,
      notchFabSize: other.notchFabSize ?? notchFabSize,
      notchLipRadius: other.notchLipRadius ?? notchLipRadius,
      reverseEntranceOnExit:
          other.reverseEntranceOnExit ?? reverseEntranceOnExit,
      marqueeLabels: other.marqueeLabels ?? marqueeLabels,
      marqueeStyle: other.marqueeStyle ?? marqueeStyle,
      iconReaction: other.iconReaction ?? iconReaction,
      iconReactionScale: other.iconReactionScale ?? iconReactionScale,
      indicatorWidth: other.indicatorWidth ?? indicatorWidth,
      bottomInsetFactor: other.bottomInsetFactor ?? bottomInsetFactor,
    );
  }

  BottomNavStyle copyWith({
    Color? backgroundColor,
    Gradient? backgroundGradient,
    double? blur,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadow,
    BorderSide? topBorder,
    Gradient? topBorderGradient,
    double? topBorderWidth,
    Border? border,
    Gradient? borderGradient,
    double? borderWidth,
    bool? floating,
    EdgeInsets? floatingMargin,
    bool? useDeviceRadius,
    Color? selectedColor,
    Color? unselectedColor,
    Color? disabledColor,
    BottomNavIndicatorStyle? indicatorStyle,
    Color? indicatorColor,
    double? indicatorOpacity,
    double? indicatorRadius,
    double? indicatorBarThickness,
    Widget? customIndicator,
    BottomNavLabelMode? labelMode,
    double? iconSize,
    double? selectedFontSize,
    double? unselectedFontSize,
    EdgeInsets? itemPadding,
    EdgeInsets? contentPadding,
    double? itemSpacing,
    double? height,
    Duration? animationDuration,
    Curve? animationCurve,
    bool? compact,
    bool? notch,
    double? notchMargin,
    bool? resetOnReTap,
    bool? bounceOnTap,
    bool? hapticFeedback,
    bool? hideOnScroll,
    bool? scrollable,
    bool? respectReducedMotion,
    NotchedShape? notchShape,
    BottomNavEntrance? entrance,
    Duration? entranceDuration,
    Curve? entranceCurve,
    double? notchFabRadius,
    double? notchFabSize,
    double? notchLipRadius,
    bool? reverseEntranceOnExit,
    bool? marqueeLabels,
    MarqueeStyle? marqueeStyle,
    BottomNavIconReaction? iconReaction,
    double? iconReactionScale,
    double? indicatorWidth,
    double? bottomInsetFactor,
  }) => BottomNavStyle(
    backgroundColor: backgroundColor ?? this.backgroundColor,
    backgroundGradient: backgroundGradient ?? this.backgroundGradient,
    blur: blur ?? this.blur,
    borderRadius: borderRadius ?? this.borderRadius,
    shadow: shadow ?? this.shadow,
    topBorder: topBorder ?? this.topBorder,
    topBorderGradient: topBorderGradient ?? this.topBorderGradient,
    topBorderWidth: topBorderWidth ?? this.topBorderWidth,
    border: border ?? this.border,
    borderGradient: borderGradient ?? this.borderGradient,
    borderWidth: borderWidth ?? this.borderWidth,
    floating: floating ?? this.floating,
    floatingMargin: floatingMargin ?? this.floatingMargin,
    useDeviceRadius: useDeviceRadius ?? this.useDeviceRadius,
    selectedColor: selectedColor ?? this.selectedColor,
    unselectedColor: unselectedColor ?? this.unselectedColor,
    disabledColor: disabledColor ?? this.disabledColor,
    indicatorStyle: indicatorStyle ?? this.indicatorStyle,
    indicatorColor: indicatorColor ?? this.indicatorColor,
    indicatorOpacity: indicatorOpacity ?? this.indicatorOpacity,
    indicatorRadius: indicatorRadius ?? this.indicatorRadius,
    indicatorBarThickness: indicatorBarThickness ?? this.indicatorBarThickness,
    customIndicator: customIndicator ?? this.customIndicator,
    labelMode: labelMode ?? this.labelMode,
    iconSize: iconSize ?? this.iconSize,
    selectedFontSize: selectedFontSize ?? this.selectedFontSize,
    unselectedFontSize: unselectedFontSize ?? this.unselectedFontSize,
    itemPadding: itemPadding ?? this.itemPadding,
    contentPadding: contentPadding ?? this.contentPadding,
    itemSpacing: itemSpacing ?? this.itemSpacing,
    height: height ?? this.height,
    animationDuration: animationDuration ?? this.animationDuration,
    animationCurve: animationCurve ?? this.animationCurve,
    compact: compact ?? this.compact,
    notch: notch ?? this.notch,
    notchMargin: notchMargin ?? this.notchMargin,
    resetOnReTap: resetOnReTap ?? this.resetOnReTap,
    bounceOnTap: bounceOnTap ?? this.bounceOnTap,
    hapticFeedback: hapticFeedback ?? this.hapticFeedback,
    hideOnScroll: hideOnScroll ?? this.hideOnScroll,
    scrollable: scrollable ?? this.scrollable,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
    notchShape: notchShape ?? this.notchShape,
    entrance: entrance ?? this.entrance,
    entranceDuration: entranceDuration ?? this.entranceDuration,
    entranceCurve: entranceCurve ?? this.entranceCurve,
    notchFabRadius: notchFabRadius ?? this.notchFabRadius,
    notchFabSize: notchFabSize ?? this.notchFabSize,
    notchLipRadius: notchLipRadius ?? this.notchLipRadius,
    reverseEntranceOnExit: reverseEntranceOnExit ?? this.reverseEntranceOnExit,
    marqueeLabels: marqueeLabels ?? this.marqueeLabels,
    marqueeStyle: marqueeStyle ?? this.marqueeStyle,
    iconReaction: iconReaction ?? this.iconReaction,
    iconReactionScale: iconReactionScale ?? this.iconReactionScale,
    indicatorWidth: indicatorWidth ?? this.indicatorWidth,
    bottomInsetFactor: bottomInsetFactor ?? this.bottomInsetFactor,
  );
}

// ---------------------------------------------------------------------------
// ResolvedBottomNavStyle
// ---------------------------------------------------------------------------

/// [BottomNavStyle] after `caller > theme > defaults > palette`. Every
/// themed field is non-null, so build code reads `rs.selectedColor` with
/// no `??` ladder behind it.
@immutable
class ResolvedBottomNavStyle {
  const ResolvedBottomNavStyle({
    required this.backgroundColor,
    required this.backgroundGradient,
    required this.blur,
    required this.borderRadius,
    required this.shadow,
    required this.topBorder,
    required this.topBorderGradient,
    required this.topBorderWidth,
    required this.border,
    required this.borderGradient,
    required this.borderWidth,
    required this.floating,
    required this.floatingMargin,
    required this.useDeviceRadius,
    required this.selectedColor,
    required this.unselectedColor,
    required this.disabledColor,
    required this.indicatorStyle,
    required this.indicatorColor,
    required this.indicatorOpacity,
    required this.indicatorRadius,
    required this.indicatorBarThickness,
    required this.customIndicator,
    required this.labelMode,
    required this.iconSize,
    required this.selectedFontSize,
    required this.unselectedFontSize,
    required this.itemPadding,
    required this.contentPadding,
    required this.itemSpacing,
    required this.height,
    required this.animationDuration,
    required this.animationCurve,
    required this.compact,
    required this.notch,
    required this.notchMargin,
    required this.resetOnReTap,
    required this.bounceOnTap,
    required this.hapticFeedback,
    required this.hideOnScroll,
    required this.scrollable,
    required this.respectReducedMotion,
    required this.notchShape,
    required this.entrance,
    required this.entranceDuration,
    required this.entranceCurve,
    required this.notchFabRadius,
    required this.notchFabSize,
    required this.notchLipRadius,
    required this.reverseEntranceOnExit,
    required this.marqueeLabels,
    required this.marqueeStyle,
    required this.iconReaction,
    required this.iconReactionScale,
    required this.indicatorWidth,
    required this.bottomInsetFactor,
    required this.prominentIconColor,
  });

  final Color backgroundColor;
  final Gradient? backgroundGradient;
  final double blur;

  /// Null means "take the device's own screen radius", which is only
  /// known asynchronously — the widget resolves it separately.
  final BorderRadius? borderRadius;

  final List<BoxShadow> shadow;
  final BorderSide? topBorder;
  final Gradient? topBorderGradient;
  final double topBorderWidth;
  final Border? border;
  final Gradient? borderGradient;
  final double borderWidth;
  final bool floating;
  final EdgeInsets floatingMargin;
  final bool useDeviceRadius;
  final Color selectedColor;
  final Color unselectedColor;
  final Color disabledColor;
  final BottomNavIndicatorStyle indicatorStyle;
  final Color indicatorColor;
  final double indicatorOpacity;
  final double? indicatorRadius;
  final double indicatorBarThickness;
  final Widget? customIndicator;
  final BottomNavLabelMode labelMode;
  final double iconSize;
  final double selectedFontSize;
  final double unselectedFontSize;
  final double? itemSpacing;

  final EdgeInsets? contentPadding;

  final EdgeInsets? itemPadding;
  final double height;
  final Duration animationDuration;
  final Curve animationCurve;
  final bool compact;
  final bool notch;
  final double notchMargin;
  final bool resetOnReTap;
  final bool bounceOnTap;
  final bool hapticFeedback;
  final bool hideOnScroll;
  final bool scrollable;
  final bool respectReducedMotion;

  /// Null means "take it from the button", resolved by the widget —
  /// only it knows what the caller handed in.
  final NotchedShape? notchShape;

  final BottomNavEntrance entrance;
  final Duration entranceDuration;
  final Curve entranceCurve;

  final double notchFabRadius;
  final double notchFabSize;
  final double notchLipRadius;
  final bool reverseEntranceOnExit;
  final bool marqueeLabels;
  final MarqueeStyle marqueeStyle;
  final BottomNavIconReaction iconReaction;
  final double iconReactionScale;

  /// Null means content-width.
  final double? indicatorWidth;
  final double bottomInsetFactor;

  /// What a prominent item's glyph is drawn in — the colour that reads
  /// ON the prominent fill, not a hard-coded white.
  final Color prominentIconColor;
}
