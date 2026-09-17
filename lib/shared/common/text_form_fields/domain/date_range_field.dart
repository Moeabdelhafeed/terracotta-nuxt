import 'package:flutter/material.dart';

import '../../../../core/localization/strings/date_field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../module/buttons/global_text_button.dart';
import '../../../module/date_time_picker/date_time_picker.dart';
import '../../../module/text_field/global_text_field.dart';
import 'date_field.dart';

/// The parsed value a [DateRangeField] emits on every change — both ends
/// plus the validity snapshot, with the night/day counts consumers
/// otherwise re-derive.
@immutable
class DateRange {
  const DateRange({
    required this.start,
    required this.end,
    required this.isValid,
  });

  /// Null while that end is empty / incomplete / impossible.
  final DateTime? start;
  final DateTime? end;

  /// Both ends parse AND pass their field validators (including the
  /// cross-field rule).
  final bool isValid;

  /// Whole nights between the ends (hotel math: check-in 14th, check-out
  /// 16th → 2). Null while either end is; negative means inverted.
  int? get nights =>
      (start == null || end == null) ? null : end!.difference(start!).inDays;

  /// Calendar days covered, inclusive of both ends ([nights] + 1).
  int? get days => nights == null ? null : nights! + 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          other.start == start &&
          other.end == end &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(start, end, isValid);

  @override
  String toString() => 'DateRange($start → $end, valid: $isValid)';
}

/// Start + end [DateField]s wired the right way — one widget (the
/// `PaymentCardForm` treatment):
///
/// * The end field cross-validates against the start (strictly after by
///   default; [allowSameDay] for same-day ranges) and re-checks when the
///   start changes.
/// * The end calendar can't open before the (typed) start.
/// * Focus chains: completing the start hops to the end.
/// * A nights info row under the end field ([showNightsInfo]).
/// * One [onRangeChanged] with a parsed [DateRange].
///
/// Both fields share [order] / bounds / day rules, so typing and the
/// calendars agree on what's selectable.
class DateRangeField extends StatefulWidget {
  const DateRangeField({
    super.key,
    this.startController,
    this.endController,
    this.onRangeChanged,
    this.startIdentifier,
    this.endIdentifier,
    this.order,
    this.minDate,
    this.maxDate,
    this.minDaysAhead,
    this.maxDaysAhead,
    this.allowedWeekdays,
    this.disabledDate,
    this.allowSameDay = false,
    this.required = true,
    this.showNightsInfo = true,
    this.showRangeCalendar = true,
    this.presets,
    this.showHijri = false,
    this.calendar = DateFieldCalendar.dialog,
    this.enabled = true,
    this.deferToParentForm = true,
    this.validationMode = ValidationMode.onInteraction,
    this.style,
    this.sizing,
  });

  /// Controllers are optional — the widget owns them when absent.
  final TextEditingController? startController;
  final TextEditingController? endController;

  /// Parsed range on every change to either end. See [DateRange].
  final ValueChanged<DateRange>? onRangeChanged;

  /// Column headers. Null → localized "Start date" / "End date".
  final String? startIdentifier;
  final String? endIdentifier;

  /// Digit order for BOTH fields. Null → locale.
  final DateDigitOrder? order;

  /// Shared window for both ends (booking horizon etc.).
  final DateTime? minDate;
  final DateTime? maxDate;
  final int? minDaysAhead;
  final int? maxDaysAhead;

  /// Day rules applied to both ends — see [DateField.allowedWeekdays] /
  /// [DateField.disabledDate].
  final Set<int>? allowedWeekdays;
  final bool Function(DateTime date)? disabledDate;

  /// Same-day ranges allowed (end ≥ start). Default: end > start.
  final bool allowSameDay;

  /// Empty ends fail validation.
  final bool required;

  /// Info row under the end field: "7 nights" once both ends parse.
  final bool showNightsInfo;

  /// A button above the pair that opens ONE range calendar and fills
  /// both ends.
  ///
  /// The two fields stay: typing a date is faster than swiping to it,
  /// and a range still has to be validated per end. What was missing is
  /// the affordance a range actually wants — dragging start to end on
  /// one grid — and without it the only way to enter a range here was
  /// two single-date dialogs that knew nothing about each other.
  final bool showRangeCalendar;

  /// Quick-select chips inside that calendar — "Last 7 days" and
  /// friends. `DateRangePreset.common()` is a reasonable set.
  final List<DateRangePreset>? presets;

  /// Hijri companion rows on both fields.
  final bool showHijri;

  final DateFieldCalendar calendar;
  final bool enabled;

  /// Keep `true` inside a `Form`; `false` standalone.
  final bool deferToParentForm;

  final ValidationMode validationMode;

  /// Visual override applied to both fields.
  final TextFieldStyle? style;

  /// Box geometry applied to both fields.
  final TextFieldSizing? sizing;

  @override
  State<DateRangeField> createState() => _DateRangeFieldState();
}

class _DateRangeFieldState extends State<DateRangeField> {
  TextEditingController? _ownedStart;
  TextEditingController? _ownedEnd;
  final _endFocus = FocusNode();

  DateValue? _startValue;
  DateValue? _endValue;

  TextEditingController get _start =>
      widget.startController ?? (_ownedStart ??= TextEditingController());
  TextEditingController get _end =>
      widget.endController ?? (_ownedEnd ??= TextEditingController());

  @override
  void dispose() {
    _ownedStart?.dispose();
    _ownedEnd?.dispose();
    _endFocus.dispose();
    super.dispose();
  }

  void _emit() {
    final cb = widget.onRangeChanged;
    if (cb == null) return;
    cb(
      DateRange(
        start: _startValue?.date,
        end: _endValue?.date,
        isValid:
            (_startValue?.isValid ?? false) && (_endValue?.isValid ?? false),
      ),
    );
  }

  int? get _nights {
    final s = _startValue?.date;
    final e = _endValue?.date;
    if (s == null || e == null) return null;
    final n = e.difference(s).inDays;
    return n >= (widget.allowSameDay ? 0 : 1) ? n : null;
  }

  /// Opens one calendar for BOTH ends and writes the result into the
  /// two controllers.
  Future<void> _openRangeCalendar() async {
    final first = widget.minDate ?? DateTime(1900);
    final last = widget.maxDate ?? DateTime(2100, 12, 31);
    final seedStart = _startValue?.date ?? DateUtils.dateOnly(DateTime.now());
    final seedEnd =
        _endValue?.date ??
        seedStart.add(Duration(days: widget.allowSameDay ? 0 : 1));

    final picked = await PickerDialogs.range(
      context,
      initial: DateTimeRange(
        start: seedStart.isBefore(first) ? first : seedStart,
        end: seedEnd.isAfter(last) ? last : seedEnd,
      ),
      firstDate: first,
      lastDate: last,
      // `allowSameDay` IS a minimum range of zero; without it, one.
      minimumRangeDays: widget.allowSameDay ? 0 : 1,
      presets: [
        for (final preset in widget.presets ?? const <DateRangePreset>[])
          (label: preset.label, range: preset.range),
      ],
    );
    if (picked == null || !mounted) return;

    // Written as TEXT, so the masks, the validators and the Hijri
    // companion rows all see it the way they see typing. `TypedDate` is
    // the picker module's own formatter for exactly this mask.
    final order = widget.order ?? TypedDate.orderForLocale();
    _start.text = TypedDate.format(picked.start, order);
    _end.text = TypedDate.format(picked.end, order);
  }

  @override
  Widget build(BuildContext context) {
    final nights = _nights;
    final pair = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DateField(
            controller: _start,
            identifier: widget.startIdentifier ?? DateRangeStrings.start,
            order: widget.order,
            required: widget.required,
            minDate: widget.minDate,
            maxDate: widget.maxDate,
            minDaysAhead: widget.minDaysAhead,
            maxDaysAhead: widget.maxDaysAhead,
            allowedWeekdays: widget.allowedWeekdays,
            disabledDate: widget.disabledDate,
            showHijri: widget.showHijri,
            calendar: widget.calendar,
            enabled: widget.enabled,
            deferToParentForm: widget.deferToParentForm,
            validationMode: widget.validationMode,
            style: widget.style,
            sizing: widget.sizing,
            onDateChanged: (v) {
              setState(() => _startValue = v);
              _emit();
            },
            onCompleted: (_) => _endFocus.requestFocus(),
          ),
        ),
        SizedBox(width: context.spacing.md),
        Expanded(
          child: DateField(
            controller: _end,
            focusNode: _endFocus,
            identifier: widget.endIdentifier ?? DateRangeStrings.end,
            order: widget.order,
            required: widget.required,
            minDate: widget.minDate,
            maxDate: widget.maxDate,
            maxDaysAhead: widget.maxDaysAhead,
            allowedWeekdays: widget.allowedWeekdays,
            disabledDate: widget.disabledDate,
            // The cross rule: strictly after, or on-or-after for
            // same-day ranges. Also floors the end calendar.
            mustBeAfter: widget.allowSameDay ? null : _start,
            mustBeOnOrAfter: widget.allowSameDay ? _start : null,
            showHijri: widget.showHijri,
            calendar: widget.calendar,
            enabled: widget.enabled,
            deferToParentForm: widget.deferToParentForm,
            validationMode: widget.validationMode,
            style: widget.style,
            sizing: widget.sizing,
            textInputAction: TextInputAction.done,
            messages: [
              if (widget.showNightsInfo && nights != null)
                FieldMessage.info(
                  DateRangeStrings.nights(nights),
                  icon: Icons.hotel_outlined,
                ),
            ],
            onDateChanged: (v) {
              setState(() => _endValue = v);
              _emit();
            },
          ),
        ),
      ],
    );

    if (!widget.showRangeCalendar) return pair;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: GlobalTextButton(
            text: DateRangeStrings.selectDateRange,
            icon: Icons.date_range_rounded,
            shrinkWidth: true,
            enabled: widget.enabled,
            onPressed: _openRangeCalendar,
          ),
        ),
        SizedBox(height: context.spacing.xs),
        pair,
      ],
    );
  }
}
