import 'package:flutter/material.dart';

/// What shape the visualizer draws.
///
/// It used to be called `VisualizerStyle`, which is the name the BAG
/// has to have — the module's other bags are all `<Name>Style` and a
/// shape enum wearing that name is why `options:` existed as a
/// parameter at all.
enum VisualizerShape {
  /// Vertical bars rising from the bottom.
  bars,

  /// Mirrored bars centred on the vertical midline.
  mirror,

  /// Dot per bin, sized by amplitude.
  dots,

  /// Continuous polyline through every bin.
  line,

  /// Radial bars around a centre point.
  circular,

  /// Smooth filled wave (closed path under the curve).
  wave,
}

/// Every number the visualizer draws with, in one place.
abstract final class VisualizerDefaults {
  static const shape = VisualizerShape.bars;
  static const barCount = 48;
  static const height = 96.0;

  /// EMA smoothing 0..1 — higher is smoother and lazier.
  static const smoothing = 0.55;

  /// Floor bar height (0..1), so a silent passage still renders.
  static const minBar = 0.04;

  /// Fraction of bin pitch used for bar width (bars / mirror).
  static const barWidthFactor = 0.6;

  /// Fraction of the FULL waveform shown across the bins in
  /// handle-driven mode. Larger zooms out around the playhead.
  static const windowSpread = 0.25;

  /// Per-tick decay when the player is not playing. 1.0 freezes.
  static const idleDecay = 0.85;
}

/// How [GlobalAudioVisualizer] looks.
///
/// Every field is nullable so the three sources layer without a
/// default clobbering a theme: `caller > GlobalVisualizerTheme.style >
/// VisualizerStyle.defaults`. Resolved once per build into a
/// [ResolvedVisualizerStyle].
///
/// It was `VisualizerOptions`, with a non-nullable field and an inline
/// default apiece — the same shape `AudioStyle` had before this pass,
/// and the same reason it could not be themed: a house that wanted 32
/// bins everywhere had to say so at every call site.
@immutable
class VisualizerStyle {
  const VisualizerStyle({
    this.shape,
    this.barCount,
    this.color,
    this.gradient,
    this.background,
    this.borderRadius,
    this.height,
    this.smoothing,
    this.minBar,
    this.glow,
    this.barWidthFactor,
    this.windowSpread,
    this.idleDecay,
  });

  /// The floor. The colour is absent on purpose — it resolves from the
  /// palette at build time so it tracks role, brightness and
  /// saturation, which a constant cannot.
  static const VisualizerStyle defaults = VisualizerStyle(
    shape: VisualizerDefaults.shape,
    barCount: VisualizerDefaults.barCount,
    height: VisualizerDefaults.height,
    smoothing: VisualizerDefaults.smoothing,
    minBar: VisualizerDefaults.minBar,
    glow: false,
    barWidthFactor: VisualizerDefaults.barWidthFactor,
    windowSpread: VisualizerDefaults.windowSpread,
    idleDecay: VisualizerDefaults.idleDecay,
  );

  // ─── Presets ──────────────────────────────────────────────
  //
  // Each is a shape that suits a particular job, and each was chosen
  // by what the numbers do TOGETHER rather than by naming a shape: a
  // bar count that suits a 96-point box does not suit a 40-point one,
  // and smoothing that reads as "lively" at 48 bins reads as noise at
  // 12.

  /// Beside a voice note, in a row.
  ///
  /// Few bins and heavy smoothing — a short wide box has no room for
  /// forty-eight bars, and at that size fast motion reads as flicker
  /// rather than as sound.
  static const VisualizerStyle compact = VisualizerStyle(
    barCount: 16,
    height: 32,
    smoothing: 0.7,
    barWidthFactor: 0.5,
    shape: VisualizerShape.mirror,
  );

  /// A now-playing screen.
  ///
  /// The full-width shape: many bins, mirrored about the middle, and a
  /// glow, because this one is the subject of the screen rather than
  /// an ornament beside something else.
  static const VisualizerStyle nowPlaying = VisualizerStyle(
    barCount: 64,
    height: 120,
    smoothing: 0.45,
    glow: true,
    shape: VisualizerShape.mirror,
  );

  /// A recording indicator.
  ///
  /// Fast and unsmoothed, because the point is to show that the
  /// microphone is HEARING something — a lazy meter looks broken when
  /// someone taps the mic to check it.
  static const VisualizerStyle monitor = VisualizerStyle(
    barCount: 32,
    height: 48,
    smoothing: 0.2,
    idleDecay: 0.6,
    minBar: 0.02,
  );

  /// Ambient, behind other content.
  ///
  /// A filled curve rather than bars: it has to read as motion at the
  /// edge of vision without competing with whatever is on top of it.
  static const VisualizerStyle ambient = VisualizerStyle(
    barCount: 48,
    height: 96,
    smoothing: 0.8,
    shape: VisualizerShape.wave,
    windowSpread: 0.4,
  );

  final VisualizerShape? shape;
  final int? barCount;

  /// Falls back to the palette primary.
  final Color? color;

  /// Wins over [color] when set.
  final Gradient? gradient;

  final Color? background;
  final BorderRadius? borderRadius;
  final double? height;
  final double? smoothing;
  final double? minBar;

  /// A soft blur halo around stroked bins.
  final bool? glow;

  final double? barWidthFactor;
  final double? windowSpread;
  final double? idleDecay;

  /// [other] wins field by field. Null means "did not say", which is
  /// what lets a caller override one thing without restating a theme.
  VisualizerStyle mergedWith(VisualizerStyle? other) {
    if (other == null) return this;
    return VisualizerStyle(
      shape: other.shape ?? shape,
      barCount: other.barCount ?? barCount,
      color: other.color ?? color,
      gradient: other.gradient ?? gradient,
      background: other.background ?? background,
      borderRadius: other.borderRadius ?? borderRadius,
      height: other.height ?? height,
      smoothing: other.smoothing ?? smoothing,
      minBar: other.minBar ?? minBar,
      glow: other.glow ?? glow,
      barWidthFactor: other.barWidthFactor ?? barWidthFactor,
      windowSpread: other.windowSpread ?? windowSpread,
      idleDecay: other.idleDecay ?? idleDecay,
    );
  }

  VisualizerStyle copyWith({
    VisualizerShape? shape,
    int? barCount,
    Color? color,
    Gradient? gradient,
    Color? background,
    BorderRadius? borderRadius,
    double? height,
    double? smoothing,
    double? minBar,
    bool? glow,
    double? barWidthFactor,
    double? windowSpread,
    double? idleDecay,
  }) => VisualizerStyle(
    shape: shape ?? this.shape,
    barCount: barCount ?? this.barCount,
    color: color ?? this.color,
    gradient: gradient ?? this.gradient,
    background: background ?? this.background,
    borderRadius: borderRadius ?? this.borderRadius,
    height: height ?? this.height,
    smoothing: smoothing ?? this.smoothing,
    minBar: minBar ?? this.minBar,
    glow: glow ?? this.glow,
    barWidthFactor: barWidthFactor ?? this.barWidthFactor,
    windowSpread: windowSpread ?? this.windowSpread,
    idleDecay: idleDecay ?? this.idleDecay,
  );

  @override
  bool operator ==(Object other) =>
      other is VisualizerStyle &&
      other.shape == shape &&
      other.barCount == barCount &&
      other.color == color &&
      other.gradient == gradient &&
      other.background == background &&
      other.borderRadius == borderRadius &&
      other.height == height &&
      other.smoothing == smoothing &&
      other.minBar == minBar &&
      other.glow == glow &&
      other.barWidthFactor == barWidthFactor &&
      other.windowSpread == windowSpread &&
      other.idleDecay == idleDecay;

  @override
  int get hashCode => Object.hash(
    shape,
    barCount,
    color,
    gradient,
    background,
    borderRadius,
    height,
    smoothing,
    minBar,
    glow,
    barWidthFactor,
    windowSpread,
    idleDecay,
  );
}

/// A [VisualizerStyle] with every question answered.
///
/// Built once per build by `style.resolve(context)`. Nothing
/// downstream takes a nullable field or reaches for `Theme.of` — the
/// widget used to do the second, which is how a visualizer in a themed
/// player could disagree with the waveform beside it.
@immutable
class ResolvedVisualizerStyle {
  const ResolvedVisualizerStyle({
    required this.shape,
    required this.barCount,
    required this.color,
    required this.height,
    required this.smoothing,
    required this.minBar,
    required this.glow,
    required this.barWidthFactor,
    required this.windowSpread,
    required this.idleDecay,
    this.gradient,
    this.background,
    this.borderRadius,
  });

  final VisualizerShape shape;
  final int barCount;
  final Color color;
  final double height;
  final double smoothing;
  final double minBar;
  final bool glow;
  final double barWidthFactor;
  final double windowSpread;
  final double idleDecay;

  final Gradient? gradient;
  final Color? background;
  final BorderRadius? borderRadius;

  /// Whether the picture needs a box drawn round it at all.
  ///
  /// The FILL decides, not the corner. Bare paint wrapped in a
  /// `Container` and a `ClipRRect` costs both of those per frame for
  /// nothing — and the app theme sets a corner on every visualizer in
  /// the app, so reading the corner here would box every one of them.
  /// The corner is for when there IS a fill, which is the only time it
  /// has an edge to round.
  bool get hasSurface => background != null;
}
