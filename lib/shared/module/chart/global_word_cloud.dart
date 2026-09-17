import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_models.dart';
import 'chart_tooltip_overlay.dart';
import 'custom_paint_tooltip.dart';

export 'chart_data.dart' show WordCloudWord;
export 'chart_models.dart' show ChartStyle, WordCloudAnimation;

/// Word cloud — words sized by [WordCloudWord.weight] and packed
/// without overlap via Archimedean spiral placement. Stable layout
/// across renders (seeded RNG).
///
/// ```dart
/// GlobalWordCloud(
///   words: [
///     WordCloudWord(text: 'Flutter', weight: 80),
///     WordCloudWord(text: 'Dart',    weight: 60),
///     ...
///   ],
/// )
/// ```
class GlobalWordCloud extends StatelessWidget {
  const GlobalWordCloud({
    required this.words,
    this.style = ChartStyle.standard,
    this.animation = WordCloudAnimation.pop,
    this.minFontSize = 12,
    this.maxFontSize = 56,
    this.fontWeight = FontWeight.w700,
    this.rotationProbability = 0.25,
    this.seed = 7,
    this.padding = 2,
    super.key,
  });

  final List<WordCloudWord> words;
  final ChartStyle style;
  final WordCloudAnimation animation;
  final double minFontSize;
  final double maxFontSize;
  final FontWeight fontWeight;

  /// Probability a word is rotated 90° during placement.
  final double rotationProbability;

  final int seed;
  final double padding;

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) return const SizedBox.shrink();
    final palette = resolveSeriesColors(
      context,
      style,
      words.length.clamp(1, 12),
    );

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
              hitTest: (pos, size) => _hitTest(pos, size, palette),
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
                    painter: _WordCloudPainter(
                      words: words,
                      palette: palette,
                      minFontSize: minFontSize,
                      maxFontSize: maxFontSize,
                      fontWeight: fontWeight,
                      rotationProbability: rotationProbability,
                      seed: seed,
                      padding: padding,
                      animation: animation,
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
  ) {
    final layout = _WordCloudLayout.compute(
      words: words,
      size: size,
      minFontSize: minFontSize,
      maxFontSize: maxFontSize,
      fontWeight: fontWeight,
      rotationProbability: rotationProbability,
      seed: seed,
      padding: padding,
    );
    if (layout == null) return const [];
    for (var i = 0; i < layout.placements.length; i++) {
      final p = layout.placements[i];
      if (p.bounds.contains(pos)) {
        final c =
            words[p.wordIndex].color ?? palette[p.wordIndex % palette.length];
        return [
          TooltipEntry(
            label: words[p.wordIndex].text,
            value: 'weight ${words[p.wordIndex].weight}',
            color: c,
          ),
        ];
      }
    }
    return const [];
  }
}

class _Placement {
  _Placement({
    required this.wordIndex,
    required this.center,
    required this.fontSize,
    required this.rotated,
    required this.bounds,
  });
  final int wordIndex;
  final Offset center;
  final double fontSize;
  final bool rotated;
  final Rect bounds;
}

class _WordCloudLayout {
  _WordCloudLayout({required this.placements});
  final List<_Placement> placements;

  static _WordCloudLayout? compute({
    required List<WordCloudWord> words,
    required Size size,
    required double minFontSize,
    required double maxFontSize,
    required FontWeight fontWeight,
    required double rotationProbability,
    required int seed,
    required double padding,
  }) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (words.isEmpty) return null;

    var maxW = 0.0;
    var minW = double.infinity;
    for (final w in words) {
      if (w.weight > maxW) maxW = w.weight;
      if (w.weight < minW) minW = w.weight;
    }
    if (maxW == 0) maxW = 1;
    if (minW == double.infinity) minW = 0;
    final span = maxW - minW;

    // Sort heaviest first — heaviest gets the center.
    final order = List<int>.generate(words.length, (i) => i)
      ..sort((a, b) => words[b].weight.compareTo(words[a].weight));

    final cx = size.width / 2;
    final cy = size.height / 2;
    final rng = math.Random(seed);
    final placed = <_Placement>[];

    bool overlapsAny(Rect r) {
      for (final p in placed) {
        if (r.overlaps(p.bounds)) return true;
      }
      return false;
    }

    for (final idx in order) {
      final w = words[idx];
      final t = span > 0
          ? math.sqrt(((w.weight - minW) / span)).clamp(0.0, 1.0)
          : 1.0;
      final fontSize = minFontSize + (maxFontSize - minFontSize) * t;
      final rotated = rng.nextDouble() < rotationProbability;
      final tp = TextPainter(
        text: TextSpan(
          text: w.text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final wBox = rotated ? tp.height : tp.width;
      final hBox = rotated ? tp.width : tp.height;

      // Spiral placement.
      var theta = rng.nextDouble() * math.pi * 2;
      var radius = 0.0;
      const radiusStep = 0.7;
      const thetaStep = 0.2;
      _Placement? placement;
      // Limit attempts to avoid hangs.
      for (var attempt = 0; attempt < 1500; attempt++) {
        final px = cx + radius * math.cos(theta);
        final py = cy + radius * math.sin(theta);
        final r = Rect.fromCenter(
          center: Offset(px, py),
          width: wBox + padding * 2,
          height: hBox + padding * 2,
        );
        if (r.left >= 0 &&
            r.top >= 0 &&
            r.right <= size.width &&
            r.bottom <= size.height &&
            !overlapsAny(r)) {
          placement = _Placement(
            wordIndex: idx,
            center: Offset(px, py),
            fontSize: fontSize,
            rotated: rotated,
            bounds: r,
          );
          break;
        }
        theta += thetaStep;
        radius += radiusStep * thetaStep / (2 * math.pi);
      }
      if (placement != null) {
        placed.add(placement);
      }
    }

    return _WordCloudLayout(placements: placed);
  }
}

class _WordCloudPainter extends CustomPainter {
  _WordCloudPainter({
    required this.words,
    required this.palette,
    required this.minFontSize,
    required this.maxFontSize,
    required this.fontWeight,
    required this.rotationProbability,
    required this.seed,
    required this.padding,
    required this.animation,
    required this.progress,
  });

  final List<WordCloudWord> words;
  final List<Color> palette;
  final double minFontSize;
  final double maxFontSize;
  final FontWeight fontWeight;
  final double rotationProbability;
  final int seed;
  final double padding;
  final WordCloudAnimation animation;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = _WordCloudLayout.compute(
      words: words,
      size: size,
      minFontSize: minFontSize,
      maxFontSize: maxFontSize,
      fontWeight: fontWeight,
      rotationProbability: rotationProbability,
      seed: seed,
      padding: padding,
    );
    if (layout == null) return;

    final rng = math.Random(seed * 31 + 1);
    final n = layout.placements.length;

    for (var i = 0; i < n; i++) {
      final p = layout.placements[i];
      final w = words[p.wordIndex];
      final c = w.color ?? palette[p.wordIndex % palette.length];

      // Heaviest words first → smallest delay; lightest delayed.
      final delay = (i / n) * 0.5;
      final t = ((progress - delay) / (1 - delay)).clamp(0.0, 1.0);

      double scale;
      var shifted = p.center;
      double opacity;
      switch (animation) {
        case WordCloudAnimation.pop:
          scale = t;
          opacity = 1.0;
        case WordCloudAnimation.fade:
          scale = 1.0;
          opacity = progress;
        case WordCloudAnimation.fly:
          scale = 1.0;
          shifted = Offset(
            p.center.dx + (1 - t) * 80 * (rng.nextDouble() - 0.5),
            p.center.dy + (1 - t) * 80 * (rng.nextDouble() - 0.5),
          );
          opacity = t;
      }
      if (scale <= 0 || opacity <= 0) continue;

      final tp = TextPainter(
        text: TextSpan(
          text: w.text,
          style: TextStyle(
            fontSize: p.fontSize * scale,
            fontWeight: fontWeight,
            color: c.withValues(alpha: opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.save();
      canvas.translate(shifted.dx, shifted.dy);
      if (p.rotated) canvas.rotate(-math.pi / 2);
      tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WordCloudPainter old) =>
      old.progress != progress ||
      old.words != words ||
      old.animation != animation;
}
