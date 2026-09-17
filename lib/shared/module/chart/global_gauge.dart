import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';

export 'chart_models.dart' show ChartStyle;

/// Single-value gauge / speedometer. Half-circle arc with an animated
/// fill that sweeps from [min] to [value]. KPI-style.
///
/// ```dart
/// GlobalGauge(value: 72, min: 0, max: 100, label: 'Score')
/// ```
class GlobalGauge extends StatelessWidget {
  const GlobalGauge({
    required this.value,
    this.min = 0,
    this.max = 100,
    this.label,
    this.unit = '',
    this.size = 200,
    this.thickness = 16,
    this.color,
    this.gradient,
    this.trackColor,
    this.animationDuration = const Duration(milliseconds: 900),
    this.animationCurve = Curves.easeOutCubic,
    this.thresholds = const [],
    super.key,
  });

  final double value;
  final double min;
  final double max;

  /// Caption rendered above the value (e.g. `"Score"`).
  final String? label;

  /// Suffix appended to the value text (e.g. `"%"`, `" mph"`).
  final String unit;

  final double size;
  final double thickness;

  /// Solid arc color. Falls back to `primary`. Ignored when
  /// [gradient] or [thresholds] are set.
  final Color? color;

  /// `LinearGradient` / `SweepGradient` painted along the active
  /// arc. Wins over [color]. Ignored when [thresholds] are set.
  final Gradient? gradient;

  /// Background ring color. Falls back to `outlineVariant`.
  final Color? trackColor;

  final Duration animationDuration;
  final Curve animationCurve;

  /// Color zones triggered when [value] crosses a threshold. Each
  /// entry is `(thresholdFraction, color)` where the fraction is
  /// `0..1` of the `(value - min) / (max - min)` range. Lower bands
  /// shadow into upper bands as the needle sweeps. When non-empty,
  /// [color] / [gradient] are ignored.
  final List<({double at, Color color})> thresholds;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);
    final fraction = (clamped - min) / (max - min == 0 ? 1 : max - min);

    final track = trackColor ?? context.backgroundColors.outlineVariant;
    final fill = color ?? context.primaryColors.primary;

    return SizedBox(
      width: size,
      height: size * 0.72,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: fraction),
        duration: animationDuration,
        curve: animationCurve,
        builder: (context, t, _) {
          final activeColor = _resolveActiveColor(t, fill);
          final theme = Theme.of(context);
          return Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(size, size * 0.62),
                painter: _GaugePainter(
                  fraction: t,
                  trackColor: track,
                  fillColor: activeColor,
                  gradient: thresholds.isEmpty ? gradient : null,
                  thickness: thickness,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: size * 0.32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (label != null)
                      Text(
                        label!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: context.textColors.secondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    Text(
                      '${AppNumbers.decimal(min + (max - min) * t, fractionDigits: 0)}$unit',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.textColors.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Lerp between threshold colors instead of stepping at each
  /// boundary — the arc color glides smoothly as the needle sweeps
  /// from one zone to the next.
  Color _resolveActiveColor(double t, Color fallback) {
    if (thresholds.isEmpty) return fallback;
    final sorted = [...thresholds]..sort((a, b) => a.at.compareTo(b.at));
    if (t <= sorted.first.at) return sorted.first.color;
    if (t >= sorted.last.at) return sorted.last.color;
    for (var i = 0; i < sorted.length - 1; i++) {
      final lo = sorted[i];
      final hi = sorted[i + 1];
      if (t >= lo.at && t <= hi.at) {
        final span = hi.at - lo.at;
        final local = span == 0 ? 0.0 : (t - lo.at) / span;
        return Color.lerp(lo.color, hi.color, local) ?? lo.color;
      }
    }
    return sorted.last.color;
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.fraction,
    required this.trackColor,
    required this.fillColor,
    required this.thickness,
    this.gradient,
  });

  final double fraction;
  final Color trackColor;
  final Color fillColor;
  final Gradient? gradient;
  final double thickness;

  static const _start = math.pi; // 9 o'clock
  static const _sweep = math.pi; // 180° clockwise to 3 o'clock

  @override
  void paint(Canvas canvas, Size size) {
    final radius = math.min(size.width / 2, size.height) - thickness / 2;
    final center = Offset(size.width / 2, size.height);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = trackColor
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, _start, _sweep, false, track);

    if (fraction <= 0) return;
    final fill = Paint()
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (gradient != null) {
      fill.shader = gradient!.createShader(rect);
    } else {
      fill.color = fillColor;
    }
    canvas.drawArc(rect, _start, _sweep * fraction, false, fill);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.fraction != fraction ||
      old.trackColor != trackColor ||
      old.fillColor != fillColor ||
      old.gradient != gradient ||
      old.thickness != thickness;
}
