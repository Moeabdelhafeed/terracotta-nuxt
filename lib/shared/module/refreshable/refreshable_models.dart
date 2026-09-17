import 'package:flutter/material.dart';

/// The floor. Every field the bag can leave unanswered has its answer
/// here, so a caller who sets nothing still gets a working indicator.
abstract final class RefreshableDefaults {
  /// How far down the settled indicator sits. Material-only.
  static const displacement = 40.0;

  /// Nudge for a sticky app bar or banner over the top of the
  /// scrollable. Material-only.
  static const edgeOffset = 0.0;

  /// Width of the circular progress stroke. Material-only.
  static const strokeWidth = 2.5;

  /// How long the indicator stays up once the work is done.
  ///
  /// A fetch that resolves in 80ms flashes the spinner on and off, and
  /// the reader is left unsure whether anything happened. This is a
  /// FLOOR on the visible time, not an animation, so reduced motion
  /// leaves it alone.
  static const minShowDuration = Duration(milliseconds: 600);

  /// How far the pull has to go before the haptic fires — short of the
  /// distance that actually triggers a refresh, so the tick says "keep
  /// going" rather than "done".
  static const hapticThreshold = 40.0;

  /// Where the illustration sits below the top of the scrollable.
  static const illustrationOffset = 88.0;

  /// How long the illustration takes to fade in. Zeroed under reduced
  /// motion — this one IS decoration.
  static const illustrationFade = Duration(milliseconds: 200);

  /// How long a caller's own indicator takes to settle back after the
  /// work is done.
  static const customSettle = Duration(milliseconds: 250);

  /// How far the pull has to travel before a caller's own indicator
  /// counts as armed. Material's own trigger is about this far.
  static const customTriggerExtent = 100.0;

  /// The shortest gap between two refreshes. Zero — pulling twice is
  /// the reader saying they meant it, and a module that silently
  /// ignored the second pull would be lying about what it did.
  static const minRefreshInterval = Duration.zero;

  static const enableHaptic = true;
  static const respectReducedMotion = true;
}

/// Which indicator is drawn.
enum RefreshableVariant {
  /// Material spinner — a circular `RefreshProgressIndicator`.
  material,

  /// Cupertino spinner, on EVERY platform.
  ///
  /// Flutter's `RefreshIndicator.adaptive` reads the platform off the
  /// ambient `Theme`, so asking for Cupertino on Android used to hand
  /// back the Material spinner — the variant said one thing and drew
  /// another. The module overrides the theme's platform for the
  /// indicator alone, so this now means what it says.
  cupertino,

  /// Cupertino on iOS and macOS, Material everywhere else.
  adaptive,

  /// The caller draws it, from `GlobalRefreshable.indicatorBuilder`.
  ///
  /// Material's `RefreshIndicator` has no slot for a different spinner
  /// — the widget owns its own painting — so this is a separate
  /// control that reports the pull instead: the builder gets the
  /// progress as the finger moves, and the module runs the work when
  /// it is released past the trigger.
  custom,
}

/// How a [GlobalRefreshable] looks and behaves.
///
/// Every field is nullable: unanswered means "ask the theme, then the
/// floor". See `theme/refreshable_theme.dart` for the resolve.
@immutable
class RefreshableStyle {
  const RefreshableStyle({
    this.variant,
    this.color,
    this.backgroundColor,
    this.displacement,
    this.edgeOffset,
    this.strokeWidth,
    this.minShowDuration,
    this.hapticThreshold,
    this.illustrationOffset,
    this.illustrationFade,
    this.customSettle,
    this.customTriggerExtent,
    this.minRefreshInterval,
    this.enableHaptic,
    this.respectReducedMotion,
  });

  /// The floor — the only place a compile-time constant lives.
  static const defaults = RefreshableStyle(
    variant: RefreshableVariant.adaptive,
    displacement: RefreshableDefaults.displacement,
    edgeOffset: RefreshableDefaults.edgeOffset,
    strokeWidth: RefreshableDefaults.strokeWidth,
    minShowDuration: RefreshableDefaults.minShowDuration,
    hapticThreshold: RefreshableDefaults.hapticThreshold,
    illustrationOffset: RefreshableDefaults.illustrationOffset,
    illustrationFade: RefreshableDefaults.illustrationFade,
    customSettle: RefreshableDefaults.customSettle,
    customTriggerExtent: RefreshableDefaults.customTriggerExtent,
    minRefreshInterval: RefreshableDefaults.minRefreshInterval,
    enableHaptic: RefreshableDefaults.enableHaptic,
    respectReducedMotion: RefreshableDefaults.respectReducedMotion,
  );

  /// Material spinner whatever the platform.
  static const material = RefreshableStyle(
    variant: RefreshableVariant.material,
  );

  /// Cupertino spinner whatever the platform.
  static const cupertino = RefreshableStyle(
    variant: RefreshableVariant.cupertino,
  );

  /// No haptic — for a surface that refreshes often, or one that
  /// already gives feedback of its own.
  static const quiet = RefreshableStyle(enableHaptic: false);

  /// Which indicator is drawn.
  final RefreshableVariant? variant;

  /// The spinner's own colour. Falls back to the palette's primary.
  final Color? color;

  /// The pill behind the spinner. Falls back to the palette's card
  /// background — a surface ABOVE the page, which is what it is.
  final Color? backgroundColor;

  /// How far down the settled indicator sits. Material-only.
  final double? displacement;

  /// Nudge for chrome pinned over the top of the scrollable.
  /// Material-only.
  final double? edgeOffset;

  /// Width of the circular progress stroke. Material-only.
  final double? strokeWidth;

  /// How long the indicator stays up once the work is done — a floor
  /// on the visible time, so a fast fetch does not flash.
  final Duration? minShowDuration;

  /// How far the pull goes before the haptic fires.
  final double? hapticThreshold;

  /// Where the illustration sits below the top of the scrollable.
  final double? illustrationOffset;

  /// How long the illustration takes to fade in. Zero under reduced
  /// motion.
  final Duration? illustrationFade;

  /// How long a caller's own indicator takes to settle back. Zero
  /// under reduced motion.
  final Duration? customSettle;

  /// How far the pull travels before a caller's own indicator is
  /// armed.
  final double? customTriggerExtent;

  /// The shortest gap between two refreshes.
  ///
  /// A pull inside the window still shows the indicator — the gesture
  /// has to feel like it landed — but the work is not re-run, and
  /// `GlobalRefreshable.onSkipped` says so. Leave it at zero unless a
  /// fetch is genuinely expensive: a reader who pulls twice usually
  /// means it.
  final Duration? minRefreshInterval;

  final bool? enableHaptic;

  /// Whether `MediaQuery.disableAnimationsOf` zeroes what it can.
  /// False for an indicator that IS the content of the screen.
  final bool? respectReducedMotion;

  /// Field-by-field: whatever `other` answers wins, and what it leaves
  /// null keeps this bag's answer.
  RefreshableStyle mergedWith(RefreshableStyle? other) {
    if (other == null) return this;
    return RefreshableStyle(
      variant: other.variant ?? variant,
      color: other.color ?? color,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      displacement: other.displacement ?? displacement,
      edgeOffset: other.edgeOffset ?? edgeOffset,
      strokeWidth: other.strokeWidth ?? strokeWidth,
      minShowDuration: other.minShowDuration ?? minShowDuration,
      hapticThreshold: other.hapticThreshold ?? hapticThreshold,
      illustrationOffset: other.illustrationOffset ?? illustrationOffset,
      illustrationFade: other.illustrationFade ?? illustrationFade,
      customSettle: other.customSettle ?? customSettle,
      customTriggerExtent: other.customTriggerExtent ?? customTriggerExtent,
      minRefreshInterval: other.minRefreshInterval ?? minRefreshInterval,
      enableHaptic: other.enableHaptic ?? enableHaptic,
      respectReducedMotion: other.respectReducedMotion ?? respectReducedMotion,
    );
  }

  RefreshableStyle copyWith({
    RefreshableVariant? variant,
    Color? color,
    Color? backgroundColor,
    double? displacement,
    double? edgeOffset,
    double? strokeWidth,
    Duration? minShowDuration,
    double? hapticThreshold,
    double? illustrationOffset,
    Duration? illustrationFade,
    Duration? customSettle,
    double? customTriggerExtent,
    Duration? minRefreshInterval,
    bool? enableHaptic,
    bool? respectReducedMotion,
  }) => RefreshableStyle(
    variant: variant ?? this.variant,
    color: color ?? this.color,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    displacement: displacement ?? this.displacement,
    edgeOffset: edgeOffset ?? this.edgeOffset,
    strokeWidth: strokeWidth ?? this.strokeWidth,
    minShowDuration: minShowDuration ?? this.minShowDuration,
    hapticThreshold: hapticThreshold ?? this.hapticThreshold,
    illustrationOffset: illustrationOffset ?? this.illustrationOffset,
    illustrationFade: illustrationFade ?? this.illustrationFade,
    customSettle: customSettle ?? this.customSettle,
    customTriggerExtent: customTriggerExtent ?? this.customTriggerExtent,
    minRefreshInterval: minRefreshInterval ?? this.minRefreshInterval,
    enableHaptic: enableHaptic ?? this.enableHaptic,
    respectReducedMotion: respectReducedMotion ?? this.respectReducedMotion,
  );

  @override
  bool operator ==(Object other) =>
      other is RefreshableStyle &&
      other.variant == variant &&
      other.color == color &&
      other.backgroundColor == backgroundColor &&
      other.displacement == displacement &&
      other.edgeOffset == edgeOffset &&
      other.strokeWidth == strokeWidth &&
      other.minShowDuration == minShowDuration &&
      other.hapticThreshold == hapticThreshold &&
      other.illustrationOffset == illustrationOffset &&
      other.illustrationFade == illustrationFade &&
      other.customSettle == customSettle &&
      other.customTriggerExtent == customTriggerExtent &&
      other.minRefreshInterval == minRefreshInterval &&
      other.enableHaptic == enableHaptic &&
      other.respectReducedMotion == respectReducedMotion;

  @override
  int get hashCode => Object.hash(
    variant,
    color,
    backgroundColor,
    displacement,
    edgeOffset,
    strokeWidth,
    minShowDuration,
    hapticThreshold,
    illustrationOffset,
    illustrationFade,
    customSettle,
    customTriggerExtent,
    minRefreshInterval,
    enableHaptic,
    respectReducedMotion,
  );
}

/// A [RefreshableStyle] with every question answered.
@immutable
class ResolvedRefreshableStyle {
  const ResolvedRefreshableStyle({
    required this.variant,
    required this.color,
    required this.backgroundColor,
    required this.displacement,
    required this.edgeOffset,
    required this.strokeWidth,
    required this.minShowDuration,
    required this.hapticThreshold,
    required this.illustrationOffset,
    required this.illustrationFade,
    required this.customSettle,
    required this.customTriggerExtent,
    required this.minRefreshInterval,
    required this.enableHaptic,
    required this.still,
  });

  /// Already resolved off [RefreshableVariant.adaptive] — every switch
  /// downstream sees a concrete indicator.
  final RefreshableVariant variant;

  final Color color;
  final Color backgroundColor;
  final double displacement;
  final double edgeOffset;
  final double strokeWidth;
  final Duration minShowDuration;
  final double hapticThreshold;
  final double illustrationOffset;

  /// Zero under reduced motion.
  final Duration illustrationFade;

  /// Zero under reduced motion.
  final Duration customSettle;

  final double customTriggerExtent;
  final Duration minRefreshInterval;
  final bool enableHaptic;

  /// Whether the reader has asked for motion to stop.
  final bool still;
}
