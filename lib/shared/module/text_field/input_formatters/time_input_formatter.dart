import 'package:flutter/material.dart' show DayPeriod;
import 'package:flutter/services.dart';

import 'date_input_formatter.dart';

/// Numeric time mask (`14:30` / `02:30` / `14:30:05`) — the date-formatter
/// smarts for clock time:
///
/// * auto-inserts the `:` between segments ([withSeconds] adds a third);
/// * zero-pads unambiguous first digits (24h: `3` → `03`; 12h: `2` →
///   `02`; minutes/seconds: `7` → `07`) AND a lone digit closed with a
///   typed separator (`9:` → `09:`);
/// * impossible values never enter (`24`+ in 24h, minutes over 59 — the
///   previous text is kept);
/// * **12h conveniences**: a typed 24h hour converts (`14` → `02` +
///   [onDayPeriod] fires PM; `00` → `12` AM), and a typed period letter
///   (`a` / `p` / `ص` / `م`) sets the period without entering the text;
/// * Eastern-Arabic / Persian keyboard digits normalize to ASCII;
/// * caret preserved by digit count.
class TimeInputFormatter extends TextInputFormatter {
  TimeInputFormatter({
    this.use24h = true,
    this.withSeconds = false,
    this.separator = ':',
    this.onDayPeriod,
  });

  /// 24-hour (`00–23`) vs 12-hour (`01–12`) hour segment. Minutes and
  /// seconds are `00–59` either way.
  final bool use24h;

  /// Add an `ss` segment (`HH:mm:ss`).
  final bool withSeconds;

  final String separator;

  /// 12h mode: fired when the INPUT implies a period — a converted 24h
  /// hour (`14` → PM) or a typed period letter. The field mirrors it
  /// onto its AM/PM picker (defer any setState — this fires during text
  /// editing).
  final ValueChanged<DayPeriod>? onDayPeriod;

  static final _nonDigit = RegExp(r'\D');

  /// A single digit "closed" by a typed separator (`9:`, `9.`, `9 `).
  static final _closedSingle = RegExp(r'(?<![0-9])([0-9])(?=[:. ])');

  /// Latin/Arabic period letters (`a`/`p`/`ص`/`م`).
  static final _periodLetter = RegExp('[AaPpصم]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var ascii = DateInputFormatter.normalizeDigits(newValue.text);

    // 12h: a typed period letter sets AM/PM and never enters the text.
    if (!use24h && onDayPeriod != null) {
      final letter = _periodLetter.firstMatch(ascii);
      if (letter != null) {
        final ch = letter.group(0)!.toLowerCase();
        onDayPeriod!(ch == 'a' || ch == 'ص' ? DayPeriod.am : DayPeriod.pm);
      }
    }
    ascii = ascii.replaceAll(_periodLetter, '');

    final closed = ascii.replaceAllMapped(
      _closedSingle,
      (m) => '0${m.group(1)}',
    );
    final raw = closed.replaceAll(_nonDigit, '');

    // (padOver, maxValue, rejectZero) per segment.
    final segments = [
      // 12h hour accepts 13–23 and 00 as INPUT — converted below.
      use24h ? (2, 23, false) : (1, 23, false), // hour
      (5, 59, false), // minute
      if (withSeconds) (5, 59, false), // second
    ];

    final padsAt = <int>[];
    final parts = <String>[];
    var i = 0;
    var segIndex = 0;
    for (final (padOver, maxValue, rejectZero) in segments) {
      if (i >= raw.length) break;
      String part;
      final first = raw.codeUnitAt(i) - 0x30;
      if (first > padOver) {
        part = '0${raw[i]}';
        padsAt.add(i);
        i++;
      } else {
        final end = i + 2 > raw.length ? raw.length : i + 2;
        part = raw.substring(i, end);
        i = end;
      }
      if (part.length == 2) {
        var v = int.parse(part);
        if (v > maxValue || (rejectZero && v == 0)) return oldValue;
        // 12h hour conveniences: 24h-style input converts in place.
        if (!use24h && segIndex == 0) {
          if (v == 0) {
            part = '12'; // midnight → 12 AM
            onDayPeriod?.call(DayPeriod.am);
          } else if (v > 12) {
            v -= 12;
            part = v.toString().padLeft(2, '0');
            onDayPeriod?.call(DayPeriod.pm);
          }
        }
      }
      parts.add(part);
      segIndex++;
    }
    final formatted = parts.join(separator);

    final rawCaret = newValue.selection.baseOffset.clamp(0, ascii.length);
    var digitsBeforeCaret = ascii
        .substring(0, rawCaret)
        .replaceAll(_nonDigit, '')
        .length;
    digitsBeforeCaret += padsAt.where((p) => p < digitsBeforeCaret).length;

    var caret = formatted.length;
    if (digitsBeforeCaret == 0) {
      caret = 0;
    } else {
      var seen = 0;
      for (var c = 0; c < formatted.length; c++) {
        if (formatted[c] != separator) {
          seen++;
          if (seen == digitsBeforeCaret) {
            caret = c + 1;
            break;
          }
        }
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: caret),
    );
  }
}
