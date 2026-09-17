import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show DumbbellDatum;
export 'chart_models.dart' show ChartStyle, DumbbellAnimation;

/// Dumbbell chart — paired dots connected by a bar, one row per
/// category. Reads the change between two states (before/after,
/// min/max, group A vs group B). Strong alternative to grouped
/// bars when the focus is the gap, not the absolute heights.
///
/// ```dart
/// GlobalDumbbell(
///   data: const [
///     DumbbellDatum(label: 'Revenue', start: 100, end: 130),
///     DumbbellDatum(label: 'Costs',   start: 70,  end: 65),
///   ],
///   startLabel: 'Q1', endLabel: 'Q2',
/// )
/// ```
class GlobalDumbbell extends StatelessWidget {
  const GlobalDumbbell({
    required this.data,
    this.style = ChartStyle.standard,
    this.animation = DumbbellAnimation.grow,
    this.startLabel = 'Start',
    this.endLabel = 'End',
    this.startColor,
    this.endColor,
    this.barWidth = 6.0,
    this.dotRadius = 7.0,
    this.showValues = true,
    this.showLegend = true,
    this.colorByDirection = false,
    this.upColor,
    this.downColor,
    this.flatColor,
    this.valueFormatter,
    super.key,
  });

  final List<DumbbellDatum> data;
  final ChartStyle style;
  final DumbbellAnimation animation;
  final String startLabel;
  final String endLabel;

  /// Color for the start dots (palette `tertiary` if null).
  final Color? startColor;

  /// Color for the end dots (palette `primary` if null).
  final Color? endColor;

  final double barWidth;
  final double dotRadius;
  final bool showValues;
  final bool showLegend;

  /// Tint the connector bar by `end − start` sign instead of using
  /// a gradient between [startColor] and [endColor].
  final bool colorByDirection;
  final Color? upColor;
  final Color? downColor;
  final Color? flatColor;

  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final gridColor = resolveGridColor(context, style);
    final palette = resolveSeriesColors(context, style, 2);
    final sCol = startColor ?? palette[1];
    final eCol = endColor ?? palette[0];
    final upCol = upColor ?? context.statusColors.success;
    final downCol = downColor ?? context.statusColors.error;
    final flatCol = flatColor ?? context.textColors.secondary;

    return wrapZoomPan(
      Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: style.minHeight,
            maxWidth: resolveChartMaxWidth(context, style),
          ),
          child: AspectRatio(
            aspectRatio: style.aspectRatio,
            child: Padding(
              padding: style.padding,
              child: Column(
                children: [
                  Expanded(
                    child: CustomPaintTooltipOverlay(
                      hitTest: (pos, size) => _hitTest(
                        pos,
                        size,
                        sCol,
                        eCol,
                        upCol,
                        downCol,
                        flatCol,
                        fmt,
                      ),
                      builder: style.tooltipBuilder ?? defaultTooltipBuilder,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: style.enableAnimation ? 0.0 : 1.0,
                          end: 1.0,
                        ),
                        duration: style.enableAnimation
                            ? style.effectiveAnimationDuration
                            : Duration.zero,
                        curve: style.effectiveAnimationCurve,
                        builder: (context, t, _) {
                          return CustomPaint(
                            painter: _DumbbellPainter(
                              data: data,
                              startColor: sCol,
                              endColor: eCol,
                              upColor: upCol,
                              downColor: downCol,
                              flatColor: flatCol,
                              colorByDirection: colorByDirection,
                              barWidth: barWidth,
                              dotRadius: dotRadius,
                              showValues: showValues,
                              gridColor: gridColor,
                              axisStyle: axisStyle,
                              valueFormatter: fmt,
                              animation: animation,
                              progress: t,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (showLegend) ...[
                    const SizedBox(height: 8),
                    _DumbbellLegend(
                      startLabel: startLabel,
                      endLabel: endLabel,
                      startColor: sCol,
                      endColor: eCol,
                      textStyle: axisStyle,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      style,
    );
  }

  Color _directionColor(double delta, Color up, Color down, Color flat) {
    if (delta > 0) return up;
    if (delta < 0) return down;
    return flat;
  }

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    Color sCol,
    Color eCol,
    Color upCol,
    Color downCol,
    Color flatCol,
    String Function(double) fmt,
  ) {
    final layout = _DumbbellLayout.compute(size: size, data: data);
    if (layout == null) return const [];
    var bestI = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < data.length; i++) {
      final ds = (layout.startDots[i] - pos).distance;
      final de = (layout.endDots[i] - pos).distance;
      final d = ds < de ? ds : de;
      // Also test bar midpoint.
      final mid = Offset(
        (layout.startDots[i].dx + layout.endDots[i].dx) / 2,
        layout.startDots[i].dy,
      );
      final dm = (mid - pos).distance;
      final best = [d, dm].reduce((a, b) => a < b ? a : b);
      if (best < bestDist) {
        bestDist = best;
        bestI = i;
      }
    }
    if (bestI < 0 || bestDist > 28) return const [];
    final d = data[bestI];
    final delta = d.delta;
    final sign = delta > 0 ? '+' : (delta < 0 ? '−' : '');
    final barCol = colorByDirection
        ? _directionColor(delta, upCol, downCol, flatCol)
        : eCol;
    return [
      TooltipEntry(
        label: d.label,
        value:
            '$startLabel ${fmt(d.start)} → $endLabel ${fmt(d.end)} '
            '($sign${fmt(delta.abs())})',
        color: barCol,
        icon: d.icon,
        iconAsset: d.iconAsset,
        iconWidget: d.iconWidget,
      ),
    ];
  }
}

class _DumbbellLayout {
  _DumbbellLayout({
    required this.startDots,
    required this.endDots,
    required this.leftPad,
    required this.rightPad,
    required this.size,
  });

  final List<Offset> startDots;
  final List<Offset> endDots;
  final double leftPad;
  final double rightPad;
  final Size size;

  static _DumbbellLayout? compute({
    required Size size,
    required List<DumbbellDatum> data,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (data.isEmpty) return null;

    var lo = data.first.start;
    var hi = data.first.start;
    for (final d in data) {
      if (d.start < lo) lo = d.start;
      if (d.start > hi) hi = d.start;
      if (d.end < lo) lo = d.end;
      if (d.end > hi) hi = d.end;
    }
    final pad = (hi - lo) * 0.1;
    lo -= pad;
    hi += pad;
    if (hi == lo) hi = lo + 1;

    const leftPad = 100.0;
    const rightPad = 60.0;
    const topPad = 12.0;
    const bottomPad = 12.0;
    final usableW = size.width - leftPad - rightPad;
    final usableH = size.height - topPad - bottomPad;
    final rowH = usableH / data.length;
    final starts = <Offset>[];
    final ends = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final y = topPad + rowH * (i + 0.5);
      final tStart = (data[i].start - lo) / (hi - lo);
      final tEnd = (data[i].end - lo) / (hi - lo);
      starts.add(Offset(leftPad + usableW * tStart, y));
      ends.add(Offset(leftPad + usableW * tEnd, y));
    }
    return _DumbbellLayout(
      startDots: starts,
      endDots: ends,
      leftPad: leftPad,
      rightPad: rightPad,
      size: size,
    );
  }
}

class _DumbbellPainter extends CustomPainter {
  _DumbbellPainter({
    required this.data,
    required this.startColor,
    required this.endColor,
    required this.upColor,
    required this.downColor,
    required this.flatColor,
    required this.colorByDirection,
    required this.barWidth,
    required this.dotRadius,
    required this.showValues,
    required this.gridColor,
    required this.axisStyle,
    required this.valueFormatter,
    required this.animation,
    required this.progress,
  });

  final List<DumbbellDatum> data;
  final Color startColor;
  final Color endColor;
  final Color upColor;
  final Color downColor;
  final Color flatColor;
  final bool colorByDirection;
  final double barWidth;
  final double dotRadius;
  final bool showValues;
  final Color gridColor;
  final TextStyle axisStyle;
  final String Function(double) valueFormatter;
  final DumbbellAnimation animation;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _DumbbellLayout.compute(size: size, data: data);
    if (layout == null) return;

    // Left baseline guide.
    final guidePaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(layout.leftPad, 0),
      Offset(layout.leftPad, size.height),
      guidePaint,
    );

    for (var i = 0; i < data.length; i++) {
      final s = layout.startDots[i];
      final e = layout.endDots[i];
      final delta = data[i].end - data[i].start;
      final dotS = data[i].startColor ?? startColor;
      final dotE = data[i].endColor ?? endColor;

      // Per-row staggered progress.
      final rowDelay = i / data.length * 0.2;
      final rowT = ((progress - rowDelay) / (1 - rowDelay)).clamp(0.0, 1.0);

      // Animation params.
      Offset animEnd;
      var rowOffset = Offset.zero;
      var opacity = 1.0;
      var dotScale = 1.0;
      switch (animation) {
        case DumbbellAnimation.grow:
          animEnd = Offset.lerp(s, e, rowT)!;
          dotScale = (rowT - 0.85).clamp(0.0, 0.15) / 0.15;
        case DumbbellAnimation.fade:
          animEnd = e;
          opacity = progress;
        case DumbbellAnimation.slide:
          animEnd = e;
          rowOffset = Offset(-40 * (1 - rowT), 0);
          opacity = rowT;
      }

      final sShifted = s + rowOffset;
      final eShifted = animEnd + rowOffset;

      // Connector bar.
      final barCol = colorByDirection
          ? () {
              if (delta > 0) return upColor;
              if (delta < 0) return downColor;
              return flatColor;
            }()
          : null;
      final r = Rect.fromPoints(
        Offset(sShifted.dx, sShifted.dy - barWidth / 2),
        Offset(eShifted.dx, sShifted.dy + barWidth / 2),
      );
      final rr = RRect.fromRectAndRadius(r, Radius.circular(barWidth / 2));

      final barPaint = Paint();
      if (barCol != null) {
        barPaint.color = barCol.withValues(alpha: 0.6 * opacity);
      } else {
        barPaint.shader = LinearGradient(
          colors: [
            dotS.withValues(alpha: 0.6 * opacity),
            dotE.withValues(alpha: 0.6 * opacity),
          ],
        ).createShader(r);
      }
      if (r.width > 0 && r.height > 0) {
        canvas.drawRRect(rr, barPaint);
      }

      // Dots.
      final dr = dotRadius * dotScale;
      if (dr > 0.5) {
        canvas.drawCircle(
          sShifted,
          dr,
          Paint()..color = dotS.withValues(alpha: opacity),
        );
        canvas.drawCircle(
          eShifted,
          dr,
          Paint()..color = dotE.withValues(alpha: opacity),
        );
        canvas.drawCircle(
          sShifted,
          dr,
          Paint()
            ..color = Colors.white.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
        canvas.drawCircle(
          eShifted,
          dr,
          Paint()
            ..color = Colors.white.withValues(alpha: opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }

      // Labels.
      if (progress < 0.4) continue;
      final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      final fade = Curves.easeOutCubic.transform(fadeRaw);
      final lblStyle = axisStyle.copyWith(
        color: axisStyle.color?.withValues(alpha: fade),
      );
      final boldStyle = lblStyle.copyWith(fontWeight: FontWeight.w700);

      // Category label on the left.
      final labelTp = TextPainter(
        text: TextSpan(text: data[i].label, style: lblStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: layout.leftPad - 6);
      labelTp.paint(
        canvas,
        Offset(layout.leftPad - 6 - labelTp.width, s.dy - labelTp.height / 2),
      );
      // Value labels at each dot — outer side based on direction.
      if (showValues) {
        final left = s.dx <= e.dx ? s : e;
        final right = s.dx <= e.dx ? e : s;
        final leftV = data[i].start <= data[i].end
            ? data[i].start
            : data[i].end;
        final rightV = data[i].start <= data[i].end
            ? data[i].end
            : data[i].start;

        final ltp = TextPainter(
          text: TextSpan(
            text: valueFormatter(leftV * progress),
            style: lblStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        ltp.paint(
          canvas,
          Offset(left.dx - dotRadius - 4 - ltp.width, left.dy - ltp.height / 2),
        );

        final rtp = TextPainter(
          text: TextSpan(
            text: valueFormatter(rightV * progress),
            style: boldStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        rtp.paint(
          canvas,
          Offset(right.dx + dotRadius + 4, right.dy - rtp.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DumbbellPainter old) =>
      old.progress != progress ||
      old.data != data ||
      old.animation != animation ||
      old.startColor != startColor ||
      old.endColor != endColor;
}

class _DumbbellLegend extends StatelessWidget {
  const _DumbbellLegend({
    required this.startLabel,
    required this.endLabel,
    required this.startColor,
    required this.endColor,
    required this.textStyle,
  });

  final String startLabel;
  final String endLabel;
  final Color startColor;
  final Color endColor;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, Color color) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: textStyle),
      ],
    );

    return Wrap(
      spacing: 16,
      runSpacing: 6,
      alignment: WrapAlignment.center,
      children: [
        chip(startLabel, startColor),
        chip(endLabel, endColor),
      ],
    );
  }
}
