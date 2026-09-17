import 'package:flutter/material.dart';

import '../../../../core/localization/strings/date_field_strings.dart';
import '../../../../core/localization/strings/time_field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../module/buttons/global_text_button.dart';
import '../../../module/date_time_picker/date_time_picker.dart';
import '../../../module/text_field/global_text_field.dart';
import 'time_field.dart';

/// The parsed value a [TimeRangeField] emits on every change — both
/// ends, the validity snapshot, and the duration math consumers
/// otherwise re-derive.
@immutable
class TimeRange {
  const TimeRange({
    required this.start,
    required this.end,
    required this.isValid,
  });

  /// Null while that end is empty / incomplete.
  final TimeOfDay? start;
  final TimeOfDay? end;

  /// Both ends parse AND pass their field validators (including the
  /// after-start rule / overnight allowance).
  final bool isValid;

  static int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Span between the ends, wrapping midnight when the end is earlier
  /// (22:00 → 02:00 = 4h). Null while either end is.
  Duration? get duration => (start == null || end == null)
      ? null
      : Duration(
          minutes: (_minutes(end!) - _minutes(start!) + 24 * 60) % (24 * 60),
        );

  /// The span crosses midnight (end clock-earlier than start).
  bool get wrapsMidnight =>
      start != null && end != null && _minutes(end!) < _minutes(start!);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeRange &&
          other.start == start &&
          other.end == end &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(start, end, isValid);

  @override
  String toString() => 'TimeRange($start → $end, valid: $isValid)';
}

/// Start + end [TimeField]s wired the right way — one widget (the
/// `DateRangeField` treatment for clock times):
///
/// * The end field cross-validates against the start (strictly after by
///   default; [allowOvernight] lets the span wrap midnight — night
///   shifts) and re-checks when the start changes.
/// * Focus chains: completing the start hops to the end.
/// * A duration info row under the end field ([showDurationInfo] —
///   "8h 30m", wrap-aware).
/// * One [onRangeChanged] with a parsed [TimeRange].
///
/// Both fields share format / window / interval settings, so typing and
/// pickers agree.
class TimeRangeField extends StatefulWidget {
  const TimeRangeField({
    super.key,
    this.startController,
    this.endController,
    this.onRangeChanged,
    this.startIdentifier,
    this.endIdentifier,
    this.hourFormat = TimeFieldHourFormat.auto,
    this.minTime,
    this.maxTime,
    this.minuteInterval,
    this.allowOvernight = false,
    this.required = true,
    this.showDurationInfo = true,
    this.showNowButton = false,
    this.pickerLayout,
    this.showRangeDialog = true,
    this.enabled = true,
    this.deferToParentForm = true,
    this.validationMode = ValidationMode.onInteraction,
    this.style,
    this.sizing,
  });

  /// Controllers are optional — the widget owns them when absent.
  final TextEditingController? startController;
  final TextEditingController? endController;

  /// Parsed range on every change to either end. See [TimeRange].
  final ValueChanged<TimeRange>? onRangeChanged;

  /// Column headers. Null → localized "Start time" / "End time".
  final String? startIdentifier;
  final String? endIdentifier;

  /// Hour notation for BOTH fields.
  final TimeFieldHourFormat hourFormat;

  /// Shared window applied to both ends.
  final TimeOfDay? minTime;
  final TimeOfDay? maxTime;

  /// Minute grid for both ends.
  final int? minuteInterval;

  /// Let the span wrap midnight (22:00 → 02:00). Off: the end must be
  /// strictly after the start.
  final bool allowOvernight;

  /// Empty ends fail validation.
  final bool required;

  /// Duration row under the end field once both ends parse.
  final bool showDurationInfo;

  /// "Now" action on both fields.
  final bool showNowButton;

  /// Wheels or a clock face, on both ends. See [TimeField].
  final TimePickerLayout? pickerLayout;

  /// A button above the pair that opens ONE dialog for both ends.
  ///
  /// It used to be two unrelated time dialogs that knew nothing about
  /// each other — the same shape the date range was in before it got a
  /// range calendar.
  final bool showRangeDialog;
  final bool enabled;

  /// Keep `true` inside a `Form`; `false` standalone.
  final bool deferToParentForm;

  final ValidationMode validationMode;

  /// Visual override applied to both fields.
  final TextFieldStyle? style;

  /// Box geometry applied to both fields.
  final TextFieldSizing? sizing;

  @override
  State<TimeRangeField> createState() => _TimeRangeFieldState();
}

class _TimeRangeFieldState extends State<TimeRangeField> {
  TextEditingController? _ownedStart;
  TextEditingController? _ownedEnd;
  final _endFocus = FocusNode();

  /// Feeds the end field's `mustBeAfter` (and the duration row).
  final _startLink = ValueNotifier<TimeValue?>(null);
  TimeValue? _endValue;

  TextEditingController get _start =>
      widget.startController ?? (_ownedStart ??= TextEditingController());
  TextEditingController get _end =>
      widget.endController ?? (_ownedEnd ??= TextEditingController());

  @override
  void dispose() {
    _ownedStart?.dispose();
    _ownedEnd?.dispose();
    _endFocus.dispose();
    _startLink.dispose();
    super.dispose();
  }

  TimeRange get _range {
    final start = _startLink.value;
    final end = _endValue;
    return TimeRange(
      start: start?.time,
      end: end?.time,
      isValid: (start?.isValid ?? false) && (end?.isValid ?? false),
    );
  }

  void _emit() => widget.onRangeChanged?.call(_range);

  FieldMessage? get _durationRow {
    if (!widget.showDurationInfo) return null;
    final duration = _range.duration;
    if (duration == null || duration.inMinutes == 0) return null;
    return FieldMessage.info(
      TimeRangeStrings.duration(duration.inHours, duration.inMinutes % 60),
      icon: Icons.timelapse,
    );
  }

  /// Whether the fields are on a 24-hour clock, resolved the way
  /// `TimeField` resolves it.
  bool get _use24h => switch (widget.hourFormat) {
    TimeFieldHourFormat.h24 => true,
    TimeFieldHourFormat.h12 => false,
    TimeFieldHourFormat.auto =>
      MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? true,
  };

  /// Opens ONE dialog for both ends and writes them into the two
  /// controllers.
  ///
  /// It used to be two unrelated time dialogs — the same shape the date
  /// range was in before it got a range calendar.
  Future<void> _openRangeDialog() async {
    final today = DateTime.now();
    DateTime at(TimeOfDay? t, TimeOfDay fallback) {
      final v = t ?? fallback;
      return DateTime(today.year, today.month, today.day, v.hour, v.minute);
    }

    final picked = await PickerDialogs.timeRange(
      context,
      initial: (
        start: at(_startLink.value?.time, const TimeOfDay(hour: 9, minute: 0)),
        end: at(_endValue?.time, const TimeOfDay(hour: 17, minute: 0)),
      ),
      use24HourFormat: _use24h,
      minuteInterval: widget.minuteInterval ?? 1,
    );
    if (picked == null || !mounted) return;

    _start.text = _renderTime(picked.start);
    _end.text = _renderTime(picked.end);
  }

  /// As the MASK would have it typed, so the fields' own parsing,
  /// validation and period chips all see it the way they see typing.
  String _renderTime(DateTime value) {
    String two(int v) => v.toString().padLeft(2, '0');
    final hour = _use24h ? value.hour : PickerMath.hour12(value.hour);
    return '${two(hour)}:${two(value.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final durationRow = _durationRow;
    final pair = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TimeField(
            controller: _start,
            identifier: widget.startIdentifier ?? TimeRangeStrings.start,
            hourFormat: widget.hourFormat,
            minTime: widget.minTime,
            maxTime: widget.maxTime,
            minuteInterval: widget.minuteInterval,
            required: widget.required,
            showNowButton: widget.showNowButton,
            pickerLayout: widget.pickerLayout,
            enabled: widget.enabled,
            deferToParentForm: widget.deferToParentForm,
            validationMode: widget.validationMode,
            style: widget.style,
            sizing: widget.sizing,
            onTimeChanged: (v) {
              setState(() => _startLink.value = v);
              _emit();
            },
            onCompleted: (_) => _endFocus.requestFocus(),
          ),
        ),
        SizedBox(width: context.spacing.md),
        Expanded(
          child: TimeField(
            controller: _end,
            focusNode: _endFocus,
            identifier: widget.endIdentifier ?? TimeRangeStrings.end,
            hourFormat: widget.hourFormat,
            minTime: widget.minTime,
            maxTime: widget.maxTime,
            minuteInterval: widget.minuteInterval,
            required: widget.required,
            showNowButton: widget.showNowButton,
            pickerLayout: widget.pickerLayout,
            // Overnight spans wrap — no ordering rule; otherwise the end
            // must be strictly after the start (re-checks on changes).
            mustBeAfter: widget.allowOvernight ? null : _startLink,
            textInputAction: TextInputAction.done,
            enabled: widget.enabled,
            deferToParentForm: widget.deferToParentForm,
            validationMode: widget.validationMode,
            style: widget.style,
            sizing: widget.sizing,
            messages: [if (durationRow != null) durationRow],
            onTimeChanged: (v) {
              setState(() => _endValue = v);
              _emit();
            },
          ),
        ),
      ],
    );

    if (!widget.showRangeDialog) return pair;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: GlobalTextButton(
            text: DatePickerStrings.selectTimeRange,
            icon: Icons.schedule_rounded,
            shrinkWidth: true,
            enabled: widget.enabled,
            onPressed: _openRangeDialog,
          ),
        ),
        SizedBox(height: context.spacing.xs),
        pair,
      ],
    );
  }
}
