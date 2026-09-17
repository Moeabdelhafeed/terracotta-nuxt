import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show ChordFlow, ChordEntity;
export 'chart_models.dart' show ChartStyle, ChordAnimation;

/// Chord diagram — entities arranged on a ring, weighted flows
/// drawn as bezier ribbons through the center. Each flow occupies
/// a slice of its source's arc and a slice of its target's arc.
///
/// Best for showing pairwise relationships in a fixed entity set:
/// trade flows, migration matrices, music collaboration networks.
///
/// Self-flows (source == target) are skipped.
///
/// ```dart
/// GlobalChord(
///   entities: [
///     ChordEntity(id: 'us', label: 'US'),
///     ChordEntity(id: 'eu', label: 'EU'),
///     ChordEntity(id: 'cn', label: 'CN'),
///   ],
///   flows: [
///     ChordFlow(source: 'us', target: 'eu', value: 320),
///     ChordFlow(source: 'eu', target: 'cn', value: 180),
///     ChordFlow(source: 'cn', target: 'us', value: 240),
///   ],
/// )
/// ```
class GlobalChord extends StatelessWidget {
  const GlobalChord({
    required this.entities,
    required this.flows,
    this.style = ChartStyle.standard,
    this.animation = ChordAnimation.sweep,
    this.arcWidth = 14,
    this.gapAngle = 0.04,
    this.ribbonOpacity = 0.55,
    this.showLabels = true,
    this.valueFormatter,
    super.key,
  });

  final List<ChordEntity> entities;
  final List<ChordFlow> flows;
  final ChartStyle style;
  final ChordAnimation animation;
  final double arcWidth;

  /// Angular gap (radians) between adjacent entity arcs.
  final double gapAngle;

  final double ribbonOpacity;
  final bool showLabels;
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (entities.isEmpty || flows.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(context, style, entities.length);
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);
    final axisStyle = resolveAxisLabelStyle(context, style);
    final fg = context.textColors.primary;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: style.minHeight,
          maxWidth: resolveSquareChartMaxWidth(context, style),
        ),
        child: AspectRatio(
          aspectRatio: 1,
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
                  final painter = CustomPaint(
                    painter: _ChordPainter(
                      entities: entities,
                      flows: flows,
                      colors: palette,
                      arcWidth: arcWidth,
                      gapAngle: gapAngle,
                      ribbonOpacity: ribbonOpacity,
                      showLabels: showLabels,
                      axisStyle: axisStyle,
                      fg: fg,
                      animation: animation,
                      progress: t,
                    ),
                  );
                  if (animation == ChordAnimation.fade) {
                    return Opacity(opacity: t, child: painter);
                  }
                  if (animation == ChordAnimation.spin) {
                    return Transform.rotate(
                      angle: -math.pi * (1 - t),
                      child: painter,
                    );
                  }
                  return painter;
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
    final layout = _ChordLayout.compute(
      entities: entities,
      flows: flows,
      size: size,
      arcWidth: arcWidth,
      gapAngle: gapAngle,
    );
    if (layout == null) return const [];
    final cx = size.width / 2;
    final cy = size.height / 2;
    final dx = pos.dx - cx;
    final dy = pos.dy - cy;
    final r = math.sqrt(dx * dx + dy * dy);

    // Hit-test arc: r within [innerR, outerR].
    if (r >= layout.innerR && r <= layout.outerR) {
      var theta = math.atan2(dy, dx);
      while (theta < 0) {
        theta += math.pi * 2;
      }
      for (var i = 0; i < entities.length; i++) {
        final a0 = layout.entityStart[i];
        final a1 = layout.entityEnd[i];
        var ta = a0;
        var tb = a1;
        // Normalize to 0..2π.
        while (ta < 0) {
          ta += math.pi * 2;
        }
        while (tb < 0) {
          tb += math.pi * 2;
        }
        // Wraparound case.
        final hit = ta <= tb
            ? (theta >= ta && theta <= tb)
            : (theta >= ta || theta <= tb);
        if (hit) {
          final total = layout.entityTotal[i];
          return [
            TooltipEntry(
              label: entities[i].label,
              value: fmt(total),
              color: entities[i].color ?? palette[i],
            ),
          ];
        }
      }
    }
    // Hit-test ribbons by mid-bezier point.
    var bestI = -1;
    var bestDist = double.infinity;
    for (var i = 0; i < layout.ribbonMid.length; i++) {
      final d = (layout.ribbonMid[i] - pos).distance;
      if (d < bestDist) {
        bestDist = d;
        bestI = i;
      }
    }
    if (bestI < 0 || bestDist > 28) return const [];
    final f = flows[bestI];
    final s = entities.firstWhere((e) => e.id == f.source);
    final t = entities.firstWhere((e) => e.id == f.target);
    return [
      TooltipEntry(
        label: '${s.label} ↔ ${t.label}',
        value: fmt(f.value),
        color:
            f.color ??
            (s.color ??
                palette[entities.indexWhere((e) => e.id == f.source) %
                    palette.length]),
      ),
    ];
  }
}

class _ChordLayout {
  _ChordLayout({
    required this.entityStart,
    required this.entityEnd,
    required this.entityTotal,
    required this.flowSrcRange,
    required this.flowTgtRange,
    required this.ribbonMid,
    required this.innerR,
    required this.outerR,
    required this.cx,
    required this.cy,
  });

  /// Per entity: angular start of its arc (radians).
  final List<double> entityStart;

  /// Per entity: angular end of its arc.
  final List<double> entityEnd;

  /// Per entity: sum of flow values where it appears as src or tgt.
  final List<double> entityTotal;

  /// Per flow: (a0, a1) on source side.
  final List<List<double>> flowSrcRange;

  /// Per flow: (a0, a1) on target side.
  final List<List<double>> flowTgtRange;

  /// Per flow: midpoint of its ribbon (for hit-test).
  final List<Offset> ribbonMid;

  final double innerR;
  final double outerR;
  final double cx;
  final double cy;

  static _ChordLayout? compute({
    required List<ChordEntity> entities,
    required List<ChordFlow> flows,
    required Size size,
    required double arcWidth,
    required double gapAngle,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (entities.isEmpty || flows.isEmpty) return null;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final outerR = math.min(cx, cy) - 24;
    final innerR = outerR - arcWidth;
    if (innerR <= 0) return null;

    // Per entity: total flow it participates in.
    final indexOf = <String, int>{
      for (var i = 0; i < entities.length; i++) entities[i].id: i,
    };
    final entityTotal = List<double>.filled(entities.length, 0);
    var grandTotal = 0.0;
    for (final f in flows) {
      if (f.source == f.target) continue;
      final si = indexOf[f.source];
      final ti = indexOf[f.target];
      if (si == null || ti == null) continue;
      entityTotal[si] += f.value;
      entityTotal[ti] += f.value;
      grandTotal += f.value * 2;
    }
    if (grandTotal <= 0) return null;

    // Available angular space after gaps.
    final totalGap = gapAngle * entities.length;
    final available = math.pi * 2 - totalGap;
    if (available <= 0) return null;

    final entityStart = <double>[];
    final entityEnd = <double>[];
    var cursor = -math.pi / 2 + gapAngle / 2;
    for (var i = 0; i < entities.length; i++) {
      final share = entityTotal[i] / grandTotal;
      final sweep = available * share;
      entityStart.add(cursor);
      entityEnd.add(cursor + sweep);
      cursor += sweep + gapAngle;
    }

    // Per entity: running offset for next flow allocation.
    final entityCursor = List<double>.from(entityStart);

    // Per flow: src + tgt arc segments.
    // Allocate from each side simultaneously so both sides advance.
    final flowSrcRange = <List<double>>[];
    final flowTgtRange = <List<double>>[];
    final ribbonMid = <Offset>[];

    for (final f in flows) {
      if (f.source == f.target) {
        flowSrcRange.add(const [0, 0]);
        flowTgtRange.add(const [0, 0]);
        ribbonMid.add(Offset(cx, cy));
        continue;
      }
      final si = indexOf[f.source];
      final ti = indexOf[f.target];
      if (si == null || ti == null) {
        flowSrcRange.add(const [0, 0]);
        flowTgtRange.add(const [0, 0]);
        ribbonMid.add(Offset(cx, cy));
        continue;
      }
      final w = (f.value / grandTotal) * available;
      final sStart = entityCursor[si];
      final sEnd = sStart + w;
      entityCursor[si] = sEnd;
      final tStart = entityCursor[ti];
      final tEnd = tStart + w;
      entityCursor[ti] = tEnd;
      flowSrcRange.add([sStart, sEnd]);
      flowTgtRange.add([tStart, tEnd]);

      final sa = (sStart + sEnd) / 2;
      final ta = (tStart + tEnd) / 2;
      final sx = cx + innerR * math.cos(sa);
      final sy = cy + innerR * math.sin(sa);
      final tx = cx + innerR * math.cos(ta);
      final ty = cy + innerR * math.sin(ta);
      ribbonMid.add(Offset((sx + tx + cx) / 3, (sy + ty + cy) / 3));
    }

    return _ChordLayout(
      entityStart: entityStart,
      entityEnd: entityEnd,
      entityTotal: entityTotal,
      flowSrcRange: flowSrcRange,
      flowTgtRange: flowTgtRange,
      ribbonMid: ribbonMid,
      innerR: innerR,
      outerR: outerR,
      cx: cx,
      cy: cy,
    );
  }
}

class _ChordPainter extends CustomPainter {
  _ChordPainter({
    required this.entities,
    required this.flows,
    required this.colors,
    required this.arcWidth,
    required this.gapAngle,
    required this.ribbonOpacity,
    required this.showLabels,
    required this.axisStyle,
    required this.fg,
    required this.animation,
    required this.progress,
  });

  final List<ChordEntity> entities;
  final List<ChordFlow> flows;
  final List<Color> colors;
  final double arcWidth;
  final double gapAngle;
  final double ribbonOpacity;
  final bool showLabels;
  final TextStyle axisStyle;
  final Color fg;
  final ChordAnimation animation;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _ChordLayout.compute(
      entities: entities,
      flows: flows,
      size: size,
      arcWidth: arcWidth,
      gapAngle: gapAngle,
    );
    if (layout == null) return;

    final cx = layout.cx;
    final cy = layout.cy;
    final innerR = layout.innerR;
    final outerR = layout.outerR;

    // ── outer arcs ──────────────────────────────────────────
    for (var i = 0; i < entities.length; i++) {
      final a0 = layout.entityStart[i];
      final a1 = layout.entityEnd[i];
      var aSweep = a1 - a0;
      if (animation == ChordAnimation.sweep) {
        aSweep *= progress;
      }
      if (aSweep <= 0) continue;
      final c = entities[i].color ?? colors[i];
      final path = Path()
        ..arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: outerR),
          a0,
          aSweep,
          true,
        )
        ..arcTo(
          Rect.fromCircle(center: Offset(cx, cy), radius: innerR),
          a0 + aSweep,
          -aSweep,
          false,
        )
        ..close();
      canvas.drawPath(path, Paint()..color = c);
    }

    // ── ribbons ─────────────────────────────────────────────
    // For sweep mode, ribbons fade in after arcs settle.
    final ribbonT = animation == ChordAnimation.sweep
        ? ((progress - 0.5) / 0.5).clamp(0.0, 1.0)
        : 1.0;

    for (var i = 0; i < flows.length; i++) {
      final f = flows[i];
      if (f.source == f.target) continue;
      final sIdx = entities.indexWhere((e) => e.id == f.source);
      final tIdx = entities.indexWhere((e) => e.id == f.target);
      if (sIdx < 0 || tIdx < 0) continue;
      final sR = layout.flowSrcRange[i];
      final tR = layout.flowTgtRange[i];
      final s0 = sR[0];
      final s1 = sR[1];
      final t0 = tR[0];
      final t1 = tR[1];

      final p0 = Offset(cx + innerR * math.cos(s0), cy + innerR * math.sin(s0));
      final p1 = Offset(cx + innerR * math.cos(s1), cy + innerR * math.sin(s1));
      final q0 = Offset(cx + innerR * math.cos(t0), cy + innerR * math.sin(t0));
      final q1 = Offset(cx + innerR * math.cos(t1), cy + innerR * math.sin(t1));

      final path = Path()
        ..moveTo(p0.dx, p0.dy)
        ..arcToPoint(
          p1,
          radius: Radius.circular(innerR),
          clockwise: true,
        )
        ..quadraticBezierTo(cx, cy, q0.dx, q0.dy)
        ..arcToPoint(
          q1,
          radius: Radius.circular(innerR),
          clockwise: true,
        )
        ..quadraticBezierTo(cx, cy, p0.dx, p0.dy)
        ..close();

      final cBase = f.color ?? entities[sIdx].color ?? colors[sIdx];
      final cOther = f.color ?? entities[tIdx].color ?? colors[tIdx];
      final bounds = path.getBounds();
      final shader = LinearGradient(
        colors: [
          cBase.withValues(alpha: ribbonOpacity * ribbonT),
          cOther.withValues(alpha: ribbonOpacity * ribbonT),
        ],
      ).createShader(bounds);
      canvas.drawPath(path, Paint()..shader = shader);
    }

    // ── labels ──────────────────────────────────────────────
    if (!showLabels) return;
    if (progress < 0.55) return;
    final fadeRaw = ((progress - 0.55) / 0.45).clamp(0.0, 1.0);
    final fade = Curves.easeOutCubic.transform(fadeRaw);
    final lblStyle = axisStyle.copyWith(
      color: fg.withValues(alpha: fade * 0.92),
      fontWeight: FontWeight.w600,
      shadows: const [],
    );
    for (var i = 0; i < entities.length; i++) {
      final mid = (layout.entityStart[i] + layout.entityEnd[i]) / 2;
      final r = outerR + 12;
      final tx = cx + r * math.cos(mid);
      final ty = cy + r * math.sin(mid);
      final tp = TextPainter(
        text: TextSpan(text: entities[i].label, style: lblStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: 80);
      // Anchor outward.
      final ax = -0.5 + 0.5 * math.cos(mid);
      final ay = -0.5 + 0.5 * math.sin(mid);
      tp.paint(
        canvas,
        Offset(tx + ax * tp.width, ty + ay * tp.height),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChordPainter old) =>
      old.progress != progress ||
      old.entities != entities ||
      old.flows != flows ||
      old.animation != animation;
}
