import 'package:flutter/cupertino.dart'
    show CupertinoPicker, CupertinoPickerDefaultSelectionOverlay;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/localization/number_formatter.dart';
import '../../../core/localization/strings/duration_field_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../text_field/input_formatters/duration_input_formatter.dart';
import 'date_time_picker_style.dart';
import 'theme/date_time_picker_theme.dart';

// ---------------------------------------------------------------------------
// GlobalDurationPicker — an elapsed span, on the module's own wheels
// ---------------------------------------------------------------------------

/// Picks a [Duration] — hours, minutes and optionally seconds.
///
/// A duration is NOT a point in time, which is why it is a widget of its
/// own rather than a mode on [GlobalDateTimePicker]: nothing about it
/// clamps to a calendar, and 90 minutes is a legal answer where 90
/// o'clock is not.
///
/// It exists because `DurationField` was the last thing in the app on a
/// borrowed picker — `CupertinoTimerPicker`, which arrives with its own
/// wheel geometry, its own type scale and its own idea of a selection
/// band, none of which the app's bag can reach.
class GlobalDurationPicker extends StatefulWidget {
  const GlobalDurationPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.format = DurationFormat.hm,
    this.minuteInterval = 1,
    this.secondInterval = 1,
    this.maxHours = 23,
    this.style,
  }) : assert(
         minuteInterval > 0 && 60 % minuteInterval == 0,
         'minuteInterval must divide 60',
       ),
       assert(
         secondInterval > 0 && 60 % secondInterval == 0,
         'secondInterval must divide 60',
       );

  final Duration value;
  final ValueChanged<Duration> onChanged;

  /// Which segments the wheels show. `hm`, `hms` or `ms`.
  final DurationFormat format;

  final int minuteInterval;
  final int secondInterval;

  /// The hour wheel's ceiling. A duration has no natural one, so this
  /// is a choice rather than a fact — 23 matches what the field it
  /// replaced offered.
  final int maxHours;

  final DateTimePickerStyle? style;

  @override
  State<GlobalDurationPicker> createState() => _GlobalDurationPickerState();
}

class _GlobalDurationPickerState extends State<GlobalDurationPicker> {
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minuteCtrl;
  late FixedExtentScrollController _secondCtrl;

  ResolvedDateTimePickerStyle _style = ResolvedDateTimePickerStyle.fallback;

  bool get _hasHours => widget.format != DurationFormat.ms;
  bool get _hasSeconds => widget.format != DurationFormat.hm;

  int get _hours => widget.value.inHours.clamp(0, widget.maxHours);
  int get _minutes =>
      _hasHours ? widget.value.inMinutes % 60 : widget.value.inMinutes;
  int get _seconds => widget.value.inSeconds % 60;

  @override
  void initState() {
    super.initState();
    _hourCtrl = FixedExtentScrollController(initialItem: _hours);
    _minuteCtrl = FixedExtentScrollController(
      initialItem: _minutes ~/ widget.minuteInterval,
    );
    _secondCtrl = FixedExtentScrollController(
      initialItem: _seconds ~/ widget.secondInterval,
    );
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _secondCtrl.dispose();
    super.dispose();
  }

  void _emit({int? hours, int? minutes, int? seconds}) {
    final next = Duration(
      hours: _hasHours ? (hours ?? _hours) : 0,
      minutes: minutes ?? _minutes,
      seconds: _hasSeconds ? (seconds ?? _seconds) : 0,
    );
    if (next == widget.value) return;
    if (_style.enableHaptic) HapticFeedback.selectionClick();
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    _style = (widget.style ?? const DateTimePickerStyle()).resolve(context);

    return SizedBox(
      height: _style.wheelHeight,
      child: Row(
        children: [
          if (_hasHours)
            _wheel(
              ctrl: _hourCtrl,
              label: DurationFieldStrings.hoursWord,
              count: widget.maxHours + 1,
              step: 1,
              onChanged: (v) => _emit(hours: v),
            ),
          _wheel(
            ctrl: _minuteCtrl,
            label: DurationFieldStrings.minutesWord,
            // Minutes-only spans past an hour, so the wheel does too.
            count: _hasHours ? 60 ~/ widget.minuteInterval : 60,
            step: widget.minuteInterval,
            onChanged: (v) => _emit(minutes: v),
          ),
          if (_hasSeconds)
            _wheel(
              ctrl: _secondCtrl,
              label: DurationFieldStrings.secondsWord,
              count: 60 ~/ widget.secondInterval,
              step: widget.secondInterval,
              onChanged: (v) => _emit(seconds: v),
            ),
        ],
      ),
    );
  }

  Widget _wheel({
    required FixedExtentScrollController ctrl,
    required String label,
    required int count,
    required int step,
    required ValueChanged<int> onChanged,
  }) {
    return Expanded(
      child: Semantics(
        container: true,
        explicitChildNodes: true,
        label: label,
        child: Column(
          children: [
            ExcludeSemantics(
              child: Text(
                label,
                style: context.textTheme.labelSmall?.copyWith(
                  color: _style.weekdayLabelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: context.spacing.xs),
            Expanded(
              child: CupertinoPicker(
                scrollController: ctrl,
                itemExtent: _style.wheelItemExtent,
                useMagnifier: _style.wheelMagnifier,
                magnification: _style.wheelMagnification,
                squeeze: _style.wheelSqueeze,
                selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                  background: _style.wheelSelectionColor,
                ),
                onSelectedItemChanged: (i) => onChanged(i * step),
                children: [
                  for (var i = 0; i < count; i++)
                    Center(
                      child: Text(
                        AppNumbers.padded(i * step, width: 2),
                        style: _style.wheelTextStyle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
