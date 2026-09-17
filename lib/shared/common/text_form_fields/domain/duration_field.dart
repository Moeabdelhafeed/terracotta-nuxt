import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/extensions/theme_colors_extension.dart';
import '../../../../core/localization/strings/duration_field_strings.dart';
import '../../../../core/localization/strings/time_field_strings.dart';
import '../../../module/date_time_picker/date_time_picker.dart';
import '../../../module/text_field/global_text_field.dart';

/// The parsed value a [DurationField] emits — a real Dart [Duration]
/// plus the sync-validity snapshot.
@immutable
class DurationValue {
  const DurationValue({required this.duration, required this.isValid});

  final Duration duration;
  final bool isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DurationValue &&
          other.duration == duration &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(duration, isValid);

  @override
  String toString() => 'DurationValue($duration, valid: $isValid)';
}

/// Duration ("how long") input — [TimeField]'s sibling for elapsed time:
/// workout length, parking, meeting slots, video trim, SLAs.
///
///  * Masked `hh:mm` / `hh:mm:ss` / `mm:ss` ([DurationFormat]) — 0–59
///    segments zero-pad impossible keystrokes, Eastern-Arabic digits
///    normalize, a typed `:` closes a single digit.
///  * [maxDuration] is HARD-BLOCKED at the keystroke; [minDuration]
///    validates on the normal triggers.
///  * ↑/↓ steps the segment under the caret (minutes snap to
///    [minuteStep] when set — booking grids).
///  * Live summary row spells the mask out ("1h 30m" — `01:30` alone is
///    ambiguous), localized.
///  * Trailing timer button opens a [CupertinoTimerPicker] bottom sheet
///    matched to the format.
///
/// Emits [DurationValue] via [onDurationChanged] — null while
/// incomplete.
///
/// ```dart
/// DurationField(
///   controller: parking,
///   maxDuration: const Duration(hours: 8),
///   minuteStep: 15,
///   onDurationChanged: (d) => cubit.setParking(d?.duration),
/// )
/// ```
class DurationField extends StatefulWidget {
  const DurationField({
    super.key,
    required this.controller,
    this.format = DurationFormat.hm,
    this.onDurationChanged,
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
    this.textInputAction = TextInputAction.done,
    this.validationMode = ValidationMode.onInteraction,
    this.deferToParentForm = true,
    this.messages = const [],
    this.showSuccess = false,
    this.minDuration,
    this.maxDuration,
    this.minuteStep,
    this.enableHaptic = true,
    this.showSummary = true,
    this.showPickerButton = true,
    this.showPrefixIcon = true,
    this.style,
    this.sizing,
  }) : assert(
         minuteStep == null || (minuteStep > 0 && minuteStep <= 30),
         'minuteStep must be 1–30',
       );

  final TextEditingController controller;

  /// Mask shape — `hh:mm` (default) / `hh:mm:ss` / `mm:ss`.
  final DurationFormat format;

  /// Parsed value on every change — null while the mask is incomplete.
  final ValueChanged<DurationValue?>? onDurationChanged;

  /// Fires once when the mask fills completely.
  final ValueChanged<DurationValue>? onCompleted;

  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final String? label;
  final String? identifier;

  /// Null → the format's template (`hh:mm`).
  final String? hint;

  final bool enabled;
  final bool readOnly;
  final String? errorText;

  /// Sync check override. Null → required + complete + bounds + step.
  final String? Function(String?)? validator;

  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final ValidationMode validationMode;

  /// Keep `true` inside a `Form`; `false` for standalone fields.
  final bool deferToParentForm;

  /// Status rows below the field (sorted by severity).
  final List<FieldMessage> messages;

  final bool showSuccess;

  /// Bounds. [maxDuration] blocks at the keystroke; [minDuration]
  /// validates on trigger (you must be able to type through low values).
  final Duration? minDuration;
  final Duration? maxDuration;

  /// Minutes must land on this grid (15 → :00/:15/:30/:45); ↑/↓ snaps.
  final int? minuteStep;

  /// Haptic tick on ↑/↓ stepping.
  final bool enableHaptic;

  /// Live "1h 30m" row under a complete value.
  final bool showSummary;

  /// Trailing timer button → [CupertinoTimerPicker] bottom sheet.
  final bool showPickerButton;

  final bool showPrefixIcon;

  /// Per-call visual override (wins over the app-wide theme).
  final TextFieldStyle? style;

  /// Box geometry (height / width / fit-to-content / density).
  final TextFieldSizing? sizing;

  @override
  State<DurationField> createState() => _DurationFieldState();
}

class _DurationFieldState extends State<DurationField> {
  FocusNode? _internalFocus;
  bool _externalKeyHandlerAttached = false;
  bool _completedFired = false;

  FocusNode get _focus =>
      widget.focusNode ??
      (_internalFocus ??= FocusNode(onKeyEvent: _onKeyEvent));

  @override
  void initState() {
    super.initState();
    final ext = widget.focusNode;
    if (ext != null && ext.onKeyEvent == null) {
      ext.onKeyEvent = _onKeyEvent;
      _externalKeyHandlerAttached = true;
    }
  }

  @override
  void dispose() {
    if (_externalKeyHandlerAttached) widget.focusNode?.onKeyEvent = null;
    _internalFocus?.dispose();
    super.dispose();
  }

  // ── parsing ─────────────────────────────────────────────────────────

  DurationFormat get _format => widget.format;

  bool _isComplete(String text) =>
      text.length == _format.template.length &&
      !text.split(':').any((s) => s.length != 2);

  /// Segments → [Duration]. Null while incomplete.
  Duration? _parse(String text) {
    if (!_isComplete(text)) return null;
    final parts = text.split(':').map(int.parse).toList();
    return switch (_format) {
      DurationFormat.hm => Duration(hours: parts[0], minutes: parts[1]),
      DurationFormat.hms => Duration(
        hours: parts[0],
        minutes: parts[1],
        seconds: parts[2],
      ),
      DurationFormat.ms => Duration(minutes: parts[0], seconds: parts[1]),
    };
  }

  /// Segment values for a possibly-partial mask (missing → 0).
  List<int> _segments(String text) {
    final parts = text.split(':');
    return List.generate(_format.segmentCount, (i) {
      if (i >= parts.length || parts[i].isEmpty) return 0;
      return int.tryParse(parts[i]) ?? 0;
    });
  }

  String _renderSegments(List<int> values) =>
      values.map((v) => v.toString().padLeft(2, '0')).join(':');

  Duration _segmentsToDuration(List<int> values) => switch (_format) {
    DurationFormat.hm => Duration(hours: values[0], minutes: values[1]),
    DurationFormat.hms => Duration(
      hours: values[0],
      minutes: values[1],
      seconds: values[2],
    ),
    DurationFormat.ms => Duration(minutes: values[0], seconds: values[1]),
  };

  /// Human copy for a duration — "1h 30m", "4m 30s" — localized.
  String _human(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final parts = <String>[
      if (_format.hasHours)
        TimeRangeStrings.duration(h, m)
      else
        DurationFieldStrings.minutes(d.inMinutes),
      if (_format.hasSeconds && s > 0) DurationFieldStrings.seconds(s),
    ];
    return parts.join(' ');
  }

  // ── max hard-block ──────────────────────────────────────────────────

  /// Runs AFTER the mask formatter: rejects an edit whose value (partial
  /// hours or complete total) already exceeds [DurationField.maxDuration].
  TextEditingValue _blockBeyondMax(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final max = widget.maxDuration;
    if (max == null) return newValue;
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final parts = text.split(':');
    // Leading segment alone can already bust the cap (9h under max 8h) —
    // the mask may have auto-appended the separator, so judge the segment
    // itself, not the part count.
    final leading = int.tryParse(parts[0]) ?? 0;
    final leadingCap = _format.hasHours ? max.inHours : max.inMinutes;
    if (parts[0].length == 2 && leading > leadingCap) return oldValue;
    final complete = _parse(text);
    if (complete != null && complete > max) return oldValue;
    return newValue;
  }

  // ── stepping ────────────────────────────────────────────────────────

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !widget.enabled || widget.readOnly) {
      return KeyEventResult.ignored;
    }
    final direction = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => 1,
      LogicalKeyboardKey.arrowDown => -1,
      _ => 0,
    };
    if (direction == 0) return KeyEventResult.ignored;

    final text = widget.controller.text;
    final caret = widget.controller.selection.baseOffset.clamp(0, text.length);
    final segIdx = (caret ~/ 3).clamp(0, _format.segmentCount - 1);
    final values = _segments(text);

    final isLeading = segIdx == 0;
    final isMinutes =
        (_format.hasHours && segIdx == 1) || (!_format.hasHours && segIdx == 0);
    final step = isMinutes && widget.minuteStep != null
        ? widget.minuteStep!
        : 1;

    var v = values[segIdx] + direction * step;
    if (isMinutes && widget.minuteStep != null) {
      // Snap onto the grid.
      v = ((v / step).round() * step);
    }
    if (isLeading) {
      final cap = _format.hasHours ? (widget.maxDuration?.inHours ?? 99) : 99;
      v = v.clamp(0, cap.clamp(0, 99));
    } else {
      if (v < 0) v = 60 - step.clamp(1, 60);
      if (v > 59) v = 0;
    }
    values[segIdx] = v;

    final max = widget.maxDuration;
    if (max != null && _segmentsToDuration(values) > max) {
      return KeyEventResult.handled; // stepping never busts the cap
    }

    final rendered = _renderSegments(values);
    widget.controller.value = TextEditingValue(
      text: rendered,
      selection: TextSelection.collapsed(
        offset: (2 + segIdx * 3).clamp(0, rendered.length),
      ),
    );
    if (widget.enableHaptic) HapticFeedback.selectionClick();
    setState(() {});
    _notify();
    return KeyEventResult.handled;
  }

  // ── picker ──────────────────────────────────────────────────────────

  Future<void> _openPicker() async {
    // `PickerDialogs.duration`, not `CupertinoTimerPicker` — the last
    // borrowed picker in the app. That one arrives with its own wheel
    // geometry, its own type scale and its own selection band, none of
    // which the app's bag can reach.
    final result = await PickerDialogs.duration(
      context,
      initial:
          _parse(widget.controller.text) ?? widget.minDuration ?? Duration.zero,
      format: _format,
      minuteInterval: widget.minuteStep ?? 1,
      maxDuration: widget.maxDuration,
      title: DurationFieldStrings.pick,
    );
    if (!mounted || result == null) return;
    var value = result;
    final max = widget.maxDuration;
    if (max != null && value > max) value = max;
    final values = switch (_format) {
      DurationFormat.hm => [value.inHours, value.inMinutes % 60],
      DurationFormat.hms => [
        value.inHours,
        value.inMinutes % 60,
        value.inSeconds % 60,
      ],
      DurationFormat.ms => [value.inMinutes, value.inSeconds % 60],
    };
    final rendered = _renderSegments(values);
    widget.controller.value = TextEditingValue(
      text: rendered,
      selection: TextSelection.collapsed(offset: rendered.length),
    );
    setState(() {});
    _notify();
  }

  // ── validation + emission ───────────────────────────────────────────

  String? _defaultValidator(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) {
      return DurationFieldStrings.required;
    }
    final parsed = _parse(text);
    if (parsed == null) {
      return DurationFieldStrings.incomplete;
    }
    final min = widget.minDuration;
    if (min != null && parsed < min) {
      return DurationFieldStrings.min(_human(min));
    }
    final max = widget.maxDuration;
    if (max != null && parsed > max) {
      return DurationFieldStrings.max(_human(max));
    }
    final step = widget.minuteStep;
    if (step != null) {
      final minutes = _format.hasHours
          ? parsed.inMinutes % 60
          : parsed.inMinutes;
      if (minutes % step != 0) {
        return DurationFieldStrings.step(step);
      }
    }
    return null;
  }

  void _notify() {
    final parsed = _parse(widget.controller.text);
    final validator = widget.validator ?? _defaultValidator;
    final value = parsed == null
        ? null
        : DurationValue(
            duration: parsed,
            isValid: validator(widget.controller.text) == null,
          );
    widget.onDurationChanged?.call(value);
    if (value != null && !_completedFired) {
      _completedFired = true;
      widget.onCompleted?.call(value);
    } else if (value == null) {
      _completedFired = false;
    }
  }

  // ── build ───────────────────────────────────────────────────────────

  FieldMessage? get _summaryRow {
    if (!widget.showSummary) return null;
    final parsed = _parse(widget.controller.text);
    if (parsed == null) return null;
    return FieldMessage.info(_human(parsed), icon: Icons.timelapse);
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summaryRow;
    return GlobalTextFormField(
      controller: widget.controller,
      label: widget.label,
      identifier: widget.identifier,
      hint: widget.hint ?? _format.template,
      focusNode: _focus,
      style: widget.style ?? const TextFieldStyle(),
      sizing: widget.sizing ?? const TextFieldSizing(),
      messages: [
        ...widget.messages,
        if (summary != null) summary,
      ],
      behavior: TextFieldBehavior(
        keyboardType: TextInputType.number,
        textInputAction: widget.textInputAction,
        inputFormatters: [
          DurationInputFormatter(format: _format),
          TextInputFormatter.withFunction(_blockBeyondMax),
        ],
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        autoDetectDirection: false,
      ),
      validation: TextFieldValidation(
        validator: widget.validator ?? _defaultValidator,
        errorText: widget.errorText,
        mode: widget.validationMode,
        deferToParentForm: widget.deferToParentForm,
        revalidateKey: (
          widget.minDuration,
          widget.maxDuration,
          widget.minuteStep,
        ),
      ),
      features: TextFieldFeatures(showSuccess: widget.showSuccess),
      slots: TextFieldSlots(
        prefixIcon: widget.showPrefixIcon
            ? Padding(
                padding: const EdgeInsetsDirectional.only(start: 12, end: 8),
                child: Icon(
                  Icons.hourglass_bottom_outlined,
                  color: context.iconColors.primary,
                ),
              )
            : null,
        suffix: widget.showPickerButton && widget.enabled && !widget.readOnly
            ? TextFieldSuffix.icon(Icons.timer_outlined, onTap: _openPicker)
            : null,
      ),
      callbacks: TextFieldCallbacks(
        onChanged: (value) {
          widget.onChanged?.call(value);
          // Summary appears/disappears with completeness.
          setState(() {});
          _notify();
        },
        onSubmitted: widget.onSubmitted,
      ),
    );
  }
}
