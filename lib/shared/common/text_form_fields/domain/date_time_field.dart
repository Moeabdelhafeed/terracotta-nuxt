import 'package:flutter/material.dart';

import '../../../../core/localization/strings/date_field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../module/date_time_picker/date_time_picker.dart';
import '../../../module/text_field/global_text_field.dart';
import 'date_field.dart';
import 'joined_pair_radii.dart';
import 'time_field.dart';

/// The parsed value a [DateTimeField] emits on every change — the
/// combined [DateTime] (null until BOTH parts parse) and the validity
/// snapshot.
@immutable
class DateTimeValue {
  const DateTimeValue({required this.dateTime, required this.isValid});

  /// Local date + time (+ seconds when the time field shows them), or
  /// null while either part is incomplete.
  final DateTime? dateTime;

  /// Both parts pass their sync validators (including the dynamic
  /// same-day window from `minDateTime` / `maxDateTime`).
  final bool isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateTimeValue &&
          other.dateTime == dateTime &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(dateTime, isValid);

  @override
  String toString() => 'DateTimeValue($dateTime, valid: $isValid)';
}

/// [DateField] + [TimeField] emitting ONE `DateTime` — with the rule
/// composites exist for: [minDateTime] / [maxDateTime] tighten the TIME
/// window only when the picked DATE sits on the boundary day. A booking
/// floor of `now + 2h` limits today's times but leaves tomorrow fully
/// open; the date field itself is clamped to the boundary dates.
///
/// Two layouts:
/// * **[joined]** (default) — ONE segmented control: date box + time box
///   attached (flat seam), a single leading icon, and ONE trailing
///   button that walks the date dialog THEN the time dialog and fills
///   both. [identifier] spans the control.
/// * **split** (`joined: false`) — two labeled fields side by side,
///   each with its own picker.
///
/// Focus chains date → time; [onChanged] fires with a [DateTimeValue]
/// on every edit to either part.
class DateTimeField extends StatefulWidget {
  const DateTimeField({
    super.key,
    this.dateController,
    this.timeController,
    this.onChanged,
    this.joined = true,
    this.identifier,
    this.dateIdentifier,
    this.timeIdentifier,
    this.order,
    this.hourFormat = TimeFieldHourFormat.auto,
    this.showFormatPicker = false,
    this.showSeconds = false,
    this.minDateTime,
    this.maxDateTime,
    this.minuteInterval,
    this.allowedWeekdays,
    this.disabledDate,
    this.required = true,
    this.showNowButton = false,
    this.calendar = DateFieldCalendar.dialog,
    this.pickerLayout,
    this.enabled = true,
    this.deferToParentForm = true,
    this.validationMode = ValidationMode.onInteraction,
    this.style,
    this.sizing,
  });

  /// Controllers are optional — the widget owns them when absent.
  final TextEditingController? dateController;
  final TextEditingController? timeController;

  /// Combined value on every change to either part. See [DateTimeValue].
  final ValueChanged<DateTimeValue>? onChanged;

  /// One attached control with a single leading icon + a single
  /// date-then-time picker button (default). `false` → two labeled
  /// fields, each with its own picker.
  final bool joined;

  /// [joined] only: the header above the whole control.
  final String? identifier;

  /// Split layout column headers. Null → localized "Date" / "Time".
  final String? dateIdentifier;
  final String? timeIdentifier;

  /// Digit order for the date part. Null → locale.
  final DateDigitOrder? order;

  /// Hour notation for the time part.
  final TimeFieldHourFormat hourFormat;
  final bool showFormatPicker;
  final bool showSeconds;

  /// Combined window. The date part is clamped to the boundary DATES;
  /// the time part gets a min/max only while the picked date IS the
  /// boundary day.
  final DateTime? minDateTime;
  final DateTime? maxDateTime;

  /// Minute grid for the time part.
  final int? minuteInterval;

  /// Day rules for the date part — see [DateField.allowedWeekdays] /
  /// [DateField.disabledDate].
  final Set<int>? allowedWeekdays;
  final bool Function(DateTime date)? disabledDate;

  /// Empty parts fail validation.
  final bool required;

  /// "Now" action on the time part (split layout; the joined layout
  /// keeps the suffix for the combined picker).
  final bool showNowButton;

  final DateFieldCalendar calendar;

  /// Wheels or a clock face, for the time half. See [TimeField].
  final TimePickerLayout? pickerLayout;
  final bool enabled;

  /// Keep `true` inside a `Form`; `false` standalone.
  final bool deferToParentForm;

  final ValidationMode validationMode;

  /// Visual override applied to both parts.
  final TextFieldStyle? style;

  /// Box geometry applied to both parts.
  final TextFieldSizing? sizing;

  @override
  State<DateTimeField> createState() => _DateTimeFieldState();
}

class _DateTimeFieldState extends State<DateTimeField> {
  TextEditingController? _ownedDate;
  TextEditingController? _ownedTime;
  final _timeFocus = FocusNode();

  /// Imperative write channels into the children — the sequential
  /// picker fills both parts through them (a bare text write can't set
  /// the 12h period).
  final _applyDate = ValueNotifier<DateTime?>(null);
  final _applyTime = ValueNotifier<TimeOfDay?>(null);

  DateValue? _dateValue;
  TimeValue? _timeValue;

  TextEditingController get _date =>
      widget.dateController ?? (_ownedDate ??= TextEditingController());
  TextEditingController get _time =>
      widget.timeController ?? (_ownedTime ??= TextEditingController());

  @override
  void dispose() {
    _ownedDate?.dispose();
    _ownedTime?.dispose();
    _timeFocus.dispose();
    _applyDate.dispose();
    _applyTime.dispose();
    super.dispose();
  }

  DateTime? _dateOnly(DateTime? d) =>
      d == null ? null : DateTime(d.year, d.month, d.day);

  /// The boundary-day rule: the time window applies only while the
  /// picked date IS the boundary date.
  TimeOfDay? _minTimeFor(DateTime? date) {
    final min = widget.minDateTime;
    if (min == null || date == null) return null;
    return _dateOnly(date) == _dateOnly(min)
        ? TimeOfDay.fromDateTime(min)
        : null;
  }

  TimeOfDay? _maxTimeFor(DateTime? date) {
    final max = widget.maxDateTime;
    if (max == null || date == null) return null;
    return _dateOnly(date) == _dateOnly(max)
        ? TimeOfDay.fromDateTime(max)
        : null;
  }

  void _emit() {
    final cb = widget.onChanged;
    if (cb == null) return;
    final date = _dateValue?.date;
    final dt = date == null ? null : _timeValue?.onDate(date);
    cb(
      DateTimeValue(
        dateTime: dt,
        isValid:
            (_dateValue?.isValid ?? false) && (_timeValue?.isValid ?? false),
      ),
    );
  }

  // ── joined picker (date AND time, in ONE dialog) ──────────────────
  Future<void> _openCombinedPicker() async {
    final t = DateTime.now();
    final first = _dateOnly(widget.minDateTime) ?? DateTime(1900);
    final last = _dateOnly(widget.maxDateTime) ?? DateTime(2100, 12, 31);
    DateTime clamp(DateTime d) =>
        d.isBefore(first) ? first : (d.isAfter(last) ? last : d);

    final seedDate = clamp(_dateValue?.date ?? _dateOnly(t)!);
    final seedTime =
        _timeValue?.time ?? _minTimeFor(seedDate) ?? TimeOfDay.fromDateTime(t);

    final use24h = switch (widget.hourFormat) {
      TimeFieldHourFormat.h24 => true,
      TimeFieldHourFormat.h12 => false,
      TimeFieldHourFormat.auto =>
        MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? true,
    };

    // ONE dialog, calendar over wheels. It used to be two in a row —
    // pick a date, it closes, pick a time — with no way back to the
    // first without starting over, and cancelling the second left the
    // date already committed.
    final picked = await PickerDialogs.dateAndTime(
      context,
      initial: DateTime(
        seedDate.year,
        seedDate.month,
        seedDate.day,
        seedTime.hour,
        seedTime.minute,
      ),
      firstDate: first,
      lastDate: last,
      use24HourFormat: use24h,
      title: DatetimeFieldStrings.date,
      style: DateTimePickerStyle(
        timeLayout: widget.pickerLayout ?? TimePickerLayout.wheels,
      ),
    );
    if (picked == null || !mounted) return;

    // Null-first so re-picking the same value still notifies.
    _applyDate.value = null;
    _applyDate.value = DateTime(picked.year, picked.month, picked.day);
    _applyTime.value = null;
    _applyTime.value = TimeOfDay(hour: picked.hour, minute: picked.minute);
  }

  Widget _dateField({required bool joined}) {
    final baseStyle = widget.style ?? const TextFieldStyle();
    return DateField(
      controller: _date,
      identifier: joined
          ? null
          : (widget.dateIdentifier ?? DatetimeFieldStrings.date),
      order: widget.order,
      required: widget.required,
      minDate: _dateOnly(widget.minDateTime),
      maxDate: _dateOnly(widget.maxDateTime),
      allowedWeekdays: widget.allowedWeekdays,
      disabledDate: widget.disabledDate,
      calendar: widget.calendar,
      // Joined: the combined trailing button replaces the per-part one.
      showCalendarButton: !joined,
      applyDate: _applyDate,
      enabled: widget.enabled,
      deferToParentForm: widget.deferToParentForm,
      validationMode: widget.validationMode,
      style: joined
          ? baseStyle.copyWith(
              borderRadius: edgeRadii(
                context,
                roundStart: true,
                roundEnd: false,
              ),
            )
          : widget.style,
      sizing: widget.sizing,
      onDateChanged: (v) {
        // The time window depends on the picked date — rebuild.
        setState(() => _dateValue = v);
        _emit();
      },
      onCompleted: (_) => _timeFocus.requestFocus(),
    );
  }

  Widget _timeField({required bool joined}) {
    final baseStyle = widget.style ?? const TextFieldStyle();
    final date = _dateValue?.date;
    return TimeField(
      controller: _time,
      focusNode: _timeFocus,
      identifier: joined
          ? null
          : (widget.timeIdentifier ?? DatetimeFieldStrings.time),
      hourFormat: widget.hourFormat,
      showFormatPicker: widget.showFormatPicker,
      showSeconds: widget.showSeconds,
      required: widget.required,
      minTime: _minTimeFor(date),
      maxTime: _maxTimeFor(date),
      minuteInterval: widget.minuteInterval,
      showNowButton: !joined && widget.showNowButton,
      showPrefixIcon: !joined, // one leading icon — the date's
      showClockButton: !joined,
      pickerLayout: widget.pickerLayout,
      applyTime: _applyTime,
      // Joined: the ONE trailing button walks date → time dialogs.
      suffix: joined && widget.enabled
          ? TextFieldSuffix.icon(
              Icons.edit_calendar_outlined,
              onTap: _openCombinedPicker,
            )
          : null,
      textInputAction: TextInputAction.done,
      enabled: widget.enabled,
      deferToParentForm: widget.deferToParentForm,
      validationMode: widget.validationMode,
      style: joined
          ? baseStyle.copyWith(
              borderRadius: edgeRadii(
                context,
                roundStart: false,
                roundEnd: true,
              ),
            )
          : widget.style,
      sizing: widget.sizing,
      onTimeChanged: (v) {
        setState(() => _timeValue = v);
        _emit();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.joined) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: _dateField(joined: false)),
          SizedBox(width: context.spacing.md),
          Expanded(flex: 2, child: _timeField(joined: false)),
        ],
      );
    }

    // Joined: one attached control (flat seam), single header.
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.identifier != null)
          Padding(
            padding: EdgeInsets.only(bottom: context.spacing.sm),
            child: Text(
              widget.identifier!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _dateField(joined: true)),
            Expanded(flex: 2, child: _timeField(joined: true)),
          ],
        ),
      ],
    );
  }
}
