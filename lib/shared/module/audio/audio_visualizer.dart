import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'audio_player_handle.dart';
import 'theme/visualizer_theme.dart';
import 'visualizer_models.dart';

/// Real-or-fake amplitude visualizer.
///
/// Three drive modes, in priority order:
///
/// 1. **[bandStream]** — full per-bin snapshot per emission. Use this
///    when you have *real* FFT data from a native plugin
///    (Android `Visualizer` / iOS `MTAudioProcessingTap`). Bins are
///    rendered as-is.
///
/// 2. **[handle]** — reads the player's `samples` + `progress` each
///    frame and projects a window around the playhead into the bins,
///    plus per-bin oscillator variance. Looks spectral but is purely
///    derived from the decoded static waveform — no real FFT.
///
/// 3. **[amplitudeStream]** — single 0..1 value per tick, expanded
///    across bins via independent per-bin oscillators. Cheapest
///    option; least realistic.
class GlobalAudioVisualizer extends StatefulWidget {
  const GlobalAudioVisualizer({
    super.key,
    this.amplitudeStream,
    this.bandStream,
    this.handle,
    this.style = const VisualizerStyle(),
  }) : assert(
         amplitudeStream != null || bandStream != null || handle != null,
         'Pass one of: bandStream, handle, amplitudeStream',
       );

  /// Single 0..1 amplitude per emission. Lowest-fidelity fake mode.
  final Stream<double>? amplitudeStream;

  /// Full band snapshot per emission — rendered as-is. Use this for
  /// real FFT data wired from a native plugin.
  final Stream<List<double>>? bandStream;

  /// Player handle — when supplied, the visualizer reads the player's
  /// decoded waveform + playhead each frame and projects a window
  /// into the bins. Far more "alive" than amplitudeStream alone.
  final AudioPlayerHandle? handle;

  /// How it looks. Layered `caller > GlobalVisualizerTheme >
  /// VisualizerStyle.defaults` and resolved once per build.
  final VisualizerStyle style;

  @override
  State<GlobalAudioVisualizer> createState() => _GlobalAudioVisualizerState();
}

class _GlobalAudioVisualizerState extends State<GlobalAudioVisualizer>
    with SingleTickerProviderStateMixin {
  /// The resolved bag, held on the STATE because the ticker reads it
  /// and the ticker runs between builds. Not `late`: the ticker starts
  /// in `initState`, and resolving needs the inherited theme, which is
  /// only there from `didChangeDependencies` — the same trap the video
  /// module hit, where every player threw on its first frame.
  ResolvedVisualizerStyle _rs = _bootStyle;

  /// A context-free bag nothing ever actually paints with — no frame
  /// can happen before `didChangeDependencies`.
  static const _bootStyle = ResolvedVisualizerStyle(
    shape: VisualizerDefaults.shape,
    barCount: VisualizerDefaults.barCount,
    color: Color(0xFF000000),
    height: VisualizerDefaults.height,
    smoothing: VisualizerDefaults.smoothing,
    minBar: VisualizerDefaults.minBar,
    glow: false,
    barWidthFactor: VisualizerDefaults.barWidthFactor,
    windowSpread: VisualizerDefaults.windowSpread,
    idleDecay: VisualizerDefaults.idleDecay,
  );

  late List<double> _bins;
  late List<double> _phase;
  late List<double> _freq;
  late List<double> _gain;

  StreamSubscription<double>? _ampSub;
  StreamSubscription<List<double>>? _bandSub;
  Ticker? _ticker;

  double _latestAmp = 0;
  double _playingEnvelope = 0;

  /// What the painter listens to.
  ///
  /// The ticker used to rebuild the whole subtree sixty times a
  /// second, with an empty setter body, to move numbers the painter
  /// already had a reference to. The bins are mutated in place, so it
  /// only ever needed telling that they changed.
  final _frame = ValueNotifier<int>(0);

  void _repaint() => _frame.value++;

  final _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _allocBuffers();

    if (widget.bandStream != null) {
      _bandSub = widget.bandStream!.listen((b) {
        if (!mounted) return;
        // Real bands — render as-is, just smooth a touch.
        final n = math.min(b.length, _bins.length);
        for (var i = 0; i < n; i++) {
          final v = b[i].isNaN ? 0.0 : b[i].clamp(0.0, 1.0);
          _bins[i] = _bins[i] * _rs.smoothing + v * (1 - _rs.smoothing);
        }
        _repaint();
      });
      return; // bandStream wins — no ticker needed.
    }

    if (widget.amplitudeStream != null) {
      _ampSub = widget.amplitudeStream!.listen(
        (v) => _latestAmp = v.isNaN ? 0 : v.clamp(0.0, 1.0),
      );
    }

    // The handle is READ each tick rather than subscribed to — the
    // ticker already runs every frame and the stream would only say
    // the same thing later. A subscription that does nothing was here
    // before, holding a broadcast stream open for no reason.

    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  /// Re-resolves, and re-allocates only when the BIN COUNT moved —
  /// the buffers are the one thing sized by the bag.
  void _resolve() {
    final next = widget.style.resolve(context);
    final resized = next.barCount != _rs.barCount;
    _rs = next;
    if (resized) _allocBuffers();
  }

  void _allocBuffers() {
    final n = _rs.barCount;
    _bins = List<double>.filled(n, 0);
    _phase = List<double>.generate(n, (_) => _rng.nextDouble() * math.pi * 2);
    // 3 Hz .. 14 Hz spread per bin — gives bars different motion rates.
    _freq = List<double>.generate(n, (_) => 3 + _rng.nextDouble() * 11);
    // 0.7..1.0 per-bin static gain so bars don't feel uniform.
    _gain = List<double>.generate(n, (_) => 0.7 + _rng.nextDouble() * 0.3);
  }

  @override
  void didUpdateWidget(covariant GlobalAudioVisualizer old) {
    super.didUpdateWidget(old);
    if (old.style != widget.style) _resolve();
  }

  void _onTick(Duration elapsed) {
    if (!mounted) return;
    final t = elapsed.inMicroseconds / 1e6;

    // Playing envelope: smooth ramp 0..1 so bars don't snap on/off.
    final isPlaying = widget.handle?.state.playing ?? (_latestAmp > 0);
    final target = isPlaying ? 1.0 : 0.0;
    _playingEnvelope = _playingEnvelope + (target - _playingEnvelope) * 0.08;

    final n = _bins.length;
    final h = widget.handle;
    final s = _rs.smoothing;

    if (h != null) {
      _driveFromHandle(h, n, t, s);
    } else {
      _driveFromAmplitude(n, t, s);
    }

    // Idle decay so the picture eases to zero on pause.
    if (_playingEnvelope < 0.02) {
      for (var i = 0; i < n; i++) {
        _bins[i] *= _rs.idleDecay;
      }
    }

    _repaint();
  }

  /// Project a window of the player's decoded waveform onto the bins,
  /// plus per-bin oscillator variance. Looks spectral.
  ///
  /// Source-index is kept as a *continuous* double + lerped between
  /// neighbouring samples so the window slides smoothly even when
  /// the playhead's integer bin would only bump once every few
  /// hundred milliseconds. Without this, low-resolution waveforms
  /// (e.g. 180 samples over a 2-min track ⇒ ~700ms per source bin)
  /// make the visualizer feel like it updates once per second.
  void _driveFromHandle(AudioPlayerHandle h, int n, double t, double s) {
    final samples = h.samples;
    if (samples.isEmpty) return;
    final len = samples.length;
    final exactPlayhead = h.progress.clamp(0.0, 1.0) * (len - 1);
    final spread = (len * _rs.windowSpread).clamp(
      8.0,
      len.toDouble(),
    );
    final halfSpread = spread / 2;
    final stride = spread / n;

    for (var i = 0; i < n; i++) {
      final exact = exactPlayhead - halfSpread + i * stride;
      // Linear interp between the two source samples bracketing this
      // bin's continuous index. The window now slides per-frame as
      // `exact` changes by sub-sample amounts.
      final lo = exact.floor();
      final hi = lo + 1;
      final frac = exact - lo;
      final loV = samples[lo < 0 ? 0 : (lo >= len ? len - 1 : lo)];
      final hiV = samples[hi < 0 ? 0 : (hi >= len ? len - 1 : hi)];
      final base = loV + (hiV - loV) * frac;

      final osc = 0.55 + 0.45 * math.sin(t * _freq[i] + _phase[i]);
      final raw = base * osc * _gain[i] * _playingEnvelope;
      _bins[i] = _bins[i] * s + raw * (1 - s);
    }
  }

  /// One amplitude expanded across bins by independent oscillators.
  /// Cheapest fake mode.
  void _driveFromAmplitude(int n, double t, double s) {
    final amp = _latestAmp * _playingEnvelope;
    for (var i = 0; i < n; i++) {
      final osc = 0.5 + 0.5 * math.sin(t * _freq[i] + _phase[i]);
      final raw = amp * osc * _gain[i];
      _bins[i] = _bins[i] * s + raw * (1 - s);
    }
  }

  @override
  void dispose() {
    _ampSub?.cancel();
    _bandSub?.cancel();
    _ticker?.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paint = RepaintBoundary(
      child: CustomPaint(
        painter: _VisualizerPainter(
          values: _bins,
          shape: _rs.shape,
          color: _rs.color,
          gradient: _rs.gradient,
          minBar: _rs.minBar,
          glow: _rs.glow,
          barWidthFactor: _rs.barWidthFactor,
          repaint: _frame,
        ),
        size: Size(double.infinity, _rs.height),
      ),
    );
    // DECORATION. A picture of a sound says nothing a reader can use,
    // and a screen reader walking a page should not stop on it.
    if (!_rs.hasSurface) return ExcludeSemantics(child: paint);
    return ExcludeSemantics(
      child: Container(
        decoration: BoxDecoration(
          color: _rs.background,
          borderRadius: _rs.borderRadius,
        ),
        child: ClipRRect(
          borderRadius: _rs.borderRadius ?? BorderRadius.zero,
          child: paint,
        ),
      ),
    );
  }
}

class _VisualizerPainter extends CustomPainter {
  _VisualizerPainter({
    required this.values,
    required super.repaint,
    required this.shape,
    required this.color,
    required this.gradient,
    required this.minBar,
    required this.glow,
    required this.barWidthFactor,
  });

  final List<double> values;
  final VisualizerShape shape;
  final Color color;
  final Gradient? gradient;
  final double minBar;
  final bool glow;
  final double barWidthFactor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.width <= 0 || size.height <= 0) return;
    switch (shape) {
      case VisualizerShape.bars:
        _paintBars(canvas, size, mirrored: false);
      case VisualizerShape.mirror:
        _paintBars(canvas, size, mirrored: true);
      case VisualizerShape.dots:
        _paintDots(canvas, size);
      case VisualizerShape.line:
        _paintLine(canvas, size);
      case VisualizerShape.circular:
        _paintCircular(canvas, size);
      case VisualizerShape.wave:
        _paintWave(canvas, size);
    }
  }

  Paint _basePaint(Size s) {
    final p = Paint();
    if (gradient != null) {
      p.shader = gradient!.createShader(Offset.zero & s);
    } else {
      p.color = color;
    }
    if (glow) {
      p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    }
    return p;
  }

  void _paintBars(Canvas canvas, Size size, {required bool mirrored}) {
    final p = _basePaint(size);
    final n = values.length;
    final pitch = size.width / n;
    final barW = pitch * barWidthFactor;
    for (var i = 0; i < n; i++) {
      final v = values[i].clamp(minBar, 1.0);
      final h = v * size.height;
      final x = i * pitch + (pitch - barW) / 2;
      final rect = mirrored
          ? Rect.fromLTWH(x, size.height / 2 - h / 2, barW, h)
          : Rect.fromLTWH(x, size.height - h, barW, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(barW / 2)),
        p,
      );
    }
  }

  void _paintDots(Canvas canvas, Size size) {
    final p = _basePaint(size);
    final n = values.length;
    final pitch = size.width / n;
    final mid = size.height / 2;
    final maxR = size.height / 2;
    for (var i = 0; i < n; i++) {
      final v = values[i].clamp(minBar, 1.0);
      final r = (v * maxR).clamp(2.0, maxR);
      canvas.drawCircle(Offset(i * pitch + pitch / 2, mid), r, p);
    }
  }

  void _paintLine(Canvas canvas, Size size) {
    final p = _basePaint(size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final n = values.length;
    if (n < 2) return;
    final pitch = size.width / (n - 1);
    final mid = size.height / 2;
    canvas.drawPath(_curveThrough(size, pitch, mid), p);
  }

  /// A smooth path through every bin.
  ///
  /// Straight segments between forty-eight points read as a jagged
  /// chart rather than as a sound — the corners are the loudest thing
  /// on screen. Each segment is a quadratic whose control point is the
  /// data point itself and whose ends are the MIDPOINTS either side,
  /// which is the standard way to draw a curve through samples without
  /// it overshooting between them.
  Path _curveThrough(Size size, double pitch, double mid) {
    final n = values.length;
    double yAt(int i) =>
        mid - (values[i.clamp(0, n - 1)].clamp(0.0, 1.0) - 0.5) * size.height;

    final path = Path()..moveTo(0, yAt(0));
    for (var i = 0; i < n - 1; i++) {
      final x = i * pitch;
      final nextX = (i + 1) * pitch;
      path.quadraticBezierTo(
        x,
        yAt(i),
        (x + nextX) / 2,
        (yAt(i) + yAt(i + 1)) / 2,
      );
    }
    return path..lineTo((n - 1) * pitch, yAt(n - 1));
  }

  void _paintWave(Canvas canvas, Size size) {
    final p = _basePaint(size)..style = PaintingStyle.fill;
    final n = values.length;
    if (n < 2) return;
    final pitch = size.width / (n - 1);
    final mid = size.height / 2;
    // The same curve as `line`, closed to the bottom edge.
    final path = _curveThrough(size, pitch, mid)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, p);
  }

  void _paintCircular(Canvas canvas, Size size) {
    final p = _basePaint(size)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final n = values.length;
    final step = 2 * math.pi / n;
    final inner = radius * 0.55;
    for (var i = 0; i < n; i++) {
      final v = values[i].clamp(minBar, 1.0);
      final outer = inner + (radius - inner) * v;
      final a = i * step - math.pi / 2;
      final cosA = math.cos(a);
      final sinA = math.sin(a);
      canvas.drawLine(
        Offset(center.dx + cosA * inner, center.dy + sinA * inner),
        Offset(center.dx + cosA * outer, center.dy + sinA * outer),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_VisualizerPainter old) {
    // The widget mutates `values` in place and hands over the same
    // list every time, so comparing them would always say "no
    // repaint". What actually drives this is the `repaint` listenable
    // the painter was built with — by the time this is asked, the
    // answer is already yes.
    return true;
  }
}
