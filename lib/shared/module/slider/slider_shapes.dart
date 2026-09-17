import 'package:flutter/material.dart';

import '../../../core/extensions/theme_colors_extension.dart';
import 'slider_models.dart';
import 'slider_style.dart';

/// The one rect every part of a bar is measured from.
///
/// Material's own `BaseSliderTrackShape` reserves
/// `max(overlayWidth, thumbWidth) / 2` at each end — the OVERLAY, which
/// is the ripple and is deliberately bigger than the thumb. At the
/// house sizes that is 16 points a side for a thumb that needs 10, and
/// it read as dead space at both ends of every slider.
///
/// This reserves what the THUMB needs, plus a hair so the edge of it
/// is not flush with the edge of the box. `GlobalSlider`'s step-label
/// row uses the same number, which is the only way the words can line
/// up with the ticks.
abstract final class SliderTrackGeometry {
  /// The inset that keeps a thumb of [thumbRadius] wholly inside the
  /// box — what a slider whose parent CLIPS wants for
  /// `SliderStyle.trackEndInset`. The default is zero.
  static double thumbSafeInset(double thumbRadius) =>
      thumbRadius + SliderDefaults.trackEndPadding;

  static Rect rectFor({
    required RenderBox parentBox,
    required Offset offset,
    required SliderThemeData sliderTheme,
    required double endInset,
  }) {
    final height = sliderTheme.trackHeight ?? SliderDefaults.trackHeight;
    final inset = endInset;
    return Rect.fromLTWH(
      offset.dx + inset,
      offset.dy + (parentBox.size.height - height) / 2,
      parentBox.size.width - inset * 2,
      height,
    );
  }
}

/// Builds the `SliderThemeData` a [ResolvedSliderStyle] describes.
///
/// It lives out here because both the single and the range slider need
/// exactly the same one, and because the shapes below are only
/// reachable through it.
SliderThemeData buildSliderTheme(
  BuildContext context, {
  required ResolvedSliderStyle style,
  required bool enabled,
  required bool hasDivisions,
  required TextDirection direction,
  List<double> segments = const [],
}) {
  // The house's shadow ink — `Colors.black` under a dark theme is a
  // shadow nobody can see.
  final shadow = context.backgroundColors.outline;
  final base = SliderTheme.of(context);

  // Ticks between two adjacent pixels are a smear, not a scale.
  final showTicks = style.showTicks && hasDivisions;
  final hasGradientTrack = style.trackGradient != null;

  Color dim(Color c) =>
      enabled ? c : c.withValues(alpha: c.a * style.disabledOpacity);

  return base.copyWith(
    activeTrackColor: dim(style.activeColor),
    inactiveTrackColor: dim(style.inactiveColor),
    thumbColor: dim(style.thumbColor),
    // The ring is what the thumb is READ by on a pale track, so it dims
    // with everything else rather than staying at full strength on a
    // disabled control.
    overlayColor: enabled
        ? style.activeColor.withValues(alpha: SliderDefaults.overlayOpacity)
        : Colors.transparent,
    trackHeight: style.trackHeight,
    thumbShape: style.thumbGradient != null
        ? _GradientThumbShape(
            radius: style.thumbRadius,
            gradient: style.thumbGradient!,
            ringColor: style.thumbBorderColor,
            shadowColor: shadow,
          )
        : RoundSliderThumbShape(
            enabledThumbRadius: style.thumbRadius,
            disabledThumbRadius:
                style.thumbRadius - SliderDefaults.disabledThumbShrink,
            elevation: style.thumbElevation,
          ),
    rangeThumbShape: RoundRangeSliderThumbShape(
      enabledThumbRadius: style.thumbRadius,
      disabledThumbRadius:
          style.thumbRadius - SliderDefaults.disabledThumbShrink,
      elevation: style.thumbElevation,
    ),
    secondaryActiveTrackColor: dim(style.secondaryColor),
    // A segmented track REPLACES the track; a gradient one only
    // recolours it. Segments win, and carry the gradient through.
    // ALWAYS one of ours, even with nothing to decorate.
    //
    // Material's own `BaseSliderTrackShape` insets each end by
    // `max(overlayWidth, thumbWidth) / 2` — the OVERLAY, not the
    // thumb. With the house overlay at 16 that is 32 points of track
    // spent on a 20-point thumb, and it showed as dead space at both
    // ends of every slider in the app. `SliderTrackGeometry.rectFor`
    // reserves what the THUMB needs and nothing more, and every part
    // of the bar — plain, gradient, segmented, the tick marks and the
    // step labels underneath — is measured from that one number.
    trackShape: segments.isNotEmpty
        ? SliderSegmentedTrackShape(
            bounds: segments,
            gap: style.segmentGap,
            gradient: style.trackGradient,
            inactiveColor: dim(style.inactiveColor),
            endInset: style.trackEndInset,
            trackRadius: style.trackRadius,
            rtl: direction == TextDirection.rtl,
          )
        : hasGradientTrack
        ? _GradientTrackShape(
            gradient: style.trackGradient!,
            inactiveColor: dim(style.inactiveColor),
            endInset: style.trackEndInset,
            trackRadius: style.trackRadius,
          )
        : _PlainTrackShape(
            inactiveColor: dim(style.inactiveColor),
            activeColor: dim(style.activeColor),
            secondaryColor: dim(style.secondaryColor),
            endInset: style.trackEndInset,
            trackRadius: style.trackRadius,
          ),
    rangeTrackShape: segments.isNotEmpty
        ? SliderSegmentedRangeTrackShape(
            bounds: segments,
            gap: style.segmentGap,
            gradient: style.trackGradient,
            inactiveColor: dim(style.inactiveColor),
            endInset: style.trackEndInset,
            trackRadius: style.trackRadius,
          )
        : hasGradientTrack
        ? _GradientRangeTrackShape(
            gradient: style.trackGradient!,
            inactiveColor: dim(style.inactiveColor),
            endInset: style.trackEndInset,
            trackRadius: style.trackRadius,
          )
        : _PlainRangeTrackShape(
            inactiveColor: dim(style.inactiveColor),
            activeColor: dim(style.activeColor),
            endInset: style.trackEndInset,
            trackRadius: style.trackRadius,
          ),
    tickMarkShape: showTicks
        ? _StyledTickMarkShape(style: style.tickStyle)
        : SliderTickMarkShape.noTickMark,
    activeTickMarkColor: showTicks
        ? dim(style.tickStyle.activeColor)
        : Colors.transparent,
    inactiveTickMarkColor: showTicks
        ? dim(style.tickStyle.color)
        : Colors.transparent,
    valueIndicatorShape: _indicatorShape(style.indicatorStyle, shadow),
    valueIndicatorColor: style.indicatorStyle.color,
    valueIndicatorTextStyle: style.indicatorStyle.textStyle,
    showValueIndicator: style.showValueIndicator
        ? ShowValueIndicator.onDrag
        : ShowValueIndicator.never,
    overlayShape: RoundSliderOverlayShape(overlayRadius: style.overlayRadius),
  );
}

SliderComponentShape _indicatorShape(
  ResolvedSliderIndicatorStyle style,
  Color shadow,
) => switch (style.shape) {
  SliderIndicatorShape.paddle => const PaddleSliderValueIndicatorShape(),
  SliderIndicatorShape.rounded => _RoundedIndicatorShape(
    style: style,
    shadowColor: shadow,
  ),
  SliderIndicatorShape.bubble => _BubbleIndicatorShape(
    style: style,
    shadowColor: shadow,
  ),
};

/// The blurred drop under a shape.
void _paintShadow(Canvas canvas, Path path, Color color, double opacity) {
  canvas.drawPath(
    path.shift(SliderDefaults.shadowOffset),
    Paint()
      ..color = color.withValues(
        alpha: SliderDefaults.shadowOpacity * opacity,
      )
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        SliderDefaults.shadowBlur,
      ),
  );
}

// ─────────────────────────────────────────────────────────────
// Gradient track — single
// ─────────────────────────────────────────────────────────────

class _GradientTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const _GradientTrackShape({
    required this.gradient,
    required this.inactiveColor,
    required this.endInset,
    required this.trackRadius,
  });

  final Gradient gradient;
  final Color inactiveColor;

  /// What each end of the track gives up. See
  /// `SliderStyle.trackEndInset`.
  final double endInset;
  final double trackRadius;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    // The rect Material would use, so a gradient track lines up with
    // a plain one, with the tick marks, and with the step labels. It
    // was hand-rolled from `thumbRadius + 2` against the parent box —
    // which is the PADDED box, so the inset landed twice and a
    // gradient track sat 6 points wider than the default one.
    final full = SliderTrackGeometry.rectFor(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      endInset: endInset,
    );
    final left = full.left;
    final right = full.right;
    final top = full.top;
    final height = full.height;
    final radius = Radius.circular(trackRadius);

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(full, radius),
      Paint()..color = inactiveColor,
    );

    // In Arabic the low end of the track is the RIGHT one, so the
    // filled part runs from the thumb to the right edge. It always ran
    // left-to-right, which drew a gradient slider's fill on the side
    // the value was NOT.
    final span = SliderMath.activeSpan(
      trackLeft: left,
      trackRight: right,
      thumbX: thumbCenter.dx,
      rtl: textDirection == TextDirection.rtl,
    );
    if (span.end <= span.start) return;

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(span.start, top, span.end, top + height),
        radius,
      ),
      // The shader spans the WHOLE track, so a given value keeps its
      // colour as the thumb moves past it.
      Paint()..shader = gradient.createShader(full),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Gradient track — range
// ─────────────────────────────────────────────────────────────

class _GradientRangeTrackShape extends RangeSliderTrackShape
    with BaseRangeSliderTrackShape {
  const _GradientRangeTrackShape({
    required this.gradient,
    required this.inactiveColor,
    required this.endInset,
    required this.trackRadius,
  });

  final Gradient gradient;
  final Color inactiveColor;

  /// What each end of the track gives up. See
  /// `SliderStyle.trackEndInset`.
  final double endInset;
  final double trackRadius;

  // No rect of its own: `BaseRangeSliderTrackShape` computes the one
  // Material positions the thumbs and ticks against, and it already
  // knows to add nothing when a padding is set.

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final full = SliderTrackGeometry.rectFor(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      endInset: endInset,
    );
    final top = full.top;
    final height = full.height;
    final radius = Radius.circular(trackRadius);

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(full, radius),
      Paint()..color = inactiveColor,
    );

    // Material hands the thumbs back in VALUE order, so in Arabic the
    // start thumb is the one further right — take the span by position
    // rather than by name.
    final a = startThumbCenter.dx;
    final b = endThumbCenter.dx;
    final lo = a < b ? a : b;
    final hi = a < b ? b : a;
    if (hi <= lo) return;

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(lo, top, hi, top + height), radius),
      Paint()..shader = gradient.createShader(full),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Gradient thumb
// ─────────────────────────────────────────────────────────────

class _GradientThumbShape extends SliderComponentShape {
  const _GradientThumbShape({
    required this.radius,
    required this.gradient,
    required this.ringColor,
    required this.shadowColor,
  });

  final double radius;
  final Gradient gradient;

  /// The inner ring. It was `Colors.white`, which vanished the moment
  /// the gradient ran anywhere near white.
  final Color ringColor;
  final Color shadowColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      Size.fromRadius(radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final rect = Rect.fromCircle(center: center, radius: radius);

    _paintShadow(
      canvas,
      Path()..addOval(rect),
      shadowColor,
      1,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()..shader = gradient.createShader(rect),
    );
    canvas.drawCircle(
      center,
      radius - SliderDefaults.thumbBorderWidth / 2 - 1,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = SliderDefaults.thumbBorderWidth,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Tick marks
// ─────────────────────────────────────────────────────────────

class _StyledTickMarkShape extends SliderTickMarkShape {
  const _StyledTickMarkShape({required this.style});

  final ResolvedSliderTickStyle style;

  @override
  Size getPreferredSize({
    required SliderThemeData sliderTheme,
    required bool isEnabled,
  }) => Size.fromRadius(style.radius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    required bool isEnabled,
  }) {
    // `center.dx <= thumbCenter.dx` is only "before the thumb" when the
    // track runs left to right; in Arabic it marked every passed tick
    // as unreached and every unreached one as passed.
    final isActive = SliderMath.tickIsActive(
      tickX: center.dx,
      thumbX: thumbCenter.dx,
      rtl: textDirection == TextDirection.rtl,
    );
    final color = isActive ? style.activeColor : style.color;

    switch (style.shape) {
      case SliderTickShape.circle:
        context.canvas.drawCircle(center, style.radius, Paint()..color = color);
      case SliderTickShape.line:
        final trackHeight =
            sliderTheme.trackHeight ?? SliderDefaults.trackHeight;
        context.canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: style.radius,
              height: trackHeight + style.radius * 2,
            ),
            Radius.circular(style.radius / 2),
          ),
          Paint()..color = color,
        );
    }
  }
}

// ─────────────────────────────────────────────────────────────
// Value indicators
// ─────────────────────────────────────────────────────────────

/// What the two custom indicators share: a body sized to the label, a
/// shadow, an optional gradient, and the label drawn inside it.
abstract class _LabelIndicatorShape extends SliderComponentShape {
  const _LabelIndicatorShape({required this.style, required this.shadowColor});

  final ResolvedSliderIndicatorStyle style;
  final Color shadowColor;

  /// The path to fill, given the body's rect. The bubble adds an arrow.
  Path buildPath(Rect body, Offset thumb);

  /// How far above the thumb the body's bottom sits.
  double get bodyLift => 0;

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final opacity = activationAnimation.value;
    if (opacity == 0) return;

    final canvas = context.canvas;
    final width = labelPainter.width + style.padding.horizontal;
    final height = labelPainter.height + style.padding.vertical;
    final lift =
        style.verticalOffset +
        (sliderTheme.thumbShape?.getPreferredSize(true, isDiscrete).height ??
                20) /
            2 +
        bodyLift;

    // Kept inside the slider's own box, so a bubble on the last value
    // does not hang off the edge of the card the slider sits in.
    final half = width / 2;
    final dx = center.dx.clamp(
      half,
      (sizeWithOverflow.width - half).clamp(half, double.infinity),
    );

    final body = Rect.fromCenter(
      center: Offset(dx, center.dy - lift - height / 2),
      width: width,
      height: height,
    );
    final path = buildPath(body, center);

    _paintShadow(canvas, path, shadowColor, opacity);

    final labelAt = Offset(
      body.left + style.padding.left,
      body.top + style.padding.top,
    );

    if (style.gradient != null) {
      // One layer for shape and label together, so the fade takes both
      // — fading them separately let the label show THROUGH the body.
      canvas.saveLayer(
        path.getBounds().inflate(4),
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: opacity),
      );
      canvas.drawPath(
        path,
        Paint()..shader = style.gradient!.createShader(path.getBounds()),
      );
      labelPainter.paint(canvas, labelAt);
      canvas.restore();
      return;
    }

    canvas.drawPath(
      path,
      Paint()..color = style.color.withValues(alpha: style.color.a * opacity),
    );
    labelPainter.paint(canvas, labelAt);
  }
}

class _RoundedIndicatorShape extends _LabelIndicatorShape {
  const _RoundedIndicatorShape({
    required super.style,
    required super.shadowColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(48, 32);

  @override
  Path buildPath(Rect body, Offset thumb) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(body, Radius.circular(style.borderRadius)),
    );
}

class _BubbleIndicatorShape extends _LabelIndicatorShape {
  const _BubbleIndicatorShape({
    required super.style,
    required super.shadowColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(48, 40);

  @override
  double get bodyLift => style.arrowSize;

  @override
  Path buildPath(Rect body, Offset thumb) {
    // The arrow points at the THUMB, not at the body's middle — the
    // body is clamped to the slider's box near the ends and a
    // centre-anchored arrow left it pointing at nothing.
    final tip = thumb.dx.clamp(
      body.left + style.borderRadius + style.arrowSize,
      body.right - style.borderRadius - style.arrowSize,
    );
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(body, Radius.circular(style.borderRadius)),
      )
      ..moveTo(tip - style.arrowSize, body.bottom)
      ..lineTo(tip, body.bottom + style.arrowSize)
      ..lineTo(tip + style.arrowSize, body.bottom)
      ..close();
  }
}

// ─────────────────────────────────────────────────────────────
// Segmented track
// ─────────────────────────────────────────────────────────────

/// One rounded bar per segment, drawn inactive → secondary → active.
///
/// Lifted out of the video player, where it started as the seek bar's
/// chapter track. Painting gaps ON TOP of a finished track was the
/// first attempt there and it stayed a MARKED track — the pieces ran
/// together under the thumb, and a notch two points wide read as a
/// rendering fault rather than a division. Replacing the track makes
/// it look like several sliders handing the thumb between them, which
/// is what it is.
///
/// The player's copy was pinned left-to-right, because a TIMELINE does
/// not mirror. An ordinary slider does, so this one takes a direction.
void _paintSegments(
  Canvas canvas, {
  required Rect rect,
  required List<double> bounds,
  required double gap,
  required double trackRadius,
  required bool rtl,
  required Paint inactive,
  required Paint active,
  Paint? secondary,
  ({double start, double end})? activeSpan,
  ({double start, double end})? secondarySpan,
}) {
  final radius = Radius.circular(trackRadius);

  for (var i = 0; i < bounds.length - 1; i++) {
    // The two edges IN VALUE SPACE, then placed. In Arabic the low
    // value is the right-hand edge, so the pair swaps.
    final lowX = rect.left + rect.width * (rtl ? 1 - bounds[i] : bounds[i]);
    final highX =
        rect.left + rect.width * (rtl ? 1 - bounds[i + 1] : bounds[i + 1]);

    // Half a gap from each side of a seam, and none from the outer
    // ends — the track still starts and finishes where the reader
    // expects it to.
    final padLow = i == 0 ? 0.0 : gap / 2;
    final padHigh = i == bounds.length - 2 ? 0.0 : gap / 2;

    final left = rtl ? highX + padHigh : lowX + padLow;
    final right = rtl ? lowX - padLow : highX - padHigh;
    if (right <= left) continue;

    void fill(({double start, double end})? span, Paint? paint) {
      if (span == null || paint == null) return;
      final from = span.start > left ? span.start : left;
      final to = span.end < right ? span.end : right;
      if (to <= from) return;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(from, rect.top, to, rect.bottom),
          radius,
        ),
        paint,
      );
    }

    // Whole segment, then what has loaded, then what has been reached
    // — each drawn over the last, which is how one bar shows three
    // states without three shapes.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, rect.top, right, rect.bottom),
        radius,
      ),
      inactive,
    );
    fill(secondarySpan, secondary);
    fill(activeSpan, active);
  }
}

class SliderSegmentedTrackShape extends SliderTrackShape
    with BaseSliderTrackShape {
  const SliderSegmentedTrackShape({
    required this.bounds,
    required this.gap,
    required this.inactiveColor,
    required this.endInset,
    required this.trackRadius,
    required this.rtl,
    this.gradient,
  });

  /// Segment boundaries as fractions of the range, 0 and 1 included.
  final List<double> bounds;
  final double gap;
  final Color inactiveColor;

  /// What each end of the track is inset by.
  ///
  /// A number rather than a thumb radius: the video seek bar reserves
  /// NOTHING at its ends — the timeline runs the full width so it
  /// lines up with the clock and the controls under it, and the thumb
  /// overhangs into the bar's own inset instead.
  final double endInset;
  final double trackRadius;
  final bool rtl;
  final Gradient? gradient;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) => SliderTrackGeometry.rectFor(
    parentBox: parentBox,
    offset: offset,
    sliderTheme: sliderTheme,
    endInset: endInset,
  );

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    if (rect.isEmpty) return;

    final active = Paint();
    if (gradient != null) {
      active.shader = gradient!.createShader(rect);
    } else {
      active.color = sliderTheme.activeTrackColor ?? inactiveColor;
    }

    _paintSegments(
      context.canvas,
      rect: rect,
      bounds: bounds,
      gap: gap,
      trackRadius: trackRadius,
      rtl: rtl,
      inactive: Paint()
        ..color = sliderTheme.inactiveTrackColor ?? inactiveColor,
      active: active,
      secondary: sliderTheme.secondaryActiveTrackColor == null
          ? null
          : (Paint()..color = sliderTheme.secondaryActiveTrackColor!),
      activeSpan: SliderMath.activeSpan(
        trackLeft: rect.left,
        trackRight: rect.right,
        thumbX: thumbCenter.dx,
        rtl: rtl,
      ),
      // Material only hands over a secondary offset when the caller
      // gave a `secondaryTrackValue`; without one there is nothing
      // loaded-but-not-reached to draw.
      secondarySpan: secondaryOffset == null
          ? null
          : SliderMath.activeSpan(
              trackLeft: rect.left,
              trackRight: rect.right,
              thumbX: secondaryOffset.dx,
              rtl: rtl,
            ),
    );
  }
}

class SliderSegmentedRangeTrackShape extends RangeSliderTrackShape
    with BaseRangeSliderTrackShape {
  const SliderSegmentedRangeTrackShape({
    required this.bounds,
    required this.gap,
    required this.inactiveColor,
    required this.endInset,
    required this.trackRadius,
    this.gradient,
  });

  final List<double> bounds;
  final double gap;
  final Color inactiveColor;

  /// What each end of the track is inset by.
  ///
  /// A number rather than a thumb radius: the video seek bar reserves
  /// NOTHING at its ends — the timeline runs the full width so it
  /// lines up with the clock and the controls under it, and the thumb
  /// overhangs into the bar's own inset instead.
  final double endInset;
  final double trackRadius;
  final Gradient? gradient;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) => SliderTrackGeometry.rectFor(
    parentBox: parentBox,
    offset: offset,
    sliderTheme: sliderTheme,
    endInset: endInset,
  );

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    if (rect.isEmpty) return;

    final active = Paint();
    if (gradient != null) {
      active.shader = gradient!.createShader(rect);
    } else {
      active.color = sliderTheme.activeTrackColor ?? inactiveColor;
    }

    // The thumbs come back in VALUE order, so which of them is on the
    // left depends on the direction — take the span by position and
    // the mirroring takes care of itself.
    final a = startThumbCenter.dx;
    final b = endThumbCenter.dx;

    _paintSegments(
      context.canvas,
      rect: rect,
      bounds: bounds,
      gap: gap,
      trackRadius: trackRadius,
      rtl: textDirection == TextDirection.rtl,
      inactive: Paint()
        ..color = sliderTheme.inactiveTrackColor ?? inactiveColor,
      active: active,
      activeSpan: (start: a < b ? a : b, end: a < b ? b : a),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Plain track — the default one, measured our way
// ─────────────────────────────────────────────────────────────

/// What Material's `RoundedRectSliderTrackShape` draws, over
/// [SliderTrackGeometry]'s rect instead of its own.
///
/// It exists ONLY to own the rect. Material's inset is the overlay's,
/// which is the ripple; ours is the thumb's, which is the thing that
/// actually has to stay inside the box.
class _PlainTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const _PlainTrackShape({
    required this.inactiveColor,
    required this.activeColor,
    required this.secondaryColor,
    required this.endInset,
    required this.trackRadius,
  });

  final Color inactiveColor;
  final Color activeColor;
  final Color secondaryColor;

  /// What each end of the track gives up. See
  /// `SliderStyle.trackEndInset`.
  final double endInset;
  final double trackRadius;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) => SliderTrackGeometry.rectFor(
    parentBox: parentBox,
    offset: offset,
    sliderTheme: sliderTheme,
    endInset: endInset,
  );

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    if (rect.isEmpty) return;

    final radius = Radius.circular(trackRadius);
    final rtl = textDirection == TextDirection.rtl;

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = sliderTheme.inactiveTrackColor ?? inactiveColor,
    );

    void fill(double x, Color color) {
      final span = SliderMath.activeSpan(
        trackLeft: rect.left,
        trackRight: rect.right,
        thumbX: x.clamp(rect.left, rect.right),
        rtl: rtl,
      );
      if (span.end <= span.start) return;
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(span.start, rect.top, span.end, rect.bottom),
          radius,
        ),
        Paint()..color = color,
      );
    }

    if (secondaryOffset != null) {
      fill(
        secondaryOffset.dx,
        sliderTheme.secondaryActiveTrackColor ?? secondaryColor,
      );
    }
    fill(thumbCenter.dx, sliderTheme.activeTrackColor ?? activeColor);
  }
}

class _PlainRangeTrackShape extends RangeSliderTrackShape
    with BaseRangeSliderTrackShape {
  const _PlainRangeTrackShape({
    required this.inactiveColor,
    required this.activeColor,
    required this.endInset,
    required this.trackRadius,
  });

  final Color inactiveColor;
  final Color activeColor;

  /// What each end of the track gives up. See
  /// `SliderStyle.trackEndInset`.
  final double endInset;
  final double trackRadius;

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) => SliderTrackGeometry.rectFor(
    parentBox: parentBox,
    offset: offset,
    sliderTheme: sliderTheme,
    endInset: endInset,
  );

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    if (rect.isEmpty) return;

    final radius = Radius.circular(trackRadius);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = sliderTheme.inactiveTrackColor ?? inactiveColor,
    );

    // By POSITION, not by name: Material hands the thumbs back in
    // value order, so in Arabic the start thumb is the righthand one.
    final a = startThumbCenter.dx.clamp(rect.left, rect.right);
    final b = endThumbCenter.dx.clamp(rect.left, rect.right);
    final lo = a < b ? a : b;
    final hi = a < b ? b : a;
    if (hi <= lo) return;

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(lo, rect.top, hi, rect.bottom),
        radius,
      ),
      Paint()..color = sliderTheme.activeTrackColor ?? activeColor,
    );
  }
}
