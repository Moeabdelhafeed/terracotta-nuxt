import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/date_field_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../buttons/global_text_button.dart';
import '../divider/global_divider.dart';
import 'date_time_picker_models.dart';
import 'date_time_picker_style.dart';
import 'global_inline_calendar_range_picker.dart';
import 'picker_anchor.dart';
import 'picker_calendar_system.dart';
import 'picker_dialogs.dart';
import 'theme/date_time_picker_theme.dart';
import 'time_dial.dart';

// ---------------------------------------------------------------------------
// GlobalDateTimePicker
// ---------------------------------------------------------------------------

/// One date / time picker with five [PickerSurface]s behind it.
///
/// Everything visual lives in [DateTimePickerStyle]; the parameters here
/// are what to pick and how to behave.
class GlobalDateTimePicker extends StatefulWidget {
  const GlobalDateTimePicker({
    super.key,
    this.value,
    this.onChanged,
    this.mode = DateTimePickerMode.date,
    this.surface = PickerSurface.wheel,
    this.firstDate,
    this.lastDate,
    this.minuteInterval = 1,
    this.use24HourFormat = false,
    this.showSeconds = false,
    this.style,
    this.showHeader = false,
    this.headerTitle,
    this.onConfirm,
    this.onCancel,
    this.confirmText,
    this.cancelText,
    this.helpText,
    this.errorFormatText,
    this.errorInvalidText,
    this.fieldHintText,
    this.fieldLabelText,
    this.triggerBuilder,
    this.icon,
    this.hint,
    this.formatDate,
    this.overlayMode,
    this.selectableDayPredicate,
    this.startOfWeek = 0,
    this.markedDates,
    this.onMonthChanged,
    this.clearable = false,
  }) : assert(
         // 7 minutes gives an 8-row wheel ending at :49, and :56
         // becomes unreachable — the wheel silently loses its tail.
         minuteInterval > 0 && 60 % minuteInterval == 0,
         'minuteInterval must divide 60 (1, 2, 3, 4, 5, 6, 10, 12, 15, 20, 30, 60)',
       );

  /// Current selected date/time.
  final DateTime? value;

  /// Called on every wheel movement / calendar tap / dialog result.
  final ValueChanged<DateTime>? onChanged;

  final DateTimePickerMode mode;

  /// Where the picker lives. See [PickerSurface].
  final PickerSurface surface;

  final DateTime? firstDate;
  final DateTime? lastDate;

  /// Must divide 60.
  final int minuteInterval;
  final bool use24HourFormat;

  /// A seconds wheel after the minutes. Time modes only, and wheels
  /// only — a clock face with a second hand is a stopwatch.
  final bool showSeconds;

  /// Per-call visual overrides. `caller > GlobalDateTimePickerTheme >
  /// DateTimePickerStyle.defaults`.
  final DateTimePickerStyle? style;

  /// A cancel / title / done row above the wheels.
  final bool showHeader;
  final String? headerTitle;
  final ValueChanged<DateTime>? onConfirm;
  final VoidCallback? onCancel;
  final String? confirmText;
  final String? cancelText;

  // ─── Material dialog ────────────────────────────────────────

  final String? helpText;
  final String? errorFormatText;
  final String? errorInvalidText;
  final String? fieldHintText;
  final String? fieldLabelText;

  /// Replaces the default trigger. Receives the formatted value and the
  /// handler that opens the picker.
  final Widget Function(
    BuildContext context,
    String formattedValue,
    VoidCallback onTap,
  )?
  triggerBuilder;

  final IconData? icon;

  /// The trigger's label before anything is picked.
  final String? hint;

  /// Formats the trigger's label.
  final String Function(DateTime)? formatDate;

  /// What the OVERLAY shows, when it should differ from [mode].
  final DateTimePickerMode? overlayMode;

  /// 0 = Sunday (default), 1 = Monday, …
  ///
  /// This and the four below reach the CALENDAR surfaces — inline, in
  /// the anchored panel and in the dialogs. They were only settable by
  /// dropping to `GlobalInlineCalendarRangePicker` directly, which meant
  /// no dialog could have them.
  final int startOfWeek;

  /// Coloured dots under specific dates. Keys must be date-only.
  final Map<DateTime, List<Color>>? markedDates;

  /// Told when the visible month changes.
  final ValueChanged<DateTime>? onMonthChanged;

  /// Offer a "clear" affordance on the calendar.
  final bool clearable;

  /// Return false to grey a day out.
  ///
  /// The calendar has always had this; the WHEELS and the dialogs did
  /// not, so a field with an "allowed weekdays" rule could only enforce
  /// it after the fact, in a validator. Only the calendar surfaces
  /// honour it — a wheel of day numbers has nothing to grey.
  final bool Function(DateTime)? selectableDayPredicate;

  // ─── Factories ──────────────────────────────────────────────

  /// Date-only wheels.
  factory GlobalDateTimePicker.date({
    Key? key,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    DateTimePickerStyle? style,
  }) => GlobalDateTimePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    mode: DateTimePickerMode.date,
    firstDate: firstDate,
    lastDate: lastDate,
    style: style,
  );

  /// Time-only wheels.
  factory GlobalDateTimePicker.time({
    Key? key,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    int minuteInterval = 1,
    bool use24HourFormat = false,
    DateTimePickerStyle? style,
  }) => GlobalDateTimePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    mode: DateTimePickerMode.time,
    minuteInterval: minuteInterval,
    use24HourFormat: use24HourFormat,
    style: style,
  );

  /// Date + time wheels.
  factory GlobalDateTimePicker.dateAndTime({
    Key? key,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    int minuteInterval = 1,
    bool use24HourFormat = false,
    DateTimePickerStyle? style,
  }) => GlobalDateTimePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    mode: DateTimePickerMode.dateAndTime,
    firstDate: firstDate,
    lastDate: lastDate,
    minuteInterval: minuteInterval,
    use24HourFormat: use24HourFormat,
    style: style,
  );

  /// The module's own date dialog, on its calendar side.
  factory GlobalDateTimePicker.dialogDate({
    Key? key,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
    Widget Function(BuildContext, String, VoidCallback)? triggerBuilder,
    String? hint,
    DateTimePickerStyle? style,
    bool Function(DateTime)? selectableDayPredicate,
  }) => GlobalDateTimePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    mode: DateTimePickerMode.date,
    surface: PickerSurface.dialog,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
    triggerBuilder: triggerBuilder,
    hint: hint,
    style: style,
    selectableDayPredicate: selectableDayPredicate,
  );

  /// The same dialog, opened on its keyboard-entry side.
  factory GlobalDateTimePicker.inputDate({
    Key? key,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    String? helpText,
    String? fieldHintText,
    String? fieldLabelText,
    Widget Function(BuildContext, String, VoidCallback)? triggerBuilder,
    String? hint,
    DateTimePickerStyle? style,
    bool Function(DateTime)? selectableDayPredicate,
  }) => GlobalDateTimePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    mode: DateTimePickerMode.date,
    surface: PickerSurface.input,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
    fieldHintText: fieldHintText,
    fieldLabelText: fieldLabelText,
    triggerBuilder: triggerBuilder,
    hint: hint,
    style: style,
    selectableDayPredicate: selectableDayPredicate,
  );

  /// The app's own calendar, inline.
  factory GlobalDateTimePicker.calendar({
    Key? key,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    DateTimePickerStyle? style,
    bool Function(DateTime)? selectableDayPredicate,
  }) => GlobalDateTimePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    mode: DateTimePickerMode.date,
    surface: PickerSurface.calendar,
    firstDate: firstDate,
    lastDate: lastDate,
    style: style,
    selectableDayPredicate: selectableDayPredicate,
  );

  /// The module's own time dialog.
  factory GlobalDateTimePicker.dialogTime({
    Key? key,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    bool use24HourFormat = false,
    Widget Function(BuildContext, String, VoidCallback)? triggerBuilder,
    String? hint,
    DateTimePickerStyle? style,
  }) => GlobalDateTimePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    mode: DateTimePickerMode.time,
    surface: PickerSurface.dialog,
    use24HourFormat: use24HourFormat,
    triggerBuilder: triggerBuilder,
    hint: hint,
    style: style,
  );

  /// Calendar over wheels, in ONE dialog.
  factory GlobalDateTimePicker.dialogDateTime({
    Key? key,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    bool use24HourFormat = false,
    Widget Function(BuildContext, String, VoidCallback)? triggerBuilder,
    String? hint,
    DateTimePickerStyle? style,
  }) => GlobalDateTimePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    mode: DateTimePickerMode.dateAndTime,
    surface: PickerSurface.dialog,
    firstDate: firstDate,
    lastDate: lastDate,
    use24HourFormat: use24HourFormat,
    triggerBuilder: triggerBuilder,
    hint: hint,
    style: style,
  );

  /// A calendar panel anchored to a trigger.
  factory GlobalDateTimePicker.overlayDate({
    Key? key,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    Widget Function(BuildContext, String, VoidCallback)? triggerBuilder,
    String? hint,
    DateTimePickerStyle? style,
    bool Function(DateTime)? selectableDayPredicate,
  }) => GlobalDateTimePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    mode: DateTimePickerMode.date,
    surface: PickerSurface.overlay,
    firstDate: firstDate,
    lastDate: lastDate,
    triggerBuilder: triggerBuilder,
    hint: hint,
    style: style,
    selectableDayPredicate: selectableDayPredicate,
  );

  /// Time wheels anchored to a trigger.
  factory GlobalDateTimePicker.overlayTime({
    Key? key,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    int minuteInterval = 1,
    bool use24HourFormat = false,
    Widget Function(BuildContext, String, VoidCallback)? triggerBuilder,
    String? hint,
    DateTimePickerStyle? style,
  }) => GlobalDateTimePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    mode: DateTimePickerMode.time,
    surface: PickerSurface.overlay,
    minuteInterval: minuteInterval,
    use24HourFormat: use24HourFormat,
    triggerBuilder: triggerBuilder,
    hint: hint,
    style: style,
  );

  /// A calendar over time wheels, anchored to a trigger.
  factory GlobalDateTimePicker.overlayDateTime({
    Key? key,
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    int minuteInterval = 1,
    bool use24HourFormat = false,
    Widget Function(BuildContext, String, VoidCallback)? triggerBuilder,
    String? hint,
    DateTimePickerStyle? style,
  }) => GlobalDateTimePicker(
    key: key,
    value: value,
    onChanged: onChanged,
    mode: DateTimePickerMode.dateAndTime,
    surface: PickerSurface.overlay,
    firstDate: firstDate,
    lastDate: lastDate,
    minuteInterval: minuteInterval,
    use24HourFormat: use24HourFormat,
    triggerBuilder: triggerBuilder,
    hint: hint,
    style: style,
  );

  @override
  State<GlobalDateTimePicker> createState() => _GlobalDateTimePickerState();
}

class _GlobalDateTimePickerState extends State<GlobalDateTimePicker> {
  /// The mode, as a calendar grain. `monthYear` and `year` used to be
  /// ignored on every calendar surface — they drew a grid of days.
  CalendarGrain get _grain => switch (widget.mode) {
    DateTimePickerMode.monthYear => CalendarGrain.month,
    DateTimePickerMode.year => CalendarGrain.year,
    _ => CalendarGrain.day,
  };

  late DateTime _current;
  late DateTime _first;
  late DateTime _last;

  /// The last value this picker itself reported.
  ///
  /// A parent that echoes `onChanged` straight back used to interrupt
  /// the very scroll that produced it. The old guard was a one-shot
  /// bool, which meant a genuine external change arriving while the
  /// flag was still set got swallowed instead.
  DateTime? _lastEmitted;

  late FixedExtentScrollController _monthCtrl;
  late FixedExtentScrollController _dayCtrl;
  late FixedExtentScrollController _yearCtrl;
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;
  late FixedExtentScrollController _secondCtrl;
  late FixedExtentScrollController _amPmCtrl;

  ResolvedDateTimePickerStyle _style = ResolvedDateTimePickerStyle.fallback;

  bool get _wheelLike =>
      widget.surface == PickerSurface.wheel ||
      widget.surface == PickerSurface.overlay;

  // ─── Lifecycle ─────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _readBounds();
    _current = _normalise(widget.value ?? DateTime.now());
    _initControllers();
  }

  @override
  void didUpdateWidget(GlobalDateTimePicker oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.firstDate != oldWidget.firstDate ||
        widget.lastDate != oldWidget.lastDate) {
      _readBounds();
    }

    final incoming = widget.value;
    if (incoming != null && incoming != oldWidget.value) {
      // Our own value coming back around. Syncing here would jump the
      // wheel out from under the finger that is turning it.
      if (incoming == _lastEmitted) return;
      _current = _normalise(incoming);
      _syncControllers();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    _yearCtrl.dispose();
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _secondCtrl.dispose();
    _amPmCtrl.dispose();
    super.dispose();
  }

  void _readBounds() {
    final now = DateTime.now();
    _first =
        widget.firstDate ??
        (_wheelLike ? DateTime(now.year - 50) : DateTime(1900));
    _last =
        widget.lastDate ??
        (_wheelLike ? DateTime(now.year + 50) : DateTime(2100));
    if (_last.isBefore(_first)) _last = _first;
  }

  /// Clamp to the bounds AND to a minute the wheel can actually show.
  ///
  /// :07 on a 15-minute wheel used to sit at row 0 — the wheel read
  /// "00" while the value stayed :07, so it displayed one time and
  /// reported another.
  DateTime _normalise(DateTime value) {
    final snapped = DateTime(
      value.year,
      value.month,
      value.day,
      value.hour,
      PickerMath.snapMinute(value.minute, widget.minuteInterval),
    );
    return snapped.clampTo(_first, _last);
  }

  // ─── Wheel controllers ─────────────────────────────────────

  void _initControllers() {
    _monthCtrl = FixedExtentScrollController(initialItem: _current.month - 1);
    _dayCtrl = FixedExtentScrollController(initialItem: _current.day - 1);
    _yearCtrl = FixedExtentScrollController(
      initialItem: _current.year - _first.year,
    );
    _hourCtrl = FixedExtentScrollController(
      initialItem: PickerMath.hourIndex(
        _current.hour,
        use24HourFormat: widget.use24HourFormat,
      ),
    );
    _minuteCtrl = FixedExtentScrollController(
      initialItem: _current.minute ~/ widget.minuteInterval,
    );
    _secondCtrl = FixedExtentScrollController(initialItem: _current.second);
    _amPmCtrl = FixedExtentScrollController(
      initialItem: _current.hour >= 12 ? 1 : 0,
    );
  }

  /// `jumpToItem` walks `positions`, so a controller whose wheel this
  /// mode never builds is a no-op rather than a throw — but the guard
  /// says so out loud, because that is not obvious from the call.
  void _jump(FixedExtentScrollController ctrl, int item) {
    if (!ctrl.hasClients) return;
    ctrl.jumpToItem(item);
  }

  void _syncControllers() {
    _jump(_monthCtrl, _current.month - 1);
    _jump(_dayCtrl, _current.day - 1);
    _jump(_yearCtrl, _current.year - _first.year);
    _jump(
      _hourCtrl,
      PickerMath.hourIndex(
        _current.hour,
        use24HourFormat: widget.use24HourFormat,
      ),
    );
    _jump(_minuteCtrl, _current.minute ~/ widget.minuteInterval);
    _jump(_secondCtrl, _current.second);
    _jump(_amPmCtrl, _current.hour >= 12 ? 1 : 0);
  }

  bool get _isPm =>
      _amPmCtrl.hasClients ? _amPmCtrl.selectedItem == 1 : _current.hour >= 12;

  void _update({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    bool? isPm,
  }) {
    final oldDays = PickerMath.daysInMonth(_current.year, _current.month);

    final next = PickerMath.rebuild(
      _current,
      year: year,
      month: month,
      day: day,
      hour: hour,
      minute: minute,
      second: second,
      isPm: isPm,
      use24HourFormat: widget.use24HourFormat,
    ).clampTo(_first, _last);

    // Nothing changed — and this is not merely an optimisation.
    // `_syncControllers` jumps the wheels, each jump reports its new
    // index synchronously, and reporting THAT back to the parent while
    // it is mid-build is a `setState() during build` crash.
    if (next == _current) return;

    _current = next;
    _lastEmitted = next;
    widget.onChanged?.call(next);

    // Rebuild only when the DAY wheel's item count changed — a
    // `setState` on every tick kills the scroll gesture in progress.
    final newDays = PickerMath.daysInMonth(next.year, next.month);
    if (newDays != oldDays) setState(() {});
  }

  // ─── Overlay body ──────────────────────────────────────────

  Widget _buildOverlayBody(BuildContext context, VoidCallback close) {
    final mode = widget.overlayMode ?? widget.mode;

    Widget calendar({required bool closeOnPick}) =>
        GlobalInlineCalendarRangePicker(
          selection: CalendarSelection.single,
          selectedRange: DateTimeRange(start: _current, end: _current),
          firstDate: _first,
          lastDate: _last,
          // The panel IS the surface; a second bordered, shadowed box
          // inside it drew a frame within a frame.
          style: (widget.style ?? const DateTimePickerStyle()).mergedWith(
            DateTimePickerStyle.flat,
          ),
          selectableDayPredicate: widget.selectableDayPredicate,
          startOfWeek: widget.startOfWeek,
          markedDates: widget.markedDates,
          onMonthChanged: widget.onMonthChanged,
          clearable: widget.clearable,
          grain: _grain,
          autofocus: true,
          onChanged: (range) {
            if (range == null) return;
            setState(
              () => _update(
                year: range.start.year,
                month: range.start.month,
                day: range.start.day,
              ),
            );
            // A date-only panel has nothing left to ask, so it gets out
            // of the way. A date+time one still has the wheels below.
            if (closeOnPick) close();
          },
        );

    return switch (mode) {
      DateTimePickerMode.time =>
        _usesDial
            ? Padding(
                padding: EdgeInsets.all(context.spacing.md),
                child: _timeDial(),
              )
            : SizedBox(height: _style.wheelHeight, child: _buildWheels()),
      // No scroll view here — `PickerAnchor` owns the scrolling, so
      // that what it measures is this panel's NATURAL height.
      DateTimePickerMode.date ||
      DateTimePickerMode.monthYear ||
      DateTimePickerMode.year => calendar(closeOnPick: true),
      DateTimePickerMode.dateAndTime => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          calendar(closeOnPick: false),
          const GlobalDivider(),
          if (_style.timeLayout == TimePickerLayout.dial)
            Padding(
              padding: EdgeInsets.all(context.spacing.md),
              child: TimeDial(
                value: _current,
                use24HourFormat: widget.use24HourFormat,
                minuteInterval: widget.minuteInterval,
                style: widget.style,
                onChanged: (d) => setState(
                  () => _update(hour: d.hour, minute: d.minute),
                ),
              ),
            )
          else
            SizedBox(
              height: DateTimePickerDefaults.overlayTimeWheelHeight,
              child: _buildTimeWheels(),
            ),
        ],
      ),
    };
  }

  // ─── Formatting ────────────────────────────────────────────

  String _formatValue() {
    if (widget.formatDate != null) return widget.formatDate!(_current);
    final time = PickerFormat.time(
      _current,
      use24HourFormat: widget.use24HourFormat,
    );
    // A Hijri picker says the date it drew. Reporting 19/8/2026 under a
    // grid that counted ١٤٤٨ is two calendars in one field.
    final date = _style.calendar == PickerCalendar.hijri
        ? _style.calendarSystem.describeShort(_current)
        : PickerFormat.short(_current);

    return switch (widget.mode) {
      DateTimePickerMode.date => date,
      DateTimePickerMode.time => time,
      DateTimePickerMode.dateAndTime => '$date $time',
      DateTimePickerMode.monthYear => AppNumbers.localizeDigits(
        DateFormat.yMMM().format(_current),
      ),
      DateTimePickerMode.year => AppNumbers.padded(_current.year, width: 4),
    };
  }

  String get _hintText =>
      widget.hint ??
      switch (widget.mode) {
        DateTimePickerMode.date => DateFieldStrings.selectDate,
        DateTimePickerMode.time => DatePickerStrings.selectTime,
        DateTimePickerMode.dateAndTime => DatePickerStrings.selectDateTime,
        DateTimePickerMode.monthYear => DatePickerStrings.selectMonthYear,
        DateTimePickerMode.year => DatePickerStrings.selectYear,
      };

  // ─── Material dialogs ──────────────────────────────────────

  Future<void> _openDialog() async {
    final picked = switch (widget.mode) {
      DateTimePickerMode.time => await PickerDialogs.time(
        context,
        initial: _current,
        use24HourFormat: widget.use24HourFormat,
        minuteInterval: widget.minuteInterval,
        style: widget.style,
        title: widget.helpText,
        confirmText: widget.confirmText,
        cancelText: widget.cancelText,
      ),
      DateTimePickerMode.dateAndTime => await PickerDialogs.dateAndTime(
        context,
        initial: _current,
        firstDate: _first,
        lastDate: _last,
        use24HourFormat: widget.use24HourFormat,
        minuteInterval: widget.minuteInterval,
        style: widget.style,
        selectableDayPredicate: widget.selectableDayPredicate,
        startOfWeek: widget.startOfWeek,
        markedDates: widget.markedDates,
        title: widget.helpText,
        confirmText: widget.confirmText,
        cancelText: widget.cancelText,
      ),
      _ => await PickerDialogs.date(
        context,
        initial: _current,
        firstDate: _first,
        lastDate: _last,
        style: widget.style,
        selectableDayPredicate: widget.selectableDayPredicate,
        startOfWeek: widget.startOfWeek,
        markedDates: widget.markedDates,
        entryMode: widget.surface == PickerSurface.input
            ? PickerEntryMode.input
            : PickerEntryMode.calendar,
        title: widget.helpText,
        confirmText: widget.confirmText,
        cancelText: widget.cancelText,
        fieldLabel: widget.fieldLabelText,
        fieldHint: widget.fieldHintText,
        errorFormatText: widget.errorFormatText,
        errorInvalidText: widget.errorInvalidText,
      ),
    };
    if (picked == null || !mounted) return;
    setState(
      () => _update(
        year: picked.year,
        month: picked.month,
        day: picked.day,
        hour: picked.hour,
        minute: picked.minute,
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _style = (widget.style ?? const DateTimePickerStyle()).resolve(context);

    return switch (widget.surface) {
      PickerSurface.overlay => PickerAnchor(
        style: _style,
        trigger: (context, open, toggle) =>
            _buildTrigger(context, onTap: toggle, active: open),
        panel: _buildOverlayBody,
      ),
      PickerSurface.dialog ||
      PickerSurface.input => _buildTrigger(context, onTap: _openDialog),
      PickerSurface.calendar => GlobalInlineCalendarRangePicker(
        selection: CalendarSelection.single,
        selectedRange: DateTimeRange(start: _current, end: _current),
        firstDate: _first,
        lastDate: _last,
        style: widget.style,
        selectableDayPredicate: widget.selectableDayPredicate,
        startOfWeek: widget.startOfWeek,
        markedDates: widget.markedDates,
        onMonthChanged: widget.onMonthChanged,
        clearable: widget.clearable,
        grain: _grain,
        onChanged: (range) {
          if (range == null) return;
          setState(
            () => _update(
              year: range.start.year,
              month: range.start.month,
              day: range.start.day,
            ),
          );
        },
      ),
      PickerSurface.wheel => _buildInlineWheels(context),
    };
  }

  /// Whether a TIME is being asked for on a clock face rather than on
  /// wheels. Only the time modes have a face to offer.
  bool get _usesDial =>
      widget.mode == DateTimePickerMode.time &&
      _style.timeLayout == TimePickerLayout.dial;

  Widget _timeDial() => TimeDial(
    value: _current,
    use24HourFormat: widget.use24HourFormat,
    minuteInterval: widget.minuteInterval,
    style: widget.style,
    onChanged: (d) => setState(() => _update(hour: d.hour, minute: d.minute)),
  );

  Widget _buildInlineWheels(BuildContext context) {
    final dial = _usesDial;
    return Container(
      // A dial is as tall as it is; only a wheel stack needs telling.
      height: dial
          ? null
          : _style.wheelHeight + (widget.showHeader ? _style.headerHeight : 0),
      decoration: BoxDecoration(
        color: _style.surfaceColor,
        borderRadius: BorderRadius.circular(_style.radius),
      ),
      child: Column(
        mainAxisSize: dial ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (widget.showHeader) _buildHeader(context),
          if (dial)
            Padding(
              padding: EdgeInsets.all(context.spacing.md),
              child: _timeDial(),
            )
          else
            Expanded(child: _buildWheels()),
        ],
      ),
    );
  }

  /// The cancel / title / done row above the wheels.
  ///
  /// A `spaceBetween` Row centred the title BETWEEN the two buttons, so
  /// "Cancel" and "Done" being different widths pushed it off the middle
  /// of the picker. `NavigationToolbar` is what an `AppBar` uses for
  /// exactly this: the middle is centred on the ROW, and only gives way
  /// when it would otherwise collide with a side.
  Widget _buildHeader(BuildContext context) {
    final title = widget.headerTitle;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: _style.borderColor,
            width: _style.borderWidth,
          ),
        ),
      ),
      child: SizedBox(
        height: _style.headerHeight,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: _style.headerPadding,
          ),
          child: NavigationToolbar(
            centerMiddle: true,
            middleSpacing: context.spacing.sm,
            leading: GlobalTextButton(
              text: widget.cancelText ?? CommonStrings.cancel,
              onPressed: widget.onCancel,
              shrinkWidth: true,
              enableHaptic: _style.enableHaptic,
              style: ButtonStateStyle(
                foregroundColor: context.textColors.secondary,
                padding: EdgeInsets.symmetric(horizontal: context.spacing.sm),
              ),
            ),
            middle: title == null
                ? null
                : Semantics(
                    header: true,
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _style.headerTitleStyle,
                    ),
                  ),
            // The one action the header is FOR, so it wears the accent
            // as a surface rather than as tinted text sitting level with
            // "Cancel" — the two used to read as a pair of equals.
            trailing: GlobalTextButton(
              text: widget.confirmText ?? CommonStrings.done,
              onPressed: () => widget.onConfirm?.call(_current),
              shrinkWidth: true,
              enableHaptic: _style.enableHaptic,
              style: ButtonStateStyle(
                foregroundColor: _style.selectedDayColor,
                backgroundColor: _style.selectedDayColor.withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(context.radii.full),
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.md,
                  vertical: context.spacing.xs,
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Wheels ────────────────────────────────────────────────

  Widget _buildWheels() => switch (widget.mode) {
    DateTimePickerMode.date => _buildDateWheels(),
    DateTimePickerMode.time => _buildTimeWheels(),
    DateTimePickerMode.dateAndTime => _buildDateAndTimeWheels(),
    DateTimePickerMode.monthYear => _buildMonthYearWheels(),
    DateTimePickerMode.year => _buildYearWheel(),
  };

  List<String> get _monthNumbers => [for (var i = 1; i <= 12; i++) _digits(i)];

  List<String> get _shortMonths => DateFormat.MMM().dateSymbols.SHORTMONTHS;

  List<String> get _dayNumbers => [
    for (
      var i = 1;
      i <= PickerMath.daysInMonth(_current.year, _current.month);
      i++
    )
      _digits(i),
  ];

  List<String> get _years => [
    // `padded`, not `DateFormat.y()`: a year is a NUMBER here, and the
    // locale's own digits are what a wheel of them should show. Padded
    // rather than grouped, or 2026 becomes ٢٬٠٢٦.
    for (var y = _first.year; y <= _last.year; y++)
      AppNumbers.padded(y, width: 4),
  ];

  List<String> get _hours => [
    for (
      var i = widget.use24HourFormat ? 0 : 1;
      i <= (widget.use24HourFormat ? 23 : 12);
      i++
    )
      _digits(i),
  ];

  List<String> get _seconds => [for (var i = 0; i < 60; i++) _digits(i)];

  List<String> get _minutes => [
    for (var i = 0; i < 60; i += widget.minuteInterval) _digits(i),
  ];

  /// AM / PM straight from the locale's own symbols — an ARB copy of
  /// two words `intl` already knows would only drift from it.
  List<String> get _periods => DateFormat().dateSymbols.AMPMS;

  /// Two digits, in the LOCALE's own numerals — `AppNumbers` maps
  /// Arabic onto the variant that actually emits Arabic-Indic ones.
  String _digits(int value) => AppNumbers.padded(value, width: 2);

  Widget _buildDateWheels() => Row(
    children: [
      _wheel(
        ctrl: _monthCtrl,
        items: _monthNumbers,
        label: DatePickerStrings.month,
        onChanged: (i) => _update(month: i + 1),
      ),
      _separator('/'),
      _wheel(
        ctrl: _dayCtrl,
        items: _dayNumbers,
        label: DatePickerStrings.day,
        onChanged: (i) => _update(day: i + 1),
      ),
      _separator('/'),
      _wheel(
        ctrl: _yearCtrl,
        items: _years,
        flex: 2,
        label: DatePickerStrings.year,
        onChanged: (i) => _update(year: _first.year + i),
      ),
    ],
  );

  Widget _buildTimeWheels() => Row(
    children: [
      _wheel(
        ctrl: _hourCtrl,
        items: _hours,
        label: DatePickerStrings.hour,
        onChanged: (i) => _update(
          hour: PickerMath.hour24(
            index: i,
            use24HourFormat: widget.use24HourFormat,
            isPm: _isPm,
          ),
        ),
      ),
      _separator(':'),
      _wheel(
        ctrl: _minuteCtrl,
        items: _minutes,
        label: DatePickerStrings.minute,
        onChanged: (i) => _update(minute: i * widget.minuteInterval),
      ),
      if (widget.showSeconds) ...[
        _separator(':'),
        _wheel(
          ctrl: _secondCtrl,
          items: _seconds,
          label: DatePickerStrings.second,
          onChanged: (i) => _update(second: i),
        ),
      ],
      if (!widget.use24HourFormat) ...[
        SizedBox(width: context.spacing.xs),
        _wheel(
          ctrl: _amPmCtrl,
          items: _periods,
          label: DatePickerStrings.period,
          onChanged: (i) => _update(isPm: i == 1),
        ),
      ],
    ],
  );

  /// Six wheels in one row, flex-weighted by how many glyphs each
  /// carries — the YEAR is here, because without it a `dateAndTime`
  /// picker could not set one at all.
  Widget _buildDateAndTimeWheels() => Row(
    children: [
      _wheel(
        ctrl: _monthCtrl,
        items: _monthNumbers,
        flex: 2,
        label: DatePickerStrings.month,
        onChanged: (i) => _update(month: i + 1),
      ),
      _wheel(
        ctrl: _dayCtrl,
        items: _dayNumbers,
        flex: 2,
        label: DatePickerStrings.day,
        onChanged: (i) => _update(day: i + 1),
      ),
      _wheel(
        ctrl: _yearCtrl,
        items: _years,
        flex: 3,
        label: DatePickerStrings.year,
        onChanged: (i) => _update(year: _first.year + i),
      ),
      SizedBox(width: context.spacing.xs),
      _wheel(
        ctrl: _hourCtrl,
        items: _hours,
        flex: 2,
        label: DatePickerStrings.hour,
        onChanged: (i) => _update(
          hour: PickerMath.hour24(
            index: i,
            use24HourFormat: widget.use24HourFormat,
            isPm: _isPm,
          ),
        ),
      ),
      _separator(':'),
      _wheel(
        ctrl: _minuteCtrl,
        items: _minutes,
        flex: 2,
        label: DatePickerStrings.minute,
        onChanged: (i) => _update(minute: i * widget.minuteInterval),
      ),
      if (!widget.use24HourFormat)
        _wheel(
          ctrl: _amPmCtrl,
          items: _periods,
          flex: 2,
          label: DatePickerStrings.period,
          onChanged: (i) => _update(isPm: i == 1),
        ),
    ],
  );

  Widget _buildMonthYearWheels() => Row(
    children: [
      _wheel(
        ctrl: _monthCtrl,
        items: _shortMonths,
        label: DatePickerStrings.month,
        onChanged: (i) => _update(month: i + 1),
      ),
      _separator('/'),
      _wheel(
        ctrl: _yearCtrl,
        items: _years,
        label: DatePickerStrings.year,
        onChanged: (i) => _update(year: _first.year + i),
      ),
    ],
  );

  Widget _buildYearWheel() => Center(
    child: SizedBox(
      width: 120,
      child: Row(
        children: [
          _wheel(
            ctrl: _yearCtrl,
            items: _years,
            label: DatePickerStrings.year,
            onChanged: (i) => _update(year: _first.year + i),
          ),
        ],
      ),
    ),
  );

  Widget _wheel({
    required FixedExtentScrollController ctrl,
    required List<String> items,
    required String label,
    required ValueChanged<int> onChanged,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: Semantics(
        // Each row is a `Text`, so a reader already hears the numbers;
        // what it could not hear was WHICH wheel it was on. The child
        // nodes stay EXPLICIT — merged, the wheel's label would be the
        // word "Minute" followed by all sixty of them.
        container: true,
        explicitChildNodes: true,
        label: label,
        child: CupertinoPicker(
          scrollController: ctrl,
          itemExtent: _style.wheelItemExtent,
          useMagnifier: _style.wheelMagnifier,
          magnification: _style.wheelMagnification,
          squeeze: _style.wheelSqueeze,
          selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
            background: _style.wheelSelectionColor,
          ),
          onSelectedItemChanged: (index) {
            if (_style.enableHaptic) HapticFeedback.selectionClick();
            onChanged(index);
          },
          children: [
            for (final item in items)
              Center(child: Text(item, style: _style.wheelTextStyle)),
          ],
        ),
      ),
    );
  }

  Widget _separator(String char) => Padding(
    padding: EdgeInsets.symmetric(horizontal: _style.wheelSeparatorGap),
    child: ExcludeSemantics(
      child: Text(char, style: _style.wheelSeparatorStyle),
    ),
  );

  // ─── Trigger ───────────────────────────────────────────────

  Widget _buildTrigger(
    BuildContext context, {
    required VoidCallback onTap,
    bool active = false,
  }) {
    final formatted = _formatValue();
    final hasValue = widget.value != null;

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
                  widget.icon ??
                      (widget.mode == DateTimePickerMode.time
                          ? Icons.access_time
                          : Icons.calendar_today),
                  size: _style.triggerIconSize,
                  color: active
                      ? _style.triggerActiveBorderColor
                      : _style.triggerIconColor,
                ),
                SizedBox(width: _style.triggerGap),
                Expanded(
                  child: Text(
                    hasValue ? formatted : _hintText,
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
                  Icon(
                    Icons.arrow_drop_down,
                    color: _style.triggerIconColor,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
