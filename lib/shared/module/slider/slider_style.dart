import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'slider_models.dart';

// ---------------------------------------------------------------------------
// Defaults — every hard-coded number the slider draws with
// ---------------------------------------------------------------------------

/// The compile-time floor under [SliderStyle].
///
/// Sizes a token can express are NOT here — they come from
/// `MyGlobalSliderTheme.build`, which reads `AppTokens` and so tracks
/// the window bucket. What is here is what a token cannot say: the
/// geometry Material needs, and the opacities.
abstract final class SliderDefaults {
  // ─── Track ────────────────────────────────────────────────
  static const trackHeight = 4.0;

  /// A pill. `null` on the bag means "half the height", which is
  /// what Material draws and what keeps a thicker track looking
  /// deliberate rather than blunt.
  static const trackRadiusFactor = 0.5;

  /// What each END of the track gives up, by default: NOTHING.
  ///
  /// The track runs the full width it is given and the thumb overhangs
  /// into whatever the slider sits in — which every slider in this app
  /// has room for, since they all sit in a padded card or a padded
  /// row. Reserving the thumb's radius at both ends instead spent 24
  /// points of a 300-point slider on empty space at the two places a
  /// reader is most likely to aim.
  ///
  /// A slider whose parent CLIPS wants [thumbSafeEndInset] instead, or
  /// the thumb is cut in half at the ends.
  static const trackEndInset = 0.0;

  /// The hair beyond the thumb's radius that [thumbSafeEndInset] adds,
  /// so its edge is not flush with the edge of the box.
  static const trackEndPadding = 2.0;

  // ─── Thumb ────────────────────────────────────────────────
  static const thumbRadius = 10.0;
  static const thumbElevation = 3.0;
  static const overlayRadius = 16.0;

  /// How much smaller a disabled thumb is drawn.
  static const disabledThumbShrink = 2.0;

  /// The ring inside a gradient thumb.
  static const thumbBorderWidth = 1.5;

  // ─── Circular ─────────────────────────────────────────────
  /// The ring's weight, and the diameter it draws at when the caller
  /// gives it no bounded box.
  static const ringThickness = 14.0;
  static const ringDiameter = 240.0;

  /// The thumb on a ring is bigger than the one on a bar: there is no
  /// track under a finger to aim at, only the ring itself.
  static const ringThumbRadius = 14.0;

  /// The FLOOR under how far off the ring a finger still counts.
  ///
  /// The real band is this or the ring's own thickness plus its thumb,
  /// whichever is more — a 14-point ring with a 14-point thumb is 28
  /// points of target, and asking for it within 28 of the centre-line
  /// meant the outer edge of the thumb was already outside.
  static const ringTouchSlop = 36.0;

  // ─── Trim ─────────────────────────────────────────────────
  /// The grab bar at each end of a trimmed span.
  ///
  /// Wide enough to be a target in its own right: the two handles of a
  /// span closed to its floor are otherwise impossible to tell apart
  /// under a fingertip.
  static const trimHandleWidth = 14.0;

  /// Extra margin either side of a handle that still counts as it.
  static const trimHandleTouchSlop = 10.0;

  /// The rails along the top and bottom of the frame.
  static const trimRailHeight = 3.0;

  static const trimPlayheadWidth = 3.0;

  /// How hard the film outside the span is dimmed.
  static const trimScrimOpacity = 0.55;

  // ─── Segments ─────────────────────────────────────────────
  /// How much track a seam between two segments eats, split evenly on
  /// both sides of the boundary. The video player's chapter gap, which
  /// is where this shape came from.
  static const segmentGap = 4.0;

  /// The loaded-but-not-reached part of the track, against the accent.
  static const secondaryTrackOpacity = 0.35;

  /// How THICK a vertical track's touch strip is.
  ///
  /// Material's minimum target. A rotated slider fills whatever height
  /// it is given, so without a bound here it took the parent's whole
  /// width and the "vertical" slider came out 778 points across.
  static const verticalThickness = 48.0;

  // ─── Ticks ────────────────────────────────────────────────
  static const tickRadius = 3.0;

  // ─── Indicator ────────────────────────────────────────────
  static const indicatorRadius = 6.0;
  static const indicatorPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: 5,
  );
  static const indicatorArrowSize = 6.0;
  static const indicatorVerticalOffset = 4.0;

  /// The soft drop under the thumb and the indicator.
  static const shadowBlur = 3.0;
  static const shadowOffset = Offset(0, 1.5);
  static const shadowOpacity = 0.15;

  // ─── Opacity ──────────────────────────────────────────────
  static const disabledOpacity = 0.4;

  /// The inactive track against the outline colour.
  static const inactiveTrackOpacity = 0.15;

  /// The ripple, and the value badge behind its number.
  static const overlayOpacity = 0.08;
  static const badgeFillOpacity = 0.08;
  static const badgeBorderOpacity = 0.2;
  static const endChipOpacity = 0.4;
}

// ---------------------------------------------------------------------------
// SliderStyle — the themeable bag
// ---------------------------------------------------------------------------

/// How a [GlobalSlider] looks and how it behaves.
///
/// Every field is nullable so the three sources layer without a
/// default clobbering a theme: `caller > GlobalSliderTheme.style >
/// SliderStyle.defaults`. Resolved once per build into a
/// [ResolvedSliderStyle].
///
/// It was half-nullable: only the colours could be omitted, and every
/// size carried an inline default, so a house that wanted a thicker
/// track had to say so at every call site and could never change it
/// centrally.
@immutable
class SliderStyle {
  const SliderStyle({
    this.activeColor,
    this.inactiveColor,
    this.trackGradient,
    this.trackHeight,
    this.trackRadius,
    this.trackEndInset,
    this.thumbColor,
    this.thumbBorderColor,
    this.thumbGradient,
    this.thumbRadius,
    this.thumbElevation,
    this.overlayRadius,
    this.segmentGap,
    this.secondaryColor,
    this.ringThickness,
    this.ringDiameter,
    this.ringThumbRadius,
    this.ringCapped,
    this.ringTouchSlop,
    this.trimHandleWidth,
    this.trimHandleTouchSlop,
    this.trimRailHeight,
    this.trimPlayheadWidth,
    this.trimPlayheadColor,
    this.trimScrimColor,
    this.trimGripColor,
    this.showTicks,
    this.tickStyle,
    this.stepLabelStyle,
    this.stepLabelGap,
    this.showValueIndicator,
    this.indicatorStyle,
    this.showContainer,
    this.containerDecoration,
    this.containerPadding,
    this.containerColor,
    this.containerBorderColor,
    this.containerRadius,
    this.containerShadow,
    this.labelStyle,
    this.valueStyle,
    this.minMaxStyle,
    this.valueBadgeColor,
    this.valueBadgeBorderColor,
    this.valueBadgeRadius,
    this.valueBadgePadding,
    this.endChipColor,
    this.endChipRadius,
    this.endChipPadding,
    this.enableHaptic,
    this.disabledOpacity,
  });

  /// The floor.
  ///
  /// Colours are absent on purpose — they resolve from the palette at
  /// build time so they track role, brightness and saturation, which a
  /// constant cannot.
  static const SliderStyle defaults = SliderStyle(
    trackHeight: SliderDefaults.trackHeight,
    thumbRadius: SliderDefaults.thumbRadius,
    thumbElevation: SliderDefaults.thumbElevation,
    overlayRadius: SliderDefaults.overlayRadius,
    showValueIndicator: true,
    showContainer: true,
    enableHaptic: true,
    disabledOpacity: SliderDefaults.disabledOpacity,
  );

  // ─── Presets ──────────────────────────────────────────────
  //
  // A preset is a NAMED BAG. Everything it decides is what the bag
  // already carries, so it merges with a theme and loses to a
  // per-call override like any other, and adds no code path.

  /// A slider inside a form row or a settings list.
  ///
  /// No card of its own — the row it sits in already has one — and a
  /// thinner track, because at this size the slider is one control
  /// among several rather than the subject of the screen.
  static const SliderStyle bare = SliderStyle(
    showContainer: false,
    trackHeight: 3,
    thumbRadius: 8,
    overlayRadius: 14,
  );

  /// A slider someone will drag repeatedly — a seek bar, a filter.
  ///
  /// A fatter track and a bigger target. The value indicator is off:
  /// a bubble that appears on every drag is noise when the drag is
  /// the point, and the value badge already says the number.
  static const SliderStyle prominent = SliderStyle(
    trackHeight: 8,
    thumbRadius: 12,
    overlayRadius: 22,
    showValueIndicator: false,
  );

  /// Discrete steps, marked.
  static const SliderStyle stepped = SliderStyle(
    showTicks: true,
    trackHeight: 6,
    tickStyle: SliderTickStyle(shape: SliderTickShape.circle),
  );

  // ─── Track.

  /// The ring's weight, on a circular slider.
  final double? ringThickness;

  /// The ring's outside diameter, when nothing bounds it.
  final double? ringDiameter;

  /// The thumb's radius on a ring. Falls back to a size of its own
  /// rather than to [thumbRadius] — a bar's thumb sits ON a track a
  /// finger can aim at, and a ring's does not.
  final double? ringThumbRadius;

  /// Rounded ends on the ring's arcs. Off makes a gauge read as a
  /// measuring instrument rather than a progress pill.
  final bool? ringCapped;

  /// How far either side of the ring a touch still counts.
  final double? ringTouchSlop;

  // ─── Trim.

  /// The grab bar at each end of a trimmed span.
  final double? trimHandleWidth;

  /// Extra margin either side of a handle that still counts as it.
  final double? trimHandleTouchSlop;

  /// The rails joining the two handles.
  final double? trimRailHeight;

  final double? trimPlayheadWidth;

  /// The playhead. Falls back to what reads ON the accent, because it
  /// sits inside the selected span.
  final Color? trimPlayheadColor;

  /// What covers the part of the content outside the span.
  final Color? trimScrimColor;

  /// The grip lines on a handle.
  final Color? trimGripColor;

  /// How much track a seam between two `segments` eats.
  ///
  /// The gap is VISUAL, so it lives here — but WHERE the seams are is
  /// content, and lives on the widget. A theme cannot know where the
  /// second act starts.
  final double? segmentGap;

  /// The secondary track — loaded, cached, downloaded: reached by
  /// something other than the reader. Falls back to the accent at
  /// [SliderDefaults.secondaryTrackOpacity].
  final Color? secondaryColor;

  /// The words under a discrete slider's ticks.
  final TextStyle? stepLabelStyle;

  /// Between the track and those words.
  final double? stepLabelGap;

  /// The filled part of the track, and the accent every other
  /// tinted piece of the slider takes. Falls back to the palette
  /// primary.
  final Color? activeColor;

  /// The rest of the track.
  final Color? inactiveColor;

  /// How much room each END of the track gives up.
  ///
  /// Null is [SliderDefaults.trackEndInset], which is NOTHING: the
  /// track runs the full width it is given and the thumb overhangs
  /// into whatever the slider sits in. Everything on the bar is
  /// measured from this — the track shapes, the tick marks, and the
  /// step labels under them — so moving it moves all three together.
  ///
  /// Pass [SliderTrackGeometry.thumbSafeInset] when the parent CLIPS,
  /// or the thumb is cut in half at the two ends. Anything larger
  /// insets the whole track.
  final double? trackEndInset;

  /// Painted INSTEAD of [activeColor] on the filled part. Stays
  /// nullable through resolution — a flat fill is a legitimate answer.
  final Gradient? trackGradient;

  final double? trackHeight;

  /// The track's end caps. Half the height is a pill, which is what
  /// Material draws.
  final double? trackRadius;

  // ─── Thumb.

  final Color? thumbColor;

  /// The ring inside a GRADIENT thumb, which needs one to stay
  /// legible over a dark stop. It was `Colors.white`.
  final Color? thumbBorderColor;

  /// Painted INSTEAD of [thumbColor].
  final Gradient? thumbGradient;

  final double? thumbRadius;

  final double? thumbElevation;

  /// The ripple under a pressed thumb.
  final double? overlayRadius;

  // ─── Ticks and the value indicator.

  /// Draw a mark at each division.
  ///
  /// Defaults to whether [tickStyle] was set, so a caller who styles
  /// ticks gets ticks — but a THEME that styles them can still be
  /// turned off per call, which `tickStyle: null` alone could not say.
  final bool? showTicks;

  /// How those marks look.
  final SliderTickStyle? tickStyle;

  /// The bubble that follows the thumb while it is dragged.
  final bool? showValueIndicator;

  /// How that bubble looks.
  final SliderIndicatorStyle? indicatorStyle;

  // ─── The box around it.

  /// Whether the slider sits on a card of its own.
  ///
  /// A slider inside a form row already has one. Off, the box
  /// collapses to nothing — no fill, no border, no padding.
  final bool? showContainer;

  /// A whole decoration, replacing the four fields below. The escape
  /// hatch for a caller who wants something the bag cannot say.
  final BoxDecoration? containerDecoration;

  final EdgeInsetsGeometry? containerPadding;

  final Color? containerColor;

  final Color? containerBorderColor;

  final double? containerRadius;

  /// `null` asks for the house shadow; `const []` is FLAT. Collapsing
  /// the two makes flat impossible to ask for.
  final List<BoxShadow>? containerShadow;

  // ─── Type.

  final TextStyle? labelStyle;

  /// The badge beside the label.
  final TextStyle? valueStyle;

  /// The two end chips.
  final TextStyle? minMaxStyle;

  final Color? valueBadgeColor;

  final Color? valueBadgeBorderColor;

  final double? valueBadgeRadius;

  final EdgeInsetsGeometry? valueBadgePadding;

  final Color? endChipColor;

  final double? endChipRadius;

  final EdgeInsetsGeometry? endChipPadding;

  // ─── Behaviour.

  /// A tick as the thumb crosses a DIVISION. There is nothing else to
  /// say a discrete slider moved — the number changes under a finger
  /// that is covering it.
  final bool? enableHaptic;

  /// How far a disabled slider is dulled.
  final double? disabledOpacity;

  /// [other] wins field by field. Null means "did not say", which is
  /// what lets a caller override one thing without restating a theme.
  SliderStyle mergedWith(SliderStyle? other) {
    if (other == null) return this;
    return SliderStyle(
      activeColor: other.activeColor ?? activeColor,
      inactiveColor: other.inactiveColor ?? inactiveColor,
      trackGradient: other.trackGradient ?? trackGradient,
      trackHeight: other.trackHeight ?? trackHeight,
      trackRadius: other.trackRadius ?? trackRadius,
      trackEndInset: other.trackEndInset ?? trackEndInset,
      thumbColor: other.thumbColor ?? thumbColor,
      thumbBorderColor: other.thumbBorderColor ?? thumbBorderColor,
      thumbGradient: other.thumbGradient ?? thumbGradient,
      thumbRadius: other.thumbRadius ?? thumbRadius,
      thumbElevation: other.thumbElevation ?? thumbElevation,
      overlayRadius: other.overlayRadius ?? overlayRadius,
      segmentGap: other.segmentGap ?? segmentGap,
      secondaryColor: other.secondaryColor ?? secondaryColor,
      ringThickness: other.ringThickness ?? ringThickness,
      ringDiameter: other.ringDiameter ?? ringDiameter,
      ringThumbRadius: other.ringThumbRadius ?? ringThumbRadius,
      ringCapped: other.ringCapped ?? ringCapped,
      ringTouchSlop: other.ringTouchSlop ?? ringTouchSlop,
      trimHandleWidth: other.trimHandleWidth ?? trimHandleWidth,
      trimHandleTouchSlop: other.trimHandleTouchSlop ?? trimHandleTouchSlop,
      trimRailHeight: other.trimRailHeight ?? trimRailHeight,
      trimPlayheadWidth: other.trimPlayheadWidth ?? trimPlayheadWidth,
      trimPlayheadColor: other.trimPlayheadColor ?? trimPlayheadColor,
      trimScrimColor: other.trimScrimColor ?? trimScrimColor,
      trimGripColor: other.trimGripColor ?? trimGripColor,
      showTicks: other.showTicks ?? showTicks,
      tickStyle: tickStyle?.mergedWith(other.tickStyle) ?? other.tickStyle,
      stepLabelStyle: other.stepLabelStyle ?? stepLabelStyle,
      stepLabelGap: other.stepLabelGap ?? stepLabelGap,
      showValueIndicator: other.showValueIndicator ?? showValueIndicator,
      indicatorStyle:
          indicatorStyle?.mergedWith(other.indicatorStyle) ??
          other.indicatorStyle,
      showContainer: other.showContainer ?? showContainer,
      containerDecoration: other.containerDecoration ?? containerDecoration,
      containerPadding: other.containerPadding ?? containerPadding,
      containerColor: other.containerColor ?? containerColor,
      containerBorderColor: other.containerBorderColor ?? containerBorderColor,
      containerRadius: other.containerRadius ?? containerRadius,
      containerShadow: other.containerShadow ?? containerShadow,
      labelStyle: other.labelStyle ?? labelStyle,
      valueStyle: other.valueStyle ?? valueStyle,
      minMaxStyle: other.minMaxStyle ?? minMaxStyle,
      valueBadgeColor: other.valueBadgeColor ?? valueBadgeColor,
      valueBadgeBorderColor:
          other.valueBadgeBorderColor ?? valueBadgeBorderColor,
      valueBadgeRadius: other.valueBadgeRadius ?? valueBadgeRadius,
      valueBadgePadding: other.valueBadgePadding ?? valueBadgePadding,
      endChipColor: other.endChipColor ?? endChipColor,
      endChipRadius: other.endChipRadius ?? endChipRadius,
      endChipPadding: other.endChipPadding ?? endChipPadding,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      disabledOpacity: other.disabledOpacity ?? disabledOpacity,
    );
  }

  SliderStyle copyWith({
    Color? activeColor,
    Color? inactiveColor,
    Gradient? trackGradient,
    double? trackHeight,
    double? trackRadius,
    double? trackEndInset,
    Color? thumbColor,
    Color? thumbBorderColor,
    Gradient? thumbGradient,
    double? thumbRadius,
    double? thumbElevation,
    double? overlayRadius,
    double? segmentGap,
    Color? secondaryColor,
    double? ringThickness,
    double? ringDiameter,
    double? ringThumbRadius,
    bool? ringCapped,
    double? ringTouchSlop,
    double? trimHandleWidth,
    double? trimHandleTouchSlop,
    double? trimRailHeight,
    double? trimPlayheadWidth,
    Color? trimPlayheadColor,
    Color? trimScrimColor,
    Color? trimGripColor,
    bool? showTicks,
    SliderTickStyle? tickStyle,
    TextStyle? stepLabelStyle,
    double? stepLabelGap,
    bool? showValueIndicator,
    SliderIndicatorStyle? indicatorStyle,
    bool? showContainer,
    BoxDecoration? containerDecoration,
    EdgeInsetsGeometry? containerPadding,
    Color? containerColor,
    Color? containerBorderColor,
    double? containerRadius,
    List<BoxShadow>? containerShadow,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
    TextStyle? minMaxStyle,
    Color? valueBadgeColor,
    Color? valueBadgeBorderColor,
    double? valueBadgeRadius,
    EdgeInsetsGeometry? valueBadgePadding,
    Color? endChipColor,
    double? endChipRadius,
    EdgeInsetsGeometry? endChipPadding,
    bool? enableHaptic,
    double? disabledOpacity,
  }) => SliderStyle(
    activeColor: activeColor ?? this.activeColor,
    inactiveColor: inactiveColor ?? this.inactiveColor,
    trackGradient: trackGradient ?? this.trackGradient,
    trackHeight: trackHeight ?? this.trackHeight,
    trackRadius: trackRadius ?? this.trackRadius,
    trackEndInset: trackEndInset ?? this.trackEndInset,
    thumbColor: thumbColor ?? this.thumbColor,
    thumbBorderColor: thumbBorderColor ?? this.thumbBorderColor,
    thumbGradient: thumbGradient ?? this.thumbGradient,
    thumbRadius: thumbRadius ?? this.thumbRadius,
    thumbElevation: thumbElevation ?? this.thumbElevation,
    overlayRadius: overlayRadius ?? this.overlayRadius,
    segmentGap: segmentGap ?? this.segmentGap,
    secondaryColor: secondaryColor ?? this.secondaryColor,
    ringThickness: ringThickness ?? this.ringThickness,
    ringDiameter: ringDiameter ?? this.ringDiameter,
    ringThumbRadius: ringThumbRadius ?? this.ringThumbRadius,
    ringCapped: ringCapped ?? this.ringCapped,
    ringTouchSlop: ringTouchSlop ?? this.ringTouchSlop,
    trimHandleWidth: trimHandleWidth ?? this.trimHandleWidth,
    trimHandleTouchSlop: trimHandleTouchSlop ?? this.trimHandleTouchSlop,
    trimRailHeight: trimRailHeight ?? this.trimRailHeight,
    trimPlayheadWidth: trimPlayheadWidth ?? this.trimPlayheadWidth,
    trimPlayheadColor: trimPlayheadColor ?? this.trimPlayheadColor,
    trimScrimColor: trimScrimColor ?? this.trimScrimColor,
    trimGripColor: trimGripColor ?? this.trimGripColor,
    showTicks: showTicks ?? this.showTicks,
    tickStyle: tickStyle ?? this.tickStyle,
    stepLabelStyle: stepLabelStyle ?? this.stepLabelStyle,
    stepLabelGap: stepLabelGap ?? this.stepLabelGap,
    showValueIndicator: showValueIndicator ?? this.showValueIndicator,
    indicatorStyle: indicatorStyle ?? this.indicatorStyle,
    showContainer: showContainer ?? this.showContainer,
    containerDecoration: containerDecoration ?? this.containerDecoration,
    containerPadding: containerPadding ?? this.containerPadding,
    containerColor: containerColor ?? this.containerColor,
    containerBorderColor: containerBorderColor ?? this.containerBorderColor,
    containerRadius: containerRadius ?? this.containerRadius,
    containerShadow: containerShadow ?? this.containerShadow,
    labelStyle: labelStyle ?? this.labelStyle,
    valueStyle: valueStyle ?? this.valueStyle,
    minMaxStyle: minMaxStyle ?? this.minMaxStyle,
    valueBadgeColor: valueBadgeColor ?? this.valueBadgeColor,
    valueBadgeBorderColor: valueBadgeBorderColor ?? this.valueBadgeBorderColor,
    valueBadgeRadius: valueBadgeRadius ?? this.valueBadgeRadius,
    valueBadgePadding: valueBadgePadding ?? this.valueBadgePadding,
    endChipColor: endChipColor ?? this.endChipColor,
    endChipRadius: endChipRadius ?? this.endChipRadius,
    endChipPadding: endChipPadding ?? this.endChipPadding,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
  );

  @override
  bool operator ==(Object other) =>
      other is SliderStyle &&
      other.activeColor == activeColor &&
      other.inactiveColor == inactiveColor &&
      other.trackGradient == trackGradient &&
      other.trackHeight == trackHeight &&
      other.trackRadius == trackRadius &&
      other.trackEndInset == trackEndInset &&
      other.thumbColor == thumbColor &&
      other.thumbBorderColor == thumbBorderColor &&
      other.thumbGradient == thumbGradient &&
      other.thumbRadius == thumbRadius &&
      other.thumbElevation == thumbElevation &&
      other.overlayRadius == overlayRadius &&
      other.segmentGap == segmentGap &&
      other.secondaryColor == secondaryColor &&
      other.ringThickness == ringThickness &&
      other.ringDiameter == ringDiameter &&
      other.ringThumbRadius == ringThumbRadius &&
      other.ringCapped == ringCapped &&
      other.ringTouchSlop == ringTouchSlop &&
      other.trimHandleWidth == trimHandleWidth &&
      other.trimHandleTouchSlop == trimHandleTouchSlop &&
      other.trimRailHeight == trimRailHeight &&
      other.trimPlayheadWidth == trimPlayheadWidth &&
      other.trimPlayheadColor == trimPlayheadColor &&
      other.trimScrimColor == trimScrimColor &&
      other.trimGripColor == trimGripColor &&
      other.showTicks == showTicks &&
      other.tickStyle == tickStyle &&
      other.stepLabelStyle == stepLabelStyle &&
      other.stepLabelGap == stepLabelGap &&
      other.showValueIndicator == showValueIndicator &&
      other.indicatorStyle == indicatorStyle &&
      other.showContainer == showContainer &&
      other.containerDecoration == containerDecoration &&
      other.containerPadding == containerPadding &&
      other.containerColor == containerColor &&
      other.containerBorderColor == containerBorderColor &&
      other.containerRadius == containerRadius &&
      listEquals(other.containerShadow, containerShadow) &&
      other.labelStyle == labelStyle &&
      other.valueStyle == valueStyle &&
      other.minMaxStyle == minMaxStyle &&
      other.valueBadgeColor == valueBadgeColor &&
      other.valueBadgeBorderColor == valueBadgeBorderColor &&
      other.valueBadgeRadius == valueBadgeRadius &&
      other.valueBadgePadding == valueBadgePadding &&
      other.endChipColor == endChipColor &&
      other.endChipRadius == endChipRadius &&
      other.endChipPadding == endChipPadding &&
      other.enableHaptic == enableHaptic &&
      other.disabledOpacity == disabledOpacity;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    activeColor,
    inactiveColor,
    trackGradient,
    trackHeight,
    trackRadius,
    trackEndInset,
    thumbColor,
    thumbBorderColor,
    thumbGradient,
    thumbRadius,
    thumbElevation,
    overlayRadius,
    segmentGap,
    secondaryColor,
    ringThickness,
    ringDiameter,
    ringThumbRadius,
    ringCapped,
    ringTouchSlop,
    trimHandleWidth,
    trimHandleTouchSlop,
    trimRailHeight,
    trimPlayheadWidth,
    trimPlayheadColor,
    trimScrimColor,
    trimGripColor,
    showTicks,
    tickStyle,
    stepLabelStyle,
    stepLabelGap,
    showValueIndicator,
    indicatorStyle,
    showContainer,
    containerDecoration,
    containerPadding,
    containerColor,
    containerBorderColor,
    containerRadius,
    containerShadow == null ? null : Object.hashAll(containerShadow!),
    labelStyle,
    valueStyle,
    minMaxStyle,
    valueBadgeColor,
    valueBadgeBorderColor,
    valueBadgeRadius,
    valueBadgePadding,
    endChipColor,
    endChipRadius,
    endChipPadding,
    enableHaptic,
    disabledOpacity,
  ]);
}

// ---------------------------------------------------------------------------
// ResolvedSliderStyle — the bag with every question answered
// ---------------------------------------------------------------------------

/// What the widget and the painters actually read.
///
/// Built once per build by `SliderStyleResolve.resolve` and handed
/// DOWN to the shapes — each one used to answer its leftover colours
/// itself out of `Theme.of`, so a tick could disagree with the track
/// it sat on.
@immutable
class ResolvedSliderStyle {
  const ResolvedSliderStyle({
    required this.activeColor,
    required this.inactiveColor,
    this.trackGradient,
    required this.trackHeight,
    required this.trackRadius,
    required this.trackEndInset,
    required this.thumbColor,
    required this.thumbBorderColor,
    this.thumbGradient,
    required this.thumbRadius,
    required this.thumbElevation,
    required this.overlayRadius,
    required this.segmentGap,
    required this.secondaryColor,
    required this.ringThickness,
    required this.ringDiameter,
    required this.ringThumbRadius,
    required this.ringCapped,
    required this.ringTouchSlop,
    required this.trimHandleWidth,
    required this.trimHandleTouchSlop,
    required this.trimRailHeight,
    required this.trimPlayheadWidth,
    required this.trimPlayheadColor,
    required this.trimScrimColor,
    required this.trimGripColor,
    required this.showTicks,
    required this.tickStyle,
    required this.stepLabelStyle,
    required this.stepLabelGap,
    required this.showValueIndicator,
    required this.indicatorStyle,
    required this.showContainer,
    this.containerDecoration,
    required this.containerPadding,
    required this.containerColor,
    required this.containerBorderColor,
    required this.containerRadius,
    required this.containerShadow,
    required this.labelStyle,
    required this.valueStyle,
    required this.minMaxStyle,
    required this.valueBadgeColor,
    required this.valueBadgeBorderColor,
    required this.valueBadgeRadius,
    required this.valueBadgePadding,
    required this.endChipColor,
    required this.endChipRadius,
    required this.endChipPadding,
    required this.enableHaptic,
    required this.disabledOpacity,
  });

  final Color activeColor;
  final Color inactiveColor;
  final Gradient? trackGradient;
  final double trackHeight;
  final double trackRadius;
  final double trackEndInset;
  final Color thumbColor;
  final Color thumbBorderColor;
  final Gradient? thumbGradient;
  final double thumbRadius;
  final double thumbElevation;
  final double overlayRadius;
  final double segmentGap;
  final Color secondaryColor;
  final double ringThickness;
  final double ringDiameter;
  final double ringThumbRadius;
  final bool ringCapped;
  final double ringTouchSlop;
  final double trimHandleWidth;
  final double trimHandleTouchSlop;
  final double trimRailHeight;
  final double trimPlayheadWidth;
  final Color trimPlayheadColor;
  final Color trimScrimColor;
  final Color trimGripColor;
  final bool showTicks;
  final ResolvedSliderTickStyle tickStyle;
  final TextStyle stepLabelStyle;
  final double stepLabelGap;
  final bool showValueIndicator;
  final ResolvedSliderIndicatorStyle indicatorStyle;
  final bool showContainer;
  final BoxDecoration? containerDecoration;
  final EdgeInsetsGeometry containerPadding;
  final Color containerColor;
  final Color containerBorderColor;
  final double containerRadius;
  final List<BoxShadow> containerShadow;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final TextStyle minMaxStyle;
  final Color valueBadgeColor;
  final Color valueBadgeBorderColor;
  final double valueBadgeRadius;
  final EdgeInsetsGeometry valueBadgePadding;
  final Color endChipColor;
  final double endChipRadius;
  final EdgeInsetsGeometry endChipPadding;
  final bool enableHaptic;
  final double disabledOpacity;

  /// A bag with no palette behind it.
  ///
  /// Only ever the value a state holds between construction and its
  /// first `build`; nothing is painted from it.
  static const ResolvedSliderStyle fallback = ResolvedSliderStyle(
    activeColor: Color(0xFF2196F3),
    inactiveColor: Color(0x332196F3),
    trackHeight: SliderDefaults.trackHeight,
    trackRadius: SliderDefaults.trackHeight * SliderDefaults.trackRadiusFactor,
    trackEndInset: SliderDefaults.trackEndInset,
    thumbColor: Color(0xFFFFFFFF),
    thumbBorderColor: Color(0xFFFFFFFF),
    thumbRadius: SliderDefaults.thumbRadius,
    thumbElevation: SliderDefaults.thumbElevation,
    overlayRadius: SliderDefaults.overlayRadius,
    segmentGap: SliderDefaults.segmentGap,
    secondaryColor: Color(0x592196F3),
    ringThickness: SliderDefaults.ringThickness,
    ringDiameter: SliderDefaults.ringDiameter,
    ringThumbRadius: SliderDefaults.ringThumbRadius,
    ringCapped: true,
    ringTouchSlop: SliderDefaults.ringTouchSlop,
    trimHandleWidth: SliderDefaults.trimHandleWidth,
    trimHandleTouchSlop: SliderDefaults.trimHandleTouchSlop,
    trimRailHeight: SliderDefaults.trimRailHeight,
    trimPlayheadWidth: SliderDefaults.trimPlayheadWidth,
    trimPlayheadColor: Color(0xFFFFFFFF),
    trimScrimColor: Color(0x8C000000),
    trimGripColor: Color(0xFFFFFFFF),
    stepLabelStyle: TextStyle(),
    stepLabelGap: 4,
    showTicks: false,
    tickStyle: ResolvedSliderTickStyle(
      color: Color(0x4D000000),
      activeColor: Color(0xFFFFFFFF),
      radius: SliderDefaults.tickRadius,
      shape: SliderTickShape.circle,
    ),
    showValueIndicator: true,
    indicatorStyle: ResolvedSliderIndicatorStyle(
      shape: SliderIndicatorShape.paddle,
      color: Color(0xFF2196F3),
      textStyle: TextStyle(color: Color(0xFFFFFFFF)),
      borderRadius: SliderDefaults.indicatorRadius,
      padding: SliderDefaults.indicatorPadding,
      arrowSize: SliderDefaults.indicatorArrowSize,
      verticalOffset: SliderDefaults.indicatorVerticalOffset,
    ),
    showContainer: true,
    containerPadding: EdgeInsets.all(12),
    containerColor: Color(0xFFFFFFFF),
    containerBorderColor: Color(0x1F000000),
    containerRadius: 12,
    containerShadow: <BoxShadow>[],
    labelStyle: TextStyle(),
    valueStyle: TextStyle(),
    minMaxStyle: TextStyle(),
    valueBadgeColor: Color(0x142196F3),
    valueBadgeBorderColor: Color(0x332196F3),
    valueBadgeRadius: 8,
    valueBadgePadding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    endChipColor: Color(0x0A000000),
    endChipRadius: 4,
    endChipPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    enableHaptic: true,
    disabledOpacity: SliderDefaults.disabledOpacity,
  );
}
