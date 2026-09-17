import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/date_field_strings.dart';
import '../../../core/localization/strings/duration_field_strings.dart';
import '../../../core/localization/strings/time_field_strings.dart';
import '../../../core/navigation/transitions/route_transition.dart';
import '../../../core/tokens/extensions.dart';
import '../app_bar/global_app_bar.dart';
import '../buttons/global_filled_button.dart';
import '../buttons/global_icon_button.dart';
import '../buttons/global_text_button.dart';
import '../chip/global_chip.dart';
import '../dialog/global_dialog.dart';
import '../divider/global_divider.dart';
import '../text_field/text_field.dart';
import 'date_time_picker_models.dart';
import 'date_time_picker_style.dart';
import 'global_date_time_picker.dart';
import 'global_duration_picker.dart';
import 'global_inline_calendar_range_picker.dart';
import 'theme/date_time_picker_theme.dart';

// ---------------------------------------------------------------------------
// PickerDialogs — the module's own dialogs
// ---------------------------------------------------------------------------

/// Date, time and range dialogs built from THIS app's parts.
///
/// They replace `showDatePicker` / `showTimePicker` /
/// `showDateRangePicker`. Those are Material's own widgets, and the only
/// way to make them look like the rest of the app was a 60-line
/// `Theme` wrapper that reached into `datePickerTheme`,
/// `timePickerTheme` and `textButtonTheme` and still could not touch
/// their icons, their layout, or their two-step date-then-time flow.
///
/// What is inside these is the same calendar and the same wheels every
/// other surface in this module builds, the same `GlobalDialog` chrome
/// every other dialog in the app uses, and the same buttons — so a
/// rebrand reaches them the way it reaches everything else.
abstract final class PickerDialogs {
  /// A calendar, or a typed date, or both with a toggle between them.
  static Future<DateTime?> date(
    BuildContext context, {
    required DateTime initial,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTimePickerStyle? style,
    PickerEntryMode entryMode = PickerEntryMode.calendar,
    String? title,
    String? confirmText,
    String? cancelText,
    String? fieldLabel,
    String? fieldHint,
    String? errorFormatText,
    String? errorInvalidText,
    bool Function(DateTime)? selectableDayPredicate,
    int startOfWeek = 0,
    Map<DateTime, List<Color>>? markedDates,
    List<({String label, DateTime date})> presets = const [],
  }) => GlobalDialog.builder<DateTime>(
    context,
    builder: (_) => _DateDialog(
      initial: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      style: style,
      entryMode: entryMode,
      title: title ?? DateFieldStrings.selectDate,
      confirmText: confirmText,
      cancelText: cancelText,
      fieldLabel: fieldLabel,
      fieldHint: fieldHint,
      errorFormatText: errorFormatText,
      errorInvalidText: errorInvalidText,
      selectableDayPredicate: selectableDayPredicate,
      startOfWeek: startOfWeek,
      markedDates: markedDates,
      presets: presets,
    ),
  );

  /// The module's own time wheels.
  static Future<DateTime?> time(
    BuildContext context, {
    required DateTime initial,
    bool use24HourFormat = false,
    int minuteInterval = 1,
    bool showSeconds = false,
    DateTimePickerStyle? style,
    String? title,
    String? confirmText,
    String? cancelText,
  }) => GlobalDialog.builder<DateTime>(
    context,
    builder: (_) => _TimeDialog(
      initial: initial,
      use24HourFormat: use24HourFormat,
      minuteInterval: minuteInterval,
      showSeconds: showSeconds,
      style: style,
      title: title ?? DatePickerStrings.selectTime,
      confirmText: confirmText,
      cancelText: cancelText,
    ),
  );

  /// Calendar over wheels, in ONE dialog.
  ///
  /// Material's answer was two dialogs in a row — pick a date, it
  /// closes, pick a time — with no way back to the first without
  /// starting over, and no way to see what you had chosen.
  static Future<DateTime?> dateAndTime(
    BuildContext context, {
    required DateTime initial,
    required DateTime firstDate,
    required DateTime lastDate,
    bool use24HourFormat = false,
    int minuteInterval = 1,
    DateTimePickerStyle? style,
    String? title,
    String? confirmText,
    String? cancelText,
    bool Function(DateTime)? selectableDayPredicate,
    int startOfWeek = 0,
    Map<DateTime, List<Color>>? markedDates,
  }) => GlobalDialog.builder<DateTime>(
    context,
    builder: (_) => _DateTimeDialog(
      initial: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      use24HourFormat: use24HourFormat,
      minuteInterval: minuteInterval,
      style: style,
      title: title ?? DatePickerStrings.selectDateTime,
      confirmText: confirmText,
      cancelText: cancelText,
      selectableDayPredicate: selectableDayPredicate,
      startOfWeek: startOfWeek,
      markedDates: markedDates,
    ),
  );

  /// An elapsed SPAN — hours, minutes, optionally seconds.
  ///
  /// Not a time of day: nothing here clamps to a clock, and 90 minutes
  /// is a legal answer where 90 o'clock is not.
  static Future<Duration?> duration(
    BuildContext context, {
    required Duration initial,
    DurationFormat format = DurationFormat.hm,
    int minuteInterval = 1,
    int secondInterval = 1,
    int maxHours = 23,
    Duration? maxDuration,
    DateTimePickerStyle? style,
    String? title,
    String? confirmText,
    String? cancelText,
  }) => GlobalDialog.builder<Duration>(
    context,
    builder: (_) => _DurationDialog(
      initial: initial,
      format: format,
      minuteInterval: minuteInterval,
      secondInterval: secondInterval,
      maxHours: maxHours,
      maxDuration: maxDuration,
      style: style,
      title: title ?? DurationFieldStrings.pick,
      confirmText: confirmText,
      cancelText: cancelText,
    ),
  );

  /// Two times, from and to, in ONE dialog.
  ///
  /// A RECORD, not a `DateTimeRange`: that type asserts its start is
  /// not after its end, and a shift from 22:00 to 06:00 is a night, not
  /// a mistake. Only the clock parts of the two `DateTime`s mean
  /// anything — they arrive and leave on an arbitrary shared day.
  ///
  /// `TimeRangeField` opened two unrelated time dialogs that knew
  /// nothing about each other, which is the shape the date range was in
  /// before it got a range calendar.
  static Future<({DateTime start, DateTime end})?> timeRange(
    BuildContext context, {
    required ({DateTime start, DateTime end}) initial,
    bool use24HourFormat = false,
    int minuteInterval = 1,
    DateTimePickerStyle? style,
    String? title,
    String? confirmText,
    String? cancelText,
  }) => GlobalDialog.builder<({DateTime start, DateTime end})>(
    context,
    builder: (_) => _TimeRangeDialog(
      initial: initial,
      use24HourFormat: use24HourFormat,
      minuteInterval: minuteInterval,
      style: style,
      title: title ?? DatePickerStrings.selectTimeRange,
      confirmText: confirmText,
      cancelText: cancelText,
    ),
  );

  /// A span, with optional quick-select chips.
  static Future<DateTimeRange?> range(
    BuildContext context, {
    required DateTimeRange initial,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTimePickerStyle? style,
    List<({String label, DateTimeRange range})> presets = const [],
    int? minimumRangeDays,
    int? maximumRangeDays,
    String? title,
    String? confirmText,
    String? cancelText,
    RangePickerLayout? layout,
  }) {
    final resolved =
        layout ??
        (style ?? const DateTimePickerStyle()).resolve(context).rangeLayout;

    Widget body(BuildContext _) => _RangeDialog(
      initial: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      style: style,
      presets: presets,
      minimumRangeDays: minimumRangeDays,
      maximumRangeDays: maximumRangeDays,
      title: title ?? DateRangeStrings.selectDateRange,
      confirmText: confirmText,
      cancelText: cancelText,
      fullScreen: resolved == RangePickerLayout.fullScreen,
    );

    if (resolved == RangePickerLayout.dialog) {
      return GlobalDialog.builder<DateTimeRange>(context, builder: body);
    }
    // A page of its own, not a modal blown up: it gets an app bar with
    // the span in it, and the calendar gets the room a phone modal
    // cannot give it.
    return Navigator.of(context, rootNavigator: true).push<DateTimeRange>(
      RouteTransition.route<DateTimeRange>(
        context: context,
        name: 'date-range',
        fullscreenDialog: true,
        style: TransitionStyle.modal,
        child: Builder(builder: body),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shell
// ---------------------------------------------------------------------------

/// Title row, scrolling body, action row — the shape every picker
/// dialog here takes.
class _DialogShell extends StatelessWidget {
  const _DialogShell({
    required this.title,
    required this.style,
    required this.child,
    required this.onConfirm,
    this.confirmText,
    this.cancelText,
    this.headerAction,
    this.summary,
  });

  final String title;
  final ResolvedDateTimePickerStyle style;
  final Widget child;
  final VoidCallback? onConfirm;
  final String? confirmText;
  final String? cancelText;

  /// An icon button on the title row — the entry-mode toggle.
  final Widget? headerAction;

  /// What is currently picked, under the title.
  final String? summary;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final text = context.textColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(
            spacing.md,
            spacing.md,
            headerAction == null ? spacing.md : spacing.sm,
            spacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: text.primary,
                        ),
                      ),
                    ),
                    if (summary != null)
                      Text(
                        summary!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: style.selectedDayColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              if (headerAction != null) headerAction!,
            ],
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: spacing.md),
            child: child,
          ),
        ),
        SizedBox(height: spacing.sm),
        GlobalDivider(style: DividerStyle(color: style.borderColor)),
        Padding(
          padding: EdgeInsets.all(spacing.sm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GlobalTextButton(
                text: cancelText ?? CommonStrings.cancel,
                shrinkWidth: true,
                enableHaptic: style.enableHaptic,
                onPressed: () => Navigator.of(context).pop(),
                style: ButtonStateStyle(foregroundColor: text.secondary),
              ),
              SizedBox(width: spacing.sm),
              GlobalFilledButton(
                text: confirmText ?? CommonStrings.done,
                shrinkWidth: true,
                enableHaptic: style.enableHaptic,
                onPressed: onConfirm,
                style: ButtonStateStyle(
                  backgroundColor: style.selectedDayColor,
                  foregroundColor: style.selectedDayTextColor,
                  borderRadius: BorderRadius.circular(context.radii.md),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The calendar, stripped of its own panel — the dialog IS the surface.
DateTimePickerStyle _flat(DateTimePickerStyle? style) =>
    (style ?? const DateTimePickerStyle()).mergedWith(
      DateTimePickerStyle.flat,
    );

// ---------------------------------------------------------------------------
// Date
// ---------------------------------------------------------------------------

class _DateDialog extends StatefulWidget {
  const _DateDialog({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
    required this.entryMode,
    required this.title,
    this.style,
    this.confirmText,
    this.cancelText,
    this.fieldLabel,
    this.fieldHint,
    this.errorFormatText,
    this.errorInvalidText,
    this.selectableDayPredicate,
    this.startOfWeek = 0,
    this.markedDates,
    this.presets = const [],
  });

  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;
  final PickerEntryMode entryMode;
  final String title;
  final DateTimePickerStyle? style;
  final String? confirmText;
  final String? cancelText;
  final String? fieldLabel;
  final String? fieldHint;
  final String? errorFormatText;
  final String? errorInvalidText;

  /// Return false to grey a day out.
  final bool Function(DateTime)? selectableDayPredicate;

  final int startOfWeek;
  final Map<DateTime, List<Color>>? markedDates;

  /// "Today", "Tomorrow" — one tap for the dates people actually mean.
  final List<({String label, DateTime date})> presets;

  @override
  State<_DateDialog> createState() => _DateDialogState();
}

class _DateDialogState extends State<_DateDialog> {
  late PickerEntryMode _mode = widget.entryMode;
  late DateTime _value = widget.initial.clampTo(
    widget.firstDate,
    widget.lastDate,
  );

  late final TextEditingController _controller = TextEditingController(
    text: TypedDate.format(_value, TypedDate.orderForLocale()),
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      if (_mode == PickerEntryMode.calendar) {
        _controller.text = TypedDate.format(
          _value,
          TypedDate.orderForLocale(),
        );
        _mode = PickerEntryMode.input;
      } else {
        _readTyped();
        _mode = PickerEntryMode.calendar;
      }
      _error = null;
    });
  }

  /// Pulls the field's text into [_value], or sets [_error].
  bool _readTyped() {
    final order = TypedDate.orderForLocale();
    final parsed = TypedDate.parse(_controller.text, order);
    if (parsed == null) {
      _error =
          widget.errorFormatText ??
          DateFieldStrings.incomplete(order.template());
      return false;
    }
    if (parsed.isBefore(widget.firstDate) || parsed.isAfter(widget.lastDate)) {
      _error =
          widget.errorInvalidText ??
          DateFieldStrings.minDate(
            DateFormat.yMd().format(widget.firstDate),
          );
      return false;
    }
    _error = null;
    _value = parsed;
    return true;
  }

  void _confirm() {
    if (_mode == PickerEntryMode.input && !_readTyped()) {
      setState(() {});
      return;
    }
    Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    final style = (widget.style ?? const DateTimePickerStyle()).resolve(
      context,
    );
    final typing = _mode == PickerEntryMode.input;

    return _DialogShell(
      title: widget.title,
      summary: style.calendarSystem.describe(_value),
      style: style,
      confirmText: widget.confirmText,
      cancelText: widget.cancelText,
      onConfirm: _confirm,
      headerAction: GlobalIconButton(
        iconData: typing
            ? Icons.calendar_month_rounded
            : Icons.edit_calendar_rounded,
        iconSize: context.iconSizes.md,
        enableHaptic: style.enableHaptic,
        onPressed: _toggleMode,
        semanticLabel: typing
            ? DatePickerStrings.pickFromCalendar
            : DatePickerStrings.typeADate,
        tooltip: typing
            ? DatePickerStrings.pickFromCalendar
            : DatePickerStrings.typeADate,
        style: ButtonStateStyle(foregroundColor: style.selectedDayColor),
      ),
      child: typing
          ? _TypedDateField(
              controller: _controller,
              label: widget.fieldLabel,
              hint: widget.fieldHint,
              error: _error,
              onSubmitted: (_) => _confirm(),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.presets.isNotEmpty) ...[
                  GlobalChipStrip(
                    children: [
                      for (final preset in widget.presets)
                        GlobalChip.pill(
                          label: preset.label,
                          variant: ChipVariant.outlined,
                          selected: DateUtils.isSameDay(preset.date, _value),
                          onSelected: (_) =>
                              setState(() => _value = preset.date),
                        ),
                    ],
                  ),
                  SizedBox(height: context.spacing.sm),
                ],
                GlobalInlineCalendarRangePicker(
                  selection: CalendarSelection.single,
                  firstDate: widget.firstDate,
                  lastDate: widget.lastDate,
                  selectedRange: DateTimeRange(start: _value, end: _value),
                  style: _flat(widget.style),
                  selectableDayPredicate: widget.selectableDayPredicate,
                  startOfWeek: widget.startOfWeek,
                  markedDates: widget.markedDates,
                  autofocus: true,
                  onChanged: (range) {
                    if (range == null) return;
                    setState(() => _value = range.start);
                  },
                ),
              ],
            ),
    );
  }
}

/// The typed half of the date dialog.
class _TypedDateField extends StatelessWidget {
  const _TypedDateField({
    required this.controller,
    required this.error,
    required this.onSubmitted,
    this.label,
    this.hint,
  });

  final TextEditingController controller;
  final String? error;
  final ValueChanged<String> onSubmitted;
  final String? label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final order = TypedDate.orderForLocale();
    return Padding(
      padding: EdgeInsets.only(bottom: context.spacing.sm),
      child: GlobalTextFormField(
        controller: controller,
        hint: hint ?? order.template(),
        identifier: label ?? DateFieldStrings.selectDate,
        behavior: TextFieldBehavior(
          keyboardType: TextInputType.datetime,
          textInputAction: TextInputAction.done,
          autofocus: true,
          inputFormatters: [DateInputFormatter(order: order)],
        ),
        callbacks: TextFieldCallbacks(onSubmitted: onSubmitted),
        messages: [
          if (error != null) FieldMessage.error(error!),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time
// ---------------------------------------------------------------------------

class _TimeDialog extends StatefulWidget {
  const _TimeDialog({
    required this.initial,
    required this.use24HourFormat,
    required this.minuteInterval,
    required this.title,
    this.showSeconds = false,
    this.style,
    this.confirmText,
    this.cancelText,
  });

  final DateTime initial;
  final bool use24HourFormat;
  final int minuteInterval;
  final bool showSeconds;
  final String title;
  final DateTimePickerStyle? style;
  final String? confirmText;
  final String? cancelText;

  @override
  State<_TimeDialog> createState() => _TimeDialogState();
}

class _TimeDialogState extends State<_TimeDialog> {
  late DateTime _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    final style = (widget.style ?? const DateTimePickerStyle()).resolve(
      context,
    );

    return _DialogShell(
      title: widget.title,
      summary: PickerFormat.time(
        _value,
        use24HourFormat: widget.use24HourFormat,
      ),
      style: style,
      confirmText: widget.confirmText,
      cancelText: widget.cancelText,
      onConfirm: () => Navigator.of(context).pop(_value),
      child: GlobalDateTimePicker(
        value: _value,
        mode: DateTimePickerMode.time,
        use24HourFormat: widget.use24HourFormat,
        minuteInterval: widget.minuteInterval,
        showSeconds: widget.showSeconds,
        style: _flat(widget.style),
        onChanged: (d) => setState(() => _value = d),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date + time
// ---------------------------------------------------------------------------

class _DateTimeDialog extends StatefulWidget {
  const _DateTimeDialog({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
    required this.use24HourFormat,
    required this.minuteInterval,
    required this.title,
    this.style,
    this.confirmText,
    this.cancelText,
    this.selectableDayPredicate,
    this.startOfWeek = 0,
    this.markedDates,
  });

  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool use24HourFormat;
  final int minuteInterval;
  final bool Function(DateTime)? selectableDayPredicate;
  final int startOfWeek;
  final Map<DateTime, List<Color>>? markedDates;
  final String title;
  final DateTimePickerStyle? style;
  final String? confirmText;
  final String? cancelText;

  @override
  State<_DateTimeDialog> createState() => _DateTimeDialogState();
}

class _DateTimeDialogState extends State<_DateTimeDialog> {
  late DateTime _value = widget.initial.clampTo(
    widget.firstDate,
    widget.lastDate,
  );

  @override
  Widget build(BuildContext context) {
    final style = (widget.style ?? const DateTimePickerStyle()).resolve(
      context,
    );

    return _DialogShell(
      title: widget.title,
      summary:
          '${style.calendarSystem.describeShort(_value)} · '
          '${PickerFormat.time(_value, use24HourFormat: widget.use24HourFormat)}',
      style: style,
      confirmText: widget.confirmText,
      cancelText: widget.cancelText,
      onConfirm: () => Navigator.of(context).pop(_value),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlobalInlineCalendarRangePicker(
            selection: CalendarSelection.single,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            selectedRange: DateTimeRange(start: _value, end: _value),
            style: _flat(widget.style),
            selectableDayPredicate: widget.selectableDayPredicate,
            startOfWeek: widget.startOfWeek,
            markedDates: widget.markedDates,
            autofocus: true,
            onChanged: (range) {
              if (range == null) return;
              setState(
                () => _value = DateTime(
                  range.start.year,
                  range.start.month,
                  range.start.day,
                  _value.hour,
                  _value.minute,
                ),
              );
            },
          ),
          GlobalDivider(style: DividerStyle(color: style.borderColor)),
          // No outer SizedBox: the wheel stack takes its height from the
          // bag, and a clock face is as tall as it is.
          GlobalDateTimePicker(
            key: ValueKey('dialog-time-${widget.minuteInterval}'),
            value: _value,
            mode: DateTimePickerMode.time,
            use24HourFormat: widget.use24HourFormat,
            minuteInterval: widget.minuteInterval,
            style: _flat(widget.style).copyWith(
              wheelHeight: DateTimePickerDefaults.overlayTimeWheelHeight,
            ),
            onChanged: (d) => setState(() => _value = d),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Range
// ---------------------------------------------------------------------------

class _RangeDialog extends StatefulWidget {
  const _RangeDialog({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
    required this.presets,
    required this.title,
    this.style,
    this.minimumRangeDays,
    this.maximumRangeDays,
    this.confirmText,
    this.cancelText,
    this.fullScreen = false,
  });

  final DateTimeRange initial;
  final DateTime firstDate;
  final DateTime lastDate;
  final List<({String label, DateTimeRange range})> presets;
  final String title;
  final DateTimePickerStyle? style;
  final int? minimumRangeDays;
  final int? maximumRangeDays;
  final String? confirmText;
  final String? cancelText;

  /// Whether this is a route rather than a modal.
  final bool fullScreen;

  @override
  State<_RangeDialog> createState() => _RangeDialogState();
}

class _RangeDialogState extends State<_RangeDialog> {
  late DateTimeRange _value = widget.initial;
  String? _complaint;

  @override
  Widget build(BuildContext context) {
    final style = (widget.style ?? const DateTimePickerStyle()).resolve(
      context,
    );
    final calendar = GlobalInlineCalendarRangePicker(
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      selectedRange: _value,
      minimumRangeDays: widget.minimumRangeDays,
      maximumRangeDays: widget.maximumRangeDays,
      autofocus: true,
      // A page gets the VERTICAL list of months: the room is there, and
      // a range spanning a fold is easier to pick when both ends are on
      // screen. A modal keeps the paged one.
      style: _flat(widget.style).copyWith(
        monthFlow: widget.fullScreen ? MonthFlow.list : null,
      ),
      onRangeValidationError: (m) => setState(() => _complaint = m),
      onChanged: (range) {
        if (range == null) return;
        setState(() {
          _value = range;
          _complaint = null;
        });
      },
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: widget.fullScreen ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (widget.presets.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: context.spacing.sm),
            child: Wrap(
              spacing: context.spacing.sm,
              runSpacing: context.spacing.sm,
              children: [
                for (final preset in widget.presets)
                  GlobalChip.pill(
                    label: preset.label,
                    variant: ChipVariant.outlined,
                    selected:
                        DateUtils.isSameDay(
                          preset.range.start,
                          _value.start,
                        ) &&
                        DateUtils.isSameDay(preset.range.end, _value.end),
                    onSelected: (_) => setState(() {
                      _value = DateTimeRange(
                        start: preset.range.start.clampTo(
                          widget.firstDate,
                          widget.lastDate,
                        ),
                        end: preset.range.end.clampTo(
                          widget.firstDate,
                          widget.lastDate,
                        ),
                      );
                      _complaint = null;
                    }),
                  ),
              ],
            ),
          ),
        if (widget.fullScreen) Expanded(child: calendar) else calendar,
        if (_complaint != null)
          Padding(
            padding: EdgeInsets.only(top: context.spacing.xs),
            child: Text(
              _complaint!,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.statusColors.error,
              ),
            ),
          ),
      ],
    );

    if (!widget.fullScreen) {
      return _DialogShell(
        title: widget.title,
        summary:
            '${style.calendarSystem.describeShort(_value.start)} → '
            '${style.calendarSystem.describeShort(_value.end)}',
        style: style,
        confirmText: widget.confirmText,
        cancelText: widget.cancelText,
        onConfirm: () => Navigator.of(context).pop(_value),
        child: body,
      );
    }

    return _FullScreenShell(
      title: widget.title,
      summary:
          '${style.calendarSystem.describeShort(_value.start)} → '
          '${style.calendarSystem.describeShort(_value.end)}',
      style: style,
      confirmText: widget.confirmText,
      onConfirm: () => Navigator.of(context).pop(_value),
      child: body,
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen shell
// ---------------------------------------------------------------------------

/// A picker that owns the whole screen.
///
/// The other half of [RangePickerLayout]. A range in a modal on a phone
/// leaves the month grid squeezed between two dates and a pair of
/// buttons; given the page, the same calendar has room to be read.
class _FullScreenShell extends StatelessWidget {
  const _FullScreenShell({
    required this.title,
    required this.summary,
    required this.style,
    required this.child,
    required this.onConfirm,
    this.confirmText,
  });

  final String title;
  final String summary;
  final ResolvedDateTimePickerStyle style;
  final Widget child;
  final VoidCallback onConfirm;
  final String? confirmText;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      appBar: GlobalAppBar(
        title: title,
        subtitle: summary,
        leading: GlobalIconButton(
          iconData: Icons.close_rounded,
          enableHaptic: style.enableHaptic,
          semanticLabel: CommonStrings.cancel,
          tooltip: CommonStrings.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: EdgeInsetsDirectional.only(end: spacing.sm),
            child: GlobalTextButton(
              text: confirmText ?? CommonStrings.done,
              shrinkWidth: true,
              enableHaptic: style.enableHaptic,
              onPressed: onConfirm,
              style: ButtonStateStyle(
                foregroundColor: style.selectedDayColor,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      // No outer scroll view: the month LIST scrolls itself, and
      // wrapping an unbounded box round it would leave it nothing to
      // fill.
      body: SafeArea(
        child: Padding(padding: EdgeInsets.all(spacing.md), child: child),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Duration
// ---------------------------------------------------------------------------

class _DurationDialog extends StatefulWidget {
  const _DurationDialog({
    required this.initial,
    required this.format,
    required this.minuteInterval,
    required this.secondInterval,
    required this.maxHours,
    required this.title,
    this.maxDuration,
    this.style,
    this.confirmText,
    this.cancelText,
  });

  final Duration initial;
  final DurationFormat format;
  final int minuteInterval;
  final int secondInterval;
  final int maxHours;
  final Duration? maxDuration;
  final String title;
  final DateTimePickerStyle? style;
  final String? confirmText;
  final String? cancelText;

  @override
  State<_DurationDialog> createState() => _DurationDialogState();
}

class _DurationDialogState extends State<_DurationDialog> {
  late Duration _value = widget.initial;

  /// `h:mm:ss`, in the reader's own numerals.
  String get _summary {
    String two(int v) => AppNumbers.padded(v, width: 2);
    final hours = _value.inHours;
    final minutes = _value.inMinutes % 60;
    final seconds = _value.inSeconds % 60;
    return switch (widget.format) {
      DurationFormat.hm => '${two(hours)}:${two(minutes)}',
      DurationFormat.hms => '${two(hours)}:${two(minutes)}:${two(seconds)}',
      DurationFormat.ms => '${two(_value.inMinutes)}:${two(seconds)}',
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = (widget.style ?? const DateTimePickerStyle()).resolve(
      context,
    );

    return _DialogShell(
      title: widget.title,
      summary: _summary,
      style: style,
      confirmText: widget.confirmText,
      cancelText: widget.cancelText,
      onConfirm: () => Navigator.of(context).pop(_value),
      child: GlobalDurationPicker(
        value: _value,
        format: widget.format,
        minuteInterval: widget.minuteInterval,
        secondInterval: widget.secondInterval,
        maxHours: widget.maxHours,
        style: _flat(widget.style),
        onChanged: (d) {
          final max = widget.maxDuration;
          setState(() => _value = max != null && d > max ? max : d);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Time range
// ---------------------------------------------------------------------------

class _TimeRangeDialog extends StatefulWidget {
  const _TimeRangeDialog({
    required this.initial,
    required this.use24HourFormat,
    required this.minuteInterval,
    required this.title,
    this.style,
    this.confirmText,
    this.cancelText,
  });

  final ({DateTime start, DateTime end}) initial;
  final bool use24HourFormat;
  final int minuteInterval;
  final String title;
  final DateTimePickerStyle? style;
  final String? confirmText;
  final String? cancelText;

  @override
  State<_TimeRangeDialog> createState() => _TimeRangeDialogState();
}

class _TimeRangeDialogState extends State<_TimeRangeDialog> {
  late DateTime _start = widget.initial.start;
  late DateTime _end = widget.initial.end;

  @override
  Widget build(BuildContext context) {
    final style = (widget.style ?? const DateTimePickerStyle()).resolve(
      context,
    );

    Widget half({
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
              color: style.dayTextColor,
            ),
          ),
        ),
        GlobalDateTimePicker(
          key: ValueKey('range-$label-${widget.minuteInterval}'),
          value: value,
          mode: DateTimePickerMode.time,
          use24HourFormat: widget.use24HourFormat,
          minuteInterval: widget.minuteInterval,
          // Two stacks in one dialog: each gets less than a lone one
          // would, or the pair pushes the actions off a short screen.
          style: _flat(widget.style).copyWith(
            wheelHeight: DateTimePickerDefaults.wheelMinHeight * 0.8,
          ),
          onChanged: onChanged,
        ),
      ],
    );

    return _DialogShell(
      title: widget.title,
      summary:
          '${PickerFormat.time(_start, use24HourFormat: widget.use24HourFormat)}'
          ' → '
          '${PickerFormat.time(_end, use24HourFormat: widget.use24HourFormat)}',
      style: style,
      confirmText: widget.confirmText,
      cancelText: widget.cancelText,
      onConfirm: () => Navigator.of(context).pop((start: _start, end: _end)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          half(
            label: TimeRangeStrings.start,
            value: _start,
            onChanged: (d) => setState(() => _start = d),
          ),
          GlobalDivider(style: DividerStyle(color: style.borderColor)),
          half(
            label: TimeRangeStrings.end,
            value: _end,
            onChanged: (d) => setState(() => _end = d),
          ),
        ],
      ),
    );
  }
}
