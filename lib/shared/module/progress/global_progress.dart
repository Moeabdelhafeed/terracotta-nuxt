import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../text/global_text.dart';
import 'progress_models.dart';
import 'progress_painters.dart';
import 'theme/progress_theme.dart';

export 'progress_models.dart';
export 'theme/progress_theme.dart';

// ---------------------------------------------------------------------------
// GlobalProgress
// ---------------------------------------------------------------------------

/// A universal progress indicator supporting linear, circular, gauge, stepped,
/// multi-segment, and wave fill modes with gradient fills, labels, buffered
/// progress, tick marks, color thresholds, pulse animation, countdown timer,
/// step labels, and full theming.
class GlobalProgress extends StatefulWidget {
  const GlobalProgress({
    super.key,
    this.value = 0.0,
    this.type = ProgressType.linear,
    this.style = const ProgressStyle(),
    this.bufferValue,
    this.steps,
    this.currentStep,
    this.stepLabels,
    this.label,
    this.sublabel,
    this.segments,
    this.semanticLabel,
    this.stepProgress,
    this.onComplete,
  });

  /// Progress value from 0.0 to 1.0.
  final double value;
  final ProgressType type;
  final ProgressStyle style;

  /// Secondary value drawn behind the fill — how much has been buffered
  /// against how much has played. DATA, like [value], which is why it
  /// is here and not on the style bag.
  final double? bufferValue;

  /// Number of steps for stepped progress.
  final int? steps;

  /// Current step index (0-based).
  final int? currentStep;

  /// Labels for each step in stepped mode.
  final List<String>? stepLabels;

  /// Custom label widget.
  final Widget? label;

  /// Sub-label for gauge mode.
  final String? sublabel;

  /// Segments for multi-segment mode.
  final List<ProgressSegment>? segments;

  /// What this is reporting on. Without it a reader hears a bare
  /// percentage with nothing attached to it.
  final String? semanticLabel;

  /// How far through the CURRENT step, 0..1, for `stepped`.
  ///
  /// Null fills the current step whole. A story reel is the case this
  /// exists for: four segments, three behind you, and the one you are
  /// watching draining in real time.
  final double? stepProgress;

  /// Fired once when a determinate value ARRIVES at 1.
  ///
  /// Once — not on every frame it stays there — and again only if the
  /// value drops back and returns. The countdown had this and a bar
  /// reaching the end fired nothing.
  final VoidCallback? onComplete;

  // ─── Factories ─────────────────────────────────────────────

  factory GlobalProgress.linear({
    Key? key,
    required double value,
    ProgressStyle style = const ProgressStyle(),
    double? bufferValue,
    String? semanticLabel,
    VoidCallback? onComplete,
  }) => GlobalProgress(
    key: key,
    value: value,
    style: style,
    bufferValue: bufferValue,
    semanticLabel: semanticLabel,
    onComplete: onComplete,
  );

  factory GlobalProgress.circular({
    Key? key,
    required double value,
    ProgressStyle style = const ProgressStyle(thickness: 4),
    Widget? label,
    String? semanticLabel,
  }) => GlobalProgress(
    key: key,
    value: value,
    type: ProgressType.circular,
    style: style,
    label: label,
    semanticLabel: semanticLabel,
  );

  factory GlobalProgress.gauge({
    Key? key,
    required double value,
    ProgressStyle style = const ProgressStyle(thickness: 8),
    String? sublabel,
    String? semanticLabel,
  }) => GlobalProgress(
    key: key,
    value: value,
    type: ProgressType.gauge,
    style: style,
    sublabel: sublabel,
    semanticLabel: semanticLabel,
  );

  factory GlobalProgress.stepped({
    Key? key,
    required int steps,
    required int currentStep,
    ProgressStyle style = const ProgressStyle(),
    List<String>? stepLabels,
    String? semanticLabel,
    double? stepProgress,
  }) => GlobalProgress(
    key: key,
    type: ProgressType.stepped,
    style: style,
    steps: steps,
    currentStep: currentStep,
    stepLabels: stepLabels,
    semanticLabel: semanticLabel,
    stepProgress: stepProgress,
  );

  /// An indicator for work with no known end.
  ///
  /// `indeterminate` is FORCED, not defaulted: passing any `style` at
  /// all used to replace the one this factory set, so
  /// `GlobalProgress.loading(style: ProgressStyle(color: red))` quietly
  /// became a determinate bar stuck at zero.
  factory GlobalProgress.loading({
    Key? key,
    ProgressType type = ProgressType.linear,
    ProgressStyle style = const ProgressStyle(),
    String? semanticLabel,
  }) => GlobalProgress(
    key: key,
    type: type,
    style: style.copyWith(indeterminate: true),
    semanticLabel: semanticLabel,
  );

  factory GlobalProgress.multiSegment({
    Key? key,
    required List<ProgressSegment> segments,
    ProgressStyle style = const ProgressStyle(),
    String? semanticLabel,
  }) => GlobalProgress(
    key: key,
    type: ProgressType.multiSegment,
    style: style,
    segments: segments,
    semanticLabel: semanticLabel,
  );

  factory GlobalProgress.waveFill({
    Key? key,
    required double value,
    ProgressStyle style = const ProgressStyle(),
    Widget? label,
    String? semanticLabel,
  }) => GlobalProgress(
    key: key,
    value: value,
    type: ProgressType.waveFill,
    style: style,
    label: label,
    semanticLabel: semanticLabel,
  );

  /// Countdown timer progress.
  static Widget countdown({
    Key? key,
    required Duration duration,
    VoidCallback? onComplete,
    ProgressStyle style = const ProgressStyle(),
    String? semanticLabel,
    bool paused = false,
  }) => _CountdownProgress(
    key: key,
    duration: duration,
    onComplete: onComplete,
    style: style,
    semanticLabel: semanticLabel,
    paused: paused,
  );

  @override
  State<GlobalProgress> createState() => _GlobalProgressState();
}

class _GlobalProgressState extends State<GlobalProgress>
    with TickerProviderStateMixin {
  /// Materialized once in didChangeDependencies — caller > theme >
  /// defaults > palette. Build code reads this, never the raw bag.
  late ResolvedProgressStyle _rs;

  late AnimationController _ctrl;
  late Animation<double> _valueAnim;
  double _prevValue = 0;

  /// Only exist when asked for, so nothing ticks that nobody can see.
  AnimationController? _pulseCtrl;
  AnimationController? _waveCtrl;

  /// Latched so [GlobalProgress.onComplete] fires ONCE at the top, not
  /// on every frame the value spends there.
  bool _completed = false;

  /// Whether an indeterminate indicator has waited out `appearAfter`.
  bool _visible = true;
  Timer? _appearTimer;

  @override
  void initState() {
    super.initState();
    _prevValue = widget.value.clamp(0.0, 1.0);
    // No duration yet: it comes from the resolved style, which needs a
    // context that `initState` does not have.
    _ctrl = AnimationController(vsync: this);
    _valueAnim = AlwaysStoppedAnimation<double>(_prevValue);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
    _valueAnim = _tween(_prevValue, _prevValue);
    _syncControllers();
    _syncAppearance();
  }

  @override
  void didUpdateWidget(GlobalProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resolve();
    _syncControllers();
    _syncAppearance();

    final next = widget.value.clamp(0.0, 1.0);
    if (next == _prevValue || _rs.indeterminate) return;
    _checkComplete(next);

    if (!_rs.animated) {
      // Reduced motion, or animation turned off: land on the value
      // rather than crawling to it.
      _valueAnim = AlwaysStoppedAnimation<double>(next);
      _prevValue = next;
      return;
    }
    _valueAnim = _tween(_prevValue, next);
    _ctrl.forward(from: 0);
    _prevValue = next;
  }

  @override
  void dispose() {
    _appearTimer?.cancel();
    _ctrl.dispose();
    _pulseCtrl?.dispose();
    _waveCtrl?.dispose();
    super.dispose();
  }

  /// Holds an indeterminate indicator back for `appearAfter`.
  ///
  /// Work that finishes inside the grace period never shows a spinner,
  /// so a fast round trip does not flash one. A determinate bar has
  /// something to say from the first frame and is never held.
  void _syncAppearance() {
    final wanted = _rs.indeterminate && _rs.appearAfter > Duration.zero;
    if (!wanted) {
      _appearTimer?.cancel();
      _appearTimer = null;
      if (!_visible) setState(() => _visible = true);
      return;
    }
    if (_appearTimer != null || !_visible) return;
    _visible = false;
    _appearTimer = Timer(_rs.appearAfter, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  /// Fires [GlobalProgress.onComplete] the first time the value lands
  /// on 1, and re-arms if it ever comes back down.
  void _checkComplete(double next) {
    if (next >= 1 && !_completed) {
      _completed = true;
      widget.onComplete?.call();
    } else if (next < 1) {
      _completed = false;
    }
  }

  void _resolve() => _rs = widget.style.resolve(
    context,
    type: widget.type,
    disableAnimations: MediaQuery.disableAnimationsOf(context),
  );

  Animation<double> _tween(double from, double to) =>
      Tween<double>(begin: from, end: to).animate(
        CurvedAnimation(parent: _ctrl, curve: _rs.animationCurve),
      );

  /// Brings the tickers in line with the resolved style, creating and
  /// disposing them as the flags change rather than leaving a ticker
  /// running for a feature that has been turned off.
  void _syncControllers() {
    _ctrl.duration = _rs.indeterminate
        ? _rs.indeterminateDuration
        : _rs.animationDuration;

    if (_rs.indeterminate) {
      if (!_ctrl.isAnimating) _ctrl.repeat();
    } else {
      if (_ctrl.isAnimating) _ctrl.stop();
      _ctrl.value = 1;
    }

    if (_rs.pulse && _pulseCtrl == null) {
      _pulseCtrl = AnimationController(
        vsync: this,
        duration: ProgressDefaults.pulseDuration,
      )..repeat(reverse: true);
    } else if (!_rs.pulse && _pulseCtrl != null) {
      _pulseCtrl!.dispose();
      _pulseCtrl = null;
    }

    final wantsWave = widget.type == ProgressType.waveFill && _rs.animated;
    if (wantsWave && _waveCtrl == null) {
      _waveCtrl = AnimationController(
        vsync: this,
        duration: ProgressDefaults.indeterminateDuration,
      )..repeat();
    } else if (!wantsWave && _waveCtrl != null) {
      _waveCtrl!.dispose();
      _waveCtrl = null;
    }
  }

  double get _animatedValue => _rs.indeterminate ? 0 : _valueAnim.value;

  /// What a reader hears.
  ///
  /// A multi-segment bar reads out its PARTS. "72%" is true of the
  /// whole and says nothing about the thing it is actually showing,
  /// which is a breakdown — a reader got a single number for a chart.
  String _semanticValue() {
    final segments = widget.segments;
    if (widget.type != ProgressType.multiSegment ||
        segments == null ||
        segments.isEmpty) {
      return _rs.format(_animatedValue);
    }
    return segments
        .map(
          (s) => s.label == null
              ? _rs.format(s.value)
              : '${s.label}: ${_rs.format(s.value)}',
        )
        .join(', ');
  }

  double get _pulseOpacity => _pulseCtrl == null
      ? 1
      : ProgressDefaults.pulseMinOpacity +
            (1 - ProgressDefaults.pulseMinOpacity) * _pulseCtrl!.value;

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[
      _ctrl,
      if (_pulseCtrl != null) _pulseCtrl!,
      if (_waveCtrl != null) _waveCtrl!,
    ];

    // Held back until `appearAfter` elapses — and it takes NO space
    // meanwhile, so nothing jumps when it does arrive.
    if (!_visible) return const SizedBox.shrink();

    return Semantics(
      container: true,
      label:
          widget.semanticLabel ??
          (_rs.indeterminate ? CommonStrings.loading : null),
      // A reader announces a progress node by its VALUE. The painted
      // read-out would otherwise be a second, unlabelled node saying
      // the same number.
      value: _rs.indeterminate ? null : _semanticValue(),
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: listenables.length == 1
            ? _ctrl
            : Listenable.merge(listenables),
        builder: (context, _) => switch (widget.type) {
          ProgressType.linear => _buildLinear(),
          ProgressType.circular => _buildCircular(),
          ProgressType.gauge => _buildGauge(),
          ProgressType.stepped => _buildStepped(),
          ProgressType.multiSegment => _buildMultiSegment(),
          ProgressType.waveFill => _buildWaveFill(),
        },
      ),
    );
  }

  // ─── Linear ───────────────────────────────────────────────

  Widget _buildLinear() {
    final rs = _rs;
    final value = _animatedValue;
    final color = rs.colorFor(value);
    final isRound = rs.capStyle == ProgressCapStyle.round;
    final radius =
        rs.borderRadius ??
        (isRound ? BorderRadius.circular(rs.thickness / 2) : BorderRadius.zero);

    Widget bar = Opacity(
      opacity: _pulseOpacity,
      child: SizedBox(
        height: rs.thickness,
        child: CustomPaint(
          painter: LinearProgressPainter(
            value: value,
            color: color,
            gradient: rs.gradient,
            trackColor: rs.trackFor(value),
            trackGradient: rs.trackGradient,
            radius: radius,
            indeterminate: rs.indeterminate,
            indeterminateProgress: rs.indeterminate ? _ctrl.value : 0,
            innerShadow: rs.innerShadow,
            bufferValue: widget.bufferValue,
            bufferColor: rs.bufferColor,
            showTickMarks: rs.showTickMarks,
            tickCount: rs.tickCount,
            tickColor: rs.tickColor,
            tickWidth: rs.tickWidth,
          ),
          size: Size(double.infinity, rs.thickness),
        ),
      ),
    );

    bar = _mirrored(bar);

    if (rs.shadow != null) {
      bar = DecoratedBox(
        decoration: BoxDecoration(boxShadow: rs.shadow, borderRadius: radius),
        child: bar,
      );
    }

    if (!rs.showLabel && widget.label == null) return bar;

    final formatted = rs.format(value);
    final labelStyle = rs.labelStyle.copyWith(color: color);

    switch (rs.labelPosition) {
      case ProgressLabelPosition.start:
        return Row(
          children: [
            _sideLabel(formatted, labelStyle, TextAlign.end),
            const SizedBox(width: ProgressDefaults.labelPad),
            Expanded(child: bar),
          ],
        );
      case ProgressLabelPosition.end:
        return Row(
          children: [
            Expanded(child: bar),
            const SizedBox(width: ProgressDefaults.labelPad),
            _sideLabel(formatted, labelStyle, TextAlign.start),
          ],
        );
      case ProgressLabelPosition.top:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            widget.label ?? Text(formatted, style: labelStyle),
            const SizedBox(height: ProgressDefaults.labelPad / 2),
            bar,
          ],
        );
      case ProgressLabelPosition.bottom:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            bar,
            const SizedBox(height: ProgressDefaults.labelPad / 2),
            widget.label ?? Text(formatted, style: labelStyle),
          ],
        );
      case ProgressLabelPosition.center:
      case ProgressLabelPosition.inside:
        if (widget.label != null) {
          return Stack(
            alignment: Alignment.center,
            children: [bar, widget.label!],
          );
        }
        return _splitLabel(bar, formatted, color, value);
    }
  }

  /// A side label reserves the width of the WIDEST thing it can say, so
  /// the bar does not jump as "9%" becomes "100%".
  ///
  /// Measured, not guessed. It was a flat forty pixels, which is both
  /// too much and — for a formatter like `"500 MB / 500 MB"` — far too
  /// little: the reserve is only ever right by accident. Forty against
  /// a three-glyph Arabic-Indic percentage left a hole you could park
  /// in, at whichever ed the alignment did not favour.
  ///
  /// The text still aligns toward the BAR, so what slack remains falls
  /// against the page edge rather than between the label and the thing
  /// it labels.
  Widget _sideLabel(String text, TextStyle style, TextAlign towardBar) =>
      widget.label ??
      ConstrainedBox(
        constraints: BoxConstraints(minWidth: _labelReserve(style)),
        child: Text(text, style: style, textAlign: towardBar),
      );

  /// Width of the longest label this formatter can produce, cached.
  ///
  /// Only the ENDS are measured — empty and full. A formatter whose
  /// widest output is somewhere in the middle still fits: the reserve
  /// is a minimum, not a cap.
  double _labelReserve(TextStyle style) {
    final ends = [_rs.format(0), _rs.format(1)];
    final key = '${ends.join('|')}|${style.fontSize}|${style.fontWeight}';
    if (key == _reserveKey) return _reserveWidth;

    final direction = Directionality.of(context);
    var widest = 0.0;
    for (final text in ends) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }

    _reserveKey = key;
    return _reserveWidth = widest;
  }

  String? _reserveKey;
  double _reserveWidth = 0;

  /// The read-out ON the bar, in two colours: the fill's colour where
  /// the bar is empty, and the on-fill colour where it is not.
  ///
  /// One colour cannot work — the text crosses the fill edge as the
  /// value climbs, so whichever you pick it disappears against one side
  /// or the other.
  Widget _splitLabel(Widget bar, String text, Color color, double value) {
    final style = _rs.labelStyle;
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        final fillWidth = barWidth * value;

        return Stack(
          children: [
            bar,
            Positioned.fill(
              child: ClipRect(
                clipper: _AbsoluteClipper(left: fillWidth, right: barWidth),
                child: Center(
                  child: Text(text, style: style.copyWith(color: color)),
                ),
              ),
            ),
            Positioned.fill(
              child: ClipRect(
                clipper: _AbsoluteClipper(left: 0, right: fillWidth),
                child: Center(
                  child: Text(
                    text,
                    style: style.copyWith(color: _onFill(context)),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─── Circular ─────────────────────────────────────────────

  Widget _buildCircular() {
    final rs = _rs;
    final value = _animatedValue;
    final color = rs.colorFor(value);
    final size = rs.size ?? ProgressDefaults.circularSize;

    Widget circle = Opacity(
      opacity: _pulseOpacity,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: CircularProgressPainter(
            value: value,
            color: color,
            gradient: rs.gradient,
            trackColor: rs.trackFor(value),
            thickness: rs.thickness,
            capStyle: rs.capStyle,
            indeterminate: rs.indeterminate,
            indeterminateProgress: rs.indeterminate ? _ctrl.value : 0,
          ),
        ),
      ),
    );

    if (widget.label != null || rs.showLabel) {
      circle = Stack(
        alignment: Alignment.center,
        children: [
          circle,
          widget.label ??
              Text(
                rs.format(value),
                style: rs.labelStyle.copyWith(color: color),
              ),
        ],
      );
    }
    return circle;
  }

  // ─── Gauge ────────────────────────────────────────────────

  Widget _buildGauge() {
    final rs = _rs;
    final value = _animatedValue;
    final color = rs.colorFor(value);
    final size = rs.size ?? ProgressDefaults.gaugeSize;

    return SizedBox(
      width: size,
      height: size * ProgressDefaults.gaugeHeightRatio,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          _mirrored(
            CustomPaint(
              size: Size(size, size * ProgressDefaults.gaugeHeightRatio),
              painter: GaugeProgressPainter(
                value: value,
                color: color,
                gradient: rs.gradient,
                trackColor: rs.trackFor(value),
                thickness: rs.thickness,
                capStyle: rs.capStyle,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rs.format(value),
                  style: rs.labelStyle.copyWith(
                    fontSize: ProgressDefaults.gaugeLabelFontSize,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                if (widget.sublabel != null)
                  Text(widget.sublabel!, style: rs.sublabelStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stepped ──────────────────────────────────────────────

  Widget _buildStepped() {
    final rs = _rs;
    final steps = widget.steps ?? 4;
    final current = widget.currentStep ?? 0;
    final color = rs.colorFor(_animatedValue);
    final track = rs.trackFor(_animatedValue);
    final isRound = rs.capStyle == ProgressCapStyle.round;
    final radius =
        rs.borderRadius ??
        BorderRadius.circular(
          isRound ? rs.thickness / 2 : ProgressDefaults.stepRadius,
        );
    final hasLabels =
        widget.stepLabels != null && widget.stepLabels!.length >= steps;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rs.gradient != null)
          _steppedGradient(rs, steps, current, track, radius)
        else
          Row(
            children: [
              for (var i = 0; i < steps; i++) ...[
                if (i > 0) SizedBox(width: rs.stepGap),
                Expanded(
                  child: _step(rs, i, current, color, track, radius),
                ),
              ],
            ],
          ),
        if (hasLabels) ...[
          const SizedBox(height: ProgressDefaults.stepLabelPad),
          Row(
            children: [
              for (var i = 0; i < steps; i++) ...[
                if (i > 0) SizedBox(width: rs.stepGap),
                Expanded(
                  child: Text(
                    widget.stepLabels![i],
                    textAlign: TextAlign.center,
                    style: i <= current
                        ? rs.stepLabelStyle.copyWith(
                            color: color,
                            fontWeight: FontWeight.w600,
                          )
                        : rs.stepLabelStyle,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  /// One step of a stepped bar: behind, current, or ahead.
  ///
  /// The CURRENT one can be part-filled — `stepProgress` — which is
  /// what a story reel needs: the ones behind you full, the one playing
  /// draining in real time, the rest empty.
  Widget _step(
    ResolvedProgressStyle rs,
    int index,
    int current,
    Color color,
    Color track,
    BorderRadius radius,
  ) {
    final partial = widget.stepProgress;
    final duration = rs.animated ? rs.animationDuration : Duration.zero;

    if (partial != null && index == current) {
      return ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          height: rs.thickness,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: track),
              // Aligned to the START, so it fills the way the language
              // reads rather than always from the left.
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: FractionallySizedBox(
                  widthFactor: partial.clamp(0.0, 1.0),
                  // FULL HEIGHT, explicitly.
                  //
                  // Without a `heightFactor` the child is left loose on
                  // that axis, and a `ColoredBox` with no child of its
                  // own then measures ZERO high — so the part-filled
                  // step painted nothing at all and every step read as
                  // either full or empty. It is the step a story bar
                  // spends all its time in.
                  heightFactor: 1,
                  child: ColoredBox(color: color),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: duration,
      curve: rs.animationCurve,
      height: rs.thickness,
      decoration: BoxDecoration(
        color: partial != null
            ? (index < current ? color : track)
            : (index <= current ? color : track),
        borderRadius: radius,
      ),
    );
  }

  /// A gradient runs across the WHOLE bar, not once per step.
  ///
  /// Painting each step with the same gradient makes every one of them
  /// a miniature copy of the ramp, so the row reads as stripes rather
  /// than as one bar. Each active step draws a full-width gradient and
  /// clips its own slice out of it.
  Widget _steppedGradient(
    ResolvedProgressStyle rs,
    int steps,
    int current,
    Color track,
    BorderRadius radius,
  ) {
    return SizedBox(
      height: rs.thickness,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final gapTotal = rs.stepGap * (steps - 1);
          final stepWidth = (totalWidth - gapTotal) / steps;

          return Stack(
            children: [
              Row(
                children: [
                  for (var i = 0; i < steps; i++) ...[
                    if (i > 0) SizedBox(width: rs.stepGap),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: track,
                          borderRadius: radius,
                        ),
                        child: SizedBox(height: rs.thickness),
                      ),
                    ),
                  ],
                ],
              ),
              for (var i = 0; i <= current && i < steps; i++)
                PositionedDirectional(
                  start: i * (stepWidth + rs.stepGap),
                  width: stepWidth,
                  height: rs.thickness,
                  child: ClipRRect(
                    borderRadius: radius,
                    child: OverflowBox(
                      alignment: AlignmentDirectional.centerStart,
                      maxWidth: totalWidth,
                      child: Transform.translate(
                        offset: Offset(-i * (stepWidth + rs.stepGap), 0),
                        child: AnimatedContainer(
                          duration: rs.animated
                              ? rs.animationDuration
                              : Duration.zero,
                          width: totalWidth,
                          height: rs.thickness,
                          decoration: BoxDecoration(gradient: rs.gradient),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ─── Multi-segment ────────────────────────────────────────

  Widget _buildMultiSegment() {
    final rs = _rs;
    final segments = widget.segments ?? const <ProgressSegment>[];
    final isRound = rs.capStyle == ProgressCapStyle.round;
    final radius = isRound
        ? BorderRadius.circular(rs.thickness / 2)
        : BorderRadius.zero;
    final filled = segments.fold<double>(0, (sum, s) => sum + s.value);
    const scale = ProgressDefaults.segmentFlexScale;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: radius,
          child: SizedBox(
            height: rs.thickness,
            child: Row(
              // STRETCH. A `ColoredBox` with no child takes its child's
              // size, and the row's default centre alignment hands it a
              // loose height — so every segment measured zero and the
              // bar vanished, leaving only its legend.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final seg in segments)
                  Expanded(
                    flex: (seg.value * scale).round(),
                    child: ColoredBox(color: seg.color),
                  ),
                if (filled < 1)
                  Expanded(
                    flex: ((1 - filled) * scale).round(),
                    child: ColoredBox(color: rs.trackFor(filled)),
                  ),
              ],
            ),
          ),
        ),
        if (segments.any((s) => s.label != null)) ...[
          const SizedBox(height: ProgressDefaults.stepLabelPad),
          Row(
            children: [
              for (final seg in segments)
                Expanded(
                  flex: (seg.value * scale).round(),
                  child: seg.label == null
                      ? const SizedBox.shrink()
                      : _segmentLegend(rs, seg),
                ),
              // The SAME remainder the bar has. Without it the legend
              // shared out the full width while the segments above it
              // only covered `filled`, so every caption drifted right
              // of the block it names — by more the emptier the bar.
              if (filled < 1)
                Expanded(
                  flex: ((1 - filled) * scale).round(),
                  child: const SizedBox.shrink(),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _segmentLegend(ResolvedProgressStyle rs, ProgressSegment seg) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: ProgressDefaults.segmentLegendDotSize,
        height: ProgressDefaults.segmentLegendDotSize,
        decoration: BoxDecoration(color: seg.color, shape: BoxShape.circle),
      ),
      const SizedBox(width: ProgressDefaults.segmentLegendGap),
      Flexible(
        child: Text(
          seg.label!,
          style: rs.stepLabelStyle.copyWith(
            color: rs.stepLabelStyle.color?.withValues(
              alpha: ProgressDefaults.segmentLabelOpacity,
            ),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ],
  );

  // ─── Wave fill ────────────────────────────────────────────

  Widget _buildWaveFill() {
    final rs = _rs;
    // The wave reads the RAW value, not the tween: it is a water level,
    // and the surface is already in motion.
    final value = widget.value.clamp(0.0, 1.0);
    final color = rs.colorFor(value);
    final size = rs.size ?? ProgressDefaults.waveSize;
    final waveProgress = _waveCtrl?.value ?? 0;

    Widget wave = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: WaveFillPainter(
          value: value,
          color: color,
          trackColor: rs.trackFor(value),
          waveProgress: waveProgress,
        ),
      ),
    );

    if (widget.label != null) {
      return Stack(
        alignment: Alignment.center,
        children: [wave, widget.label!],
      );
    }
    if (!rs.showLabel) return wave;

    final text = rs.format(value);
    final style = rs.labelStyle.copyWith(
      fontSize: rs.labelStyle.fontSize! + 2,
      fontWeight: FontWeight.w800,
    );

    // Same split as the linear bar, along the WAVE's edge rather than a
    // straight one: the water crosses the text as the level rises.
    return Stack(
      children: [
        wave,
        Positioned.fill(
          child: Center(
            child: Text(text, style: style.copyWith(color: color)),
          ),
        ),
        Positioned.fill(
          child: ClipPath(
            clipper: WaveClipper(value: value, waveProgress: waveProgress),
            child: Center(
              child: Text(text, style: style.copyWith(color: _onFill(context))),
            ),
          ),
        ),
      ],
    );
  }

  /// Mirrors a painted shape in an RTL layout.
  ///
  /// A bar that fills leftward where you read right-to-left reads as
  /// DRAINING. `Row`-based shapes — stepped, multi-segment — get this
  /// from `Directionality` already; the hand-painted ones do not,
  /// because a `Canvas` has no reading direction.
  ///
  /// The label is NOT inside this: mirroring it would reverse the text.
  Widget _mirrored(Widget painted) {
    if (!_rs.followTextDirection) return painted;
    if (Directionality.of(context) != TextDirection.rtl) return painted;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..scaleByDouble(-1, 1, 1, 1),
      child: painted,
    );
  }

  /// Text drawn ON the fill. From the palette, not `Colors.white` —
  /// which was invisible on a light-coloured bar.
  Color _onFill(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;
}

// ---------------------------------------------------------------------------
// Countdown
// ---------------------------------------------------------------------------

class _CountdownProgress extends StatefulWidget {
  const _CountdownProgress({
    super.key,
    required this.duration,
    required this.style,
    required this.paused,
    this.onComplete,
    this.semanticLabel,
  });

  final Duration duration;
  final ProgressStyle style;
  final VoidCallback? onComplete;
  final String? semanticLabel;

  /// Holds the clock where it is. Changing [duration] restarts it.
  final bool paused;

  @override
  State<_CountdownProgress> createState() => _CountdownProgressState();
}

class _CountdownProgressState extends State<_CountdownProgress>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) widget.onComplete?.call();
      });
    if (!widget.paused) _ctrl.forward();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(_CountdownProgress old) {
    super.didUpdateWidget(old);
    // A NEW duration is a new countdown, not a rescaled one.
    if (old.duration != widget.duration) {
      _ctrl
        ..duration = widget.duration
        ..value = 0;
      if (!widget.paused) _ctrl.forward();
      return;
    }
    if (old.paused == widget.paused) return;
    widget.paused ? _ctrl.stop() : _ctrl.forward();
  }

  // A five-minute countdown used to expire in a pocket: the ticker kept
  // running with the app backgrounded, so the clock came back already
  // finished. It holds where it was instead — the same fix the banner's
  // auto-dismiss carries.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (widget.paused) return;
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_ctrl.isCompleted) _ctrl.forward();
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _ctrl.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ctrl.dispose();
    super.dispose();
  }

  /// `m:ss` once there is a minute to show, bare seconds below that —
  /// in the LOCALE's digits.
  ///
  /// The padding comes from the number pattern, not `padLeft('0')`,
  /// which would put an ASCII zero next to an Arabic-Indic digit.
  String _format(Duration remaining) {
    final seconds = remaining.inSeconds;
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return minutes > 0
        ? '${AppNumbers.integer(minutes)}:'
              '${AppNumbers.padded(secs, width: 2)}'
        : AppNumbers.integer(secs);
  }

  @override
  Widget build(BuildContext context) {
    final rs = widget.style.resolve(context, type: ProgressType.circular);
    final size = widget.style.size ?? ProgressDefaults.countdownSize;
    final thickness =
        widget.style.thickness ?? ProgressDefaults.countdownThickness;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final remaining = widget.duration * (1 - _ctrl.value);
        final text = _format(remaining);

        return Semantics(
          container: true,
          label: widget.semanticLabel,
          value: text,
          excludeSemantics: true,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(size, size),
                  painter: CircularProgressPainter(
                    value: 1 - _ctrl.value,
                    color: rs.color,
                    trackColor: rs.trackColor,
                    thickness: thickness,
                    capStyle: rs.capStyle,
                    indeterminate: false,
                    indeterminateProgress: 0,
                  ),
                ),
                GlobalText(
                  text,
                  textStyle: GlobalTextStyle(
                    fontSize: ProgressDefaults.gaugeLabelFontSize,
                    fontWeight: FontWeight.w800,
                    color: rs.color,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Absolute clipper — clips a rect using absolute pixel coordinates
// ---------------------------------------------------------------------------

class _AbsoluteClipper extends CustomClipper<Rect> {
  const _AbsoluteClipper({required this.left, required this.right});

  final double left;
  final double right;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(left, 0, right, size.height);

  @override
  bool shouldReclip(_AbsoluteClipper old) =>
      left != old.left || right != old.right;
}
