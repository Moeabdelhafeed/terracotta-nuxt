import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart' as g;

import '../../../core/extensions/theme_colors_extension.dart';
import 'chart_internals.dart';
import 'chart_models.dart';

export 'chart_models.dart' show ChartStyle, LineChartAnimation;

/// Compact, axis-less line chart for card embeds + dashboard cells.
/// Shows trend at a glance — no grid, no tooltip, no legend.
///
/// ```dart
/// GlobalSparkline(values: [12, 15, 14, 18, 22, 19, 24], filled: true)
/// ```
class GlobalSparkline extends StatelessWidget {
  const GlobalSparkline({
    required this.values,
    this.color,
    this.fillColor,
    this.lineGradient,
    this.fillGradient,
    this.filled = true,
    this.strokeWidth = 2,
    this.height = 36,
    this.width,
    this.maxWidth,
    this.curved = true,
    this.animation = LineChartAnimation.growUp,
    this.animationDuration,
    this.animationCurve,
    super.key,
  });

  /// Y-values; x is implicit (0..n-1).
  final List<double> values;

  final Color? color;
  final Color? fillColor;

  /// Apply a [Gradient] to the line stroke. Wins over [color] for
  /// the line. graphic forbids both color + gradient on a mark, so
  /// when set, the line uses gradient encoding only.
  final Gradient? lineGradient;

  /// Apply a [Gradient] to the area fill (when [filled] is true).
  /// Independent of [lineGradient].
  final Gradient? fillGradient;

  final bool filled;
  final double strokeWidth;
  final double height;

  /// Fixed width — overrides [maxWidth].
  final double? width;

  /// Max width when [width] is null. Falls back to a bucket-aware
  /// default (compact: full, medium: 320, expanded: 360, large: 400,
  /// extraLarge: 440) so sparklines don't stretch across wide screens.
  final double? maxWidth;

  final bool curved;

  /// Entry animation preset. See [LineChartAnimation].
  final LineChartAnimation animation;

  /// Override animation duration. Falls back to 700ms.
  final Duration? animationDuration;

  /// Override animation curve. Falls back to `Curves.easeOutCubic`.
  final Curve? animationCurve;

  /// Map [LineChartAnimation] to graphic's native [g.MarkEntrance].
  /// `drawIn` returns null — that mode disables native entrance and
  /// uses a Flutter-side `ClipRect` reveal instead.
  Set<g.MarkEntrance>? get _markEntrance => switch (animation) {
    LineChartAnimation.growUp => const {g.MarkEntrance.y},
    LineChartAnimation.slideIn => const {g.MarkEntrance.x},
    LineChartAnimation.fade => const {g.MarkEntrance.opacity},
    LineChartAnimation.scale => const {g.MarkEntrance.size},
    LineChartAnimation.drawIn => null,
  };

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height, width: width);

    final lineColor = color ?? context.primaryColors.primary;
    final fill = fillColor ?? lineColor.withValues(alpha: 0.18);
    final duration = animationDuration ?? const Duration(milliseconds: 700);
    final curve = animationCurve ?? Curves.easeOutCubic;

    final data = [
      for (var i = 0; i < values.length; i++) {'x': i, 'y': values[i]},
    ];

    final cap = width ?? resolveSparklineMaxWidth(context, maxWidth);
    final entrance = _markEntrance;
    final useDrawIn =
        animation == LineChartAnimation.drawIn && duration > Duration.zero;

    final chart = EntranceGate(
      enabled: duration > Duration.zero,
      duration: duration,
      builder: (playEntrance) => IgnorePointer(
        ignoring: playEntrance,
        child: g.Chart<Map<String, dynamic>>(
          data: data,
          padding: (_) => EdgeInsets.zero,
          variables: {
            'x': g.Variable(accessor: (m) => (m['x'] as num).toDouble()),
            'y': g.Variable(accessor: (m) => (m['y'] as num).toDouble()),
          },
          marks: [
            if (filled)
              g.AreaMark(
                shape: g.ShapeEncode(value: g.BasicAreaShape(smooth: curved)),
                color: fillGradient != null ? null : g.ColorEncode(value: fill),
                gradient: fillGradient != null
                    ? g.GradientEncode(value: fillGradient!)
                    : null,
                transition: playEntrance && entrance != null
                    ? g.Transition(duration: duration, curve: curve)
                    : null,
                entrance: playEntrance ? entrance : null,
              ),
            g.LineMark(
              shape: g.ShapeEncode(value: g.BasicLineShape(smooth: curved)),
              color: lineGradient != null
                  ? null
                  : g.ColorEncode(value: lineColor),
              gradient: lineGradient != null
                  ? g.GradientEncode(value: lineGradient!)
                  : null,
              size: g.SizeEncode(value: strokeWidth),
              transition: playEntrance && entrance != null
                  ? g.Transition(duration: duration, curve: curve)
                  : null,
              entrance: playEntrance ? entrance : null,
            ),
          ],
        ),
      ),
    );

    final maybeDrawIn = useDrawIn
        ? DrawInRevealer(duration: duration, curve: curve, child: chart)
        : chart;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: cap),
        child: SizedBox(
          width: width,
          height: height,
          child: maybeDrawIn,
        ),
      ),
    );
  }
}
