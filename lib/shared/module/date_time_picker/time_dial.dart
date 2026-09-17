import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/extensions/context_extensions.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/date_field_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../divider/global_divider.dart';
import 'date_time_picker_models.dart';
import 'date_time_picker_style.dart';
import 'theme/date_time_picker_theme.dart';

// ---------------------------------------------------------------------------
// TimeDial — a clock face
// ---------------------------------------------------------------------------

/// Sets a time by dragging a hand around a clock.
///
/// The other half of [TimePickerLayout]. Wheels set one part per
/// gesture and stay legible while they move; a dial is faster to read
/// back at a glance and is the shape a phone's own alarm has.
///
/// Built here rather than borrowed from `showTimePicker`: that one comes
/// with its own dialog, its own buttons and its own colours, and the
/// point of this module is that all three come from the app.
class TimeDial extends StatefulWidget {
  const TimeDial({
    super.key,
    required this.value,
    required this.onChanged,
    this.use24HourFormat = false,
    this.minuteInterval = 1,
    this.style,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final bool use24HourFormat;

  /// Minutes snap to this. The dial always shows all sixty ticks — the
  /// snap is what a drag lands on.
  final int minuteInterval;

  final DateTimePickerStyle? style;

  @override
  State<TimeDial> createState() => _TimeDialState();
}

class _TimeDialState extends State<TimeDial> {
  DialMode _mode = DialMode.hour;
  final FocusNode _focus = FocusNode(debugLabel: 'timeDial');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  ResolvedDateTimePickerStyle _style = ResolvedDateTimePickerStyle.fallback;

  bool get _isPm => widget.value.hour >= 12;

  void _emit(DateTime next) {
    if (_style.enableHaptic) HapticFeedback.selectionClick();
    widget.onChanged(next);
  }

  void _setHour(int hour24) => _emit(
    DateTime(
      widget.value.year,
      widget.value.month,
      widget.value.day,
      hour24,
      widget.value.minute,
    ),
  );

  void _setMinute(int minute) => _emit(
    DateTime(
      widget.value.year,
      widget.value.month,
      widget.value.day,
      widget.value.hour,
      minute,
    ),
  );

  void _setPeriod({required bool pm}) {
    if (pm == _isPm) return;
    final hour12 = widget.value.hour % 12;
    _setHour(pm ? hour12 + 12 : hour12);
  }

  /// Turns a touch inside the face into a time.
  void _handlePointer(Offset local, Size size) {
    final hit = DialGeometry.hitTest(
      local: local,
      size: size,
      mode: _mode,
      use24HourFormat: widget.use24HourFormat,
      minuteInterval: widget.minuteInterval,
    );
    if (hit == null) return;

    if (_mode == DialMode.hour) {
      // The dial shows 1..12 in 12-hour mode; which half of the day it
      // means is the period toggle's business, not the hand's.
      final hour = widget.use24HourFormat ? hit : (hit % 12) + (_isPm ? 12 : 0);
      if (hour != widget.value.hour) _setHour(hour);
    } else if (hit != widget.value.minute) {
      _setMinute(hit);
    }
  }

  @override
  Widget build(BuildContext context) {
    _style = (widget.style ?? const DateTimePickerStyle()).resolve(context);
    final size = math.min(
      _style.dialSize,
      MediaQuery.sizeOf(context).width - context.spacing.xl * 2,
    );

    return CallbackShortcuts(
      bindings: _shortcuts,
      child: Focus(
        focusNode: _focus,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Readout(
              value: widget.value,
              mode: _mode,
              use24HourFormat: widget.use24HourFormat,
              isPm: _isPm,
              style: _style,
              onModeChanged: (m) => setState(() => _mode = m),
              onPeriodChanged: (pm) => _setPeriod(pm: pm),
            ),
            SizedBox(height: context.spacing.md),
            Semantics(
              // The face itself is a slider in spirit: a continuous value
              // set by dragging. A screen reader gets the readout above,
              // which is where the value actually is.
              label: _mode == DialMode.hour
                  ? DatePickerStrings.hour
                  : DatePickerStrings.minute,
              value: PickerFormat.time(
                widget.value,
                use24HourFormat: widget.use24HourFormat,
              ),
              child: SizedBox(
                width: size,
                height: size,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (d) =>
                      _handlePointer(d.localPosition, Size(size, size)),
                  onPanStart: (d) =>
                      _handlePointer(d.localPosition, Size(size, size)),
                  onPanUpdate: (d) =>
                      _handlePointer(d.localPosition, Size(size, size)),
                  // Setting the hour moves you on to the minutes, the way
                  // every clock picker behaves — otherwise the second half
                  // of the job needs a tap nobody expects to have to make.
                  onPanEnd: (_) => _advance(),
                  onTapUp: (_) => _advance(),
                  child: CustomPaint(
                    painter: _DialPainter(
                      value: widget.value,
                      mode: _mode,
                      use24HourFormat: widget.use24HourFormat,
                      style: _style,
                      textDirection: Directionality.of(context),
                      labelStyle:
                          context.textTheme.bodyMedium ??
                          const TextStyle(fontSize: 14),
                      minuteInterval: widget.minuteInterval,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _advance() {
    if (_mode != DialMode.hour) return;
    setState(() => _mode = DialMode.minute);
  }

  // ─── Keyboard ──────────────────────────────────────────────
  //
  // A dial is a pointer affordance, so the keys act on the READOUT: the
  // arrows step whichever half is live, and left/right swap which half
  // that is. Without them the face was unreachable without a mouse.

  void _step(int direction) {
    if (_mode == DialMode.hour) {
      _setHour((widget.value.hour + direction) % 24);
      return;
    }
    final step = widget.minuteInterval;
    final next = (widget.value.minute + direction * step) % 60;
    _setMinute(next < 0 ? next + 60 : next);
  }

  Map<ShortcutActivator, VoidCallback> get _shortcuts => {
    const SingleActivator(LogicalKeyboardKey.arrowUp): () => _step(1),
    const SingleActivator(LogicalKeyboardKey.arrowDown): () => _step(-1),
    const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
        setState(() => _mode = DialMode.minute),
    const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
        setState(() => _mode = DialMode.hour),
  };
}

// ---------------------------------------------------------------------------
// Readout — the hour : minute header
// ---------------------------------------------------------------------------

class _Readout extends StatelessWidget {
  const _Readout({
    required this.value,
    required this.mode,
    required this.use24HourFormat,
    required this.isPm,
    required this.style,
    required this.onModeChanged,
    required this.onPeriodChanged,
  });

  final DateTime value;
  final DialMode mode;
  final bool use24HourFormat;
  final bool isPm;
  final ResolvedDateTimePickerStyle style;
  final ValueChanged<DialMode> onModeChanged;
  final ValueChanged<bool> onPeriodChanged;

  @override
  Widget build(BuildContext context) {
    final hour = use24HourFormat ? value.hour : PickerMath.hour12(value.hour);
    final periods = DateFormat().dateSymbols.AMPMS;

    return Directionality(
      // A clock is read left to right in every language — the hour
      // comes before the minute. Letting the Row flip in Arabic put
      // the minutes first.
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _Part(
            text: AppNumbers.padded(hour, width: 2),
            label: DatePickerStrings.hour,
            active: mode == DialMode.hour,
            style: style,
            onTap: () => onModeChanged(DialMode.hour),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
            child: ExcludeSemantics(
              child: Text(
                ':',
                style: context.textTheme.displaySmall?.copyWith(
                  color: style.dayTextColor,
                ),
              ),
            ),
          ),
          _Part(
            text: AppNumbers.padded(value.minute, width: 2),
            label: DatePickerStrings.minute,
            active: mode == DialMode.minute,
            style: style,
            onTap: () => onModeChanged(DialMode.minute),
          ),
          if (!use24HourFormat) ...[
            SizedBox(width: context.spacing.sm),
            _PeriodToggle(
              labels: periods,
              isPm: isPm,
              style: style,
              onChanged: onPeriodChanged,
            ),
          ],
        ],
      ),
    );
  }
}

/// One half of the readout — tap to point the hand at it.
class _Part extends StatelessWidget {
  const _Part({
    required this.text,
    required this.label,
    required this.active,
    required this.style,
    required this.onTap,
  });

  final String text;
  final String label;
  final bool active;
  final ResolvedDateTimePickerStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      value: text,
      child: ExcludeSemantics(
        child: Material(
          color: active
              ? style.selectedDayColor.withValues(alpha: 0.12)
              : style.dialFaceColor,
          borderRadius: BorderRadius.circular(context.radii.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(context.radii.md),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.spacing.md,
                vertical: context.spacing.sm,
              ),
              child: Text(
                text,
                style: context.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: active ? style.selectedDayColor : style.dayTextColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// AM / PM, stacked the way a clock picker stacks them.
class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.labels,
    required this.isPm,
    required this.style,
    required this.onChanged,
  });

  final List<String> labels;
  final bool isPm;
  final ResolvedDateTimePickerStyle style;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget half(String text, {required bool pm}) {
      final active = pm == isPm;
      return Expanded(
        child: Semantics(
          button: true,
          selected: active,
          label: text,
          child: ExcludeSemantics(
            child: Material(
              color: active
                  ? style.selectedDayColor.withValues(alpha: 0.16)
                  : Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(pm),
                child: Center(
                  child: Text(
                    text,
                    style: context.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: active
                          ? style.selectedDayColor
                          : style.dayTextColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SizedBox(
      width: 56,
      height: 76,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: style.borderColor),
          borderRadius: BorderRadius.circular(context.radii.md),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(context.radii.md),
          child: Column(
            children: [
              half(labels.first, pm: false),
              GlobalDivider(
                style: DividerStyle(
                  color: style.borderColor,
                  thickness: 1,
                  spacing: 0,
                ),
              ),
              half(labels.last, pm: true),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DialGeometry — where a touch on a clock face lands
// ---------------------------------------------------------------------------

/// The dial's arithmetic, without a widget.
///
/// A clock face runs CLOCKWISE in every language, so none of this
/// mirrors in Arabic — only the readout above it is laid out by
/// direction, and even that is pinned left-to-right because an hour
/// comes before a minute everywhere.
abstract final class DialGeometry {
  /// Where the label for [index] of [count] sits, as a fraction of the
  /// box, at [radiusFactor] of the radius.
  static Offset positionOf({
    required int index,
    required int count,
    required Size size,
    required double radiusFactor,
  }) {
    final radius = math.min(size.width, size.height) / 2;
    final angle = index * 2 * math.pi / count;
    return Offset(
      size.width / 2 + radius * radiusFactor * math.sin(angle),
      size.height / 2 - radius * radiusFactor * math.cos(angle),
    );
  }

  /// The value under [local], or null if the touch is outside the face.
  ///
  /// Returns an HOUR (0..23 in 24-hour mode, 0..11 otherwise) or a
  /// MINUTE, depending on [mode].
  static int? hitTest({
    required Offset local,
    required Size size,
    required DialMode mode,
    required bool use24HourFormat,
    required int minuteInterval,
  }) {
    final radius = math.min(size.width, size.height) / 2;
    if (radius <= 0) return null;

    final dx = local.dx - size.width / 2;
    final dy = local.dy - size.height / 2;
    final distance = math.sqrt(dx * dx + dy * dy);
    // A generous slop outside the face — a finger that slides past the
    // edge mid-drag should keep dragging, not stop dead.
    if (distance > radius * 1.35) return null;

    // Clockwise from twelve.
    var angle = math.atan2(dx, -dy);
    if (angle < 0) angle += 2 * math.pi;

    if (mode == DialMode.minute) {
      final minute = (angle / (2 * math.pi) * 60).round() % 60;
      return PickerMath.snapMinute(minute, minuteInterval) % 60;
    }

    final index = (angle / (2 * math.pi) * 12).round() % 12;
    if (!use24HourFormat) return index;

    // 24-hour dials carry a second ring. Outer is 0..11, inner 12..23 —
    // one ring per half of the day, at the same twelve angles.
    final inner =
        distance <
        radius *
            (DateTimePickerDefaults.dialLabelRadius +
                DateTimePickerDefaults.dialInnerLabelRadius) /
            2;
    return inner ? index + 12 : index;
  }
}

// ---------------------------------------------------------------------------
// Painter
// ---------------------------------------------------------------------------

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.value,
    required this.mode,
    required this.use24HourFormat,
    required this.style,
    required this.textDirection,
    required this.labelStyle,
    required this.minuteInterval,
  });

  final DateTime value;
  final DialMode mode;
  final bool use24HourFormat;
  final ResolvedDateTimePickerStyle style;
  final TextDirection textDirection;
  final TextStyle labelStyle;
  final int minuteInterval;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    canvas.drawCircle(centre, radius, Paint()..color = style.dialFaceColor);

    final selected = _selectedIndex();
    final knobFactor = _knobRadiusFactor(selected.inner);
    final knob = DialGeometry.positionOf(
      index: selected.index,
      count: selected.count,
      size: size,
      radiusFactor: knobFactor,
    );

    final accent = Paint()..color = style.selectedDayColor;
    canvas
      ..drawLine(
        centre,
        knob,
        Paint()
          ..color = style.selectedDayColor
          ..strokeWidth = DateTimePickerDefaults.dialHandWidth,
      )
      ..drawCircle(centre, DateTimePickerDefaults.dialCentreRadius, accent)
      ..drawCircle(knob, DateTimePickerDefaults.dialKnobRadius, accent);

    _paintLabels(canvas, size, selected);
  }

  ({int index, int count, bool inner}) _selectedIndex() {
    if (mode == DialMode.minute) {
      return (index: value.minute, count: 60, inner: false);
    }
    if (!use24HourFormat) {
      return (index: value.hour % 12, count: 12, inner: false);
    }
    return (
      index: value.hour % 12,
      count: 12,
      inner: value.hour >= 12,
    );
  }

  double _knobRadiusFactor(bool inner) => inner
      ? DateTimePickerDefaults.dialInnerLabelRadius
      : DateTimePickerDefaults.dialLabelRadius;

  void _paintLabels(
    Canvas canvas,
    Size size,
    ({int index, int count, bool inner}) selected,
  ) {
    void label(
      String text, {
      required int index,
      required int count,
      required bool inner,
      required bool highlighted,
    }) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: labelStyle.copyWith(
            color: highlighted
                ? style.selectedDayTextColor
                : style.dayTextColor,
            fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        textDirection: textDirection,
      )..layout();

      final at = DialGeometry.positionOf(
        index: index,
        count: count,
        size: size,
        radiusFactor: _knobRadiusFactor(inner),
      );
      painter.paint(
        canvas,
        at - Offset(painter.width / 2, painter.height / 2),
      );
    }

    if (mode == DialMode.minute) {
      // Every five, or sixty numbers overlap into a grey ring — unless
      // the interval is COARSER, in which case they are the intervals.
      // Labelling ":05" on a fifteen-minute dial offers a minute the
      // face will not give you.
      final step = minuteInterval > 5 ? minuteInterval : 5;
      for (var minute = 0; minute < 60; minute += step) {
        label(
          AppNumbers.padded(minute, width: 2),
          index: minute,
          count: 60,
          inner: false,
          highlighted: value.minute == minute,
        );
      }
      return;
    }

    for (var i = 0; i < 12; i++) {
      final outer = use24HourFormat ? i : (i == 0 ? 12 : i);
      label(
        AppNumbers.padded(outer, width: use24HourFormat ? 2 : 1),
        index: i,
        count: 12,
        inner: false,
        highlighted: !selected.inner && selected.index == i,
      );
      if (use24HourFormat) {
        label(
          AppNumbers.padded(i + 12, width: 2),
          index: i,
          count: 12,
          inner: true,
          highlighted: selected.inner && selected.index == i,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.value != value ||
      old.mode != mode ||
      old.use24HourFormat != use24HourFormat ||
      old.style != style ||
      old.labelStyle != labelStyle ||
      old.minuteInterval != minuteInterval;
}
