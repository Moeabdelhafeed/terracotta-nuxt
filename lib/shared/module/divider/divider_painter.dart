import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import 'divider_models.dart';

/// Paints the dashed / dotted / gradient / wave / zigzag line.
///
/// It takes the RESOLVED bag rather than ten loose numbers, so the
/// painter and the widget can never disagree about what a divider looks
/// like — they read the same object.
class DividerPainter extends CustomPainter {
  const DividerPainter({
    required this.rs,
    required this.lineStyle,
    this.isVertical = false,
  });

  final ResolvedDividerStyle rs;
  final DividerLineStyle lineStyle;
  final bool isVertical;

  Color get color => rs.color;
  Gradient? get gradient => rs.gradient;
  double get thickness => rs.thickness;
  double get dashWidth => rs.dashWidth;
  double get dashGap => rs.dashGap;
  bool get roundedCaps => rs.roundedCaps;
  double get waveAmplitude => rs.waveAmplitude;
  double get waveFrequency => rs.waveFrequency;

  @override
  void paint(Canvas canvas, Size size) {
    // Guard against zero-size canvas
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = roundedCaps || lineStyle == DividerLineStyle.dotted
          ? StrokeCap.round
          : StrokeCap.butt;

    if (gradient != null) {
      paint.shader = gradient!.createShader(Offset.zero & size);
    } else {
      paint.color = color;
    }

    switch (lineStyle) {
      case DividerLineStyle.solid:
        _drawSolid(canvas, size, paint);
      case DividerLineStyle.dashed:
      case DividerLineStyle.dotted:
        _drawDashed(canvas, size, paint);
      case DividerLineStyle.wave:
        _drawWave(canvas, size, paint);
      case DividerLineStyle.zigzag:
        _drawZigzag(canvas, size, paint);
    }
  }

  void _drawSolid(Canvas canvas, Size size, Paint paint) {
    if (isVertical) {
      canvas.drawLine(
        Offset(thickness / 2, 0),
        Offset(thickness / 2, size.height),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    }
  }

  void _drawDashed(Canvas canvas, Size size, Paint paint) {
    final effectiveDashWidth = lineStyle == DividerLineStyle.dotted
        ? thickness
        : dashWidth;
    final totalLength = isVertical ? size.height : size.width;
    final center = isVertical ? thickness / 2 : size.height / 2;
    var current = 0.0;

    while (current < totalLength) {
      final end = (current + effectiveDashWidth).clamp(0.0, totalLength);
      if (isVertical) {
        canvas.drawLine(Offset(center, current), Offset(center, end), paint);
      } else {
        canvas.drawLine(Offset(current, center), Offset(end, center), paint);
      }
      current += effectiveDashWidth + dashGap;
    }
  }

  void _drawWave(Canvas canvas, Size size, Paint paint) {
    final totalLength = isVertical ? size.height : size.width;
    if (totalLength <= 0 || waveFrequency <= 0) return;

    final path = Path();
    final center = isVertical ? size.width / 2 : size.height / 2;

    if (isVertical) {
      path.moveTo(center, 0);
      for (var t = 0.0; t <= totalLength; t += DividerDefaults.waveStep) {
        final offset =
            sin(t / totalLength * waveFrequency * 2 * pi) * waveAmplitude;
        path.lineTo(center + offset, t);
      }
      // Ensure path reaches the final edge
      path.lineTo(center, totalLength);
    } else {
      path.moveTo(0, center);
      for (var t = 0.0; t <= totalLength; t += DividerDefaults.waveStep) {
        final offset =
            sin(t / totalLength * waveFrequency * 2 * pi) * waveAmplitude;
        path.lineTo(t, center + offset);
      }
      path.lineTo(totalLength, center);
    }

    canvas.drawPath(path, paint);
  }

  void _drawZigzag(Canvas canvas, Size size, Paint paint) {
    final totalLength = isVertical ? size.height : size.width;
    if (totalLength <= 0 || waveFrequency <= 0) return;

    final path = Path();
    final center = isVertical ? size.width / 2 : size.height / 2;
    final segmentLen = totalLength / waveFrequency;

    if (isVertical) {
      path.moveTo(center, 0);
      for (var i = 0; i < waveFrequency.toInt(); i++) {
        final t1 = (i + 0.5) * segmentLen;
        final off1 = i.isEven ? -waveAmplitude : waveAmplitude;
        final t2 = (i + 1) * segmentLen;
        path.lineTo(center + off1, t1);
        path.lineTo(center, t2);
      }
      // Ensure path reaches the final edge
      path.lineTo(center, totalLength);
    } else {
      path.moveTo(0, center);
      for (var i = 0; i < waveFrequency.toInt(); i++) {
        final t1 = (i + 0.5) * segmentLen;
        final off1 = i.isEven ? -waveAmplitude : waveAmplitude;
        final t2 = (i + 1) * segmentLen;
        path.lineTo(t1, center + off1);
        path.lineTo(t2, center);
      }
      path.lineTo(totalLength, center);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DividerPainter old) =>
      lineStyle != old.lineStyle ||
      isVertical != old.isVertical ||
      color != old.color ||
      gradient != old.gradient ||
      thickness != old.thickness ||
      dashWidth != old.dashWidth ||
      dashGap != old.dashGap ||
      roundedCaps != old.roundedCaps ||
      waveAmplitude != old.waveAmplitude ||
      waveFrequency != old.waveFrequency;
}
