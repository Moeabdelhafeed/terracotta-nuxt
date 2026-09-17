import 'package:flutter/material.dart';

import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'chart_zoom_pan.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show MarimekkoColumn, MarimekkoSegment;
export 'chart_models.dart' show ChartStyle;

/// Marimekko / Mosaic chart — variable-width stacked bars. Each
/// column's width is proportional to its `total`; each segment's
/// height is proportional to its share within the column. Common
/// for market share × segment, or revenue mix × region.
///
/// ```dart
/// GlobalMarimekko(
///   columns: [
///     MarimekkoColumn(label: 'NA', segments: [
///       MarimekkoSegment(label: 'Pro', value: 60),
///       MarimekkoSegment(label: 'Free', value: 40),
///     ]),
///     ...
///   ],
/// )
/// ```
class GlobalMarimekko extends StatelessWidget {
  const GlobalMarimekko({
    required this.columns,
    this.style = ChartStyle.standard,
    this.cellPadding = 1.5,
    this.cellRadius = 2,
    this.showColumnLabels = true,
    this.showSegmentLabels = true,
    this.minLabelArea = 600,
    this.valueFormatter,
    super.key,
  });

  final List<MarimekkoColumn> columns;
  final ChartStyle style;

  /// Gap between cells in dp.
  final double cellPadding;
  final double cellRadius;

  /// Show column labels along the bottom.
  final bool showColumnLabels;

  /// Show segment value labels inside each cell when there's room.
  final bool showSegmentLabels;

  /// Skip painting segment labels for cells smaller than this
  /// minimum area (px²).
  final double minLabelArea;

  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (columns.isEmpty) return const SizedBox.shrink();

    // Resolve segment colors — first column's segment list determines
    // the canonical legend; each segment label gets the same color
    // across all columns.
    final segLabels = <String>[];
    for (final col in columns) {
      for (final seg in col.segments) {
        if (!segLabels.contains(seg.label)) segLabels.add(seg.label);
      }
    }
    final palette = resolveSeriesColors(context, style, segLabels.length);
    final segColorByLabel = <String, Color>{
      for (var i = 0; i < segLabels.length; i++) segLabels[i]: palette[i],
    };
    // Honor per-segment color overrides — last one wins per label.
    for (final col in columns) {
      for (final seg in col.segments) {
        if (seg.color != null) segColorByLabel[seg.label] = seg.color!;
      }
    }

    final theme = Theme.of(context);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);

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
                  return CustomPaintTooltipOverlay(
                    hitTest: (pos, size) =>
                        _hitTest(pos, size, segColorByLabel, fmt),
                    builder: style.tooltipBuilder ?? defaultTooltipBuilder,
                    child: CustomPaint(
                      painter: _MarimekkoPainter(
                        columns: columns,
                        colorByLabel: segColorByLabel,
                        cellPadding: cellPadding,
                        cellRadius: cellRadius,
                        showColumnLabels: showColumnLabels,
                        showSegmentLabels: showSegmentLabels,
                        minLabelArea: minLabelArea,
                        axisStyle: axisStyle,
                        labelStyle:
                            theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ) ??
                            const TextStyle(),
                        valueFormatter: fmt,
                        progress: t,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
      style,
    );
  }

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    Map<String, Color> colorByLabel,
    String Function(double) fmt,
  ) {
    if (pos.dx < 0 || pos.dx > size.width) return const [];
    final layout = _MarimekkoLayout(
      columns: columns,
      size: size,
      showColumnLabels: showColumnLabels,
      cellPadding: cellPadding,
    );
    if (!layout.plotRect.contains(pos)) return const [];
    final colIdx = layout.columnAt(pos.dx);
    if (colIdx < 0) return const [];
    final col = columns[colIdx];
    final segIdx = layout.segmentAt(colIdx, pos.dy);
    if (segIdx < 0) return const [];
    final seg = col.segments[segIdx];
    final share = col.total == 0 ? 0 : (seg.value / col.total * 100);
    return [
      TooltipEntry(
        label: '${col.label} · ${seg.label}',
        value: '${fmt(seg.value)} (${share.toStringAsFixed(0)}%)',
        color: colorByLabel[seg.label] ?? Colors.grey,
      ),
    ];
  }
}

class _MarimekkoLayout {
  _MarimekkoLayout({
    required this.columns,
    required this.size,
    required this.showColumnLabels,
    required this.cellPadding,
  }) {
    final bottomPad = showColumnLabels ? 22.0 : 4.0;
    plotRect = Rect.fromLTRB(0, 0, size.width, size.height - bottomPad);
    grandTotal = columns.fold<double>(0, (s, c) => s + c.total);
  }

  final List<MarimekkoColumn> columns;
  final Size size;
  final bool showColumnLabels;
  final double cellPadding;
  late final Rect plotRect;
  late final double grandTotal;

  /// Returns column index at the given x, or -1 if outside.
  int columnAt(double x) {
    if (grandTotal <= 0) return -1;
    var cursor = plotRect.left;
    for (var i = 0; i < columns.length; i++) {
      final w = columns[i].total / grandTotal * plotRect.width;
      if (x >= cursor && x <= cursor + w) return i;
      cursor += w;
    }
    return -1;
  }

  /// Returns segment index within the column at the given y, or -1.
  int segmentAt(int colIdx, double y) {
    final col = columns[colIdx];
    if (col.total <= 0) return -1;
    var cursor = plotRect.top;
    for (var i = 0; i < col.segments.length; i++) {
      final h = col.segments[i].value / col.total * plotRect.height;
      if (y >= cursor && y <= cursor + h) return i;
      cursor += h;
    }
    return -1;
  }
}

class _MarimekkoPainter extends CustomPainter {
  _MarimekkoPainter({
    required this.columns,
    required this.colorByLabel,
    required this.cellPadding,
    required this.cellRadius,
    required this.showColumnLabels,
    required this.showSegmentLabels,
    required this.minLabelArea,
    required this.axisStyle,
    required this.labelStyle,
    required this.valueFormatter,
    required this.progress,
  });

  final List<MarimekkoColumn> columns;
  final Map<String, Color> colorByLabel;
  final double cellPadding;
  final double cellRadius;
  final bool showColumnLabels;
  final bool showSegmentLabels;
  final double minLabelArea;
  final TextStyle axisStyle;
  final TextStyle labelStyle;
  final String Function(double) valueFormatter;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final layout = _MarimekkoLayout(
      columns: columns,
      size: size,
      showColumnLabels: showColumnLabels,
      cellPadding: cellPadding,
    );
    final plot = layout.plotRect;
    if (layout.grandTotal <= 0) return;
    if (plot.width <= 0 || plot.height <= 0) return;

    var cursorX = plot.left;
    for (final col in columns) {
      final colW = col.total / layout.grandTotal * plot.width;
      if (col.total <= 0) {
        cursorX += colW;
        continue;
      }
      var cursorY = plot.top;
      for (final seg in col.segments) {
        final segH = seg.value / col.total * plot.height;
        final color = colorByLabel[seg.label] ?? Colors.grey;
        final rect = Rect.fromLTRB(
          cursorX + cellPadding / 2,
          cursorY + cellPadding / 2,
          cursorX + colW - cellPadding / 2,
          cursorY + segH - cellPadding / 2,
        );
        if (rect.width > 0 && rect.height > 0) {
          // Animate scale from cell center.
          final cx = rect.center;
          final scaledW = rect.width * progress;
          final scaledH = rect.height * progress;
          final animRect = Rect.fromCenter(
            center: cx,
            width: scaledW,
            height: scaledH,
          );
          final paint = Paint();
          if (seg.gradient != null) {
            paint.shader = seg.gradient!.createShader(animRect);
          } else {
            paint.color = color.withValues(alpha: color.a * progress);
          }
          canvas.drawRRect(
            RRect.fromRectAndRadius(animRect, Radius.circular(cellRadius)),
            paint,
          );

          if (showSegmentLabels &&
              progress > 0.4 &&
              animRect.width * animRect.height > minLabelArea) {
            final text =
                '${seg.label}\n${valueFormatter(seg.value * progress)}';
            final fadeRaw = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
            final fade = Curves.easeOutCubic.transform(fadeRaw);
            final tp = TextPainter(
              text: TextSpan(
                text: text,
                style: labelStyle.copyWith(
                  color: labelStyle.color?.withValues(alpha: fade),
                ),
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
              maxLines: 2,
              ellipsis: '…',
            )..layout(maxWidth: animRect.width - 8);
            if (tp.height < animRect.height - 6) {
              tp.paint(
                canvas,
                Offset(
                  animRect.left + (animRect.width - tp.width) / 2,
                  animRect.top + (animRect.height - tp.height) / 2,
                ),
              );
            }
          }
        }
        cursorY += segH;
      }
      if (showColumnLabels) {
        final tp = TextPainter(
          text: TextSpan(text: col.label, style: axisStyle),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          ellipsis: '…',
        )..layout(maxWidth: colW);
        tp.paint(
          canvas,
          Offset(
            cursorX + (colW - tp.width) / 2,
            plot.bottom + 4,
          ),
        );
      }
      cursorX += colW;
    }
  }

  @override
  bool shouldRepaint(covariant _MarimekkoPainter old) =>
      old.progress != progress ||
      old.columns != columns ||
      old.colorByLabel != colorByLabel ||
      old.cellPadding != cellPadding ||
      old.cellRadius != cellRadius ||
      old.showColumnLabels != showColumnLabels ||
      old.showSegmentLabels != showSegmentLabels ||
      old.minLabelArea != minLabelArea;
}
