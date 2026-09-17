import 'package:flutter/material.dart';

/// Direction the top card was swiped toward when dismissed.
enum CardSwipeDirection { left, right, up, down }

/// Where the cards BEHIND the top one peek out from.
///
/// [none] puts them exactly under it — a flat pile, told apart only
/// by `scaleStep`.
enum StackPeekDirection {
  none,
  top,
  bottom,
  left,
  right,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// The floor for both stacks.
abstract final class StackDefaults {
  // ─── Depth: shared by BOTH stacks ─────────────────────────
  /// How many cards are drawn, the top one included.
  static const visibleDepth = 3;

  /// Scale removed per depth. Three cards at 0.05 read as a deck;
  /// much more and the third card looks like a different object.
  static const scaleStep = 0.05;

  /// Pixels each card is shifted by, per depth, along
  /// [peekDirection].
  static const peekOffset = 16.0;

  static const peekDirection = StackPeekDirection.bottom;

  /// Opacity removed per depth. Zero — a deck that fades out reads
  /// as a deck that is loading.
  static const opacityStep = 0.0;

  /// The smallest a deep card is allowed to get, whatever
  /// [scaleStep] and [visibleDepth] multiply out to.
  static const minScale = 0.6;

  static const duration = Duration(milliseconds: 280);
  static const curve = Curves.easeOutCubic;

  // ─── The swipe: GlobalCardStack only ──────────────────────
  /// Drag distance, in pixels, that dismisses instead of snapping
  /// back.
  static const swipeThreshold = 100.0;

  /// Tilt at a full-width drag.
  static const maxRotationDegrees = 14.0;

  /// A FLICK dismisses under the threshold, at this speed in pixels
  /// a second.
  ///
  /// Distance alone made a fast, short flick snap back — which is
  /// the gesture people actually make once they know the deck.
  static const flingVelocity = 700.0;

  static const snapDuration = Duration(milliseconds: 240);
  static const dismissDuration = Duration(milliseconds: 320);

  /// A dismissal ticks. It is a commitment, and the card leaving is
  /// the only other confirmation.
  static const enableHaptic = true;

  /// How many dismissals can be rewound.
  ///
  /// A triage session that deals a thousand cards kept every one of
  /// them; ten is further back than anyone reaches, and the oldest
  /// falls off the end.
  static const undoLimit = 10;

  /// Where the top card PIVOTS, as a fraction of half its height
  /// below the centre.
  ///
  /// A card rotating about its own centre reads as a card being
  /// twisted. A real deck pivots about a point below the card, near
  /// where a thumb would be — the top swings further than the bottom
  /// and it reads as a card being flicked away.
  static const rotationAnchorY = 1.6;

  static const respectReducedMotion = true;
}

/// How a stack is BUILT — shared by `GlobalCardStack` and
/// `GlobalLayeredStack`.
///
/// Every field is nullable: unanswered means "ask the theme, then the
/// floor". The bag carries no COLOURS — neither stack paints anything
/// of its own; the caller's `itemBuilder` draws every card. What a
/// house sets once here is the GEOMETRY of depth, and that is exactly
/// what must not drift: the two modules had their own copies of
/// `scaleStep`, a peek offset and a visible-layer cap, so deepening
/// the pile on one left the other on its own numbers.
///
/// The swipe fields belong to the card stack alone and are ignored by
/// the layered one — the same shape as the page family's bag, where
/// one extension serves three widgets and each reads the fields it
/// has a use for. Two bags would be two rebrand hooks that can
/// disagree about the one thing the two modules genuinely share.
@immutable
class StackStyle {
  const StackStyle({
    this.visibleDepth,
    this.scaleStep,
    this.peekOffset,
    this.peekDirection,
    this.opacityStep,
    this.minScale,
    this.duration,
    this.curve,
    this.swipeThreshold,
    this.maxRotationDegrees,
    this.flingVelocity,
    this.snapDuration,
    this.dismissDuration,
    this.enableHaptic,
    this.undoLimit,
    this.rotationAnchorY,
    this.respectReducedMotion,
  });

  /// The floor — the only place a compile-time constant lives.
  static const defaults = StackStyle(
    visibleDepth: StackDefaults.visibleDepth,
    scaleStep: StackDefaults.scaleStep,
    peekOffset: StackDefaults.peekOffset,
    peekDirection: StackDefaults.peekDirection,
    opacityStep: StackDefaults.opacityStep,
    minScale: StackDefaults.minScale,
    duration: StackDefaults.duration,
    curve: StackDefaults.curve,
    swipeThreshold: StackDefaults.swipeThreshold,
    maxRotationDegrees: StackDefaults.maxRotationDegrees,
    flingVelocity: StackDefaults.flingVelocity,
    snapDuration: StackDefaults.snapDuration,
    dismissDuration: StackDefaults.dismissDuration,
    enableHaptic: StackDefaults.enableHaptic,
    undoLimit: StackDefaults.undoLimit,
    rotationAnchorY: StackDefaults.rotationAnchorY,
    respectReducedMotion: StackDefaults.respectReducedMotion,
  );

  /// A flat pile: no peek, no tilt, told apart by scale alone. What
  /// a wallet or a stack of photos looks like.
  static const flat = StackStyle(
    peekDirection: StackPeekDirection.none,
    scaleStep: 0.04,
    maxRotationDegrees: 0,
    rotationAnchorY: 0,
  );

  /// A notification pile — offset down and to the reading end, each
  /// card slightly faded.
  static const notifications = StackStyle(
    peekDirection: StackPeekDirection.bottomRight,
    peekOffset: 8,
    scaleStep: 0.03,
    opacityStep: 0.15,
    visibleDepth: 4,
  );

  /// A deck that answers quickly — a lighter threshold and a faster
  /// fly-out, for a triage screen where the reader deals many cards.
  static const decisive = StackStyle(
    swipeThreshold: 72,
    flingVelocity: 500,
    dismissDuration: Duration(milliseconds: 220),
  );

  // ─── Depth ────────────────────────────────────────────────
  final int? visibleDepth;
  final double? scaleStep;
  final double? peekOffset;
  final StackPeekDirection? peekDirection;
  final double? opacityStep;
  final double? minScale;

  /// How long a card takes to settle into a new depth.
  final Duration? duration;
  final Curve? curve;

  // ─── The swipe (card stack only) ──────────────────────────
  final double? swipeThreshold;
  final double? maxRotationDegrees;
  final double? flingVelocity;
  final Duration? snapDuration;
  final Duration? dismissDuration;
  final bool? enableHaptic;

  /// How many dismissals can be rewound. Zero disables undo as surely
  /// as `allowUndo: false` does.
  final int? undoLimit;

  /// Where the top card pivots, in half-heights below its centre.
  /// Zero rotates about the card's own middle.
  final double? rotationAnchorY;

  /// Whether `MediaQuery.disableAnimationsOf` flattens the motion.
  ///
  /// It does NOT stop the deck working: a dismissal is the control,
  /// and a card that cannot leave is a deck that cannot be used. What
  /// goes is the TILT and the travel — the card is simply gone, and
  /// the one behind it is simply there.
  final bool? respectReducedMotion;

  /// Field-by-field: whatever `other` answers wins, and what it
  /// leaves null keeps this bag's answer.
  StackStyle mergedWith(StackStyle? other) {
    if (other == null) return this;
    return StackStyle(
      visibleDepth: other.visibleDepth ?? visibleDepth,
      scaleStep: other.scaleStep ?? scaleStep,
      peekOffset: other.peekOffset ?? peekOffset,
      peekDirection: other.peekDirection ?? peekDirection,
      opacityStep: other.opacityStep ?? opacityStep,
      minScale: other.minScale ?? minScale,
      duration: other.duration ?? duration,
      curve: other.curve ?? curve,
      swipeThreshold: other.swipeThreshold ?? swipeThreshold,
      maxRotationDegrees: other.maxRotationDegrees ?? maxRotationDegrees,
      flingVelocity: other.flingVelocity ?? flingVelocity,
      snapDuration: other.snapDuration ?? snapDuration,
      dismissDuration: other.dismissDuration ?? dismissDuration,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      undoLimit: other.undoLimit ?? undoLimit,
      rotationAnchorY: other.rotationAnchorY ?? rotationAnchorY,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
    );
  }

  StackStyle copyWith({
    int? visibleDepth,
    double? scaleStep,
    double? peekOffset,
    StackPeekDirection? peekDirection,
    double? opacityStep,
    double? minScale,
    Duration? duration,
    Curve? curve,
    double? swipeThreshold,
    double? maxRotationDegrees,
    double? flingVelocity,
    Duration? snapDuration,
    Duration? dismissDuration,
    bool? enableHaptic,
    int? undoLimit,
    double? rotationAnchorY,
    bool? respectReducedMotion,
  }) => StackStyle(
    visibleDepth: visibleDepth ?? this.visibleDepth,
    scaleStep: scaleStep ?? this.scaleStep,
    peekOffset: peekOffset ?? this.peekOffset,
    peekDirection: peekDirection ?? this.peekDirection,
    opacityStep: opacityStep ?? this.opacityStep,
    minScale: minScale ?? this.minScale,
    duration: duration ?? this.duration,
    curve: curve ?? this.curve,
    swipeThreshold: swipeThreshold ?? this.swipeThreshold,
    maxRotationDegrees: maxRotationDegrees ?? this.maxRotationDegrees,
    flingVelocity: flingVelocity ?? this.flingVelocity,
    snapDuration: snapDuration ?? this.snapDuration,
    dismissDuration: dismissDuration ?? this.dismissDuration,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    undoLimit: undoLimit ?? this.undoLimit,
    rotationAnchorY: rotationAnchorY ?? this.rotationAnchorY,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );

  @override
  bool operator ==(Object other) =>
      other is StackStyle &&
      other.visibleDepth == visibleDepth &&
      other.scaleStep == scaleStep &&
      other.peekOffset == peekOffset &&
      other.peekDirection == peekDirection &&
      other.opacityStep == opacityStep &&
      other.minScale == minScale &&
      other.duration == duration &&
      other.curve == curve &&
      other.swipeThreshold == swipeThreshold &&
      other.maxRotationDegrees == maxRotationDegrees &&
      other.flingVelocity == flingVelocity &&
      other.snapDuration == snapDuration &&
      other.dismissDuration == dismissDuration &&
      other.enableHaptic == enableHaptic &&
      other.undoLimit == undoLimit &&
      other.rotationAnchorY == rotationAnchorY &&
      other.respectReducedMotion == respectReducedMotion;

  @override
  int get hashCode => Object.hash(
    visibleDepth,
    scaleStep,
    peekOffset,
    peekDirection,
    opacityStep,
    minScale,
    duration,
    curve,
    swipeThreshold,
    maxRotationDegrees,
    flingVelocity,
    snapDuration,
    dismissDuration,
    enableHaptic,
    undoLimit,
    rotationAnchorY,
    respectReducedMotion,
  );
}

/// A [StackStyle] with every question answered.
@immutable
class ResolvedStackStyle {
  const ResolvedStackStyle({
    required this.visibleDepth,
    required this.scaleStep,
    required this.peekOffset,
    required this.peekDirection,
    required this.opacityStep,
    required this.minScale,
    required this.duration,
    required this.curve,
    required this.swipeThreshold,
    required this.maxRotationDegrees,
    required this.flingVelocity,
    required this.snapDuration,
    required this.dismissDuration,
    required this.enableHaptic,
    required this.undoLimit,
    required this.rotationAnchorY,
    required this.still,
  });

  final int visibleDepth;
  final double scaleStep;
  final double peekOffset;
  final StackPeekDirection peekDirection;
  final double opacityStep;
  final double minScale;
  final Duration duration;
  final Curve curve;

  /// ZERO when [still] — the card is simply gone.
  final double maxRotationDegrees;

  final double swipeThreshold;
  final double flingVelocity;
  final Duration snapDuration;
  final Duration dismissDuration;
  final bool enableHaptic;
  final int undoLimit;

  /// ZERO when [still] — a card that does not travel does not pivot
  /// either.
  final double rotationAnchorY;

  /// Whether the reader has asked for motion to stop.
  final bool still;

  /// Where a card sits at [depth], relative to the top one.
  ///
  /// Mirrored for the reading direction: a pile peeking out to the
  /// `right` in English peeks out to the LEFT in Arabic, because the
  /// direction it fans toward is where a reader's eye already goes.
  Offset peekAt(int depth, TextDirection direction) {
    final base = peekOffset * depth;
    final rtl = direction == TextDirection.rtl;
    final x = rtl ? -base : base;
    switch (peekDirection) {
      case StackPeekDirection.none:
        return Offset.zero;
      case StackPeekDirection.top:
        return Offset(0, -base);
      case StackPeekDirection.bottom:
        return Offset(0, base);
      case StackPeekDirection.left:
        return Offset(-x, 0);
      case StackPeekDirection.right:
        return Offset(x, 0);
      case StackPeekDirection.topLeft:
        return Offset(-x, -base);
      case StackPeekDirection.topRight:
        return Offset(x, -base);
      case StackPeekDirection.bottomLeft:
        return Offset(-x, base);
      case StackPeekDirection.bottomRight:
        return Offset(x, base);
    }
  }

  /// The scale at [depth], never past [minScale].
  double scaleAt(double depth) => (1 - scaleStep * depth).clamp(minScale, 1.0);

  /// The opacity at [depth].
  double opacityAt(double depth) => (1 - opacityStep * depth).clamp(0.0, 1.0);
}
