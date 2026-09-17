import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/localization/number_formatter.dart';
import '../../../core/tokens/extensions.dart';
import 'slider_models.dart';
import 'slider_shapes.dart';
import 'slider_style.dart';
import 'theme/slider_theme.dart';

export 'circular_slider_math.dart';
export 'global_circular_slider.dart';
export 'global_trim_slider.dart';
export 'slider_models.dart';
// The track shapes are public: the video player's seek bar builds its
// own `SliderThemeData` and reaches for the segmented one directly.
export 'slider_shapes.dart';
export 'slider_style.dart';
export 'theme/slider_theme.dart';

/// A slider with an optional label, a value badge and end labels.
///
/// [GlobalSlider] takes one value; [GlobalSlider.range] takes two.
class GlobalSlider extends StatefulWidget {
  const GlobalSlider({
    super.key,
    this.label,
    required this.min,
    required this.max,
    required double this.value,
    required ValueChanged<double> this.onChanged,
    this.divisions,
    this.minLabel,
    this.maxLabel,
    this.enabled = true,
    this.valueFormatter,
    this.semanticFormatter,
    this.showMinMaxLabels = true,
    this.showValue = true,
    this.segments = const [],
    this.stepLabels,
    this.secondaryValue,
    this.leading,
    this.style,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticLabel,
  }) : rangeValues = null,
       onRangeChanged = null,
       axis = Axis.horizontal,
       extent = defaultExtent,
       assert(min < max, 'min ($min) must be below max ($max)'),
       assert(
         divisions == null || divisions > 0,
         'divisions must be positive; null is a continuous slider',
       );

  /// Up is MORE.
  ///
  /// A volume or brightness column. Material ships no vertical slider,
  /// so the track is the horizontal one turned a quarter — which is
  /// what every implementation of this does, and it keeps the drag
  /// maths, the divisions, the value indicator and the semantics
  /// actions rather than reinventing all four.
  const GlobalSlider.vertical({
    super.key,
    this.label,
    required this.min,
    required this.max,
    required double this.value,
    required ValueChanged<double> this.onChanged,
    this.extent = defaultExtent,
    this.divisions,
    this.minLabel,
    this.maxLabel,
    this.enabled = true,
    this.valueFormatter,
    this.semanticFormatter,
    this.showMinMaxLabels = true,
    this.showValue = true,
    this.segments = const [],
    this.secondaryValue,
    this.leading,
    this.style,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticLabel,
  }) : rangeValues = null,
       onRangeChanged = null,
       stepLabels = null,
       axis = Axis.vertical,
       assert(min < max, 'min ($min) must be below max ($max)'),
       assert(
         divisions == null || divisions > 0,
         'divisions must be positive; null is a continuous slider',
       );

  /// Two thumbs and a span between them.
  const GlobalSlider.range({
    super.key,
    this.label,
    required this.min,
    required this.max,
    required RangeValues this.rangeValues,
    required ValueChanged<RangeValues> this.onRangeChanged,
    this.divisions,
    this.minLabel,
    this.maxLabel,
    this.enabled = true,
    this.valueFormatter,
    this.semanticFormatter,
    this.showMinMaxLabels = true,
    this.showValue = true,
    this.segments = const [],
    this.stepLabels,
    this.secondaryValue,
    this.leading,
    this.style,
    this.onChangeStart,
    this.onChangeEnd,
    this.semanticLabel,
  }) : value = null,
       onChanged = null,
       axis = Axis.horizontal,
       extent = defaultExtent,
       assert(min < max, 'min ($min) must be below max ($max)'),
       assert(
         divisions == null || divisions > 0,
         'divisions must be positive; null is a continuous slider',
       );

  /// How long a vertical track is.
  ///
  /// A length rather than "fill the parent": rotating a widget does
  /// not rotate its CONSTRAINTS, so the track asks its parent for a
  /// width that the parent measures vertically, and an unbounded
  /// column would give it infinity.
  static const double defaultExtent = 220;

  /// Which way the track runs. `GlobalSlider.vertical` sets it.
  final Axis axis;

  /// The track's length when [axis] is vertical. Ignored otherwise.
  final double extent;

  /// Shown above the track.
  final String? label;

  /// A glyph before the label, inside the same row.
  ///
  /// It belongs to the header rather than to whatever wraps the
  /// slider: a wrapper putting it on a line of its own leaves it
  /// floating above the label with nothing beside it whenever there is
  /// no second line to share that row with.
  ///
  /// Decorative by default — it is wrapped in `ExcludeSemantics`,
  /// because a speaker glyph next to the word "Volume" says the word
  /// "Volume".
  final Widget? leading;

  final double min;
  final double max;

  /// Single-slider value.
  final double? value;

  /// Range-slider values.
  final RangeValues? rangeValues;

  final ValueChanged<double>? onChanged;
  final ValueChanged<RangeValues>? onRangeChanged;

  /// Discrete steps. Null is a continuous slider.
  final int? divisions;

  /// Text at the low end. Null formats [min].
  final String? minLabel;

  /// Text at the high end. Null formats [max].
  final String? maxLabel;

  final bool enabled;

  /// How the number READS — in the badge, the end chips and the drag
  /// bubble.
  final String Function(double)? valueFormatter;

  /// How the number is ANNOUNCED, when that should differ.
  ///
  /// Falls back to [valueFormatter], then to the plain number. Without
  /// it a screen reader read Material's raw value — "0.5" for a slider
  /// whose badge said "50%".
  final String Function(double)? semanticFormatter;

  final bool showMinMaxLabels;

  /// The value badge beside the label.
  final bool showValue;

  /// Where the track is CUT, in value space.
  ///
  /// Each span between two boundaries is drawn as its own rounded bar,
  /// so a track with acts, tiers or chapters reads as several sliders
  /// handing the thumb between them. Values at or outside the bounds
  /// are ignored; the ends are always seams.
  ///
  /// It is on the WIDGET rather than the bag because where the second
  /// act starts is a property of the CONTENT, and a theme cannot know
  /// it. The gap between the segments is visual, and is on the bag.
  final List<double> segments;

  /// One word per step, drawn under the track.
  ///
  /// Needs `divisions`, and one more label than there are divisions —
  /// a 1–5 slider with four divisions has five steps. Anything else is
  /// ignored rather than drawn wrong.
  ///
  /// It also becomes the ANNOUNCEMENT for each step, so a reader hears
  /// "Great" rather than "5" — unless [semanticFormatter] says
  /// otherwise.
  final List<String>? stepLabels;

  /// A second, dimmer fill: loaded, cached, downloaded — reached by
  /// something other than the reader.
  ///
  /// Material has always had `secondaryTrackValue` and this module
  /// never passed it on, so a buffered-progress bar had to be a
  /// `Stack` of two widgets.
  final double? secondaryValue;

  /// Per-call visual overrides. `caller > GlobalSliderTheme >
  /// SliderStyle.defaults`.
  final SliderStyle? style;

  /// Called when a drag starts and ends, with the value at that moment.
  ///
  /// They were `VoidCallback`s and dropped the value Material hands
  /// them, so a caller who wanted "commit on release" had to keep its
  /// own copy.
  final ValueChanged<double>? onChangeStart;
  final ValueChanged<double>? onChangeEnd;

  /// What the control is called, when [label] is absent or says less
  /// than a screen reader needs.
  final String? semanticLabel;

  @override
  State<GlobalSlider> createState() => _GlobalSliderState();
}

class _GlobalSliderState extends State<GlobalSlider> {
  late double _value;
  late RangeValues _rangeValues;

  /// Which step the thumb was last on, so a tick fires once per
  /// division rather than once per pixel of a drag.
  int? _lastDivision;

  /// Materialised at the top of every `build`. It is not `late`: a
  /// painter can be asked for its preferred size before the first
  /// frame, and a `late` field throws there.
  ResolvedSliderStyle _style = ResolvedSliderStyle.fallback;

  bool get _isRange => widget.rangeValues != null;

  @override
  void initState() {
    super.initState();
    _value = widget.value ?? widget.min;
    _rangeValues = widget.rangeValues ?? RangeValues(widget.min, widget.max);
  }

  @override
  void didUpdateWidget(GlobalSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != null && widget.value != oldWidget.value) {
      _value = widget.value!;
    }
    if (widget.rangeValues != null &&
        widget.rangeValues != oldWidget.rangeValues) {
      _rangeValues = widget.rangeValues!;
    }
  }

  // ─── Geometry ──────────────────────────────────────────────

  /// [GlobalSlider.segments] as fractions of the range, both ends
  /// included, sorted.
  ///
  /// Empty when the caller named no interior seam — one bar is not a
  /// segmented track, and asking for the shape would only cost a
  /// custom painter.
  List<double> get _segmentBounds {
    if (widget.segments.isEmpty) return const [];
    final inner =
        widget.segments
            .map(
              (v) => SliderMath.fraction(v, min: widget.min, max: widget.max),
            )
            .where((f) => f > 0 && f < 1)
            .toSet()
            .toList()
          ..sort();
    return inner.isEmpty ? const [] : <double>[0, ...inner, 1];
  }

  /// The step labels, or null when they cannot line up with the ticks.
  List<String>? get _stepLabels {
    final labels = widget.stepLabels;
    final divisions = widget.divisions;
    if (labels == null || divisions == null) return null;
    return labels.length == divisions + 1 ? labels : null;
  }

  // ─── Formatting ────────────────────────────────────────────

  /// The number as it READS.
  ///
  /// Through `AppNumbers`, so Arabic gets Arabic-Indic digits — it was
  /// `toStringAsFixed`, which writes ASCII whatever the locale is.
  String _format(double v) {
    if (widget.valueFormatter != null) return widget.valueFormatter!(v);
    return AppNumbers.decimal(
      v,
      fractionDigits: widget.divisions != null ? 0 : 1,
    );
  }

  /// The number as it is ANNOUNCED.
  ///
  /// A labelled step says its WORD — "Great", not "5" — because the
  /// word is what the reader is choosing between.
  String _announce(double v) {
    if (widget.semanticFormatter != null) return widget.semanticFormatter!(v);
    final labels = _stepLabels;
    if (labels != null) {
      final step = SliderMath.divisionIndex(
        v,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
      );
      if (step != null) return labels[step.clamp(0, labels.length - 1)];
    }
    return _format(v);
  }

  // ─── Haptics ───────────────────────────────────────────────

  /// Ticks when the thumb crosses a division, and never on a continuous
  /// slider — a haptic on every pixel of a drag is a buzz.
  void _hapticFor(double v) {
    if (!_style.enableHaptic) return;
    final division = SliderMath.divisionIndex(
      v,
      min: widget.min,
      max: widget.max,
      divisions: widget.divisions,
    );
    if (division == null || division == _lastDivision) return;
    _lastDivision = division;
    HapticFeedback.selectionClick();
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _style = (widget.style ?? const SliderStyle()).resolve(context);

    final content = widget.axis == Axis.vertical
        ? _buildVertical(context)
        : _buildHorizontal(context);

    // One group, so a reader hears the label, the value and the ends as
    // one control rather than as four loose strings.
    final grouped = Semantics(
      container: true,
      enabled: widget.enabled,
      label: widget.semanticLabel ?? widget.label,
      child: content,
    );

    if (!_style.showContainer) return grouped;

    return Container(
      padding: _style.containerPadding,
      decoration:
          _style.containerDecoration ??
          BoxDecoration(
            color: _style.containerColor,
            borderRadius: BorderRadius.circular(_style.containerRadius),
            border: Border.all(color: _style.containerBorderColor),
            boxShadow: _style.containerShadow,
          ),
      child: grouped,
    );
  }

  Widget _buildHorizontal(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null || widget.leading != null) ...[
          _buildHeader(context),
          SizedBox(height: context.spacing.xs),
        ],
        if (widget.showMinMaxLabels) ...[
          _buildEndLabels(context),
          SizedBox(height: context.spacing.xs / 2),
        ],
        _isRange ? _buildRangeSlider(context) : _buildSlider(context),
        if (_stepLabels != null) ...[
          SizedBox(height: _style.stepLabelGap),
          _StepLabelRow(
            labels: _stepLabels!,
            style: _dulled(_style.stepLabelStyle),
            // The SAME number the track is inset by, which is the
            // only reason the words sit under the marks they name.
            inset: _style.trackEndInset,
          ),
        ],
      ],
    );
  }

  /// Max on TOP, min at the bottom, and the track between them.
  ///
  /// The end labels swap places rather than keeping the horizontal
  /// order: up is more, so the biggest number belongs at the top. A
  /// column that read 0 at the top and 100 at the bottom would be
  /// telling the reader the drag goes the other way.
  Widget _buildVertical(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null || widget.leading != null) ...[
          _buildHeader(context),
          SizedBox(height: context.spacing.xs),
        ],
        if (widget.showMinMaxLabels) ...[
          _endChip(widget.maxLabel ?? _format(widget.max)),
          SizedBox(height: context.spacing.xs),
        ],
        SizedBox(
          height: widget.extent,
          // BOTH axes are bounded. A `Slider` fills the height it is
          // handed, and `RotatedBox` hands its child the parent's
          // constraints FLIPPED — so with only a height set, the
          // child's height came from the parent's width and the
          // "vertical" slider was 778 points across.
          width: _verticalThickness,
          // A quarter turn ANTICLOCKWISE, so the track's high end
          // points up.
          child: RotatedBox(
            quarterTurns: 3,
            // Pinned left-to-right INSIDE the rotation. A slider
            // mirrors under `Directionality.rtl`, and a mirrored track
            // turned on its side runs downwards — so an Arabic reader
            // would drag up for less. Up is up in every language,
            // which is the same argument the video timeline makes.
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: _buildSlider(context),
            ),
          ),
        ),
        if (widget.showMinMaxLabels) ...[
          SizedBox(height: context.spacing.xs),
          _endChip(widget.minLabel ?? _format(widget.min)),
        ],
      ],
    );
  }

  /// The vertical track's cross axis: the touch target, never less
  /// than Material's minimum however thin the thumb is styled.
  double get _verticalThickness => math.max(
    SliderDefaults.verticalThickness,
    _style.overlayRadius * 2,
  );

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        if (widget.leading != null) ...[
          // The icon dims with the label rather than staying at full
          // strength beside a greyed-out one.
          Opacity(
            opacity: widget.enabled ? 1 : _style.disabledOpacity,
            child: ExcludeSemantics(child: widget.leading!),
          ),
          SizedBox(width: context.spacing.sm),
        ],
        Expanded(
          // The group already carries the name; leaving this readable
          // too had a reader say "Volume, Volume".
          child: ExcludeSemantics(
            child: widget.label == null
                ? const SizedBox.shrink()
                : Text(widget.label!, style: _dulled(_style.labelStyle)),
          ),
        ),
        if (widget.showValue) _buildValueBadge(context),
      ],
    );
  }

  Widget _buildValueBadge(BuildContext context) {
    final text = _isRange
        ? '${_format(_rangeValues.start)} – ${_format(_rangeValues.end)}'
        : _format(_value);

    return Container(
      padding: _style.valueBadgePadding,
      decoration: BoxDecoration(
        color: _style.valueBadgeColor,
        borderRadius: BorderRadius.circular(_style.valueBadgeRadius),
        border: Border.all(color: _style.valueBadgeBorderColor),
      ),
      // The slider already announces its value; the badge saying it
      // again is the same number twice.
      child: ExcludeSemantics(
        child: Text(text, style: _dulled(_style.valueStyle)),
      ),
    );
  }

  Widget _buildEndLabels(BuildContext context) {
    return Padding(
      // The SAME inset the TRACK has, so the two end chips sit over
      // the two ends of the scale they name. It was a fixed spacing
      // token, which agreed with the track's inset only by accident
      // and stopped agreeing the moment either moved.
      padding: EdgeInsets.symmetric(horizontal: _style.trackEndInset),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _endChip(widget.minLabel ?? _format(widget.min)),
          _endChip(widget.maxLabel ?? _format(widget.max)),
        ],
      ),
    );
  }

  Widget _endChip(String text) {
    return Container(
      padding: _style.endChipPadding,
      decoration: BoxDecoration(
        color: _style.endChipColor,
        borderRadius: BorderRadius.circular(_style.endChipRadius),
      ),
      // The ends are a scale, not controls — Material already puts the
      // range into the slider's own node.
      child: ExcludeSemantics(
        child: Text(text, style: _dulled(_style.minMaxStyle)),
      ),
    );
  }

  /// Dulls a style when the slider is off.
  TextStyle _dulled(TextStyle style) => widget.enabled
      ? style
      : style.copyWith(
          color: (style.color ?? _style.labelStyle.color)?.withValues(
            alpha: _style.disabledOpacity,
          ),
        );

  Widget _buildSlider(BuildContext context) {
    return SliderTheme(
      data: buildSliderTheme(
        context,
        style: _style,
        enabled: widget.enabled,
        hasDivisions: widget.divisions != null,
        direction: Directionality.of(context),
        segments: _segmentBounds,
      ),
      child: Slider(
        // CLAMPED, not asserted. A value outside the bounds is a
        // caller's bug, but it is a caller's bug in the PARENT's
        // build — a throw there takes down the whole page rather than
        // the one slider, and a page of twenty sliders went red
        // because one of them shared a state field with a card that
        // had a wider range.
        value: _value.clamp(widget.min, widget.max),
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        secondaryTrackValue: widget.secondaryValue?.clamp(
          widget.min,
          widget.max,
        ),
        label: _format(_value),
        semanticFormatterCallback: _announce,
        onChangeStart: widget.enabled
            ? (v) => widget.onChangeStart?.call(v)
            : null,
        onChangeEnd: widget.enabled
            ? (v) {
                _lastDivision = null;
                widget.onChangeEnd?.call(v);
              }
            : null,
        onChanged: widget.enabled
            ? (v) {
                _hapticFor(v);
                setState(() => _value = v);
                widget.onChanged?.call(v);
              }
            : null,
      ),
    );
  }

  Widget _buildRangeSlider(BuildContext context) {
    // Clamped for the same reason the single slider is, and ORDERED:
    // Material asserts its own start is not above its end.
    final lo = _rangeValues.start.clamp(widget.min, widget.max);
    final hi = _rangeValues.end.clamp(widget.min, widget.max);
    final values = RangeValues(lo < hi ? lo : hi, lo < hi ? hi : lo);

    return SliderTheme(
      data: buildSliderTheme(
        context,
        style: _style,
        enabled: widget.enabled,
        hasDivisions: widget.divisions != null,
        direction: Directionality.of(context),
        segments: _segmentBounds,
      ),
      child: RangeSlider(
        values: values,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        labels: RangeLabels(
          _format(values.start),
          _format(values.end),
        ),
        semanticFormatterCallback: _announce,
        onChangeStart: widget.enabled
            ? (v) => widget.onChangeStart?.call(v.start)
            : null,
        onChangeEnd: widget.enabled
            ? (v) {
                _lastDivision = null;
                widget.onChangeEnd?.call(v.end);
              }
            : null,
        onChanged: widget.enabled
            ? (v) {
                // The end that MOVED is the one worth ticking for.
                _hapticFor(
                  v.start != _rangeValues.start ? v.start : v.end,
                );
                setState(() => _rangeValues = v);
                widget.onRangeChanged?.call(v);
              }
            : null,
      ),
    );
  }
}

/// The words under a discrete slider's ticks.
///
/// Not a `spaceBetween` Row: the first and last labels have to sit
/// against the first and last TICKS, which are inset by the thumb's
/// radius, and every one in between has to land on its own tick rather
/// than on an even share of the width.
///
/// The flexes do that exactly. With `n` steps the row is `n - 1` tick
/// spacings wide; the end cells take HALF a spacing each and the
/// middle cells take a whole one, so every middle cell's CENTRE is a
/// tick and the two end cells finish flush with the outermost ones.
///
/// The first attempt was a `Stack` of boxes centred on each tick and
/// clamped inside the row — which moved the box and left the text
/// centred in it, so "Draft" and "Master" were dragged inward until
/// they collided with their neighbours. There is nothing to clamp
/// here.
class _StepLabelRow extends StatelessWidget {
  const _StepLabelRow({
    required this.labels,
    required this.style,
    required this.inset,
  });

  final List<String> labels;
  final TextStyle style;

  /// What the track itself is inset by at each end — the same number
  /// the track shapes reserve for the thumb.
  final double inset;

  @override
  Widget build(BuildContext context) {
    if (labels.length < 2) return const SizedBox.shrink();

    return Padding(
      // Symmetric, and therefore direction-free: the thumb is inset by
      // the same amount at both ends.
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              flex: (i == 0 || i == labels.length - 1) ? 1 : 2,
              child: Text(
                labels[i],
                style: style,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                // `start` / `end` rather than left / right, so Arabic
                // reads outward from the same two ends.
                textAlign: switch (i) {
                  0 => TextAlign.start,
                  _ when i == labels.length - 1 => TextAlign.end,
                  _ => TextAlign.center,
                },
              ),
            ),
        ],
      ),
    );
  }
}
