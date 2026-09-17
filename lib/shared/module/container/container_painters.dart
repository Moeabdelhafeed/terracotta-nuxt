part of 'global_container.dart';

// Everything that paints on a canvas rather than laying out: the two
// inner-shadow painters, the styled border, and the wave geometry the
// border walks.

/// How deep a wave may go, as a fraction of the tightest corner radius.
/// Past about two thirds the crest folds through the inside of the arc.
const _kAmplitudeOfRadius = 0.6;

/// Roughly how long one wave should be, in points.
///
/// `waveFrequency` used to mean two different things: the wave read it
/// as cycles-per-twenty-points, and the zigzag as "this many zigzags
/// round the WHOLE perimeter". On the showcase's own card that came to
/// a 10-point wave beside a 68-point zigzag, against a corner arc of
/// 25 — so one zigzag segment swallowed an entire corner and the corner
/// came out as a lobe.
double waveLengthFor(double frequency) => 20 / math.max(frequency, 0.1) * 12;

/// The amplitude a wave may actually use on a rounded box.
///
/// The painter used to DAMP by curvature, down to eight per cent on a
/// corner — so the line waved along every straight and went flat round
/// every corner, which is the one place the eye is looking. A wave
/// offset along the normal only misbehaves when it is deep enough to
/// fold through the inside of the curve, so this is a CEILING against
/// the tightest corner rather than a fade to nothing.
@visibleForTesting
double safeWaveAmplitude(RRect rrect, double amplitude) {
  final smallest = <double>[
    rrect.tlRadiusX,
    rrect.trRadiusX,
    rrect.blRadiusX,
    rrect.brRadiusX,
    rrect.tlRadiusY,
    rrect.trRadiusY,
    rrect.blRadiusY,
    rrect.brRadiusY,
  ].where((r) => r > 0).fold<double>(double.infinity, math.min);
  if (smallest == double.infinity) return amplitude;
  return math.min(amplitude, smallest * _kAmplitudeOfRadius);
}

/// How many whole wave cycles go round a perimeter.
///
/// A WHOLE number, so the wave meets itself where the path closes —
/// the phase used to be raw arc length, which lands wherever it lands
/// after one lap and left a visible kink on every container.
///
/// And UNIFORM, deliberately. An earlier attempt gave each run of the
/// outline — four straights, four arcs — its own whole number of
/// half-cycles, which does make the four corners identical, but it also
/// pins the wave to zero at all eight junctions: eight flat spots, four
/// of them right where a corner starts. A decorative scallop runs
/// unbroken round the whole shape.
@visibleForTesting
int waveCyclesFor(double perimeter, double wavelength) =>
    math.max(1, (perimeter / wavelength).round());

/// A triangle wave with the same zeros and peaks as `sin(2 * pi * x)`,
/// so the zigzag and the wave agree on where a crest belongs.
@visibleForTesting
double triangleForTest(double cycles) => _triangle(cycles);

double _triangle(double cycles) {
  final t = cycles % 1;
  return t < 0.5 ? 1 - (4 * t - 1).abs() : (4 * (t - 0.5) - 1).abs() - 1;
}

class _InnerShadowPainter extends CustomPainter {
  const _InnerShadowPainter({
    required this.shadows,
    required this.borderRadius,
  });
  final List<BoxShadow> shadows;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    for (final shadow in shadows) {
      final paint = Paint()
        ..color = shadow.color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadow.blurRadius);

      // Create a path that's the inverse of the rrect — this creates the inner shadow
      final outer = Path()
        ..addRect(rect.inflate(shadow.blurRadius * 2 + shadow.spreadRadius));
      final inner = Path()
        ..addRRect(rrect.shift(shadow.offset).deflate(shadow.spreadRadius));
      final shadowPath = Path.combine(PathOperation.difference, outer, inner);

      canvas.save();
      canvas.clipRRect(rrect);
      canvas.drawPath(shadowPath, paint);
      canvas.restore();
    }
  }

  /// Decoration only — see the note on `_StyledBorderPainter.hitTest`.
  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_InnerShadowPainter old) =>
      shadows != old.shadows || borderRadius != old.borderRadius;
}

// ═══════════════════════════════════════════════════════════════
// Styled border painter (dashed, dotted, wave, zigzag)
// ═══════════════════════════════════════════════════════════════

/// One walk of the outline, offset along the normal by a wave of
/// constant wavelength — the same scallop on the straights and round
/// the corners, unbroken all the way round.
///
/// Returns the SAMPLES rather than a `Path`, because the seam is the
/// thing that goes wrong and a closed path cannot show it: `close()`
/// draws the joining segment, so the first and last points of the path
/// coincide however badly the phase actually lands. Two versions of
/// this test passed against a reverted painter before that was noticed.
@visibleForTesting
List<List<Offset>> rippleSamples(
  RRect rrect, {
  required double amplitude,
  required double wavelength,
  required bool sine,
}) {
  final source = Path()..addRRect(rrect);
  final out = <List<Offset>>[];
  // Enough samples that a crest is a curve rather than a corner.
  final step = math.min(1.0, wavelength / 16);

  for (final metric in source.computeMetrics()) {
    final cycles = waveCyclesFor(metric.length, wavelength);
    final points = <Offset>[];
    var distance = 0.0;

    while (distance <= metric.length) {
      final tangent = metric.getTangentForOffset(distance);
      if (tangent == null) break;

      final phase = distance / metric.length * cycles;
      final offset = sine ? math.sin(phase * 2 * math.pi) : _triangle(phase);
      final wave = amplitude * offset;
      points.add(
        Offset(
          tangent.position.dx + wave * -math.sin(tangent.angle),
          tangent.position.dy + wave * math.cos(tangent.angle),
        ),
      );
      distance += step;
    }
    if (points.isNotEmpty) out.add(points);
  }
  return out;
}

/// The same walk, as paths ready to stroke.
List<Path> ripplePaths(
  RRect rrect, {
  required double amplitude,
  required double wavelength,
  required bool sine,
}) => [
  for (final points in rippleSamples(
    rrect,
    amplitude: amplitude,
    wavelength: wavelength,
    sine: sine,
  ))
    Path()..addPolygon(points, true),
];

class _StyledBorderPainter extends CustomPainter {
  const _StyledBorderPainter({
    required this.borderRadius,
    required this.color,
    required this.width,
    required this.lineStyle,
    required this.dashWidth,
    required this.dashGap,
    required this.waveAmplitude,
    required this.waveFrequency,
  });

  final BorderRadius borderRadius;
  final Color color;
  final double width;
  final ContainerBorderLineStyle lineStyle;
  final double dashWidth;
  final double dashGap;
  final double waveAmplitude;
  final double waveFrequency;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect).deflate(width / 2);
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    switch (lineStyle) {
      case ContainerBorderLineStyle.solid:
        canvas.drawRRect(rrect, paint);

      case ContainerBorderLineStyle.dashed:
        _drawDashedRRect(canvas, rrect, paint, dashWidth, dashGap);

      case ContainerBorderLineStyle.dotted:
        _drawDashedRRect(canvas, rrect, paint, width, dashGap);

      case ContainerBorderLineStyle.wave:
        _drawWaveRRect(canvas, rrect, paint);

      case ContainerBorderLineStyle.zigzag:
        _drawZigzagRRect(canvas, rrect, paint);
    }
  }

  void _drawDashedRRect(
    Canvas canvas,
    RRect rrect,
    Paint paint,
    double dw,
    double gap,
  ) {
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();

    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dw).clamp(0.0, metric.length);
        final segment = metric.extractPath(distance, end);
        canvas.drawPath(segment, paint);
        distance += dw + gap;
      }
    }
  }

  /// Measures curvature at a point by sampling the angle change over a small step.
  /// Returns a damping factor: 1.0 on straight edges, reduced on corners.
  void _drawWaveRRect(Canvas canvas, RRect rrect, Paint paint) {
    _drawRippledRRect(canvas, rrect, paint, sine: true);
  }

  void _drawRippledRRect(
    Canvas canvas,
    RRect rrect,
    Paint paint, {
    required bool sine,
  }) {
    for (final path in ripplePaths(
      rrect,
      amplitude: safeWaveAmplitude(rrect, waveAmplitude),
      wavelength: waveLengthFor(waveFrequency),
      sine: sine,
    )) {
      canvas.drawPath(path, paint);
    }
  }

  void _drawZigzagRRect(Canvas canvas, RRect rrect, Paint paint) {
    // Same walk, triangle instead of sine. It used to divide the whole
    // perimeter into `waveFrequency * 2` segments, which on the
    // showcase's own card was a 68-point period against a 25-point
    // corner arc — one segment cut clean across the corner and the
    // corner read as a lobe.
    _drawRippledRRect(canvas, rrect, paint, sine: false);
  }

  /// DECORATION, and nothing to press.
  ///
  /// `RenderCustomPaint.hitTestSelf` reads a BACKGROUND painter as
  /// `_painter!.hitTest(position) ?? true` — the fallback is **true**,
  /// the opposite of the foreground painter's — so a painter that does
  /// not answer this swallows every tap that lands on it. Painted over
  /// a container in `Positioned.fill`, that killed the `InkWell`
  /// underneath: a dashed or dotted card looked interactive, rippled
  /// nowhere and did nothing.
  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_StyledBorderPainter old) =>
      color != old.color ||
      width != old.width ||
      lineStyle != old.lineStyle ||
      dashWidth != old.dashWidth ||
      dashGap != old.dashGap;
}

// ═══════════════════════════════════════════════════════════════
// Gradient inner shadow painter
// ═══════════════════════════════════════════════════════════════

class _GradientInnerShadowPainter extends CustomPainter {
  const _GradientInnerShadowPainter({
    required this.gradient,
    required this.borderRadius,
  });
  final Gradient gradient;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);
    canvas.save();
    canvas.clipRRect(rrect);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
    canvas.restore();
  }

  /// Decoration only — see the note on `_StyledBorderPainter.hitTest`.
  @override
  bool? hitTest(Offset position) => false;

  @override
  bool shouldRepaint(_GradientInnerShadowPainter old) =>
      gradient != old.gradient;
}

// ═══════════════════════════════════════════════════════════════
// Animated border container
// ═══════════════════════════════════════════════════════════════
