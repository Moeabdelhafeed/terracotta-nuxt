import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import 'chart_data.dart';
import 'chart_internals.dart';
import 'chart_legend.dart';
import 'chart_models.dart';

export 'chart_data.dart' show FunnelStage;
export 'chart_legend.dart' show ChartLegendEntry;
export 'chart_models.dart';

/// Funnel chart — sequential stages where each band's width is
/// proportional to its [FunnelStage.value]. Common for sales
/// pipelines, signup conversion, marketing analytics.
///
/// ```dart
/// GlobalFunnel(
///   stages: [
///     FunnelStage(label: 'Visitors', value: 1000),
///     FunnelStage(label: 'Sign-ups', value: 420),
///     FunnelStage(label: 'Trials', value: 180),
///     FunnelStage(label: 'Customers', value: 64),
///   ],
/// )
/// ```
class GlobalFunnel extends StatelessWidget {
  const GlobalFunnel({
    required this.stages,
    this.style = ChartStyle.standard,
    this.bandHeight = 48,
    this.gap = 4,
    this.showValueLabels = true,
    this.showStageLabels = false,
    this.legendPosition = ChartLegendPosition.right,
    this.enableBandEffects = false,
    this.valueFormatter,
    super.key,
  });

  /// Enable a soft drop shadow + thin self-edge stroke on each
  /// band. Off by default (clean flat look). Turn on for elevated /
  /// tactile presentations.
  final bool enableBandEffects;

  /// Where the legend renders. Defaults to `right` (overrides
  /// [ChartStyle.legendPosition] for funnels — when on a side, each
  /// legend chip aligns with its corresponding band).
  final ChartLegendPosition legendPosition;

  final List<FunnelStage> stages;
  final ChartStyle style;

  /// Vertical height per stage band.
  final double bandHeight;

  /// Vertical gap between stages.
  final double gap;

  /// Render `value` text inside (or just outside) each band.
  final bool showValueLabels;

  /// Render the stage `label` text to the right of each band.
  /// Off by default — the legend already shows stage names. Turn on
  /// when the legend is hidden or you want labels anchored to bands.
  final bool showStageLabels;

  /// Format the value text. Defaults to locale-aware compact.
  final String Function(double)? valueFormatter;

  @override
  Widget build(BuildContext context) {
    if (stages.isEmpty) return const SizedBox.shrink();

    final palette = resolveSeriesColors(context, style, stages.length);
    final colors = [
      for (var i = 0; i < stages.length; i++) stages[i].color ?? palette[i],
    ];
    final hasGradient = stages.any((s) => s.gradient != null);
    final gradients = [
      for (var i = 0; i < stages.length; i++)
        stages[i].gradient ?? flatGradient(colors[i]),
    ];
    final fmt = valueFormatter ?? (v) => AppNumbers.compact(v);

    final maxValue = stages.map((s) => s.value).reduce((a, b) => a > b ? a : b);
    if (maxValue <= 0) return const SizedBox.shrink();

    final entries = [
      for (var i = 0; i < stages.length; i++)
        ChartLegendEntry(
          label: stages[i].label,
          color: colors[i],
          icon: stages[i].icon,
          iconAsset: stages[i].iconAsset,
          iconWidget: stages[i].iconWidget,
        ),
    ];

    final body = TweenAnimationBuilder<double>(
      tween: Tween(begin: style.enableAnimation ? 0.0 : 1.0, end: 1.0),
      duration: style.enableAnimation
          ? style.effectiveAnimationDuration
          : Duration.zero,
      curve: style.effectiveAnimationCurve,
      builder: (context, t, _) {
        return CustomPaint(
          painter: _FunnelPainter(
            stages: stages,
            colors: colors,
            gradients: gradients,
            useGradient: hasGradient,
            maxValue: maxValue,
            bandHeight: bandHeight,
            gap: gap,
            progress: t,
            showValueLabels: showValueLabels,
            showStageLabels: showStageLabels,
            enableBandEffects: enableBandEffects,
            valueFormatter: fmt,
            labelStyle:
                Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ) ??
                const TextStyle(),
            stageLabelStyle:
                Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: context.textColors.secondary,
                  letterSpacing: 0.2,
                ) ??
                const TextStyle(),
            outsideHaloColor: context.backgroundColors.background,
          ),
        );
      },
    );

    final totalHeight = stages.length * bandHeight + (stages.length - 1) * gap;

    final chart = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: resolveChartMaxWidth(context, style),
      ),
      child: Padding(
        padding: style.padding,
        child: SizedBox(
          width: double.infinity,
          height: totalHeight,
          child: body,
        ),
      ),
    );

    return Center(child: _wrap(entries, chart));
  }

  /// Wrap chart with legend at the configured position. For
  /// left/right, builds a band-aligned side legend (one row per
  /// stage, vertically centered with its band). For top/bottom
  /// uses the standard inline `ChartLegend` chips.
  Widget _wrap(List<ChartLegendEntry> entries, Widget chart) {
    if (!style.effectiveShowLegend ||
        legendPosition == ChartLegendPosition.hidden) {
      return chart;
    }

    final isSide =
        legendPosition == ChartLegendPosition.left ||
        legendPosition == ChartLegendPosition.right;

    final legend = isSide
        ? _FunnelSideLegend(
            entries: entries,
            bandHeight: bandHeight,
            gap: gap,
          )
        : ChartLegend(entries: entries, position: legendPosition);

    switch (legendPosition) {
      case ChartLegendPosition.top:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [legend, const SizedBox(height: 8), chart],
        );
      case ChartLegendPosition.bottom:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [chart, const SizedBox(height: 8), legend],
        );
      case ChartLegendPosition.left:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            legend,
            const SizedBox(width: 12),
            Flexible(child: chart),
          ],
        );
      case ChartLegendPosition.right:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(child: chart),
            const SizedBox(width: 12),
            legend,
          ],
        );
      case ChartLegendPosition.hidden:
        return chart;
    }
  }
}

/// Side legend whose rows align vertically with the funnel bands.
/// Each row's height equals [bandHeight], separated by [gap]-sized
/// spacers so chip y-center matches band y-center.
class _FunnelSideLegend extends StatelessWidget {
  const _FunnelSideLegend({
    required this.entries,
    required this.bandHeight,
    required this.gap,
  });

  final List<ChartLegendEntry> entries;
  final double bandHeight;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: context.textColors.primary,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );

    final rows = <Widget>[];
    for (var i = 0; i < entries.length; i++) {
      if (i > 0) rows.add(SizedBox(height: gap));
      rows.add(
        SizedBox(
          height: bandHeight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: entries[i].color,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              Text(entries[i].label, style: labelStyle),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}

class _FunnelPainter extends CustomPainter {
  _FunnelPainter({
    required this.stages,
    required this.colors,
    required this.gradients,
    required this.useGradient,
    required this.maxValue,
    required this.bandHeight,
    required this.gap,
    required this.progress,
    required this.showValueLabels,
    required this.showStageLabels,
    required this.enableBandEffects,
    required this.valueFormatter,
    required this.labelStyle,
    required this.stageLabelStyle,
    required this.outsideHaloColor,
  });

  final List<FunnelStage> stages;
  final List<Color> colors;
  final List<Gradient> gradients;
  final bool useGradient;
  final double maxValue;
  final double bandHeight;
  final double gap;
  final double progress;
  final bool showValueLabels;
  final bool showStageLabels;
  final bool enableBandEffects;
  final String Function(double) valueFormatter;
  final TextStyle labelStyle;
  final TextStyle stageLabelStyle;
  final Color outsideHaloColor;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    // When stage labels are anchored beside bands, reserve a 30%
    // gutter for them. Otherwise (default) bands fill nearly the
    // full width — the side legend handles labeling.
    final maxBandWidth = size.width * (showStageLabels ? 0.7 : 0.92);

    for (var i = 0; i < stages.length; i++) {
      final s = stages[i];
      final yTop = i * (bandHeight + gap);
      final yBottom = yTop + bandHeight;
      final wTop = maxBandWidth * (s.value / maxValue) * progress;
      final next = i < stages.length - 1
          ? stages[i + 1].value / maxValue
          : (s.value / maxValue) * 0.85;
      final wBottom = maxBandWidth * next * progress;

      final path = Path()
        ..moveTo(cx - wTop / 2, yTop)
        ..lineTo(cx + wTop / 2, yTop)
        ..lineTo(cx + wBottom / 2, yBottom)
        ..lineTo(cx - wBottom / 2, yBottom)
        ..close();

      if (enableBandEffects) {
        // Blurred drop shadow under the band. Painted as a shifted
        // copy of the path so it survives the next band painting on
        // top of it (canvas.drawShadow gets clipped by stacking).
        canvas.drawPath(
          path.shift(const Offset(0, 3)),
          Paint()
            ..color = Colors.black.withValues(alpha: 0.22)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
        );
      }

      final paint = Paint();
      if (useGradient) {
        final rect = Rect.fromLTWH(cx - wTop / 2, yTop, wTop, bandHeight);
        paint.shader = gradients[i].createShader(rect);
      } else {
        paint.color = colors[i];
      }
      canvas.drawPath(path, paint);

      if (enableBandEffects) {
        // Self-edge stroke — band color darkened so it reads as
        // shading, not a hard outline.
        final hsl = HSLColor.fromColor(colors[i]);
        final strokeColor = hsl
            .withLightness((hsl.lightness * 0.65).clamp(0.0, 1.0))
            .toColor()
            .withValues(alpha: 0.85);
        canvas.drawPath(
          path,
          Paint()
            ..color = strokeColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..isAntiAlias = true,
        );
      }

      // Value label — fades + counts up over the second half of
      // the global progress window. Falls back to outside the band
      // (next to the stage label) when the band is too narrow to
      // host the text.
      if (showValueLabels) {
        final valueOpacity = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
        if (valueOpacity > 0) {
          final countValue = s.value * valueOpacity;
          final valueText = valueFormatter(countValue);

          // Fit check uses the FINAL value's text width — locking
          // the inside-vs-outside decision to the end state stops
          // the label flickering between inside/outside as the
          // count grows during animation.
          final finalText = valueFormatter(s.value);
          final finalTp = TextPainter(
            text: TextSpan(text: finalText, style: labelStyle),
            textDirection: TextDirection.ltr,
          )..layout();
          // Use the band's FINAL width (progress=1) for the fit so
          // it doesn't depend on the in-flight band growth either.
          final finalWTop = maxBandWidth * (s.value / maxValue);

          final fits = finalTp.width + 12 <= finalWTop;
          if (fits) {
            // Paint inside the band centered, white label with a
            // soft halo + drop shadow for legibility against any
            // band tint (gradient stops, dark/light variants).
            // Layout unbounded + maxLines:1 so the count text never
            // wraps to two lines as the band grows during animation.
            final styled = labelStyle.copyWith(
              color: (labelStyle.color ?? Colors.white).withValues(
                alpha: valueOpacity,
              ),
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.55 * valueOpacity),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
                Shadow(
                  color: Colors.black.withValues(alpha: 0.35 * valueOpacity),
                  blurRadius: 2,
                ),
              ],
            );
            final tp = TextPainter(
              text: TextSpan(text: valueText, style: styled),
              textDirection: TextDirection.ltr,
              maxLines: 1,
            )..layout();
            tp.paint(
              canvas,
              Offset(cx - tp.width / 2, yTop + (bandHeight - tp.height) / 2),
            );
          } else {
            // Paint outside the band on the right — colored by the
            // band's primary color so the value visually anchors to
            // its stage even when crowding labels. Halo (theme bg
            // color) + soft drop shadow lift it off the page so it
            // reads cleanly on any background.
            final outsideColor = colors[i].withValues(alpha: valueOpacity);
            final outsideTp = TextPainter(
              text: TextSpan(
                text: valueText,
                style: labelStyle.copyWith(
                  color: outsideColor,
                  shadows: [
                    // Background-tinted halo — masks any geometry
                    // bleed-through from the band edge.
                    Shadow(
                      color: outsideHaloColor.withValues(
                        alpha: 0.85 * valueOpacity,
                      ),
                      blurRadius: 4,
                    ),
                    Shadow(
                      color: outsideHaloColor.withValues(
                        alpha: 0.85 * valueOpacity,
                      ),
                      blurRadius: 2,
                    ),
                    // Subtle elevation drop shadow.
                    Shadow(
                      color: Colors.black.withValues(
                        alpha: 0.20 * valueOpacity,
                      ),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout();
            outsideTp.paint(
              canvas,
              Offset(
                cx + wTop / 2 + 6,
                yTop + (bandHeight - outsideTp.height) / 2,
              ),
            );
          }
        }
      }

      // Stage label to the right of the band. Off by default since
      // the legend already shows stage names — opt in via
      // `showStageLabels: true` when legend is hidden.
      if (!showStageLabels) continue;
      final labelMax = ((size.width - maxBandWidth) / 2 - 8).clamp(
        0.0,
        double.infinity,
      );
      if (labelMax <= 0) continue;
      final labelTp = TextPainter(
        text: TextSpan(text: s.label, style: stageLabelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: labelMax);
      labelTp.paint(
        canvas,
        Offset(
          cx + maxBandWidth / 2 + 8,
          yTop + (bandHeight - labelTp.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FunnelPainter old) =>
      old.progress != progress ||
      old.stages != stages ||
      old.colors != colors ||
      old.gradients != gradients ||
      old.useGradient != useGradient ||
      old.maxValue != maxValue ||
      old.bandHeight != bandHeight ||
      old.gap != gap ||
      old.showValueLabels != showValueLabels;
}
