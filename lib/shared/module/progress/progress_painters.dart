import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'progress_models.dart';

/// The four shapes `GlobalProgress` draws by hand, split out of the
/// widget: it was 890 lines with the geometry inlined, and the painters
/// are the part with the arithmetic worth reading on its own.

// ---------------------------------------------------------------------------
// Linear
// ---------------------------------------------------------------------------

class LinearProgressPainter extends CustomPainter {
  const LinearProgressPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.radius,
    required this.indeterminate,
    required this.indeterminateProgress,
    required this.innerShadow,
    required this.bufferColor,
    required this.showTickMarks,
    required this.tickCount,
    required this.tickColor,
    required this.tickWidth,
    this.gradient,
    this.trackGradient,
    this.bufferValue,
  });

  final double value;
  final Color color;
  final Gradient? gradient;
  final Color trackColor;
  final Gradient? trackGradient;
  final BorderRadius radius;
  final bool indeterminate;
  final double indeterminateProgress;
  final bool innerShadow;
  final double? bufferValue;
  final Color bufferColor;
  final bool showTickMarks;
  final int tickCount;
  final Color tickColor;
  final double tickWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = radius.toRRect(rect);

    final trackPaint = Paint()..color = trackColor;
    if (trackGradient != null) {
      trackPaint.shader = trackGradient!.createShader(rect);
    }
    canvas.drawRRect(rrect, trackPaint);

    if (innerShadow) _paintInnerShadow(canvas, rect, rrect);

    final buffer = bufferValue;
    if (buffer != null && buffer > 0) {
      canvas
        ..save()
        ..clipRRect(rrect)
        ..drawRect(
          Rect.fromLTWH(0, 0, size.width * buffer.clamp(0.0, 1.0), size.height),
          Paint()..color = bufferColor,
        )
        ..restore();
    }

    final fillPaint = Paint()..color = color;
    if (gradient != null) fillPaint.shader = gradient!.createShader(rect);

    if (indeterminate) {
      _paintSweep(canvas, size, rrect, fillPaint);
    } else if (value > 0) {
      canvas
        ..save()
        ..clipRRect(rrect)
        ..drawRect(
          Rect.fromLTWH(0, 0, size.width * value, size.height),
          fillPaint,
        )
        ..restore();
    }

    if (showTickMarks && tickCount > 1) {
      final tickPaint = Paint()
        ..color = tickColor
        ..strokeWidth = tickWidth;
      for (var i = 1; i < tickCount; i++) {
        final x = size.width * i / tickCount;
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), tickPaint);
      }
    }
  }

  void _paintInnerShadow(Canvas canvas, Rect rect, RRect rrect) {
    canvas
      ..save()
      ..clipRRect(rrect);
    final paint = Paint()
      ..color = Colors.black.withValues(
        alpha: ProgressDefaults.innerShadowOpacity,
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        ProgressDefaults.innerShadowBlur,
      );
    final outer = Path()
      ..addRect(rect.inflate(ProgressDefaults.innerShadowBlur * 2));
    final inner = Path()..addRRect(rrect.deflate(1));
    canvas
      ..drawPath(Path.combine(PathOperation.difference, outer, inner), paint)
      ..restore();
  }

  /// The indeterminate bar: it travels left to right and its width
  /// swells mid-journey, so the ends of the run do not look like a stall.
  void _paintSweep(Canvas canvas, Size size, RRect rrect, Paint paint) {
    final t = indeterminateProgress;
    final w = size.width;
    final barWidth = w * (0.15 + 0.35 * math.sin(t * math.pi));
    final center = -barWidth + t * (w + barWidth * 2);
    canvas
      ..save()
      ..clipRRect(rrect)
      ..drawRect(
        Rect.fromLTRB(
          (center - barWidth / 2).clamp(0, w),
          0,
          (center + barWidth / 2).clamp(0, w),
          size.height,
        ),
        paint,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(LinearProgressPainter old) =>
      value != old.value ||
      indeterminateProgress != old.indeterminateProgress ||
      bufferValue != old.bufferValue ||
      color != old.color ||
      trackColor != old.trackColor;
}

// ---------------------------------------------------------------------------
// Circular
// ---------------------------------------------------------------------------

class CircularProgressPainter extends CustomPainter {
  const CircularProgressPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.thickness,
    required this.capStyle,
    required this.indeterminate,
    required this.indeterminateProgress,
    this.gradient,
  });

  final double value;
  final Color color;
  final Gradient? gradient;
  final Color trackColor;
  final double thickness;
  final ProgressCapStyle capStyle;
  final bool indeterminate;
  final double indeterminateProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = (math.min(size.width, size.height) - thickness) / 2;
    final rect = Rect.fromCircle(center: center, radius: r);
    final cap = capStyle == ProgressCapStyle.round
        ? StrokeCap.round
        : StrokeCap.butt;

    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness,
    );

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = cap;
    if (gradient != null) fillPaint.shader = gradient!.createShader(rect);

    if (indeterminate) {
      final t = indeterminateProgress;
      // TWO whole turns per cycle. A fractional count leaves the arc
      // somewhere other than where it started, so the loop visibly
      // jumps every time it repeats.
      final rotation = t * 2 * math.pi * 2;
      final sweep = 0.3 + 1.2 * math.sin(t * math.pi);
      canvas.drawArc(
        rect,
        rotation - math.pi / 2,
        sweep * math.pi,
        false,
        fillPaint,
      );
    } else if (value > 0) {
      canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * value, false, fillPaint);
    }
  }

  @override
  bool shouldRepaint(CircularProgressPainter old) =>
      value != old.value ||
      indeterminateProgress != old.indeterminateProgress ||
      color != old.color ||
      trackColor != old.trackColor;
}

// ---------------------------------------------------------------------------
// Gauge
// ---------------------------------------------------------------------------

class GaugeProgressPainter extends CustomPainter {
  const GaugeProgressPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.thickness,
    required this.capStyle,
    this.gradient,
  });

  final double value;
  final Color color;
  final Gradient? gradient;
  final Color trackColor;
  final double thickness;
  final ProgressCapStyle capStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final r = (math.min(size.width, size.height * 2) - thickness) / 2;
    final rect = Rect.fromCircle(center: center, radius: r);
    final cap = capStyle == ProgressCapStyle.round
        ? StrokeCap.round
        : StrokeCap.butt;

    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..strokeCap = cap,
    );

    if (value <= 0) return;
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness
      ..strokeCap = cap;
    if (gradient != null) fillPaint.shader = gradient!.createShader(rect);
    canvas.drawArc(rect, math.pi, math.pi * value, false, fillPaint);
  }

  @override
  bool shouldRepaint(GaugeProgressPainter old) =>
      value != old.value || color != old.color || trackColor != old.trackColor;
}

// ---------------------------------------------------------------------------
// Wave fill
// ---------------------------------------------------------------------------

/// The water surface at [x], for a level and a phase. Shared by the
/// painter and the clipper so the fill and the text it cuts through
/// cannot drift apart.
double waveSurface(double x, double waterLevel, double waveProgress) =>
    waterLevel +
    ProgressDefaults.waveAmplitude *
        math.sin(
          (x * ProgressDefaults.waveFrequency) +
              (waveProgress * ProgressDefaults.waveSpeed * math.pi * 2),
        );

class WaveFillPainter extends CustomPainter {
  const WaveFillPainter({
    required this.value,
    required this.color,
    required this.trackColor,
    required this.waveProgress,
  });

  final double value;
  final Color color;
  final Color trackColor;
  final double waveProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2;

    canvas
      ..save()
      ..clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r)))
      ..drawCircle(center, r, Paint()..color = trackColor);

    final waterLevel = size.height * (1 - value);
    canvas.drawPath(
      _wavePath(size, waterLevel, phase: 0, scale: 1),
      Paint()..color = color,
    );

    // A second, slower crest at a different frequency and half a turn
    // out of phase. One sine reads as a moving stripe; two crossing
    // each other read as water.
    canvas
      ..drawPath(
        _wavePath(size, waterLevel, phase: math.pi, scale: 1.3, damp: 0.7),
        Paint()
          ..color = color.withValues(
            alpha: ProgressDefaults.waveSecondLayerOpacity,
          ),
      )
      ..drawCircle(
        center,
        r,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = ProgressDefaults.waveBorderWidth,
      )
      ..restore();
  }

  Path _wavePath(
    Size size,
    double waterLevel, {
    required double phase,
    required double scale,
    double damp = 1,
  }) {
    final path = Path()..moveTo(0, waterLevel);
    for (var x = 0.0; x <= size.width; x += 1) {
      final y =
          waterLevel +
          ProgressDefaults.waveAmplitude *
              damp *
              math.sin(
                (x * ProgressDefaults.waveFrequency * scale) +
                    (waveProgress * ProgressDefaults.waveSpeed * math.pi * 2) +
                    phase,
              );
      path.lineTo(x, y);
    }
    return path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldRepaint(WaveFillPainter old) =>
      value != old.value ||
      waveProgress != old.waveProgress ||
      color != old.color;
}

/// Clips to the wave's own surface, so a label can be drawn in one
/// colour above the water and another below it.
class WaveClipper extends CustomClipper<Path> {
  const WaveClipper({required this.value, required this.waveProgress});

  final double value;
  final double waveProgress;

  @override
  Path getClip(Size size) {
    final waterLevel = size.height * (1 - value);
    final path = Path()..moveTo(0, waterLevel);
    for (var x = 0.0; x <= size.width; x += 1) {
      path.lineTo(x, waveSurface(x, waterLevel, waveProgress));
    }
    return path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(WaveClipper old) =>
      value != old.value || waveProgress != old.waveProgress;
}
