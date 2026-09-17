import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/localization/strings/date_field_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../chip/global_chip.dart';
import 'date_time_picker_models.dart';
import 'date_time_picker_style.dart';
import 'global_date_time_picker.dart';
import 'global_inline_calendar_range_picker.dart';
import 'picker_anchor.dart';
import 'picker_calendar_system.dart';
import 'picker_dialogs.dart';
import 'theme/date_time_picker_theme.dart';

// ---------------------------------------------------------------------------
// DateRangePreset — a named shortcut range
// ---------------------------------------------------------------------------

@immutable
class DateRangePreset {
  const DateRangePreset({required this.label, required this.range});

  final String label;
  final DateTimeRange range;

  /// Today, the last 7 and 30 days, this month, last month.
  ///
  /// Four of the five reach into the PAST, which is why the calendar's
  /// default bounds had to change: with `firstDate` defaulting to
  /// today, every one of them selected a span drawn entirely disabled.
  static List<DateRangePreset> common() {
    final now = DateUtils.dateOnly(DateTime.now());
    return [
      DateRangePreset(
        label: DateRangeStrings.presetToday,
        range: DateTimeRange(start: now, end: now),
      ),
      DateRangePreset(
        label: DateRangeStrings.presetLast7Days,
        range: DateTimeRange(
          start: now.subtract(const Duration(days: 6)),
          end: now,
        ),
      ),
      DateRangePreset(
        label: DateRangeStrings.presetLast30Days,
        range: DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        ),
      ),
      DateRangePreset(
        label: DateRangeStrings.presetThisMonth,
        range: DateTimeRange(start: DateTime(now.year, now.month), end: now),
      ),
      DateRangePreset(
        label: DateRangeStrings.presetLastMonth,
        range: DateTimeRange(
          start: DateTime(now.year, now.month - 1),
          end: DateTime(now.year, now.month, 0),
        ),
      ),
    ];
  }

  @override
  bool operator ==(Object other) =>
      other is DateRangePreset && other.label == label && other.range == range;

  @override
  int get hashCode => Object.hash(label, range);
}

// ---------------------------------------------------------------------------
// GlobalDateTimeRangePicker
// ---------------------------------------------------------------------------

/// Picks a span of dates, on four of the five [PickerSurface]s.
class GlobalDateTimeRangePicker extends StatefulWidget {
  const GlobalDateTimeRangePicker({
    super.key,
    this.value,
    this.onChanged,
    this.surface = PickerSurface.dialog,
    this.firstDate,
    this.lastDate,
    this.includeTime = false,
    this.use24HourFormat = false,
    this.minuteInterval = 1,
    this.helpText,
    this.cancelText,
    this.confirmText,
    this.startLabel,
    this.endLabel,
    this.hint,
    this.icon,
    this.minimumRangeDays,
    this.maximumRangeDays,
    this.triggerBuilder,
    this.formatRange,
    this.style,
    this.presets,
    this.onRangeValidationError,
  });

  final DateTimeRange? value;
  final ValueChanged<DateTimeRange>? onChanged;

  /// `material` / `input` open Flutter's dialog, `calendar` is inline,
  /// `wheel` is two stacked wheel pickers, `overlay` is a panel
  /// anchored to a trigger.
  final PickerSurface surface;

  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Also pick start / end TIMES. Wheel surface only.
  final bool includeTime;
  final bool use24HourFormat;
  final int minuteInterval;

  final String? helpText;
  final String? cancelText;
  final String? confirmText;
  final String? startLabel;
  final String? endLabel;
  final String? hint;
  final IconData? icon;

  final int? minimumRangeDays;
  final int? maximumRangeDays;

  final Widget Function(BuildContext, String, VoidCallback)? triggerBuilder;

  final String Function(DateTimeRange)? formatRange;

  /// Per-call visual overrides. `caller > GlobalDateTimePickerTheme >
  /// DateTimePickerStyle.defaults`.
  final DateTimePickerStyle? style;

  /// Quick-select chips above the calendar.
  final List<DateRangePreset>? presets;

  /// Told when a pick is refused by [minimumRangeDays] /
  /// [maximumRangeDays], already in the reader's language.
  final ValueChanged<String>? onRangeValidationError;

  // ─── Factories ──────────────────────────────────────────────

  factory GlobalDateTimeRangePicker.dialog({
    Key? key,
    DateTimeRange? value,
    ValueChanged<DateTimeRange>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
    String? hint,
    DateTimePickerStyle? style,
    Widget Function(BuildContext, String, VoidCallback)? triggerBuilder,
  }) => GlobalDateTimeRangePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
    hint: hint,
    style: style,
    triggerBuilder: triggerBuilder,
  );

  factory GlobalDateTimeRangePicker.wheel({
    Key? key,
    DateTimeRange? value,
    ValueChanged<DateTimeRange>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    bool includeTime = false,
    String? startLabel,
    String? endLabel,
    DateTimePickerStyle? style,
  }) => GlobalDateTimeRangePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    surface: PickerSurface.wheel,
    firstDate: firstDate,
    lastDate: lastDate,
    includeTime: includeTime,
    startLabel: startLabel,
    endLabel: endLabel,
    style: style,
  );

  factory GlobalDateTimeRangePicker.calendar({
    Key? key,
    DateTimeRange? value,
    ValueChanged<DateTimeRange>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    List<DateRangePreset>? presets,
    DateTimePickerStyle? style,
  }) => GlobalDateTimeRangePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    surface: PickerSurface.calendar,
    firstDate: firstDate,
    lastDate: lastDate,
    presets: presets,
    style: style,
  );

  factory GlobalDateTimeRangePicker.overlay({
    Key? key,
    DateTimeRange? value,
    ValueChanged<DateTimeRange>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    List<DateRangePreset>? presets,
    String? hint,
    IconData? icon,
    Widget Function(BuildContext, String, VoidCallback)? triggerBuilder,
    DateTimePickerStyle? style,
  }) => GlobalDateTimeRangePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    surface: PickerSurface.overlay,
    firstDate: firstDate,
    lastDate: lastDate,
    presets: presets,
    hint: hint,
    icon: icon,
    triggerBuilder: triggerBuilder,
    style: style,
  );

  @override
  State<GlobalDateTimeRangePicker> createState() =>
      _GlobalDateTimeRangePickerState();
}

class _GlobalDateTimeRangePickerState extends State<GlobalDateTimeRangePicker> {
  late DateTime _start;
  late DateTime _end;
  late DateTime _first;
  late DateTime _last;

  ResolvedDateTimePickerStyle _style = ResolvedDateTimePickerStyle.fallback;

  /// A year either side of today, not "today to a year out". The old
  /// default made every past-facing preset unselectable.
  static const _defaultSpan = Duration(days: 365);

  @override
  void initState() {
    super.initState();
    _readBounds();
    _readValue();
  }

  @override
  void didUpdateWidget(GlobalDateTimeRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.firstDate != oldWidget.firstDate ||
        widget.lastDate != oldWidget.lastDate) {
      _readBounds();
    }
    if (widget.value != oldWidget.value) _readValue();
  }

  void _readBounds() {
    final today = DateUtils.dateOnly(DateTime.now());
    _first = DateUtils.dateOnly(
      widget.firstDate ?? today.subtract(_defaultSpan),
    );
    _last = DateUtils.dateOnly(widget.lastDate ?? today.add(_defaultSpan));
    if (_last.isBefore(_first)) _last = _first;
  }

  void _readValue() {
    final today = DateUtils.dateOnly(DateTime.now());
    _start = (widget.value?.start ?? today).clampTo(_first, _last);
    // Held inside the bounds — a default end of "start + 7 days" used
    // to sail past `lastDate` and open on a disabled cell.
    _end = (widget.value?.end ?? _start.add(const Duration(days: 7))).clampTo(
      _start,
      _last,
    );
  }

  void _emit() {
    if (_end.isBefore(_start)) _end = _start;
    widget.onChanged?.call(DateTimeRange(start: _start, end: _end));
  }

  String _formatValue() {
    final range = DateTimeRange(start: _start, end: _end);
    if (widget.formatRange != null) return widget.formatRange!(range);
    if (_style.calendar == PickerCalendar.hijri) {
      final system = _style.calendarSystem;
      return '${system.describeShort(_start)} – '
          '${system.describeShort(_end)}';
    }
    return '${PickerFormat.short(_start)} – ${PickerFormat.short(_end)}';
  }

  String get _hintText => widget.hint ?? DateRangeStrings.selectRange;

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _style = (widget.style ?? const DateTimePickerStyle()).resolve(context);

    return switch (widget.surface) {
      PickerSurface.dialog ||
      PickerSurface.input => _buildTrigger(context, onTap: _openDialog),
      PickerSurface.calendar => _buildInlineCalendar(context),
      PickerSurface.wheel => _buildWheelRange(context),
      PickerSurface.overlay => PickerAnchor(
        style: _style,
        trigger: (context, open, toggle) =>
            _buildTrigger(context, onTap: toggle, active: open),
        // No scroll view — `PickerAnchor` owns it, so what it measures
        // is this panel's natural height.
        panel: (context, close) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.presets?.isNotEmpty ?? false) _buildPresets(context),
            _buildCalendar(flat: true),
          ],
        ),
      ),
    };
  }

  // ─── Trigger ───────────────────────────────────────────────

  Widget _buildTrigger(
    BuildContext context, {
    required VoidCallback onTap,
    bool active = false,
  }) {
    final hasValue = widget.value != null;
    final formatted = hasValue ? _formatValue() : _hintText;

    if (widget.triggerBuilder != null) {
      return widget.triggerBuilder!(context, formatted, onTap);
    }

    return Semantics(
      button: true,
      expanded: widget.surface == PickerSurface.overlay ? active : null,
      label: _hintText,
      value: hasValue ? formatted : null,
      onTap: onTap,
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: _style.triggerPadding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_style.triggerRadius),
              border: Border.all(
                color: active
                    ? _style.triggerActiveBorderColor
                    : _style.triggerBorderColor,
                width: _style.triggerBorderWidth,
              ),
              color: _style.triggerFillColor,
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon ?? Icons.date_range,
                  size: _style.triggerIconSize,
                  color: active
                      ? _style.triggerActiveBorderColor
                      : _style.triggerIconColor,
                ),
                SizedBox(width: _style.triggerGap),
                Expanded(
                  child: Text(
                    formatted,
                    overflow: TextOverflow.ellipsis,
                    style: hasValue
                        ? _style.triggerTextStyle
                        : _style.triggerTextStyle.copyWith(
                            color: _style.triggerHintColor,
                          ),
                  ),
                ),
                if (widget.surface == PickerSurface.overlay)
                  AnimatedRotation(
                    turns: active ? 0.5 : 0,
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : _style.overlayDuration,
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: _style.triggerIconColor,
                    ),
                  )
                else
                  Icon(Icons.arrow_drop_down, color: _style.triggerIconColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Material dialog ───────────────────────────────────────

  Future<void> _openDialog() async {
    final picked = await PickerDialogs.range(
      context,
      initial: DateTimeRange(start: _start, end: _end),
      firstDate: _first,
      lastDate: _last,
      style: widget.style,
      presets: [
        for (final preset in widget.presets ?? const <DateRangePreset>[])
          (label: preset.label, range: preset.range),
      ],
      minimumRangeDays: widget.minimumRangeDays,
      maximumRangeDays: widget.maximumRangeDays,
      title: widget.helpText,
      confirmText: widget.confirmText,
      cancelText: widget.cancelText,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _start = picked.start;
      _end = picked.end;
    });
    _emit();
  }

  // ─── Inline calendar ───────────────────────────────────────

  Widget _buildInlineCalendar(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (widget.presets?.isNotEmpty ?? false) _buildPresets(context),
      _buildCalendar(flat: false),
    ],
  );

  Widget _buildCalendar({required bool flat}) {
    final style = widget.style ?? const DateTimePickerStyle();
    return GlobalInlineCalendarRangePicker(
      selectedRange: DateTimeRange(start: _start, end: _end),
      firstDate: _first,
      lastDate: _last,
      minimumRangeDays: widget.minimumRangeDays,
      maximumRangeDays: widget.maximumRangeDays,
      onRangeValidationError: widget.onRangeValidationError,
      // Inside the panel the panel IS the surface — a second bordered,
      // shadowed box drew a frame within a frame.
      style: flat ? style.mergedWith(DateTimePickerStyle.flat) : style,
      // The panel IS what just opened; a keyboard user should not have
      // to Tab into it.
      autofocus: flat,
      onChanged: (range) {
        if (range == null) return;
        setState(() {
          _start = range.start;
          _end = range.end;
        });
        _emit();
      },
    );
  }

  Widget _buildPresets(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sm),
      // `GlobalChipStrip`, not a bare scroll view with clipping off.
      // Clipping off kept the selected chip's shadow, and let the chips
      // PAST the viewport paint as well — so the strip ran out over the
      // page it was sitting in and off the side of the screen.
      child: GlobalChipStrip(
        padding: EdgeInsets.symmetric(horizontal: context.spacing.xs),
        children: [
          for (final preset in widget.presets!)
            GlobalChip.pill(
              label: preset.label,
              variant: ChipVariant.outlined,
              selected:
                  DateUtils.isSameDay(preset.range.start, _start) &&
                  DateUtils.isSameDay(preset.range.end, _end),
              onSelected: (_) {
                setState(() {
                  _start = preset.range.start.clampTo(_first, _last);
                  _end = preset.range.end.clampTo(_first, _last);
                });
                _emit();
              },
            ),
        ],
      ),
    );
  }

  // ─── Wheel range ───────────────────────────────────────────

  Widget _buildWheelRange(BuildContext context) => Column(
    children: [
      _section(
        context,
        label: widget.startLabel ?? DateRangeStrings.start,
        value: _start,
        onChanged: (d) {
          _start = d;
          _scheduleEmit();
        },
      ),
      SizedBox(height: context.spacing.sm),
      ExcludeSemantics(
        child: Icon(
          Icons.arrow_downward,
          color: _style.triggerIconColor,
          size: context.iconSizes.sm,
        ),
      ),
      SizedBox(height: context.spacing.sm),
      _section(
        context,
        label: widget.endLabel ?? DateRangeStrings.end,
        value: _end,
        onChanged: (d) {
          _end = d;
          _scheduleEmit();
        },
      ),
    ],
  );

  /// The wheels report DURING a scroll, and rebuilding then kills the
  /// gesture — so the rebuild waits for the frame to finish.
  void _scheduleEmit() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
      _emit();
    });
  }

  Widget _section(
    BuildContext context, {
    required String label,
    required DateTime value,
    required ValueChanged<DateTime> onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Semantics(
        header: true,
        child: Text(
          label,
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      SizedBox(height: context.spacing.xs),
      GlobalDateTimePicker(
        value: value,
        onChanged: onChanged,
        mode: widget.includeTime
            ? DateTimePickerMode.dateAndTime
            : DateTimePickerMode.date,
        firstDate: widget.firstDate,
        lastDate: widget.lastDate,
        use24HourFormat: widget.use24HourFormat,
        minuteInterval: widget.minuteInterval,
        style: widget.style,
      ),
    ],
  );
}
