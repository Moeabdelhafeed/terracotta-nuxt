import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/a11y/semantics_extensions.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/time_field_strings.dart';
import '../../../../core/tokens/extensions.dart';
import '../../../module/buttons/global_icon_button.dart';
import '../../../module/date_time_picker/date_time_picker.dart';
import '../../../module/drop_down/global_drop_down.dart';
import '../../../module/text_field/global_text_field.dart';
import 'joined_pair_radii.dart';

/// Hour notation for a [TimeField].
enum TimeFieldHourFormat {
  /// Follow the device (`MediaQuery.alwaysUse24HourFormat`).
  auto,

  /// `14:30`.
  h24,

  /// `02:30` + an AM/PM picker beside the field.
  h12,
}

/// The parsed value a [TimeField] emits on every change — the
/// [TimeOfDay] (null while empty / incomplete), the seconds (when the
/// field shows them), the raw text, and the sync-validity snapshot.
@immutable
class TimeValue {
  const TimeValue({
    required this.time,
    required this.raw,
    required this.isValid,
    this.second = 0,
  });

  /// 24h-normalized time, or null while the entry isn't one.
  final TimeOfDay? time;

  /// Seconds segment (0 unless `showSeconds`).
  final int second;

  /// The exact field text (`'02:30'` — 12h text carries no period; the
  /// period lives in [time]).
  final String raw;

  /// Passes the field's sync validator.
  final bool isValid;

  /// Minutes since midnight (`14:30` → 870). Null while [time] is.
  int? get minutesSinceMidnight =>
      time == null ? null : time!.hour * 60 + time!.minute;

  /// This time on [date] (midnight-based) — for combining a date field
  /// and a time field into one `DateTime`.
  DateTime? onDate(DateTime date) => time == null
      ? null
      : DateTime(
          date.year,
          date.month,
          date.day,
          time!.hour,
          time!.minute,
          second,
        );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeValue &&
          other.time == time &&
          other.second == second &&
          other.raw == raw &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(time, second, raw, isValid);

  @override
  String toString() => 'TimeValue($raw → $time+${second}s, valid: $isValid)';
}

/// Clock-time input — masked typing (`14:30`, auto-`:`, zero-padding,
/// impossible hours blocked at the keystroke, Eastern-Arabic digits —
/// see [TimeInputFormatter]) plus:
///
/// * **Hour format** — [TimeFieldHourFormat.auto] follows the device;
///   12h mode joins a localized AM/PM picker (ص/م) and still emits a
///   24h [TimeOfDay]. [showFormatPicker] adds a 12h/24h dropdown so the
///   USER picks the notation. Format flips re-express the typed text
///   (`14:30` ↔ `02:30 PM`).
/// * **12h typing conveniences** — a typed 24h hour converts (`14` →
///   `02` + PM) and `a`/`p`/`ص`/`م` keys set the period.
/// * **Smart paste** — `2:30 PM`, `14:30`, `1430`, `١٤:٣٠`, with
///   optional seconds, re-express into the field's notation (the period
///   token wins over the digits).
/// * **Clock suffix** ([Icons.more_time]) opens `showTimePicker`
///   ([pickerLayout] wheels/dial) honoring the resolved format;
///   [showNowButton] adds a one-tap "Now" fill.
/// * **Template ghost** + localized hint words (`HH:mm` /
///   `ساعة:دقيقة`); [showSeconds] extends everything to `HH:mm:ss`.
/// * **↑/↓ stepping** — hour/minute/second under the caret (minute
///   steps by [minuteInterval] when set); wraps, haptic tick
///   ([enableHaptic]), announces, empty seeds now.
/// * **Windows** — [minTime] / [maxTime] (a `min > max` pair reads as
///   an overnight window, e.g. 22:00–02:00), [minuteInterval] grids,
///   and cross-field [mustBeAfter] (feed another field's emitted
///   [TimeValue] through a `ValueNotifier` — `TimeRangeField` wires
///   this for you).
/// * **[TimeValue] emit** via [onTimeChanged]; [onCompleted] fires once
///   per complete valid entry (period flips re-fire).
///
/// The editor is pinned LTR (digit runs bidi-scramble under RTL) while
/// alignment and the hint follow the form's direction.
class TimeField extends StatefulWidget {
  const TimeField({
    super.key,
    required this.controller,
    this.onTimeChanged,
    this.onCompleted,
    this.onChanged,
    this.onSubmitted,
    this.label,
    this.identifier,
    this.hint,
    this.enabled = true,
    this.readOnly = false,
    this.errorText,
    this.validator,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.errorIcon,
    this.errorBuilder,
    this.messages = const [],
    this.showSuccess = false,
    this.successText,
    this.showPrefixIcon = true,
    this.showClockButton = true,
    this.showNowButton = false,
    this.showTemplateGhost = true,
    this.showClearButton = false,
    this.showSeconds = false,
    this.hourFormat = TimeFieldHourFormat.auto,
    this.showFormatPicker = false,
    this.pickerLayout,
    this.required = false,
    this.stepOnArrows = true,
    this.enableHaptic = true,
    this.minTime,
    this.maxTime,
    this.minuteInterval,
    this.mustBeAfter,
    this.applyTime,
    this.adaptiveActions = true,
    this.initialPickerTime,
    this.suffix,
    this.style,
    this.sizing,
    this.autofillHints,
  }) : assert(
         minuteInterval == null ||
             (minuteInterval > 0 && 60 % minuteInterval == 0),
         'minuteInterval must divide 60 (5, 10, 15, 20, 30).',
       );

  final TextEditingController controller;

  /// Parsed value on every change (typing, period toggle, picker,
  /// stepping, paste). See [TimeValue].
  final ValueChanged<TimeValue>? onTimeChanged;

  /// Fires ONCE each time the entry becomes complete and passes the sync
  /// validator (re-fires when the value changes — including a period
  /// flip).
  final ValueChanged<TimeOfDay>? onCompleted;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;

  /// Null → localized pattern words (`HH:mm` / `ساعة:دقيقة`).
  final String? hint;

  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check. Null → required + incomplete + window/interval/
  /// cross-field rules.
  final String? Function(String?)? validator;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  /// Icon shown before the error message row.
  final IconData? errorIcon;

  /// Full control over the error row.
  final Widget Function(BuildContext context, String message)? errorBuilder;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  /// Show a success row when the field is valid (with optional [successText]).
  final bool showSuccess;
  final String? successText;

  final bool showPrefixIcon;

  /// Clock suffix button — opens the platform time picker. A custom
  /// [suffix] wins.
  final bool showClockButton;

  /// One-tap localized "Now" action in the suffix (fills the current
  /// time).
  final bool showNowButton;

  /// Ghost-complete the remaining pattern while typing (`14:` → `mm`).
  final bool showTemplateGhost;

  /// Module clear (✕) button while the field has text.
  final bool showClearButton;

  /// `HH:mm:ss` — a third masked segment; seconds ride along in
  /// [TimeValue.second] (the platform picker writes `:00`).
  final bool showSeconds;

  /// See [TimeFieldHourFormat].
  final TimeFieldHourFormat hourFormat;

  /// A 12h/24h dropdown joined to the field's end — the USER picks the
  /// notation ([hourFormat] only seeds it). Choosing 24h removes the
  /// AM/PM picker; the typed text re-expresses either way.
  final bool showFormatPicker;

  /// Whether the picker is spinning wheels or a clock face.
  ///
  /// It was `TimePickerEntryMode` (dial vs keyboard) while this opened
  /// Material's dialog. The module's dialog has no keyboard side — the
  /// FIELD is the keyboard side, and it is already masked — so the
  /// choice that is left is which of the two touch surfaces it shows.
  final TimePickerLayout? pickerLayout;

  /// Empty input fails validation.
  final bool required;

  /// ↑/↓ adjust the segment under the caret; empty seeds the current
  /// time. Hardware keyboards only.
  final bool stepOnArrows;

  /// Light haptic tick per ↑/↓ step.
  final bool enableHaptic;

  /// Inclusive window. `min > max` wraps overnight (22:00–02:00 accepts
  /// 23:15 and 01:30, rejects 12:00).
  final TimeOfDay? minTime;
  final TimeOfDay? maxTime;

  /// Minutes must land on this grid (15 → :00 / :15 / :30 / :45). Also
  /// the ↑/↓ step size for the minute segment.
  final int? minuteInterval;

  /// Cross-field rule: must be strictly after the [TimeValue] this
  /// listenable holds (wire the other field's `onTimeChanged` into a
  /// `ValueNotifier<TimeValue?>`). Re-validates when it changes.
  final ValueListenable<TimeValue?>? mustBeAfter;

  /// Imperative write channel — push a [TimeOfDay] through a
  /// `ValueNotifier` and the field applies it CORRECTLY (formats into
  /// the active notation, sets the AM/PM period, emits). A bare
  /// `controller.text` write can't do that in 12h mode. Nulls are
  /// ignored; to re-apply the same value, set null first.
  final ValueListenable<TimeOfDay?>? applyTime;

  /// Collapse the suffix actions when the field is too narrow for them
  /// (the Now label goes first, then the clock). `false` forces them
  /// visible regardless of width.
  final bool adaptiveActions;

  /// Where the picker opens while the field is empty. Null → now.
  final TimeOfDay? initialPickerTime;

  /// Trailing slot — wins over the clock/now buttons.
  final TextFieldSuffix? suffix;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  /// Platform autofill (no standard time hint exists — null by default).
  final List<String>? autofillHints;

  @override
  State<TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<TimeField> {
  static const _separator = ':';

  /// A pasted time in any common notation — `2:30 PM`, `14:30`, `1430`,
  /// optional `:ss`, optional Latin/Arabic period token.
  static final _pastedTime = RegExp(
    r'^\s*(\d{1,2})[:. ]?(\d{2})(?:[:. ](\d{2}))?\s*'
    r'([AaPp](?:\.?[Mm]\.?)?|ص|م)?\s*$',
  );

  FocusNode? _internalNode;

  /// AM/PM selection for 12h mode (the text carries only `hh:mm`).
  DayPeriod _period = DayPeriod.am;

  /// User's pick from the format dropdown — wins over
  /// [TimeField.hourFormat] once set.
  bool? _formatOverride;

  /// Hour format the current text is EXPRESSED in — device-format flips
  /// re-express the text (`14:30` ↔ `02:30`+PM) instead of re-reading it.
  bool? _appliedH24;

  /// Rewrite computed during a format switch, applied post-frame; stands
  /// in for validation meanwhile (no one-frame error flash).
  String? _pendingRewrite;
  DayPeriod? _pendingPeriod;
  int _rewriteGeneration = 0;

  /// Last value [TimeField.onCompleted] fired for (`text|period`).
  String? _completedFor;

  FocusNode get _node => widget.focusNode ?? (_internalNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.onKeyEvent = _onKey;
    widget.mustBeAfter?.addListener(_onLinkedTime);
    widget.applyTime?.addListener(_onApplyTime);
  }

  /// External [TimeOfDay] pushed through [TimeField.applyTime].
  void _onApplyTime() {
    final time = widget.applyTime?.value;
    if (time == null || !mounted) return;
    _applyTime(time);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncHourFormat();
  }

  @override
  void didUpdateWidget(covariant TimeField old) {
    super.didUpdateWidget(old);
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _internalNode)?.onKeyEvent = null;
      _node.onKeyEvent = _onKey;
    }
    if (old.mustBeAfter != widget.mustBeAfter) {
      old.mustBeAfter?.removeListener(_onLinkedTime);
      widget.mustBeAfter?.addListener(_onLinkedTime);
    }
    if (old.applyTime != widget.applyTime) {
      old.applyTime?.removeListener(_onApplyTime);
      widget.applyTime?.addListener(_onApplyTime);
    }
    if (old.hourFormat != widget.hourFormat) _syncHourFormat();
    // Rule props changed (a composite tightening the window per picked
    // date) — the stored validity in consumers is stale; re-emit.
    if (old.minTime != widget.minTime ||
        old.maxTime != widget.maxTime ||
        old.minuteInterval != widget.minuteInterval ||
        old.required != widget.required) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _emit();
      });
    }
  }

  @override
  void dispose() {
    widget.mustBeAfter?.removeListener(_onLinkedTime);
    widget.applyTime?.removeListener(_onApplyTime);
    if (widget.focusNode != null) widget.focusNode!.onKeyEvent = null;
    _internalNode?.dispose();
    super.dispose();
  }

  /// The other side of the cross-field rule changed — rebuild so
  /// `revalidateKey` re-checks an interacted field, and re-emit so
  /// consumers get the fresh validity.
  void _onLinkedTime() {
    if (!mounted) return;
    setState(() {});
    _emit();
  }

  // ── hour format ───────────────────────────────────────────────────
  bool get _use24h =>
      _formatOverride ??
      switch (widget.hourFormat) {
        TimeFieldHourFormat.h24 => true,
        TimeFieldHourFormat.h12 => false,
        TimeFieldHourFormat.auto =>
          MediaQuery.maybeOf(context)?.alwaysUse24HourFormat ?? true,
      };

  /// Format-dropdown pick — re-expresses the text via the standard
  /// switch machinery.
  void _selectFormat(bool use24h) {
    if (use24h == _use24h) return;
    setState(() => _formatOverride = use24h);
    _syncHourFormat();
  }

  /// Device/param format flipped — re-express the typed text.
  void _syncHourFormat() {
    final use24h = _use24h;
    final previous = _appliedH24;
    _appliedH24 = use24h;
    if (previous == null || previous == use24h) return;
    final text = widget.controller.text;
    if (text.isEmpty) return;
    final full = _parseFullAs(previous, text, _period);
    if (full == null) return;
    final (rewritten, period) = _formatAs(use24h, full.time, full.second);
    if (rewritten == text && period == _period) return;
    _pendingRewrite = rewritten;
    _pendingPeriod = period;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pendingRewrite = null;
      _pendingPeriod = null;
      if (widget.controller.text != text) return;
      _period = period;
      _applyText(rewritten);
      setState(() => _rewriteGeneration++);
    });
  }

  /// Formatter-implied period (typed `p`, or `14` converting in a 12h
  /// field) — fires during text editing, so the state flip is deferred.
  void _setPeriodDeferred(DayPeriod period) {
    if (_period == period) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _period == period) return;
      setState(() => _period = period);
      _emit();
    });
  }

  // ── parse / format ────────────────────────────────────────────────
  String get _template =>
      (_use24h ? 'HH:mm' : 'hh:mm') + (widget.showSeconds ? ':ss' : '');

  /// Strict parse under [use24h] — complete text (+[period] in 12h
  /// mode) to a 24h [TimeOfDay] + seconds.
  ({TimeOfDay time, int second})? _parseFullAs(
    bool use24h,
    String text,
    DayPeriod period,
  ) {
    final parts = text.split(_separator);
    final expected = widget.showSeconds ? 3 : 2;
    if (parts.length != expected || parts.any((p) => p.length != 2)) {
      return null;
    }
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final s = widget.showSeconds ? int.tryParse(parts[2]) : 0;
    if (h == null || m == null || s == null || m > 59 || s > 59) return null;
    if (use24h) {
      if (h > 23) return null;
      return (time: TimeOfDay(hour: h, minute: m), second: s);
    }
    if (h < 1 || h > 12) return null;
    final h24 = switch ((h, period)) {
      (12, DayPeriod.am) => 0,
      (12, DayPeriod.pm) => 12,
      (_, DayPeriod.am) => h,
      (_, DayPeriod.pm) => h + 12,
    };
    return (time: TimeOfDay(hour: h24, minute: m), second: s);
  }

  TimeOfDay? _parse(String text) => _parseFullAs(_use24h, text, _period)?.time;

  /// [time] → (text, period) under [use24h].
  (String, DayPeriod) _formatAs(bool use24h, TimeOfDay time, [int second = 0]) {
    final period = time.hour < 12 ? DayPeriod.am : DayPeriod.pm;
    final displayHour = use24h
        ? time.hour
        : (time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod);
    final buffer = StringBuffer()
      ..write(displayHour.toString().padLeft(2, '0'))
      ..write(_separator)
      ..write(time.minute.toString().padLeft(2, '0'));
    if (widget.showSeconds) {
      buffer
        ..write(_separator)
        ..write(second.toString().padLeft(2, '0'));
    }
    return (buffer.toString(), period);
  }

  /// Localized display for error messages (`2:30 PM` / `١٤:٣٠`).
  String _display(TimeOfDay t) => MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(t, alwaysUse24HourFormat: _use24h);

  String get _hintText {
    final hour = TimeFieldStrings.hourWord;
    final minute = TimeFieldStrings.minuteWord;
    final second = TimeFieldStrings.secondWord;
    return widget.showSeconds
        ? '$hour$_separator$minute$_separator$second'
        : '$hour$_separator$minute';
  }

  // ── smart paste ───────────────────────────────────────────────────
  /// `2:30 PM` / `14:30` / `1430` / `١٤:٣٠` (optional seconds) pasted in
  /// any notation re-expresses into the field's — the period token wins
  /// over the digits. Runs BEFORE the mask formatter.
  TextEditingValue _interceptTimePaste(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length - oldValue.text.length < 3) return newValue;
    final ascii = DateInputFormatter.normalizeDigits(newValue.text);
    final m = _pastedTime.firstMatch(ascii);
    if (m == null) return newValue;
    final h = int.parse(m.group(1)!);
    final minute = int.parse(m.group(2)!);
    final second = int.tryParse(m.group(3) ?? '') ?? 0;
    final token = m.group(4);
    if (minute > 59 || second > 59) return newValue;
    final tokenPeriod = token == null
        ? null
        : (token.toLowerCase().startsWith('a') || token == 'ص'
              ? DayPeriod.am
              : DayPeriod.pm);
    final int h24;
    if (tokenPeriod != null) {
      if (h < 1 || h > 12) return newValue;
      h24 = tokenPeriod == DayPeriod.pm ? (h % 12) + 12 : h % 12;
    } else {
      if (h > 23) return newValue;
      h24 = h;
    }
    final (text, period) = _formatAs(
      _use24h,
      TimeOfDay(hour: h24, minute: minute),
      second,
    );
    _setPeriodDeferred(period);
    // Digits only — the mask formatter (next in the chain) re-inserts
    // the separators.
    final digits = text.replaceAll(_separator, '');
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }

  // ── validation ────────────────────────────────────────────────────
  int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String? _defaultValidator(String? value) {
    final text = _pendingRewrite ?? (value ?? '').trim();
    final period = _pendingPeriod ?? _period;
    if (text.isEmpty) {
      return widget.required ? TimeFieldStrings.required : null;
    }
    // A pending rewrite is already expressed in the CURRENT format.
    final time = _parseFullAs(_use24h, text, period)?.time;
    if (time == null) {
      return TimeFieldStrings.incomplete(_template);
    }
    final v = _minutes(time);
    final min = widget.minTime;
    final max = widget.maxTime;
    if (min != null && max != null && _minutes(min) > _minutes(max)) {
      // Overnight window (22:00–02:00): inside = after min OR before max.
      if (v < _minutes(min) && v > _minutes(max)) {
        return TimeFieldStrings.outsideWindow(_display(min), _display(max));
      }
    } else {
      if (min != null && v < _minutes(min)) {
        return TimeFieldStrings.minTime(_display(min));
      }
      if (max != null && v > _minutes(max)) {
        return TimeFieldStrings.maxTime(_display(max));
      }
    }
    final interval = widget.minuteInterval;
    if (interval != null && time.minute % interval != 0) {
      return TimeFieldStrings.interval(interval);
    }
    final after = widget.mustBeAfter?.value?.time;
    if (after != null && v <= _minutes(after)) {
      return TimeFieldStrings.mustBeAfter(_display(after));
    }
    return null;
  }

  String? Function(String?) get _effectiveValidator =>
      widget.validator ?? _defaultValidator;

  // ── emit / completion ─────────────────────────────────────────────
  void _emit() {
    final raw = widget.controller.text;
    final full = _parseFullAs(_use24h, raw, _period);
    widget.onTimeChanged?.call(
      TimeValue(
        time: full?.time,
        second: full?.second ?? 0,
        raw: raw,
        isValid: _effectiveValidator(raw) == null,
      ),
    );
    _maybeComplete(raw);
  }

  void _maybeComplete(String text) {
    if (text.length < _template.length) {
      _completedFor = null;
      return;
    }
    final time = _parse(text);
    if (time == null || _effectiveValidator(text) != null) return;
    final key = '$text|$_period';
    if (_completedFor == key) return;
    _completedFor = key;
    widget.onCompleted?.call(time);
  }

  /// Programmatic writes (picker, stepping, now, rewrite) — the module's
  /// own onChanged doesn't fire for these.
  void _applyText(String text) {
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    widget.onChanged?.call(text);
    _emit();
  }

  void _applyTime(TimeOfDay time, [int second = 0]) {
    final (text, period) = _formatAs(_use24h, time, second);
    setState(() => _period = period);
    _applyText(text);
  }

  void _setNow() {
    _applyTime(TimeOfDay.now());
    if (widget.enableHaptic) HapticFeedback.selectionClick();
  }

  // ── ↑/↓ segment stepping ──────────────────────────────────────────
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.stepOnArrows ||
        !widget.enabled ||
        widget.readOnly ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final dir = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => 1,
      LogicalKeyboardKey.arrowDown => -1,
      _ => 0,
    };
    if (dir == 0) return KeyEventResult.ignored;
    _stepSegment(dir);
    return KeyEventResult.handled;
  }

  void _stepSegment(int dir) {
    final text = widget.controller.text;
    if (text.isEmpty) {
      _applyTime(TimeOfDay.now());
      _afterStep();
      return;
    }
    final full = _parseFullAs(_use24h, text, _period);
    if (full == null) return;
    final time = full.time;
    var second = full.second;
    final caret = widget.controller.selection.baseOffset.clamp(0, text.length);
    final segIndex =
        text
            .substring(0, caret)
            .split(_separator)
            .length
            .clamp(1, widget.showSeconds ? 3 : 2) -
        1;
    final TimeOfDay next;
    switch (segIndex) {
      case 0: // hour
        next = TimeOfDay(
          hour: (time.hour + dir + 24) % 24,
          minute: time.minute,
        );
      case 1: // minute
        final step = widget.minuteInterval ?? 1;
        var m = time.minute + dir * step;
        // Snap onto the grid when stepping off-grid input (12:07 ↑ → 12:15).
        if (widget.minuteInterval != null && time.minute % step != 0) {
          m = dir > 0
              ? (time.minute ~/ step + 1) * step
              : (time.minute ~/ step) * step;
        }
        next = TimeOfDay(hour: time.hour, minute: (m + 60) % 60);
      default: // second
        second = (second + dir + 60) % 60;
        next = time;
    }
    _applyTime(next, second);
    // Keep the caret on the stepped segment (end of it: 2, 5, 8).
    widget.controller.selection = TextSelection.collapsed(
      offset: 2 + segIndex * 3,
    );
    _afterStep();
  }

  void _afterStep() {
    if (widget.enableHaptic) HapticFeedback.selectionClick();
    if (!mounted) return;
    final time = _parse(widget.controller.text);
    announceForAccessibility(
      context,
      time == null ? widget.controller.text : _display(time),
    );
  }

  // ── template ghost ────────────────────────────────────────────────
  String? _templateGhost(String text) {
    if (text.isEmpty || text.length >= _template.length) return null;
    return _template.substring(text.length);
  }

  // ── picker / suffix ───────────────────────────────────────────────
  Future<void> _openPicker() async {
    final seed =
        _parse(widget.controller.text) ??
        widget.initialPickerTime ??
        TimeOfDay.now();
    final today = DateTime.now();

    // `PickerDialogs.time`, not `showTimePicker` — the module's own
    // wheels or clock face, in the app's own dialog chrome. It works in
    // `DateTime`s, so the seed goes in on an arbitrary day and only the
    // clock parts come back out.
    final picked = await PickerDialogs.time(
      context,
      initial: DateTime(
        today.year,
        today.month,
        today.day,
        seed.hour,
        seed.minute,
      ),
      use24HourFormat: _use24h,
      // Honoured here, and silently ignored by `showTimePicker` — a
      // 15-minute field could produce off-grid times through the dial.
      minuteInterval: widget.minuteInterval ?? 1,
      title: TimeFieldStrings.pickTime,
      style: DateTimePickerStyle(
        timeLayout: widget.pickerLayout ?? TimePickerLayout.wheels,
      ),
    );
    if (picked == null || !mounted) return;
    _applyTime(TimeOfDay(hour: picked.hour, minute: picked.minute));
  }

  /// Width floors for the adaptive suffix actions — below these the
  /// extras collapse so the editor keeps room to breathe.
  static const _kClockMinWidth = 190.0;
  static const _kNowMinWidth = 270.0;

  /// Width one joined picker (AM/PM or 12/24) eats from the control —
  /// the editor's REAL budget is what remains after them.
  static const _kPickerReservedWidth = 90.0;

  TextFieldSuffix? _builtSuffix(
    BuildContext context, {
    required bool allowNow,
    required bool allowClock,
  }) {
    if (widget.suffix != null) return widget.suffix;
    final interactive = widget.enabled && !widget.readOnly;
    final showClock = widget.showClockButton && interactive && allowClock;
    final showNow = widget.showNowButton && interactive && allowNow;
    if (!showClock && !showNow) return null;
    if (!showNow) {
      // more_time (clock+plus) — distinct from the schedule prefix icon,
      // and reads as "add/pick a time".
      return TextFieldSuffix.icon(Icons.more_time, onTap: _openPicker);
    }
    return TextFieldSuffix.widget(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            child: InkResponse(
              radius: 20,
              onTap: _setNow,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.xs,
                  vertical: context.spacing.xs,
                ),
                child: Text(
                  TimeFieldStrings.now,
                  style: context.textTheme.labelMedium?.copyWith(
                    color: context.iconColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          if (showClock)
            GlobalIconButton(
              iconData: Icons.more_time,
              tooltip: TimeFieldStrings.pickTime,
              enforceMinTouchTarget: false,
              // Mirror the compact-density IconButton footprint it replaces.
              style: const ButtonStateStyle(width: 40, height: 40),
              onPressed: _openPicker,
            ),
          SizedBox(width: context.spacing.xs),
        ],
      ),
    );
  }

  // ── pickers (12h AM/PM + 12/24 format) ────────────────────────────
  Widget _formatPicker(BuildContext context, BorderRadius borderRadius) {
    String label(bool use24) =>
        use24 ? TimeFieldStrings.format24 : TimeFieldStrings.format12;
    return GlobalDropdown<bool>(
      enabled: widget.enabled && !widget.readOnly,
      style: TextFieldStyle(borderRadius: borderRadius),
      sizing: TextFieldSizing(
        fitWidthToContent: true,
        minWidth: 72,
        maxWidth: 110,
        height: widget.sizing?.height ?? kJoinedPairBoxHeight,
      ),
      items: [
        for (final f in const [true, false])
          DropdownItem(value: f, label: label(f), searchText: label(f)),
      ],
      selectedValue: _use24h,
      onChanged: (f) {
        if (f != null) _selectFormat(f);
      },
    );
  }

  Widget _periodPicker(BuildContext context, BorderRadius borderRadius) {
    final l10n = MaterialLocalizations.of(context);
    String label(DayPeriod p) => p == DayPeriod.am
        ? l10n.anteMeridiemAbbreviation
        : l10n.postMeridiemAbbreviation;
    return GlobalDropdown<DayPeriod>(
      enabled: widget.enabled && !widget.readOnly,
      style: TextFieldStyle(borderRadius: borderRadius),
      // Two short labels (AM/PM · ص/م) — hug them with a stable floor,
      // pinned to the field's box height so the seam lines up.
      sizing: TextFieldSizing(
        fitWidthToContent: true,
        minWidth: 72,
        maxWidth: 104,
        height: widget.sizing?.height ?? kJoinedPairBoxHeight,
      ),
      items: [
        for (final p in DayPeriod.values)
          DropdownItem(value: p, label: label(p), searchText: label(p)),
      ],
      selectedValue: _period,
      onChanged: (p) {
        if (p == null) return;
        setState(() => _period = p);
        _emit();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Adaptive suffix: measure the control's available width and drop
    // the Now label / clock button when they'd crowd the editor.
    // `adaptiveActions: false` forces them visible.
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final adaptive = widget.adaptiveActions && w.isFinite;
        // The joined AM/PM + format pickers eat fixed width — judge the
        // thresholds against the EDITOR's remaining budget, not the
        // whole chain.
        final reserved =
            (!_use24h ? _kPickerReservedWidth : 0.0) +
            (widget.showFormatPicker ? _kPickerReservedWidth : 0.0);
        final effective = w - reserved;
        final allowClock = !adaptive || effective >= _kClockMinWidth;
        final allowNow = !adaptive || effective >= _kNowMinWidth;
        return _buildField(context, allowNow: allowNow, allowClock: allowClock);
      },
    );
  }

  Widget _buildField(
    BuildContext context, {
    required bool allowNow,
    required bool allowClock,
  }) {
    // Attached chain: field → AM/PM (12h only) → format picker (opt-in).
    // Only the chain's outer corners keep the radius; every seam is flat.
    final has12h = !_use24h;
    final hasFormat = widget.showFormatPicker;
    final hasPickers = has12h || hasFormat;
    final baseStyle = widget.style ?? const TextFieldStyle();
    final field = GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      // With pickers beside the field the identifier moves above the
      // whole row.
      identifier: hasPickers ? null : widget.identifier,
      hint: widget.hint ?? _hintText,
      focusNode: _node,
      style: !hasPickers
          ? baseStyle
          : baseStyle.copyWith(
              borderRadius: edgeRadii(
                context,
                roundStart: true,
                roundEnd: false,
              ),
            ),
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: widget.messages,
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.datetime,
        textInputAction: widget.textInputAction,
        inputFormatters: [
          TextInputFormatter.withFunction(_interceptTimePaste),
          TimeInputFormatter(
            use24h: _use24h,
            withSeconds: widget.showSeconds,
            separator: _separator,
            onDayPeriod: _use24h ? null : _setPeriodDeferred,
          ),
        ],
        maxLength: _template.length,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
        // Clock text is structurally LTR; alignment + hint follow the
        // form's direction (same treatment as DateField).
        textDirection: TextDirection.ltr,
        textAlign: Directionality.of(context) == TextDirection.rtl
            ? TextAlign.end
            : TextAlign.start,
        autofillHints: widget.autofillHints,
      ),
      validation: TextFieldValidation(
        validator: (v) => _effectiveValidator(v),
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        errorIcon: widget.errorIcon,
        errorBuilder: widget.errorBuilder,
        revalidateKey: (
          _use24h,
          _period,
          _rewriteGeneration,
          widget.required,
          widget.minTime,
          widget.maxTime,
          widget.minuteInterval,
          widget.showSeconds,
          widget.mustBeAfter?.value,
        ),
      ),
      features: TextFieldFeatures(
        showSuccess: widget.showSuccess,
        successText: widget.successText,
        showClearButton: widget.showClearButton,
        suggestions: widget.showTemplateGhost
            ? SuggestionsConfig(
                showInlineCompletion: true,
                completion: _templateGhost,
              )
            : null,
      ),
      slots: TextFieldSlots(
        prefixIcon: widget.showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  Icons.schedule_outlined,
                  color: context.iconColors.primary,
                ),
              )
            : null,
        suffix: _builtSuffix(
          context,
          allowNow: allowNow,
          allowClock: allowClock,
        ),
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          _emit();
        },
        onSubmitted: widget.onSubmitted,
      ),
    );

    if (!hasPickers) return field;

    // Attached chain; the identifier spans the whole row.
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
            Expanded(child: field),
            if (has12h)
              _periodPicker(
                context,
                edgeRadii(context, roundStart: false, roundEnd: !hasFormat),
              ),
            if (hasFormat)
              _formatPicker(
                context,
                edgeRadii(context, roundStart: false, roundEnd: true),
              ),
          ],
        ),
      ],
    );
  }
}
