import 'package:flutter/services.dart';

import 'date_input_formatter.dart' show DateInputFormatter;

/// Which segments a duration mask carries.
enum DurationFormat {
  /// `hh:mm` — meetings, parking, shifts.
  hm,

  /// `hh:mm:ss` — video, workouts.
  hms,

  /// `mm:ss` — songs, intervals.
  ms,
}

extension DurationFormatX on DurationFormat {
  int get segmentCount => this == DurationFormat.hms ? 3 : 2;

  bool get hasHours => this != DurationFormat.ms;

  bool get hasSeconds => this != DurationFormat.hm;

  /// Full mask template (`hh:mm:ss`).
  String get template => switch (this) {
    DurationFormat.hm => 'hh:mm',
    DurationFormat.hms => 'hh:mm:ss',
    DurationFormat.ms => 'mm:ss',
  };
}

/// Masked duration entry — colon-separated 2-digit segments.
///
/// * Segments capped at 59 (minutes/seconds beside an hours segment)
///   zero-pad an impossible first keystroke: `6` → `06`. The LEADING
///   segment (hours — or minutes in `mm:ss`) accepts 00–99.
/// * A typed `:` closes a single-digit segment (`1:` → `01:`).
/// * Eastern-Arabic / Persian digits normalize to ASCII.
/// * Digits beyond the mask are dropped.
class DurationInputFormatter extends TextInputFormatter {
  DurationInputFormatter({this.format = DurationFormat.hm});

  final DurationFormat format;

  /// True for segments whose value can't exceed 59 (everything after
  /// the leading segment).
  bool _capped59(int segment) => segment > 0;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final grew = newValue.text.length > oldValue.text.length;
    final typedSeparator = grew && newValue.text.trimRight().endsWith(':');

    var digits = DateInputFormatter.normalizeDigits(
      newValue.text,
    ).replaceAll(RegExp(r'\D'), '');

    final segments = <String>[];
    var index = 0;
    for (
      var seg = 0;
      seg < format.segmentCount && index < digits.length;
      seg++
    ) {
      final first = digits.codeUnitAt(index) - 0x30;
      if (_capped59(seg) && first > 5) {
        // Impossible tens digit for a 0–59 segment — zero-pad.
        segments.add('0$first');
        index += 1;
        continue;
      }
      final end = (index + 2) > digits.length ? digits.length : index + 2;
      segments.add(digits.substring(index, end));
      index = end;
    }

    // A typed separator closes a 1-digit segment: `1:` → `01`.
    if (typedSeparator && segments.isNotEmpty && segments.last.length == 1) {
      segments[segments.length - 1] = '0${segments.last}';
    }

    final buffer = StringBuffer();
    for (var i = 0; i < segments.length; i++) {
      if (i > 0) buffer.write(':');
      buffer.write(segments[i]);
    }
    var text = buffer.toString();
    // Trailing separator when the last consumed segment is complete and
    // another segment remains — so typing flows `01` → `01:`.
    final lastComplete = segments.isNotEmpty && segments.last.length == 2;
    if (lastComplete && segments.length < format.segmentCount && grew) {
      text = '$text:';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
