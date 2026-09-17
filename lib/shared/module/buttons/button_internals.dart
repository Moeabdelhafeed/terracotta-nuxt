/// Internal shared utilities for button widgets. Not intended for direct external use.

// Dart imports:
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

// Flutter imports:
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// Project imports:
import '../../../core/a11y/contrast_checker.dart';
import '../../../core/animations/animation_presets.dart';
import '../../../core/theme/app_text_strut.dart';
import '../../../core/utils/loggers/logger.dart';
import '../marquee/global_marquee.dart';
import '../progress/global_progress.dart';
import 'button_models.dart';

// `marqueeLabel:` is part of the button API, so its config type
// travels with the internals every variant already imports.
export '../marquee/marquee_models.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const kHoverScale = 1.02;
const kHoverDuration = AppDurations.fast;
const kHoverElevationBoost = 2.0;
const kSlotSpacing = 8.0;
const kDefaultHorizontalPadding = 16.0;
const kLinearIndicatorWidth = 32.0;
const kLinearSegmentRatio = 0.45;
const kLinearStrokeWidth = 3.0;
const kCircularIndicatorSize = 20.0;
const kCircularStrokeWidth = 2.0;
const kDotSize = 5.0;
const kDotLiftHeight = 6.0;
const kDotSpacing = 2.0;
const kBlurSigma = 10.0;
const kBlurAlphaDefault = 0.2;
const kBlurAlphaHovered = 0.3;
const kBlurAlphaDisabled = 0.15;
const kBorderStrokeWidth = 2.0;

/// Focus ring drawn around transparent surfaces (text / outlined).
const kFocusRingWidth = 2.0;

/// How long the ring takes to draw itself around the perimeter. Kept
/// SHORT on purpose: a focus indicator that lags behind fast tabbing is
/// worse than one that just appears.
const kFocusRingDuration = AppDurations.fast;

/// Link underline geometry.
const kLinkUnderlineThickness = 1.5;
const kLinkUnderlineGap = 2.0;
const kBorderHighlightStrokeWidth = 2.5;
const kMorphDuration = AppDurations.quick;
const kMorphCurve = Curves.easeOut;

/// Material accessibility minimum touch target size.
const kMinTouchTarget = 48.0;

/// Default duration to display a completion result before auto-clearing.
const kCompletionDuration = Duration(milliseconds: 1500);

/// Size of the completion result icon (checkmark / X).
const kResultIconSize = 22.0;

/// Alpha applied to a button's BASE gradient when it is disabled and
/// the caller supplied no explicit `disabledStyle.backgroundGradient`.
/// An explicit disabled gradient is painted exactly as specified.
const kDisabledGradientAlpha = 0.38;

// ---------------------------------------------------------------------------
// Debug contrast reporter
// ---------------------------------------------------------------------------

/// Session-scoped dedupe so each offending combo logs exactly once.
final _reportedContrast = <int>{};

/// Debug-only WCAG check: warns (via Logger) when a button's rendered
/// text/icon color misses AA 4.5:1 against its opaque background —
/// low-contrast buttons (typically disabled states) are hard to spot
/// by eye but easy to grep in the log. No-op in release builds and
/// for translucent/gradient backgrounds (effective backdrop unknown).
void debugCheckButtonContrast({
  required String widgetName,
  required String label,
  required Color foreground,
  required Color background,
}) {
  if (!kDebugMode) return;
  if (background.a < 1.0) return;
  // Composite a translucent foreground over the background first —
  // scoring the raw colour rated faded loading labels as if they were
  // full strength, which is precisely when they are hardest to read.
  final effectiveFg = foreground.a >= 1.0
      ? foreground
      : Color.alphaBlend(foreground, background);
  final key = Object.hash(
    widgetName,
    effectiveFg.toARGB32(),
    background.toARGB32(),
  );
  if (_reportedContrast.contains(key)) return;
  final ratio = ContrastChecker.ratio(effectiveFg, background);
  if (ratio >= WcagLevel.aa.normalText) return;
  // Bounded: the key no longer includes the live label, but a long
  // session with many colour pairs should still not grow forever.
  if (_reportedContrast.length > 256) _reportedContrast.clear();
  _reportedContrast.add(key);
  Logger.m.w(
    '[Buttons] $widgetName "$label" contrast ${ratio.toStringAsFixed(2)}:1 '
    'is below WCAG AA 4.5:1 (fg=$effectiveFg, bg=$background). '
    'Raise the contrast or pass an explicit style.',
  );
}

// ---------------------------------------------------------------------------
// Gradient alpha utility
// ---------------------------------------------------------------------------

Gradient applyAlphaToGradient(Gradient gradient, double alpha) {
  if (gradient is LinearGradient) {
    return LinearGradient(
      colors: gradient.colors.map((c) => c.withValues(alpha: alpha)).toList(),
      stops: gradient.stops,
      begin: gradient.begin,
      end: gradient.end,
      tileMode: gradient.tileMode,
      transform: gradient.transform,
    );
  } else if (gradient is RadialGradient) {
    return RadialGradient(
      colors: gradient.colors.map((c) => c.withValues(alpha: alpha)).toList(),
      stops: gradient.stops,
      center: gradient.center,
      radius: gradient.radius,
      tileMode: gradient.tileMode,
      focal: gradient.focal,
      focalRadius: gradient.focalRadius,
      transform: gradient.transform,
    );
  } else if (gradient is SweepGradient) {
    return SweepGradient(
      colors: gradient.colors.map((c) => c.withValues(alpha: alpha)).toList(),
      stops: gradient.stops,
      center: gradient.center,
      startAngle: gradient.startAngle,
      endAngle: gradient.endAngle,
      tileMode: gradient.tileMode,
      transform: gradient.transform,
    );
  }
  assert(
    gradient is LinearGradient ||
        gradient is RadialGradient ||
        gradient is SweepGradient,
    'Unsupported gradient type: ${gradient.runtimeType}.',
  );
  return gradient;
}

// ---------------------------------------------------------------------------
// Shared hover behavior mixin
// ---------------------------------------------------------------------------

mixin HoverableMixin<T extends StatefulWidget> on State<T> {
  bool _isHovered = false;
  bool get isHovered => _isHovered;

  bool get isInteractive;
  ValueChanged<bool>? get onHoverCallback;

  void handleHoverEnter() {
    setState(() => _isHovered = true);
    onHoverCallback?.call(true);
  }

  void handleHoverExit() {
    setState(() => _isHovered = false);
    onHoverCallback?.call(false);
  }

  MouseCursor get effectiveCursor =>
      isInteractive ? SystemMouseCursors.click : SystemMouseCursors.forbidden;

  double get effectiveScale => _isHovered && isInteractive ? kHoverScale : 1.0;

  Widget buildHoverWrapper({required Widget child}) {
    // Reduced motion skips the decorative hover scale entirely —
    // hover feedback stays via cursor + elevation.
    final reduce = MediaQuery.disableAnimationsOf(context);
    return MouseRegion(
      cursor: effectiveCursor,
      onEnter: (_) => handleHoverEnter(),
      onExit: (_) => handleHoverExit(),
      child: AnimatedScale(
        scale: reduce ? 1.0 : effectiveScale,
        duration: reduce ? Duration.zero : kHoverDuration,
        curve: Curves.easeOut,
        child: child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Text size cache
// ---------------------------------------------------------------------------

const maxCacheSize = 100;
final textSizeCache = <TextSizeCacheKey, Size>{};

class TextSizeCacheKey {
  const TextSizeCacheKey({
    required this.text,
    required this.fontSize,
    this.strutFamily,
    required this.fontWeight,
    required this.fontFamily,
    required this.letterSpacing,
    required this.height,
    required this.fontStyle,
    required this.textScaler,
  });

  final String text;
  final double? fontSize;

  /// Family the strut's metrics come from — see [textSize].
  final String? strutFamily;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final double? letterSpacing;

  /// Line-height multiplier — omitting it collided two styles that
  /// differ ONLY in height, returning a stale (wrong-height) Size.
  final double? height;

  final FontStyle? fontStyle;

  /// Ambient text scaling. Must be part of the key: the same style
  /// measures taller once the user raises the system font size.
  final TextScaler textScaler;

  @override
  bool operator ==(Object other) =>
      other is TextSizeCacheKey &&
      other.strutFamily == strutFamily &&
      other.text == text &&
      other.fontSize == fontSize &&
      other.fontWeight == fontWeight &&
      other.fontFamily == fontFamily &&
      other.letterSpacing == letterSpacing &&
      other.height == height &&
      other.fontStyle == fontStyle &&
      other.textScaler == textScaler;

  @override
  int get hashCode => Object.hash(
    text,
    fontSize,
    strutFamily,
    fontWeight,
    fontFamily,
    letterSpacing,
    height,
    fontStyle,
    textScaler,
  );
}

/// Measures [text] under [style] at [textScaler]. Callers MUST pass the
/// ambient scaler (`MediaQuery.textScalerOf(context)`) — button box
/// heights derive from this, so ignoring it clips the label once the
/// user raises the system font size.
///
/// It measures WITH the same strut the label renders with, and that is
/// the whole point. Without it the two disagreed: the rendered `Text`
/// took its line box from `AppTextStrut` (font-independent by design),
/// while this measurement took its own from whatever font the script
/// resolved to. Arabic falls back to a family with a deeper descent
/// than Inter, so the SAME button came out taller in Arabic than in
/// English while both labels reported the same height — which is
/// exactly how it was reported.
Size textSize(
  String text,
  TextStyle style, {
  TextScaler textScaler = TextScaler.noScaling,
}) {
  final strut = AppTextStrut.forStyle(style);
  final key = TextSizeCacheKey(
    text: text,
    fontSize: style.fontSize,
    fontWeight: style.fontWeight,
    fontFamily: style.fontFamily,
    letterSpacing: style.letterSpacing,
    height: style.height,
    fontStyle: style.fontStyle,
    textScaler: textScaler,
    // The strut's reference family is global and swappable (tests set
    // it), so a cached size from before a swap would be the old font's.
    strutFamily: strut?.fontFamily,
  );

  final cached = textSizeCache.remove(key);
  if (cached != null) {
    textSizeCache[key] = cached;
    return cached;
  }

  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    strutStyle: strut,
    maxLines: 1,
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout(minWidth: 0, maxWidth: double.infinity);
  final size = painter.size;
  // TextPainter holds native resources until disposed.
  painter.dispose();

  while (textSizeCache.length >= maxCacheSize) {
    textSizeCache.remove(textSizeCache.keys.first);
  }
  textSizeCache[key] = size;
  return size;
}

// ---------------------------------------------------------------------------
// Resolved data classes
// ---------------------------------------------------------------------------

class ResolvedColors {
  const ResolvedColors({
    this.background,
    required this.foreground,
    this.disabledBackground,
    required this.disabledForeground,
    this.backgroundGradient,
    this.disabledBackgroundGradient,
  });
  final Color? background;
  final Color foreground;
  final Color? disabledBackground;
  final Color disabledForeground;
  final Gradient? backgroundGradient;
  final Gradient? disabledBackgroundGradient;
}

class ResolvedStyle {
  const ResolvedStyle({required this.textStyle, required this.text});
  final TextStyle textStyle;
  final String text;
}

class ResolvedSize {
  const ResolvedSize({this.width, this.height});
  final double? width;
  final double? height;
}

class ResolvedDecoration {
  const ResolvedDecoration({
    required this.borderRadius,
    this.padding,
    this.elevation,
    this.shadowColor,
    this.border,
    this.borderGradient,
  });
  final BorderRadiusGeometry borderRadius;
  final EdgeInsetsGeometry? padding;
  final double? elevation;
  final Color? shadowColor;
  final BorderSide? border;
  final Gradient? borderGradient;
}

class ResolvedSlots {
  const ResolvedSlots({this.trailing, this.leading});
  final Widget? trailing;
  final Widget? leading;
}

// ---------------------------------------------------------------------------
// Animated button content
// ---------------------------------------------------------------------------

class AnimatedButtonContent extends StatelessWidget {
  const AnimatedButtonContent({
    super.key,
    required this.slots,
    required this.style,
    required this.morphDuration,
    required this.morphCurve,
    this.marquee,
    this.labelOverflow = LabelOverflow.marquee,
    this.slotsAtEdges = false,
    this.slotEdgeInset = kSlotSpacing,
  });

  /// Pin the slots to the button's edges and centre the label in the
  /// FULL width, instead of laying slot-label-slot out as one centred
  /// row.
  ///
  /// The row is right for a button whose icon belongs TO the label
  /// ("＋ Add"). This is for the other shape: a wide bar with the label
  /// in the middle and an affordance parked in the corner, where a
  /// centred row would slide the label off-centre by half the icon and
  /// move it again whenever the label's length changed.
  final bool slotsAtEdges;

  /// Distance from the button's edge to the slot, when [slotsAtEdges].
  final double slotEdgeInset;

  final ResolvedSlots slots;
  final ResolvedStyle style;
  final Duration morphDuration;
  final Curve morphCurve;

  /// Tuning for the label marquee. Null takes the defaults.
  ///
  /// Pause-on-hover/touch are forced OFF whatever is passed: those
  /// install gesture recognizers, and a pan recognizer inside a button
  /// competes with the button's own InkWell for taps.
  final MarqueeStyle? marquee;

  /// What the label does when it does not fit. See [LabelOverflow].
  final LabelOverflow labelOverflow;

  /// Stable identity for a slot.
  ///
  /// These used to be `ValueKey(slot.hashCode)` — identity hash, so any
  /// inline-constructed `leading:`/`trailing:` (and the per-build inline
  /// loading indicator) produced a NEW key on every ancestor rebuild and
  /// the AnimatedSwitcher restarted its crossfade each time. Callers who
  /// genuinely need a crossfade between two same-typed slots can pass a
  /// [Key] on the slot widget.
  static Key _slotKey(Widget? slot, String name) {
    if (slot == null) return ValueKey('$name-none');
    return slot.key ?? ValueKey('$name-${slot.runtimeType}');
  }

  Widget _label() {
    final label = AnimatedSwitcher(
      duration: morphDuration,
      switchInCurve: morphCurve,
      switchOutCurve: morphCurve,
      // No explicit style: inheriting from the AnimatedDefaultTextStyle
      // above is what makes colour and size changes actually animate.
      // Standardized metrics: without this the label's baseline sits at
      // a different fraction of the line box per font, so an Arabic
      // button reads as vertically off against its icon while the same
      // English button looks fine.
      child: AppTextStrut.nudge(
        style: style.textStyle,
        child: Text(
          style.text,
          key: ValueKey(style.text),
          strutStyle: AppTextStrut.forStyle(style.textStyle),
        ),
      ),
    );
    // ALWAYS Flexible. The content Row is mainAxisSize.min, so without
    // this the label is handed its natural width and a button squeezed
    // below that throws a RenderFlex overflow — the label had to be
    // shortened by hand. Flexible only bites when the button is
    // genuinely too narrow; a loosely-constrained button still grows to
    // fit and nothing changes.
    return Flexible(
      child: _AdaptiveLabel(
        text: style.text,
        textStyle: style.textStyle,
        overflow: labelOverflow,
        marquee: marquee,
        child: label,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = Directionality.of(context);

    // NO manual swap. The Row below is given the ambient textDirection,
    // so it already lays the first child at the reading START — right in
    // Arabic. Swapping here as well flipped it twice and put LEADING
    // icons on the wrong side for every RTL user.
    final startSlot = slots.leading;
    final endSlot = slots.trailing;

    return AnimatedDefaultTextStyle(
      style: style.textStyle,
      duration: morphDuration,
      curve: morphCurve,
      // Slots inherit the LABEL's colour. Without this a bare
      // `style.leading: Icon(...)` fell through to the ambient page
      // IconTheme (e.g. primary purple) and painted a coloured glyph
      // next to a white label on a filled button. Only the colour is
      // forced — size stays ambient so existing layouts don't shift,
      // and a slot that sets its own colour still wins.
      child: IconTheme.merge(
        data: IconThemeData(color: style.textStyle.color),
        child: slotsAtEdges
            ? _edgeLayout(startSlot, endSlot, textDirection)
            : Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: textDirection,
                children: [
                  AnimatedSwitcher(
                    duration: morphDuration,
                    switchInCurve: morphCurve,
                    switchOutCurve: morphCurve,
                    child: startSlot != null
                        ? Row(
                            key: _slotKey(startSlot, 'start'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              startSlot,
                              const SizedBox(width: kSlotSpacing),
                            ],
                          )
                        : const SizedBox.shrink(key: ValueKey('no-start')),
                  ),
                  _label(),
                  AnimatedSwitcher(
                    duration: morphDuration,
                    switchInCurve: morphCurve,
                    switchOutCurve: morphCurve,
                    child: endSlot != null
                        ? Row(
                            key: _slotKey(endSlot, 'end'),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: kSlotSpacing),
                              endSlot,
                            ],
                          )
                        : const SizedBox.shrink(key: ValueKey('no-end')),
                  ),
                ],
              ),
      ),
    );
  }

  /// Label centred in the whole box, slots pinned to the edges.
  ///
  /// `PositionedDirectional`, so "end" is the left in Arabic and the
  /// right in English from one description.
  Widget _edgeLayout(
    Widget? startSlot,
    Widget? endSlot,
    TextDirection textDirection,
  ) {
    return Stack(
      alignment: Alignment.center,
      textDirection: textDirection,
      children: [
        // A Row so the label keeps the Flexible it needs — a bare
        // Flexible outside a flex throws.
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: textDirection,
          children: [_label()],
        ),
        if (startSlot != null)
          PositionedDirectional(
            start: slotEdgeInset,
            top: 0,
            bottom: 0,
            child: Center(child: startSlot),
          ),
        if (endSlot != null)
          PositionedDirectional(
            end: slotEdgeInset,
            top: 0,
            bottom: 0,
            child: Center(child: endSlot),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Inline loading indicators
// ---------------------------------------------------------------------------

class LinearIndicator extends StatefulWidget {
  const LinearIndicator({super.key, required this.color});
  final Color color;

  @override
  State<LinearIndicator> createState() => _LinearIndicatorState();
}

class _LinearIndicatorState extends State<LinearIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => CustomPaint(
        size: const Size(kLinearIndicatorWidth, 0),
        painter: LinearPainter(progress: _ctrl.value, color: widget.color),
      ),
    );
  }
}

class LinearPainter extends CustomPainter {
  LinearPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
      Offset.zero,
      Offset(size.width, 0),
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..strokeWidth = kLinearStrokeWidth
        ..strokeCap = StrokeCap.round,
    );
    final segLen = size.width * kLinearSegmentRatio;
    final start = (size.width + segLen) * progress - segLen;
    canvas.drawLine(
      Offset(start.clamp(0.0, size.width), 0),
      Offset((start + segLen).clamp(0.0, size.width), 0),
      Paint()
        ..color = color
        ..strokeWidth = kLinearStrokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(LinearPainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------

class CircularIndicator extends StatelessWidget {
  const CircularIndicator({super.key, required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kCircularIndicatorSize,
      height: kCircularIndicatorSize,
      child: GlobalProgress.loading(
        type: ProgressType.circular,
        style: ProgressStyle(thickness: kCircularStrokeWidth, color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class DotsIndicator extends StatefulWidget {
  const DotsIndicator({super.key, required this.color});
  final Color color;

  @override
  State<DotsIndicator> createState() => _DotsIndicatorState();
}

class _DotsIndicatorState extends State<DotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  double _liftFor(int index) {
    final phase = (_ctrl.value - (index * 0.2)) % 1.0;
    if (phase >= 0 && phase < 0.5) {
      return math.sin(phase * 2 * math.pi);
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(3, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: kDotSpacing),
            child: Transform.translate(
              offset: Offset(0, -_liftFor(i) * kDotLiftHeight),
              child: Container(
                width: kDotSize,
                height: kDotSize,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Border loading overlay
// ---------------------------------------------------------------------------

class BorderLoadingOverlay extends StatefulWidget {
  const BorderLoadingOverlay({
    super.key,
    required this.color,
    required this.borderRadius,
  });

  final Color color;
  final BorderRadius borderRadius;

  @override
  State<BorderLoadingOverlay> createState() => _BorderLoadingOverlayState();
}

class _BorderLoadingOverlayState extends State<BorderLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  Size? _cachedSize;
  PathMetric? _cachedMetric;

  PathMetric? _getMetric(Size size) {
    if (size.width <= 0 || size.height <= 0) return null;
    if (_cachedSize != size || _cachedMetric == null) {
      final rRect = widget.borderRadius.toRRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
      );
      final metrics = (Path()..addRRect(rRect)).computeMetrics();
      final first = metrics.firstOrNull;
      if (first == null) return null;
      _cachedMetric = first;
      _cachedSize = size;
    }
    return _cachedMetric;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => CustomPaint(
        painter: BorderTracePainter(
          progress: _ctrl.value,
          color: widget.color,
          borderRadius: widget.borderRadius,
          getMetric: _getMetric,
        ),
      ),
    );
  }
}

class BorderTracePainter extends CustomPainter {
  BorderTracePainter({
    required this.progress,
    required this.color,
    required this.borderRadius,
    required this.getMetric,
  });

  final double progress;
  final Color color;
  final BorderRadius borderRadius;
  final PathMetric? Function(Size size) getMetric;

  static const _segmentFraction = 0.35;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rRect = borderRadius.toRRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
    );

    canvas.drawRRect(
      rRect,
      Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = kBorderStrokeWidth
        ..strokeCap = StrokeCap.round,
    );

    final metric = getMetric(size);
    if (metric == null) return;

    final total = metric.length;
    final segLen = total * _segmentFraction;
    final start = progress * total;
    final end = start + segLen;

    final highlightPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = kBorderHighlightStrokeWidth
      ..strokeCap = StrokeCap.round;

    if (end <= total) {
      canvas.drawPath(metric.extractPath(start, end), highlightPaint);
    } else {
      canvas.drawPath(metric.extractPath(start, total), highlightPaint);
      canvas.drawPath(metric.extractPath(0, end - total), highlightPaint);
    }
  }

  @override
  bool shouldRepaint(BorderTracePainter old) => old.progress != progress;
}

// ---------------------------------------------------------------------------
// Gradient border painter
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Shared button surface
// ---------------------------------------------------------------------------

/// How [ButtonSurface] paints its background.
enum ButtonSurfaceKind {
  /// Opaque color + elevation (elevated / outlined / icon).
  solid,

  /// Gradient fill + elevation.
  gradient,

  /// Frosted backdrop blur.
  blur,

  /// No painted background, no elevation (text button).
  flat,
}

/// The single painted, interactive surface behind every `Global*Button`.
///
/// Replaces five near-identical private widgets that used to be
/// copy-pasted across the four variant files (`_RegularButton`,
/// `_GradientButton`, `_BlurButton`, `_TextButtonBody`,
/// `_IconButtonBody`). Behaviour fixes land here ONCE instead of four
/// times — which is exactly how the blur variant silently lost
/// `autofocus` and its border in the first place.
///
/// The surface paints what it is given: [ResolvedColors] must already
/// carry the final disabled/enabled gradient (it is NOT dimmed here —
/// dimming a caller's explicit `disabledStyle.backgroundGradient` was a
/// bug).
class ButtonSurface extends StatefulWidget {
  const ButtonSurface({
    super.key,
    required this.kind,
    required this.colors,
    required this.decoration,
    required this.resolvedRadius,
    required this.content,
    required this.enabled,
    required this.isLoading,
    required this.morphDuration,
    required this.morphCurve,
    this.onPressed,
    this.onLongPress,
    this.onDisabledTap,
    this.onHover,
    this.onFocusChange,
    this.onFocusVisibilityChanged,
    this.focusNode,
    this.autofocus = false,
    this.padding,
    this.showFocusRing = true,
  });

  final ButtonSurfaceKind kind;
  final ResolvedColors colors;
  final ResolvedDecoration decoration;
  final BorderRadius resolvedRadius;
  final Widget content;
  final bool enabled;
  final bool isLoading;
  final Duration morphDuration;
  final Curve morphCurve;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  /// Fired on tap while the surface is NOT interactive. Rippling from
  /// THIS InkWell (instead of an external wrapper) is what makes the
  /// splash visible — a wrapper's transparency Material sits BEHIND the
  /// opaque surface, so its ink never showed.
  final VoidCallback? onDisabledTap;
  final ValueChanged<bool>? onHover;
  final ValueChanged<bool>? onFocusChange;

  /// Fires with whether a focus RING should be visible — i.e. focused
  /// AND not focused by a pointer press. Lets a variant paint its own
  /// keyboard-focus affordance (the link underline) off the same signal
  /// instead of re-deriving it.
  final ValueChanged<bool>? onFocusVisibilityChanged;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Inner padding. `null` centres the content instead (icon buttons).
  final EdgeInsetsGeometry? padding;

  /// Draw the keyboard-focus ring on transparent surfaces. `false` for
  /// presentations that carry their own focus affordance — a link's
  /// underline IS its focus cue, and a ring around a zero-padding label
  /// crowds the glyphs.
  final bool showFocusRing;

  @override
  State<ButtonSurface> createState() => _ButtonSurfaceState();
}

class _ButtonSurfaceState extends State<ButtonSurface> with HoverableMixin {
  /// Owned only when the caller supplied none.
  FocusNode? _internalFocusNode;

  /// The node the ring reads. Reading `hasFocus` off the node at BUILD
  /// time — instead of mirroring it into State from `onFocusChange` —
  /// is what keeps the ring in step: the mirrored copy updated a frame
  /// later than the node itself, so the previous button stayed ringed
  /// until the NEXT keypress forced another rebuild.
  FocusNode get _focusNode =>
      widget.focusNode ??
      (_internalFocusNode ??= FocusNode(debugLabel: 'ButtonSurface'));

  /// True when the CURRENT focus arrived from a pointer press on this
  /// button rather than from keyboard traversal.
  ///
  /// Tapping a button focuses it, and a focus ring on a tapped button
  /// reads as "still focused" long after the user moved on. The obvious
  /// gate — `FocusManager.highlightMode` — is not dependable here: on
  /// Android hardware keys forwarded by the IME are deliberately ignored
  /// for highlight purposes, so Tab would move focus while the ring
  /// never appeared. Tracking the pointer directly is local, exact, and
  /// platform-independent.
  bool _focusFromPointer = false;

  bool get _focusVisible => _focusNode.hasFocus && !_focusFromPointer;

  @override
  bool get isInteractive => widget.enabled && !widget.isLoading;

  /// A surface with no opaque fill of its own (text / outlined, and any
  /// caller that made the background translucent).
  bool get _isTransparentSurface {
    if (widget.colors.backgroundGradient != null) return false;
    final bg = widget.enabled
        ? widget.colors.background
        : widget.colors.disabledBackground;
    return bg == null || bg.a < 1.0;
  }

  void _handleFocusChange(bool value) {
    // Losing focus clears the pointer flag, so the NEXT focus — a Tab,
    // say — paints its ring normally. No setState needed: the ring
    // rebuilds off the node, and this only affects the next transition.
    if (!value) _focusFromPointer = false;
    widget.onFocusVisibilityChanged?.call(value && !_focusFromPointer);
    widget.onFocusChange?.call(value);
  }

  void _handleTapDown(TapDownDetails _) {
    if (_focusFromPointer) return;
    setState(() => _focusFromPointer = true);
    widget.onFocusVisibilityChanged?.call(false);
  }

  @override
  void dispose() {
    _internalFocusNode?.dispose();
    super.dispose();
  }

  @override
  ValueChanged<bool>? get onHoverCallback => widget.onHover;

  double get _elevation {
    final base = widget.decoration.elevation ?? 0;
    return isHovered && isInteractive ? base + kHoverElevationBoost : base;
  }

  /// Gradient for the current enabled state. Already final — callers
  /// resolve the disabled variant, so no alpha is applied here.
  Gradient? get _gradient => widget.enabled
      ? widget.colors.backgroundGradient
      : widget.colors.disabledBackgroundGradient;

  Widget _body() {
    if (widget.padding == null) return Center(child: widget.content);
    return AnimatedPadding(
      duration: widget.morphDuration,
      curve: widget.morphCurve,
      padding: widget.padding!.resolve(Directionality.of(context)),
      child: widget.content,
    );
  }

  /// Pressing a disabled surface still ripples — feedback that the tap
  /// LANDED, even when nothing will happen. The splash is muted (drawn
  /// from the disabled foreground) so the button does not read as
  /// active.
  static void _disabledFeedbackNoop() {}

  Widget _ink(Widget child) {
    final disabled = !isInteractive;
    return InkWell(
      autofocus: widget.autofocus,
      focusNode: _focusNode,
      onFocusChange: _handleFocusChange,
      // Keyboard must only reach a disabled button when the caller
      // opted into onDisabledPressed — a bare feedback ripple is not
      // an action and should not join the tab order.
      canRequestFocus: isInteractive || widget.onDisabledTap != null,
      // Focus feedback is surface-dependent. On an OPAQUE fill the
      // default ~12% overlay disappears, so it is pushed to 28% of the
      // foreground. On a transparent surface that same 28% paints a
      // solid slab where there was no button shape at all — a text
      // button starts looking filled. Those get a ring instead (drawn
      // in [_withFocusRing]), which is also the stronger WCAG 2.2
      // "Focus Appearance" answer: an outline against the page beats a
      // tint blended into it.
      onTapDown: _handleTapDown,
      focusColor: _isTransparentSurface
          ? Colors.transparent
          : widget.colors.foreground.withValues(alpha: 0.28),
      splashColor: disabled
          ? widget.colors.disabledForeground.withValues(alpha: 0.16)
          : null,
      highlightColor: disabled
          ? widget.colors.disabledForeground.withValues(alpha: 0.08)
          : null,
      onTap: isInteractive
          ? widget.onPressed
          : (widget.onDisabledTap ?? _disabledFeedbackNoop),
      onLongPress: isInteractive ? widget.onLongPress : null,
      borderRadius: widget.resolvedRadius,
      child: child,
    );
  }

  /// Focus ring for transparent surfaces. Painted as a FOREGROUND
  /// decoration so it overlays the content without changing layout —
  /// a real border would resize the button on focus and shift the row.
  Widget _withFocusRing(Widget child) {
    if (!_isTransparentSurface || !widget.showFocusRing) return child;
    // Rebuilds when the NODE says so, and re-reads it — never a
    // mirrored copy that can be a frame behind. AnimatedFocusRing stays
    // mounted either way: wrapping conditionally would change the tree
    // SHAPE here and remount the whole content subtree, restarting any
    // animation inside it.
    return ListenableBuilder(
      listenable: _focusNode,
      builder: (context, inner) => AnimatedFocusRing(
        visible: _focusVisible,
        color: widget.colors.foreground,
        borderRadius: widget.resolvedRadius,
        child: inner!,
      ),
      child: child,
    );
  }

  /// Solid border wrap. Skipped when a gradient border is set — that one
  /// is painted by the owning widget's top-level Stack.
  Widget _withBorder(Widget child) {
    final border = widget.decoration.border;
    if (widget.decoration.borderGradient != null || border == null) {
      return child;
    }
    return AnimatedContainer(
      duration: widget.morphDuration,
      curve: widget.morphCurve,
      decoration: BoxDecoration(
        borderRadius: widget.resolvedRadius,
        border: Border.fromBorderSide(border),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget surface;

    switch (widget.kind) {
      case ButtonSurfaceKind.flat:
        surface = Material(
          color: Colors.transparent,
          borderRadius: widget.resolvedRadius,
          child: _ink(_body()),
        );

      case ButtonSurfaceKind.gradient:
        surface = Material(
          elevation: _elevation,
          shadowColor: widget.decoration.shadowColor ?? Colors.black,
          borderRadius: widget.resolvedRadius,
          clipBehavior: Clip.antiAlias,
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: _gradient,
              borderRadius: widget.resolvedRadius,
            ),
            child: _ink(_body()),
          ),
        );

      case ButtonSurfaceKind.blur:
        final gradient = _gradient;
        // Hover brightening must respect interactivity — a disabled
        // blur button used to brighten on hover.
        final hoverAlpha = (isHovered && isInteractive)
            ? kBlurAlphaHovered
            : kBlurAlphaDefault;
        final decoration = gradient != null
            ? BoxDecoration(
                gradient: applyAlphaToGradient(
                  gradient,
                  widget.enabled ? hoverAlpha : kBlurAlphaDisabled,
                ),
                borderRadius: widget.resolvedRadius,
              )
            : BoxDecoration(
                color: widget.enabled
                    ? widget.colors.background!.withValues(alpha: hoverAlpha)
                    : widget.colors.disabledBackground!.withValues(
                        alpha: kBlurAlphaDisabled,
                      ),
                borderRadius: widget.resolvedRadius,
              );
        surface = ClipRRect(
          borderRadius: widget.resolvedRadius,
          // WITH A SAVE LAYER: a plain antialiased clip does not
          // contain a `BackdropFilter`, so the rounded corners come
          // back SQUARE.
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: kBlurSigma, sigmaY: kBlurSigma),
            child: AnimatedContainer(
              duration: widget.morphDuration,
              curve: widget.morphCurve,
              decoration: decoration,
              child: Material(
                color: Colors.transparent,
                child: _ink(_body()),
              ),
            ),
          ),
        );

      case ButtonSurfaceKind.solid:
        surface = AnimatedPhysicalModel(
          duration: widget.morphDuration,
          curve: widget.morphCurve,
          shape: BoxShape.rectangle,
          borderRadius: widget.resolvedRadius,
          elevation: _elevation,
          color: widget.enabled
              ? widget.colors.background!
              : widget.colors.disabledBackground!,
          shadowColor: widget.decoration.shadowColor ?? Colors.black,
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: _ink(_body()),
          ),
        );
    }

    return buildHoverWrapper(child: _withFocusRing(_withBorder(surface)));
  }
}

// ---------------------------------------------------------------------------
// Shared behaviour: completion result + debounce
// ---------------------------------------------------------------------------

/// Completion-flash and debounce machinery shared by all four button
/// variants. Previously copy-pasted verbatim into each State class,
/// which is how the two bugs fixed below survived in quadruplicate.
mixin ButtonBehaviorMixin<W extends StatefulWidget> on State<W> {
  DateTime? _lastPressTime;
  DateTime? _lastLongPressTime;
  Timer? _resultTimer;

  /// Whether a completion flash is currently on screen.
  bool showingResult = false;
  ButtonResult activeResult = ButtonResult.none;

  /// Call from `initState` and from `didUpdateWidget` whenever `result`
  /// OR `isLoading` changes.
  ///
  /// The countdown only runs while the flash is actually VISIBLE. Every
  /// variant gives the loading skin display priority over the result,
  /// so starting the timer during loading burned the whole window
  /// behind the spinner — and fired [onResultShown] for a flash the
  /// user never saw. Here the flash is held until loading clears.
  void syncButtonResult({
    required ButtonResult result,
    required bool isLoading,
    required Duration completionDuration,
    required VoidCallback? onResultShown,
  }) {
    if (result == ButtonResult.none) {
      _resultTimer?.cancel();
      _resultTimer = null;
      showingResult = false;
      activeResult = ButtonResult.none;
      return;
    }

    // A NEW result value must get its own full window, even if the
    // previous flash is still counting down.
    final isNewResult = activeResult != result;
    showingResult = true;
    activeResult = result;

    if (isLoading) {
      // Hold — the flash is not visible yet.
      _resultTimer?.cancel();
      _resultTimer = null;
      return;
    }
    // Keep a running window only while it belongs to THIS result;
    // otherwise success -> error would inherit success's remainder and
    // wipe the error flash after the leftover milliseconds.
    if (_resultTimer != null && !isNewResult) return;

    _resultTimer?.cancel();
    _resultTimer = Timer(completionDuration, () {
      // Clear FIRST: leaving a spent Timer in the field made the guard
      // above reject every later flash for the widget's lifetime.
      _resultTimer = null;
      if (!mounted) return;
      setState(() {
        showingResult = false;
        activeResult = ButtonResult.none;
      });
      onResultShown?.call();
    });
  }

  /// Cancels the pending flash timer. Call from `dispose`.
  void disposeButtonBehavior() {
    _resultTimer?.cancel();
    _resultTimer = null;
  }

  /// Wraps [original] in the debounce window and the haptic gate.
  ///
  /// Tap and long-press keep INDEPENDENT windows: they are different
  /// gestures, and sharing one timestamp meant a tap silently swallowed
  /// a following legitimate long-press. The debounce exists to stop
  /// double-activation of the SAME action.
  VoidCallback? debouncedCallback(
    VoidCallback? original, {
    required Duration? debounce,
    required bool haptic,
    bool isLongPress = false,
  }) {
    if (original == null) return null;
    return () {
      final now = DateTime.now();
      final last = isLongPress ? _lastLongPressTime : _lastPressTime;
      if (debounce != null && last != null && now.difference(last) < debounce) {
        return;
      }
      if (isLongPress) {
        _lastLongPressTime = now;
      } else {
        _lastPressTime = now;
      }
      if (haptic) {
        if (isLongPress) {
          HapticFeedback.mediumImpact();
        } else {
          HapticFeedback.lightImpact();
        }
      }
      original();
    };
  }
}

// ---------------------------------------------------------------------------
// Minimum touch target
// ---------------------------------------------------------------------------

/// Expands the HIT AREA to at least [minSize] without stretching what
/// the child paints.
///
/// Every variant's `enforceMinTouchTarget` doc promised "the visual
/// button can be smaller; the hit area expands transparently", but the
/// implementation was `ConstrainedBox(minWidth: 48, minHeight: 48)` —
/// a min-constraint propagates INTO the child, so a 32dp icon button
/// painted a 48x48 block and adopters turned the flag off, losing the
/// accessible target entirely. This mirrors Material's own
/// `_InputPadding`.
class MinTouchTarget extends SingleChildRenderObjectWidget {
  const MinTouchTarget({super.key, required this.minSize, super.child});

  final Size minSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMinTouchTarget(minSize);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderMinTouchTarget).minSize = minSize;
  }
}

class _RenderMinTouchTarget extends RenderShiftedBox {
  _RenderMinTouchTarget(this._minSize) : super(null);

  Size _minSize;
  Size get minSize => _minSize;
  set minSize(Size value) {
    if (_minSize == value) return;
    _minSize = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) => math.max(
    child == null ? 0.0 : child!.getMinIntrinsicWidth(height),
    minSize.width,
  );

  @override
  double computeMinIntrinsicHeight(double width) => math.max(
    child == null ? 0.0 : child!.getMinIntrinsicHeight(width),
    minSize.height,
  );

  @override
  double computeMaxIntrinsicWidth(double height) => math.max(
    child == null ? 0.0 : child!.getMaxIntrinsicWidth(height),
    minSize.width,
  );

  @override
  double computeMaxIntrinsicHeight(double width) => math.max(
    child == null ? 0.0 : child!.getMaxIntrinsicHeight(width),
    minSize.height,
  );

  Size _layout(BoxConstraints constraints, ChildLayouter layoutChild) {
    final child = this.child;
    if (child == null) return Size.zero;
    // Loosen so the child keeps its own (possibly smaller) size.
    final childSize = layoutChild(child, constraints.loosen());
    return constraints.constrain(
      Size(
        math.max(childSize.width, minSize.width),
        math.max(childSize.height, minSize.height),
      ),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, ChildLayoutHelper.dryLayoutChild);

  @override
  void performLayout() {
    size = _layout(constraints, ChildLayoutHelper.layoutChild);
    final child = this.child;
    if (child == null) return;
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      size - child.size as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // MUST come first: without it the forced-centre fallback below
    // claims taps that landed outside this box entirely, so whichever
    // button paints last swallows every tap on the page.
    if (!(Offset.zero & size).contains(position)) return false;
    if (super.hitTest(result, position: position)) return true;
    if (child == null) return false;
    // A tap landing in the transparent margin is routed to the child's
    // centre so the padded area is genuinely tappable.
    final center = child!.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, position) => child!.hitTest(result, position: center),
    );
  }
}

// ---------------------------------------------------------------------------
// Link underline
// ---------------------------------------------------------------------------

/// Rules a line under [child], growing from the leading edge to the
/// trailing one.
///
/// Direction-aware by construction: the growth is anchored with
/// `AlignmentDirectional.centerStart`, so it runs left→right in LTR and
/// right→left in Arabic without a branch.
///
/// The rule is laid out as a sibling of the label rather than as a
/// `TextDecoration`, because a text decoration cannot be animated —
/// it is either on or off.
class LinkUnderlineDecorator extends StatelessWidget {
  const LinkUnderlineDecorator({
    required this.child,
    required this.mode,
    required this.active,
    required this.color,
    required this.duration,
    required this.curve,
    super.key,
  });

  final Widget child;
  final LinkUnderline mode;

  /// Hovered or focused — drives [LinkUnderline.onHover].
  final bool active;
  final Color color;
  final Duration duration;
  final Curve curve;

  double get _target => switch (mode) {
    LinkUnderline.always => 1,
    LinkUnderline.onHover => active ? 1 : 0,
    LinkUnderline.never => 0,
  };

  @override
  Widget build(BuildContext context) {
    // A Stack sized by its non-positioned child: the LABEL decides the
    // box and the rule spans whatever that turns out to be. (A Column
    // with CrossAxisAlignment.stretch would have made the button claim
    // the full available width instead of hugging its text.) The bottom
    // padding reserves the rule's band in every mode, so the label never
    // shifts as the line arrives.
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            bottom: kLinkUnderlineGap + kLinkUnderlineThickness,
          ),
          child: child,
        ),
        Positioned.directional(
          textDirection: Directionality.of(context),
          start: 0,
          end: 0,
          bottom: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _target),
            duration: duration,
            curve: curve,
            builder: (context, t, _) => SizedBox(
              height: kLinkUnderlineThickness,
              child: t <= 0
                  ? null
                  : FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: t.clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(
                            kLinkUnderlineThickness,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Focus ring
// ---------------------------------------------------------------------------

/// Draws the focus ring by tracing it around the perimeter once, then
/// holding it complete.
///
/// Always mounted (only its painter changes) — conditionally wrapping the
/// content would remount the whole subtree and restart any animation
/// inside it.
class AnimatedFocusRing extends StatefulWidget {
  const AnimatedFocusRing({
    required this.child,
    required this.visible,
    required this.color,
    required this.borderRadius,
    super.key,
  });

  final Widget child;
  final bool visible;
  final Color color;
  final BorderRadius borderRadius;

  @override
  State<AnimatedFocusRing> createState() => _AnimatedFocusRingState();
}

class _AnimatedFocusRingState extends State<AnimatedFocusRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: kFocusRingDuration,
    value: widget.visible ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant AnimatedFocusRing old) {
    super.didUpdateWidget(old);
    if (widget.visible == old.visible) return;
    if (!widget.visible) {
      // Vanish immediately. Un-drawing takes time during which a ring
      // still sits on a control that no longer has focus.
      _ctrl.value = 0;
    } else if (MediaQuery.disableAnimationsOf(context)) {
      _ctrl.value = 1;
    } else {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) => CustomPaint(
        foregroundPainter: FocusRingPainter(
          progress: _ctrl.value,
          color: widget.color,
          borderRadius: widget.borderRadius,
          // Trace away from the leading edge, so it reads the same way
          // the link underline does in either direction.
          clockwise: Directionality.of(context) == TextDirection.ltr,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Strokes `progress` of the way around a rounded rect.
class FocusRingPainter extends CustomPainter {
  const FocusRingPainter({
    required this.progress,
    required this.color,
    required this.borderRadius,
    required this.clockwise,
  });

  final double progress;
  final Color color;
  final BorderRadius borderRadius;
  final bool clockwise;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || size.isEmpty) return;
    // Inset by half the stroke so the ring sits INSIDE the box and does
    // not get clipped by an ancestor.
    final rect = Offset.zero & size;
    final rRect = borderRadius.toRRect(rect).deflate(kFocusRingWidth / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = kFocusRingWidth
      ..strokeCap = StrokeCap.round;

    if (progress >= 1) {
      canvas.drawRRect(rRect, paint);
      return;
    }

    final metric = (Path()..addRRect(rRect)).computeMetrics().firstOrNull;
    if (metric == null) return;
    final total = metric.length;
    canvas.drawPath(
      clockwise
          ? metric.extractPath(0, total * progress)
          : metric.extractPath(total * (1 - progress), total),
      paint,
    );
  }

  @override
  bool shouldRepaint(FocusRingPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.clockwise != clockwise ||
      old.borderRadius != borderRadius;
}

// ---------------------------------------------------------------------------
// Adaptive label
// ---------------------------------------------------------------------------

/// Reports, at layout time, how much width its child is being GIVEN.
///
/// `LayoutBuilder` is the obvious tool here and is the wrong one: it
/// refuses to answer intrinsic queries, so one button inside an
/// `IntrinsicWidth` — which every sheet action row uses — throws
/// "LayoutBuilder does not support returning intrinsic dimensions".
/// A proxy box forwards intrinsics to its child untouched and still
/// sees the incoming constraints.
class _WidthProbe extends SingleChildRenderObjectWidget {
  const _WidthProbe({required this.onWidth, required super.child});

  final ValueChanged<double> onWidth;

  @override
  _RenderWidthProbe createRenderObject(BuildContext context) =>
      _RenderWidthProbe(onWidth);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderWidthProbe renderObject,
  ) {
    renderObject.onWidth = onWidth;
  }
}

class _RenderWidthProbe extends RenderProxyBox {
  _RenderWidthProbe(this.onWidth);

  ValueChanged<double> onWidth;

  @override
  void performLayout() {
    super.performLayout();
    onWidth(constraints.maxWidth);
  }
}

/// Decides whether the label needs help, and only then wraps it.
///
/// The marquee could simply be left mounted always: it has its own
/// overflow gate and does nothing when the content fits. Two reasons
/// not to. It would put a `SingleChildScrollView` — a Scrollable, a
/// viewport, a ScrollPosition — under EVERY button in the app for the
/// sake of the rare one that overflows. And a horizontally-scrolling
/// viewport reports an intrinsic width of ZERO, so every button inside
/// an `IntrinsicWidth` would collapse.
///
/// So the label renders plainly until it is measured as too wide.
/// [textSize] is memoized, so after the first paint of a given
/// string+style the check is a map lookup.
class _AdaptiveLabel extends StatefulWidget {
  const _AdaptiveLabel({
    required this.text,
    required this.textStyle,
    required this.overflow,
    required this.marquee,
    required this.child,
  });

  final String text;
  final TextStyle textStyle;
  final LabelOverflow overflow;
  final MarqueeStyle? marquee;
  final Widget child;

  @override
  State<_AdaptiveLabel> createState() => _AdaptiveLabelState();
}

class _AdaptiveLabelState extends State<_AdaptiveLabel> {
  /// Unbounded until the first layout says otherwise — and unbounded
  /// means the button grows to fit, so nothing is hidden and there is
  /// nothing to solve.
  double _available = double.infinity;
  bool _pending = false;

  void _report(double width) {
    if (width == _available) return;
    _available = width;
    if (_pending) return;
    _pending = true;
    // This arrives from inside layout, where rebuilding is illegal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pending = false;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final natural = textSize(
      widget.text,
      widget.textStyle,
      // The scaler is part of the measurement AND of the cache key.
      // Measuring unscaled reports "fits" for a label about to be
      // clipped once the user raises the system font size.
      textScaler: MediaQuery.textScalerOf(context),
    ).width;

    // Half a pixel of slack: a label measured at exactly the available
    // width is not overflowing, and treating it as such arms a marquee
    // with nowhere to scroll.
    final overflows = _available.isFinite && natural > _available + 0.5;

    // A label scrolling forever is exactly what disableAnimations exists
    // to stop, so reduced motion truncates instead. The full string
    // still reaches assistive tech via the button's Semantics label.
    final wantsMarquee =
        overflows &&
        widget.overflow == LabelOverflow.marquee &&
        !MediaQuery.disableAnimationsOf(context);

    return _WidthProbe(
      onWidth: _report,
      child: wantsMarquee
          ? GlobalMarquee(
              style: (widget.marquee ?? const MarqueeStyle()).copyWith(
                pauseOnHover: false,
                pauseOnTouch: false,
              ),
              semanticLabel: widget.text,
              child: widget.child,
            )
          // Text with no `overflow` of its own inherits it from here, so
          // the label itself needs no rebuilding.
          : DefaultTextStyle.merge(
              overflow: TextOverflow.ellipsis,
              child: widget.child,
            ),
    );
  }
}
