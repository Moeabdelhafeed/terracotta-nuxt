import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';

export 'chart_data.dart' show MatrixCell, ChartPoint;
export 'chart_models.dart' show ChartStyle, ComparisonMatrixAnimation;

/// Comparison matrix — small-multiples grid of mini sparklines,
/// one cell per (row × col). Rows could be metrics; cols could be
/// entities (or vice versa). Reads dozens of trends in one image.
///
/// ```dart
/// GlobalComparisonMatrix(
///   rows: ['Revenue', 'Costs'],
///   cols: ['NA', 'EU', 'APAC'],
///   cells: [
///     MatrixCell(row: 'Revenue', col: 'NA', sparkline: [...], value: 320),
///     ...
///   ],
/// )
/// ```
class GlobalComparisonMatrix extends StatelessWidget {
  const GlobalComparisonMatrix({
    required this.rows,
    required this.cols,
    required this.cells,
    this.style = ChartStyle.standard,
    this.animation = ComparisonMatrixAnimation.draw,
    this.cellHeight = 56,
    this.showValue = true,
    this.showDelta = true,
    this.showHeaders = true,
    this.upColor,
    this.downColor,
    this.flatColor,
    this.valueFormatter,
    super.key,
  });

  final List<String> rows;
  final List<String> cols;
  final List<MatrixCell> cells;
  final ChartStyle style;
  final ComparisonMatrixAnimation animation;
  final double cellHeight;
  final bool showValue;
  final bool showDelta;
  final bool showHeaders;
  final Color? upColor;
  final Color? downColor;
  final Color? flatColor;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty || cols.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, 1);
    final base = palette.first;
    final fg = context.textColors.primary;
    final secondary = context.textColors.secondary;
    final outline = context.backgroundColors.outlineVariant;
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final upCol = upColor ?? context.statusColors.success;
    final downCol = downColor ?? context.statusColors.error;
    final flatCol = flatColor ?? secondary;

    final cellByKey = <String, MatrixCell>{
      for (final c in cells) '${c.row}|${c.col}': c,
    };

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: style.minHeight),
      child: Padding(
        padding: style.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHeaders)
              Row(
                children: [
                  const SizedBox(width: 100),
                  for (final col in cols)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          col,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            for (var ri = 0; ri < rows.length; ri++)
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: outline, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          rows[ri],
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    for (var ci = 0; ci < cols.length; ci++)
                      Expanded(
                        child: _MatrixCellTile(
                          cell: cellByKey['${rows[ri]}|${cols[ci]}'],
                          base: base,
                          fg: fg,
                          secondary: secondary,
                          upColor: upCol,
                          downColor: downCol,
                          flatColor: flatCol,
                          height: cellHeight,
                          showValue: showValue,
                          showDelta: showDelta,
                          rowIdx: ri,
                          colIdx: ci,
                          totalRows: rows.length,
                          totalCols: cols.length,
                          animation: animation,
                          style: style,
                          formatter: fmt,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MatrixCellTile extends StatelessWidget {
  const _MatrixCellTile({
    required this.cell,
    required this.base,
    required this.fg,
    required this.secondary,
    required this.upColor,
    required this.downColor,
    required this.flatColor,
    required this.height,
    required this.showValue,
    required this.showDelta,
    required this.rowIdx,
    required this.colIdx,
    required this.totalRows,
    required this.totalCols,
    required this.animation,
    required this.style,
    required this.formatter,
  });

  final MatrixCell? cell;
  final Color base;
  final Color fg;
  final Color secondary;
  final Color upColor;
  final Color downColor;
  final Color flatColor;
  final double height;
  final bool showValue;
  final bool showDelta;
  final int rowIdx;
  final int colIdx;
  final int totalRows;
  final int totalCols;
  final ComparisonMatrixAnimation animation;
  final ChartStyle style;
  final String Function(double) formatter;

  @override
  Widget build(BuildContext context) {
    if (cell == null) return SizedBox(height: height);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: style.enableAnimation ? 0.0 : 1.0, end: 1.0),
      duration: style.enableAnimation
          ? style.effectiveAnimationDuration
          : Duration.zero,
      curve: style.effectiveAnimationCurve,
      builder: (context, t, _) {
        // Animation phasing per cell.
        double drawT;
        double opacity;
        switch (animation) {
          case ComparisonMatrixAnimation.draw:
            final delay = rowIdx / totalRows * 0.25;
            final cellT = ((t - delay) / (1 - delay)).clamp(0.0, 1.0);
            drawT = cellT;
            opacity = 1.0;
          case ComparisonMatrixAnimation.fade:
            drawT = 1.0;
            opacity = t;
          case ComparisonMatrixAnimation.cascade:
            final cellRank =
                (rowIdx * totalCols + colIdx) / (totalRows * totalCols);
            final delay = cellRank * 0.7;
            final cellT = ((t - delay) / 0.3).clamp(0.0, 1.0);
            drawT = cellT;
            opacity = cellT;
        }

        final delta = cell!.delta;
        Color trendColor;
        IconData trendIcon;
        if (delta == null || delta == 0) {
          trendColor = flatColor;
          trendIcon = Icons.remove_rounded;
        } else if (delta > 0) {
          trendColor = upColor;
          trendIcon = Icons.arrow_upward_rounded;
        } else {
          trendColor = downColor;
          trendIcon = Icons.arrow_downward_rounded;
        }

        final accent = cell!.color ?? base;

        return SizedBox(
          height: height,
          child: Opacity(
            opacity: opacity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _SparkPainter(
                        points: cell!.sparkline,
                        color: accent,
                        progress: drawT,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (showValue && cell!.value != null) ...[
                          Text(
                            formatter(cell!.value!),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: fg,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (showDelta && delta != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: trendColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(trendIcon, size: 9, color: trendColor),
                                const SizedBox(width: 1),
                                Text(
                                  formatter(delta.abs()),
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: trendColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.points,
    required this.color,
    required this.progress,
  });

  final List<ChartPoint> points;
  final Color color;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width <= 0 || size.height <= 0) return;
    final sorted = [...points]..sort((a, b) => a.x.compareTo(b.x));
    var xLo = sorted.first.x;
    var xHi = sorted.last.x;
    if (xHi == xLo) xHi = xLo + 1;
    var yLo = sorted.first.y;
    var yHi = sorted.first.y;
    for (final p in sorted) {
      if (p.y < yLo) yLo = p.y;
      if (p.y > yHi) yHi = p.y;
    }
    if (yHi == yLo) yHi = yLo + 1;
    const padX = 2.0;
    final padY = size.height * 0.4;
    final w = size.width - padX * 2;
    final availH = size.height - padY - 4;
    final baselineY = size.height - 2;

    Offset proj(ChartPoint p) {
      final tx = (p.x - xLo) / (xHi - xLo);
      final ty = (p.y - yLo) / (yHi - yLo);
      return Offset(padX + tx * w, padY + availH - ty * availH);
    }

    final cutoffX = padX + w * progress;
    final fillPath = Path();
    final strokePath = Path();
    var first = true;
    for (var i = 0; i < sorted.length; i++) {
      final pos = proj(sorted[i]);
      if (pos.dx > cutoffX) {
        if (i > 0) {
          final prev = proj(sorted[i - 1]);
          final t = (cutoffX - prev.dx) / (pos.dx - prev.dx);
          final y = prev.dy + (pos.dy - prev.dy) * t;
          strokePath.lineTo(cutoffX, y);
          fillPath.lineTo(cutoffX, y);
        }
        break;
      }
      if (first) {
        strokePath.moveTo(pos.dx, pos.dy);
        fillPath.moveTo(pos.dx, baselineY);
        fillPath.lineTo(pos.dx, pos.dy);
        first = false;
      } else {
        final prev = proj(sorted[i - 1]);
        final cx = (prev.dx + pos.dx) / 2;
        strokePath.cubicTo(cx, prev.dy, cx, pos.dy, pos.dx, pos.dy);
        fillPath.cubicTo(cx, prev.dy, cx, pos.dy, pos.dx, pos.dy);
      }
    }
    fillPath.lineTo(cutoffX, baselineY);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()..color = color.withValues(alpha: 0.16),
    );
    canvas.drawPath(
      strokePath,
      Paint()
        ..color = color.withValues(alpha: 0.95)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter old) =>
      old.progress != progress || old.points != points;
}
