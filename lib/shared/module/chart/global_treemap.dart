import 'package:flutter/material.dart';

import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show TreemapNode;
export 'chart_models.dart' show ChartStyle;

/// Treemap — proportional rectangle layout. Each leaf's area is
/// proportional to its `value`. Supports flat lists and nested
/// hierarchies (folders + files, market segment + product, etc.).
///
/// Layout uses a row-major slice-and-dice algorithm — fast, stable,
/// and produces clean rectangles for typical dashboard sizes.
///
/// ```dart
/// GlobalTreemap(
///   nodes: [
///     TreemapNode(label: 'A', value: 40),
///     TreemapNode(label: 'B', value: 25),
///     TreemapNode(label: 'C', value: 15),
///     TreemapNode(label: 'D', value: 10),
///     TreemapNode(label: 'E', value: 10),
///   ],
/// )
/// ```
class GlobalTreemap extends StatelessWidget {
  const GlobalTreemap({
    required this.nodes,
    this.style = ChartStyle.standard,
    this.cellPadding = 2,
    this.cellRadius = 4,
    this.showLabels = true,
    this.showValues = true,
    this.minLabelArea = 60,
    this.enableTileEffects = false,
    this.verticalLabelThreshold = 0,
    this.valueFormatter,
    super.key,
  });

  final List<TreemapNode> nodes;
  final ChartStyle style;

  /// Gap between rectangles in dp.
  final double cellPadding;
  final double cellRadius;

  final bool showLabels;
  final bool showValues;

  /// Skip painting labels for rectangles smaller than this minimum
  /// area (px²) — avoids cluttered labels on tiny tiles.
  final double minLabelArea;

  /// Drop shadow + thin self-edge stroke on each tile for a tactile
  /// elevated look. Off by default (clean flat).
  final bool enableTileEffects;

  /// Behavior for narrow tiles whose label would overflow
  /// horizontally:
  /// - `0` (default) → **auto**: rotate label 90° when the
  ///   intrinsic text width exceeds the tile's available width AND
  ///   the tile is taller than wide enough to fit it.
  /// - `> 0` → **fixed threshold**: rotate when tile's width is
  ///   narrower than this value (dp) AND it's taller than wide.
  /// - `< 0` → **never rotate** (keep horizontal, ellipsize).
  final double verticalLabelThreshold;

  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) return const SizedBox.shrink();

    final palette = resolveSeriesColors(context, style, nodes.length);
    final theme = Theme.of(context);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: style.minHeight,
          maxWidth: resolveChartMaxWidth(context, style),
        ),
        child: AspectRatio(
          aspectRatio: style.aspectRatio,
          child: Padding(
            padding: style.padding,
            child: CustomPaintTooltipOverlay(
              hitTest: (pos, size) => _hitTest(pos, size, palette, fmt),
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
                  // Apply halo + drop shadow to label/value text so
                  // it reads against any tile color or gradient.
                  // Theme-aware halo via outlinedLabelStyle helper.
                  final labelHalo =
                      (theme.textTheme.labelLarge ?? const TextStyle())
                          .copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.55),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 2,
                              ),
                            ],
                          );
                  final valueHalo =
                      (theme.textTheme.labelSmall ?? const TextStyle())
                          .copyWith(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontFeatures: const [FontFeature.tabularFigures()],
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.55),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.30),
                                blurRadius: 2,
                              ),
                            ],
                          );
                  return CustomPaint(
                    painter: _TreemapPainter(
                      nodes: nodes,
                      palette: palette,
                      cellPadding: cellPadding,
                      cellRadius: cellRadius,
                      showLabels: showLabels,
                      showValues: showValues,
                      minLabelArea: minLabelArea,
                      enableTileEffects: enableTileEffects,
                      verticalLabelThreshold: verticalLabelThreshold,
                      labelStyle: labelHalo,
                      valueStyle: valueHalo,
                      valueFormatter: fmt,
                      progress: t,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<TooltipEntry> _hitTest(
    Offset pos,
    Size size,
    List<Color> palette,
    String Function(double) fmt,
  ) {
    if (pos.dx < 0 || pos.dx > size.width) return const [];
    if (pos.dy < 0 || pos.dy > size.height) return const [];
    final layout = _treemapLayout(
      nodes,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );
    for (final tile in layout) {
      if (tile.rect.contains(pos)) {
        final palIdx = tile.colorIndex.clamp(0, palette.length - 1);
        return [
          TooltipEntry(
            label: tile.path.join(' › '),
            value: fmt(tile.value),
            color: tile.node.color ?? palette[palIdx],
          ),
        ];
      }
    }
    return const [];
  }
}

class _Tile {
  _Tile({
    required this.node,
    required this.rect,
    required this.value,
    required this.colorIndex,
    required this.path,
  });

  final TreemapNode node;
  final Rect rect;
  final double value;
  final int colorIndex;
  final List<String> path;
}

class _TreemapPainter extends CustomPainter {
  _TreemapPainter({
    required this.nodes,
    required this.palette,
    required this.cellPadding,
    required this.cellRadius,
    required this.showLabels,
    required this.showValues,
    required this.minLabelArea,
    required this.enableTileEffects,
    required this.verticalLabelThreshold,
    required this.labelStyle,
    required this.valueStyle,
    required this.valueFormatter,
    required this.progress,
  });

  final List<TreemapNode> nodes;
  final List<Color> palette;
  final double cellPadding;
  final double cellRadius;
  final bool showLabels;
  final bool showValues;
  final double minLabelArea;
  final bool enableTileEffects;
  final double verticalLabelThreshold;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final String Function(double) valueFormatter;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final layout = _treemapLayout(
      nodes,
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    for (final tile in layout) {
      final palIdx = tile.colorIndex.clamp(0, palette.length - 1);
      final color = tile.node.color ?? palette[palIdx];

      final r = Rect.fromLTRB(
        tile.rect.left + cellPadding / 2,
        tile.rect.top + cellPadding / 2,
        tile.rect.right - cellPadding / 2,
        tile.rect.bottom - cellPadding / 2,
      );
      if (r.width <= 0 || r.height <= 0) continue;

      // Animate scale from rect center.
      final cx = r.center;
      final scaledW = r.width * progress;
      final scaledH = r.height * progress;
      if (scaledW <= 0 || scaledH <= 0) continue;
      final animRect = Rect.fromCenter(
        center: cx,
        width: scaledW,
        height: scaledH,
      );

      if (enableTileEffects) {
        // Blurred drop shadow under each tile — funnel-style.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            animRect.shift(const Offset(0, 3)),
            Radius.circular(cellRadius),
          ),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.22)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(animRect, Radius.circular(cellRadius)),
        Paint()..color = color.withValues(alpha: color.a * progress),
      );

      if (enableTileEffects) {
        // Self-edge stroke — color darkened so it reads as shading
        // not a hard outline.
        final hsl = HSLColor.fromColor(color);
        final strokeColor = hsl
            .withLightness((hsl.lightness * 0.65).clamp(0.0, 1.0))
            .toColor()
            .withValues(alpha: 0.85);
        canvas.drawRRect(
          RRect.fromRectAndRadius(animRect, Radius.circular(cellRadius)),
          Paint()
            ..color = strokeColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..isAntiAlias = true,
        );
      }

      if (progress > 0.7 &&
          showLabels &&
          animRect.width * animRect.height > minLabelArea) {
        _paintTileLabel(canvas, animRect, tile);
      }
    }
  }

  void _paintTileLabel(Canvas canvas, Rect animRect, _Tile tile) {
    final fadeIn = ((progress - 0.7) / 0.3).clamp(0.0, 1.0);
    final styledLabel = labelStyle.copyWith(
      color: labelStyle.color?.withValues(alpha: fadeIn),
      shadows: [
        for (final s in (labelStyle.shadows ?? const <Shadow>[]))
          Shadow(
            color: s.color.withValues(alpha: s.color.a * fadeIn),
            offset: s.offset,
            blurRadius: s.blurRadius,
          ),
      ],
    );
    final styledValue = valueStyle.copyWith(
      color: valueStyle.color?.withValues(alpha: fadeIn),
      shadows: [
        for (final s in (valueStyle.shadows ?? const <Shadow>[]))
          Shadow(
            color: s.color.withValues(alpha: s.color.a * fadeIn),
            offset: s.offset,
            blurRadius: s.blurRadius,
          ),
      ],
    );

    // Decide vertical mode per [verticalLabelThreshold] semantics:
    //   0 → auto (rotate when text would clip + tile is tall enough)
    //   > 0 → fixed threshold (legacy)
    //   < 0 → never rotate
    final canFitVertical = animRect.height > animRect.width * 1.2;
    var useVertical = false;
    if (verticalLabelThreshold == 0 && canFitVertical) {
      // Measure intrinsic label width — if it doesn't fit
      // horizontally and rotated would fit in tile height, rotate.
      final intrinsic = TextPainter(
        text: TextSpan(text: tile.node.label, style: styledLabel),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout();
      final wouldClip = intrinsic.width > animRect.width - 12;
      final fitsRotated = intrinsic.width <= animRect.height - 12;
      useVertical = wouldClip && fitsRotated;
    } else if (verticalLabelThreshold > 0) {
      useVertical =
          animRect.width < verticalLabelThreshold &&
          animRect.height > animRect.width * 1.4;
    }

    if (useVertical) {
      final maxText = (animRect.height - 12).clamp(0.0, double.infinity);
      if (maxText <= 0) return;
      final labelTp = TextPainter(
        text: TextSpan(text: tile.node.label, style: styledLabel),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: maxText);

      // Optional value painted next to the rotated label (also
      // rotated). Stacks below the label after rotation so the
      // user reads `Label\nvalue` along the column.
      TextPainter? valueTp;
      if (showValues) {
        valueTp = TextPainter(
          text: TextSpan(
            text: valueFormatter(tile.value * progress),
            style: styledValue,
          ),
          textDirection: TextDirection.ltr,
          maxLines: 1,
        )..layout(maxWidth: maxText);
      }

      // After rotate(-π/2) the canvas y-axis points along the
      // original +X (right) and the canvas x-axis points up. To
      // stack label-then-value reading bottom→top, paint label at
      // higher (more negative) y and value below it.
      const gap = 4.0;
      final totalLen =
          labelTp.width + (valueTp != null ? gap + valueTp.width : 0);

      // After rotate(-π/2) the original text height becomes the
      // horizontal extent on the tile. If that thickness exceeds
      // the tile's width, skip — even rotated glyphs would clip
      // sideways. Tooltip-on-hover surfaces label + value.
      final rotatedThickness = valueTp == null
          ? labelTp.height
          : labelTp.height > valueTp.height
          ? labelTp.height
          : valueTp.height;
      if (totalLen > maxText || rotatedThickness > animRect.width - 4) {
        return;
      }

      canvas.save();
      canvas.translate(
        animRect.left + animRect.width / 2,
        animRect.top + animRect.height / 2,
      );
      canvas.rotate(-1.5707963);

      // Center the (label + gap + value) chain along the rotated
      // x-axis (which is the tile's vertical direction).
      var cursor = -totalLen / 2;
      labelTp.paint(canvas, Offset(cursor, -labelTp.height / 2));
      cursor += labelTp.width;
      if (valueTp != null) {
        cursor += gap;
        valueTp.paint(canvas, Offset(cursor, -valueTp.height / 2));
      }
      canvas.restore();
      return;
    }

    final maxLine = (animRect.width - 12).clamp(0.0, double.infinity);
    if (maxLine <= 0) return;

    final labelTp = TextPainter(
      text: TextSpan(text: tile.node.label, style: styledLabel),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxLine);

    if (labelTp.height >= animRect.height - 8) return;
    labelTp.paint(canvas, Offset(animRect.left + 6, animRect.top + 6));

    if (showValues) {
      final valueTp = TextPainter(
        text: TextSpan(
          text: valueFormatter(tile.value * progress),
          style: styledValue,
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: maxLine);
      if (animRect.height > labelTp.height + valueTp.height + 10) {
        valueTp.paint(
          canvas,
          Offset(
            animRect.left + 6,
            animRect.top + 6 + labelTp.height + 1,
          ),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TreemapPainter old) =>
      old.progress != progress ||
      old.nodes != nodes ||
      old.palette != palette ||
      old.cellPadding != cellPadding ||
      old.cellRadius != cellRadius ||
      old.showLabels != showLabels ||
      old.showValues != showValues ||
      old.minLabelArea != minLabelArea;
}

/// Slice-and-dice treemap layout. Sorts siblings by value descending,
/// then alternates horizontal/vertical splits per depth level.
List<_Tile> _treemapLayout(List<TreemapNode> nodes, Rect bounds) {
  final out = <_Tile>[];
  _layoutInto(nodes, bounds, 0, const [], out, 0);
  return out;
}

int _layoutInto(
  List<TreemapNode> nodes,
  Rect bounds,
  int depth,
  List<String> path,
  List<_Tile> out,
  int colorOffset,
) {
  final sorted = [...nodes]
    ..sort(
      (a, b) => b.totalValue.compareTo(a.totalValue),
    );
  final totalValue = sorted.fold<double>(0, (s, n) => s + n.totalValue);
  if (totalValue <= 0) return colorOffset;

  final isHorizontal = bounds.width >= bounds.height;
  var cursor = isHorizontal ? bounds.left : bounds.top;
  var idx = colorOffset;
  for (final node in sorted) {
    final fraction = node.totalValue / totalValue;
    final size = (isHorizontal ? bounds.width : bounds.height) * fraction;
    final rect = isHorizontal
        ? Rect.fromLTWH(cursor, bounds.top, size, bounds.height)
        : Rect.fromLTWH(bounds.left, cursor, bounds.width, size);
    cursor += size;

    final newPath = [...path, node.label];
    if (node.children.isEmpty) {
      out.add(
        _Tile(
          node: node,
          rect: rect,
          value: node.totalValue,
          colorIndex: idx,
          path: newPath,
        ),
      );
      idx++;
    } else {
      idx = _layoutInto(node.children, rect, depth + 1, newPath, out, idx);
    }
  }
  return idx;
}
