import 'package:flutter/material.dart';

/// The compile-time floor under [SwipeButtonStyle].
///
/// Sizes a token can express are NOT here — those come from
/// `MyGlobalButtonsTheme`, which reads `AppTokens` and so tracks the
/// window bucket. What is here is what a token cannot say: the
/// geometry the gesture needs, and the opacities.
abstract final class SwipeButtonDefaults {
  static const trackHeight = 56.0;

  /// Between the thumb and the inside of the track.
  static const thumbInset = 4.0;

  /// How far along the reader must have taken it for a RELEASE to
  /// count.
  ///
  /// Not 1.0. A track that only commits when the thumb is pinned to
  /// the far wall makes the last few points feel broken — the reader
  /// is there, nothing happens, and they push harder. Not much lower
  /// either: the whole point of the control is that it cannot go off
  /// by accident.
  static const confirmThreshold = 0.9;

  /// How long the thumb takes to spring back from an abandoned drag.
  static const returnDuration = Duration(milliseconds: 240);

  /// And to snap forward once the threshold is passed.
  static const settleDuration = Duration(milliseconds: 140);

  /// One sweep of the hint shimmer, and the wait between sweeps.
  static const hintDuration = Duration(milliseconds: 1400);
  static const hintPause = Duration(milliseconds: 900);

  /// How many times it sweeps before it rests.
  ///
  /// It is an INVITATION, not a loading bar. A shimmer that never
  /// stops also means the tree never goes idle — every frame of a page
  /// that has one is spent repainting it, and nothing that waits for
  /// quiescence (a `pumpAndSettle`, an integration driver) ever gets
  /// it.
  static const hintSweeps = 3;

  /// One state of the thumb morphing into the next.
  static const morphDuration = Duration(milliseconds: 220);

  /// The keyboard focus ring. Two points, because one is a hairline
  /// against a filled track and reads as an artefact.
  static const focusRingWidth = 2.0;

  /// How long a vertical track is, when nothing bounds it.
  ///
  /// A length rather than "fill the parent": a swipe button in a
  /// column has no natural height, and an unbounded one would be
  /// asked for infinity.
  static const verticalExtent = 220.0;

  /// The narrowest a track may be, as a multiple of its thickness.
  ///
  /// Below about three thumb-widths the gesture is uncomfortable and
  /// the label has nowhere to go — it is a programmer error, caught in
  /// debug rather than shipped as a control nobody can work.
  static const minLengthFactor = 3.0;

  static const disabledOpacity = 0.4;

  /// The label under the shimmer, at rest.
  static const labelOpacity = 0.85;

  /// How far past the thumb the shimmer's highlight reaches.
  static const hintWidthFactor = 0.35;
}

/// How a `GlobalSwipeButton` looks and how far it has to travel.
///
/// Every field is nullable so the three sources layer without a
/// default clobbering a theme: `caller > GlobalButtonsTheme.swipeStyle
/// > SwipeButtonStyle.defaults`.
@immutable
class SwipeButtonStyle {
  const SwipeButtonStyle({
    this.trackColor,
    this.trackGradient,
    this.fillColor,
    this.fillTrack,
    this.trackHeight,
    this.trackRadius,
    this.thumbColor,
    this.thumbForegroundColor,
    this.thumbInset,
    this.thumbRadius,
    this.labelStyle,
    this.confirmThreshold,
    this.showHint,
    this.hintColor,
    this.returnDuration,
    this.settleDuration,
    this.fillEndRadius,
    this.confirmedLabelColor,
    this.flingVelocity,
    this.focusRingColor,
    this.focusRingWidth,
    this.enableHaptic,
    this.disabledOpacity,
  });

  /// The floor.
  ///
  /// Colours are absent on purpose — they resolve from the palette at
  /// build time so they track role, brightness and saturation, which a
  /// constant cannot.
  static const SwipeButtonStyle defaults = SwipeButtonStyle(
    fillTrack: true,
    trackHeight: SwipeButtonDefaults.trackHeight,
    thumbInset: SwipeButtonDefaults.thumbInset,
    confirmThreshold: SwipeButtonDefaults.confirmThreshold,
    showHint: true,
    returnDuration: SwipeButtonDefaults.returnDuration,
    settleDuration: SwipeButtonDefaults.settleDuration,
    focusRingWidth: SwipeButtonDefaults.focusRingWidth,
    enableHaptic: true,
    disabledOpacity: SwipeButtonDefaults.disabledOpacity,
  );

  /// The unswiped track.
  final Color? trackColor;
  final Gradient? trackGradient;

  /// What fills in BEHIND the thumb as it travels.
  final Color? fillColor;

  /// Whether it fills at all. Off leaves a plain track with a thumb
  /// sliding along it — quieter, and right when the track is already
  /// a strong colour.
  final bool? fillTrack;

  final double? trackHeight;

  /// The corner on the MOVING edge of the fill.
  ///
  /// Zero is a straight cut, which is what a progress bar looks like.
  /// Half the thickness makes the fill a capsule that grows out from
  /// under the thumb. The other end is rounded by the track's own clip
  /// either way.
  final double? fillEndRadius;

  /// The completed label, which sits ON the fill rather than on the
  /// empty track. Falls back to what reads on the fill colour.
  final Color? confirmedLabelColor;

  /// Pixels per second past which a RELEASE confirms even short of
  /// [confirmThreshold].
  ///
  /// Null is off, and off is the default: the whole point of the
  /// control is that it cannot fire by accident, and a flick is the
  /// gesture most likely to happen without meaning. Turn it on where a
  /// deliberate flick is the expected motion and the action is
  /// recoverable.
  final double? flingVelocity;

  /// The track's corner. Null is a pill: half the height.
  final double? trackRadius;

  final Color? thumbColor;

  /// The glyph inside the thumb.
  final Color? thumbForegroundColor;

  final double? thumbInset;

  /// The thumb's corner. Null follows the track's, less the inset, so
  /// a pill track gets a round thumb and a soft-cornered one gets a
  /// soft-cornered thumb.
  final double? thumbRadius;

  final TextStyle? labelStyle;

  /// How far along a RELEASE counts as a confirmation, 0..1.
  final double? confirmThreshold;

  /// The shimmer that says the track is draggable.
  final bool? showHint;
  final Color? hintColor;

  final Duration? returnDuration;
  final Duration? settleDuration;

  /// The ring drawn round the track while the KEYBOARD is on it.
  /// Falls back to the accent.
  final Color? focusRingColor;
  final double? focusRingWidth;

  final bool? enableHaptic;
  final double? disabledOpacity;

  /// [other] wins field by field. Null means "did not say".
  SwipeButtonStyle mergedWith(SwipeButtonStyle? other) {
    if (other == null) return this;
    return SwipeButtonStyle(
      trackColor: other.trackColor ?? trackColor,
      trackGradient: other.trackGradient ?? trackGradient,
      fillColor: other.fillColor ?? fillColor,
      fillTrack: other.fillTrack ?? fillTrack,
      trackHeight: other.trackHeight ?? trackHeight,
      trackRadius: other.trackRadius ?? trackRadius,
      thumbColor: other.thumbColor ?? thumbColor,
      thumbForegroundColor: other.thumbForegroundColor ?? thumbForegroundColor,
      thumbInset: other.thumbInset ?? thumbInset,
      thumbRadius: other.thumbRadius ?? thumbRadius,
      labelStyle: other.labelStyle ?? labelStyle,
      confirmThreshold: other.confirmThreshold ?? confirmThreshold,
      showHint: other.showHint ?? showHint,
      hintColor: other.hintColor ?? hintColor,
      returnDuration: other.returnDuration ?? returnDuration,
      settleDuration: other.settleDuration ?? settleDuration,
      fillEndRadius: other.fillEndRadius ?? fillEndRadius,
      confirmedLabelColor: other.confirmedLabelColor ?? confirmedLabelColor,
      flingVelocity: other.flingVelocity ?? flingVelocity,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      focusRingWidth: other.focusRingWidth ?? focusRingWidth,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      disabledOpacity: other.disabledOpacity ?? disabledOpacity,
    );
  }

  SwipeButtonStyle copyWith({
    Color? trackColor,
    Gradient? trackGradient,
    Color? fillColor,
    bool? fillTrack,
    double? trackHeight,
    double? trackRadius,
    Color? thumbColor,
    Color? thumbForegroundColor,
    double? thumbInset,
    double? thumbRadius,
    TextStyle? labelStyle,
    double? confirmThreshold,
    bool? showHint,
    Color? hintColor,
    Duration? returnDuration,
    Duration? settleDuration,
    double? fillEndRadius,
    Color? confirmedLabelColor,
    double? flingVelocity,
    Color? focusRingColor,
    double? focusRingWidth,
    bool? enableHaptic,
    double? disabledOpacity,
  }) => SwipeButtonStyle(
    trackColor: trackColor ?? this.trackColor,
    trackGradient: trackGradient ?? this.trackGradient,
    fillColor: fillColor ?? this.fillColor,
    fillTrack: fillTrack ?? this.fillTrack,
    trackHeight: trackHeight ?? this.trackHeight,
    trackRadius: trackRadius ?? this.trackRadius,
    thumbColor: thumbColor ?? this.thumbColor,
    thumbForegroundColor: thumbForegroundColor ?? this.thumbForegroundColor,
    thumbInset: thumbInset ?? this.thumbInset,
    thumbRadius: thumbRadius ?? this.thumbRadius,
    labelStyle: labelStyle ?? this.labelStyle,
    confirmThreshold: confirmThreshold ?? this.confirmThreshold,
    showHint: showHint ?? this.showHint,
    hintColor: hintColor ?? this.hintColor,
    returnDuration: returnDuration ?? this.returnDuration,
    settleDuration: settleDuration ?? this.settleDuration,
    fillEndRadius: fillEndRadius ?? this.fillEndRadius,
    confirmedLabelColor: confirmedLabelColor ?? this.confirmedLabelColor,
    flingVelocity: flingVelocity ?? this.flingVelocity,
    focusRingColor: focusRingColor ?? this.focusRingColor,
    focusRingWidth: focusRingWidth ?? this.focusRingWidth,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    disabledOpacity: disabledOpacity ?? this.disabledOpacity,
  );

  @override
  bool operator ==(Object other) =>
      other is SwipeButtonStyle &&
      other.trackColor == trackColor &&
      other.trackGradient == trackGradient &&
      other.fillColor == fillColor &&
      other.fillTrack == fillTrack &&
      other.trackHeight == trackHeight &&
      other.trackRadius == trackRadius &&
      other.thumbColor == thumbColor &&
      other.thumbForegroundColor == thumbForegroundColor &&
      other.thumbInset == thumbInset &&
      other.thumbRadius == thumbRadius &&
      other.labelStyle == labelStyle &&
      other.confirmThreshold == confirmThreshold &&
      other.showHint == showHint &&
      other.hintColor == hintColor &&
      other.returnDuration == returnDuration &&
      other.settleDuration == settleDuration &&
      other.fillEndRadius == fillEndRadius &&
      other.confirmedLabelColor == confirmedLabelColor &&
      other.flingVelocity == flingVelocity &&
      other.focusRingColor == focusRingColor &&
      other.focusRingWidth == focusRingWidth &&
      other.enableHaptic == enableHaptic &&
      other.disabledOpacity == disabledOpacity;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    trackColor,
    trackGradient,
    fillColor,
    fillTrack,
    trackHeight,
    trackRadius,
    thumbColor,
    thumbForegroundColor,
    thumbInset,
    thumbRadius,
    labelStyle,
    confirmThreshold,
    showHint,
    hintColor,
    returnDuration,
    settleDuration,
    fillEndRadius,
    confirmedLabelColor,
    flingVelocity,
    focusRingColor,
    focusRingWidth,
    enableHaptic,
    disabledOpacity,
  ]);
}

/// A [SwipeButtonStyle] with every question answered.
@immutable
class ResolvedSwipeButtonStyle {
  const ResolvedSwipeButtonStyle({
    required this.trackColor,
    required this.trackGradient,
    required this.fillColor,
    required this.fillTrack,
    required this.trackHeight,
    required this.trackRadius,
    required this.thumbColor,
    required this.thumbForegroundColor,
    required this.thumbInset,
    required this.thumbRadius,
    required this.labelStyle,
    required this.confirmThreshold,
    required this.showHint,
    required this.hintColor,
    required this.returnDuration,
    required this.settleDuration,
    required this.fillEndRadius,
    required this.confirmedLabelColor,
    required this.flingVelocity,
    required this.focusRingColor,
    required this.focusRingWidth,
    required this.enableHaptic,
    required this.disabledOpacity,
  });

  final Color trackColor;
  final Gradient? trackGradient;
  final Color fillColor;
  final bool fillTrack;
  final double trackHeight;
  final double trackRadius;
  final Color thumbColor;
  final Color thumbForegroundColor;
  final double thumbInset;
  final double thumbRadius;
  final TextStyle labelStyle;
  final double confirmThreshold;
  final bool showHint;
  final Color hintColor;
  final Duration returnDuration;
  final Duration settleDuration;
  final double fillEndRadius;
  final Color confirmedLabelColor;

  /// Null when a fling never confirms on its own.
  final double? flingVelocity;
  final Color focusRingColor;
  final double focusRingWidth;
  final bool enableHaptic;
  final double disabledOpacity;
}
