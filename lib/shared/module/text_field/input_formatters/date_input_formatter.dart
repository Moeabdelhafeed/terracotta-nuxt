import 'package:flutter/services.dart';

/// Digit order of a numeric date mask — which segments, in which order.
/// The last two are PARTIAL dates (no year / no day) for expiries and
/// recurring dates.
enum DateDigitOrder {
  /// `DD/MM/YYYY` — most of the world (and the Arabic locales).
  dmy,

  /// `MM/DD/YYYY` — US style.
  mdy,

  /// `YYYY/MM/DD` — ISO-flavored.
  ymd,

  /// `DD/MM` — day + month only (recurring dates, day-month forms).
  /// Consumers get a sentinel LEAP year (2000), so `29/02` stays valid.
  dm,

  /// `MM/YY` — card-expiry style month + 2-digit year (read as 20xx).
  /// Consumers get the LAST day of that month (expiry semantics).
  my;

  List<DateSegmentKind> get segments => switch (this) {
    DateDigitOrder.dmy => const [
      DateSegmentKind.day,
      DateSegmentKind.month,
      DateSegmentKind.year,
    ],
    DateDigitOrder.mdy => const [
      DateSegmentKind.month,
      DateSegmentKind.day,
      DateSegmentKind.year,
    ],
    DateDigitOrder.ymd => const [
      DateSegmentKind.year,
      DateSegmentKind.month,
      DateSegmentKind.day,
    ],
    DateDigitOrder.dm => const [
      DateSegmentKind.day,
      DateSegmentKind.month,
    ],
    DateDigitOrder.my => const [
      DateSegmentKind.month,
      DateSegmentKind.year2,
    ],
  };

  /// Full date (day + month + 4-digit year)? Partial orders skip the
  /// calendar picker, Hijri/age rows, smart paste and year expansion.
  bool get isFullDate => segments.contains(DateSegmentKind.year);

  /// The typing template for this order (`DD/MM/YYYY`) — hint + ghost text.
  String template([String separator = '/']) =>
      segments.map((s) => s.patternChar * s.length).join(separator);
}

/// One slot of the date mask.
enum DateSegmentKind {
  /// `01–31`; a first keystroke of 4–9 is unambiguous → zero-padded.
  day(length: 2, maxValue: 31, padOver: 3, patternChar: 'D'),

  /// `01–12`; a first keystroke of 2–9 is unambiguous → zero-padded.
  month(length: 2, maxValue: 12, padOver: 1, patternChar: 'M'),

  /// Four digits, no keystroke rules (the validator owns range checks).
  year(length: 4, maxValue: 9999, padOver: 9, patternChar: 'Y'),

  /// Two-digit year (`MM/YY` expiries) — read as 20xx.
  year2(length: 2, maxValue: 99, padOver: 9, patternChar: 'Y');

  const DateSegmentKind({
    required this.length,
    required this.maxValue,
    required this.padOver,
    required this.patternChar,
  });

  final int length;
  final int maxValue;

  /// First digits above this can only start a single-digit value —
  /// zero-pad immediately (9 = never pads).
  final int padOver;

  final String patternChar;
}

/// Numeric date mask (`14/05/2001`) with the expiry-formatter smarts,
/// generalized over [DateDigitOrder]:
///
/// * auto-inserts the separator between segments;
/// * zero-pads unambiguous first digits (`4` → `04` in a day slot) AND a
///   lone digit the user closed with a separator (`1/` → `01/`);
/// * impossible segment values never enter the field (`00`, day `> 31`,
///   month `> 12` keep the previous text);
/// * caret is preserved by digit count, so mid-edit doesn't jump it to
///   the end.
///
/// Calendar validity (Feb 30, year bounds) is the VALIDATOR's job — this
/// only polices what a segment could never be.
class DateInputFormatter extends TextInputFormatter {
  DateInputFormatter({
    this.order = DateDigitOrder.dmy,
    this.separator = '/',
  });

  final DateDigitOrder order;
  final String separator;

  static final _nonDigit = RegExp(r'\D');

  /// A single digit "closed" by a typed separator (`1/`, `1-`, `1.`).
  static final _closedSingle = RegExp(r'(?<![0-9])([0-9])(?=[/\-. ])');

  /// Arabic-Indic (`٠–٩`) and Extended/Persian (`۰–۹`) digits → ASCII.
  /// Arabic keyboards emit these; without the mapping every keystroke
  /// would be stripped as a non-digit.
  static String normalizeDigits(String text) {
    if (text.codeUnits.every((u) => u < 0x0660)) return text; // fast path
    final buffer = StringBuffer();
    for (final u in text.codeUnits) {
      if (u >= 0x0660 && u <= 0x0669) {
        buffer.writeCharCode(u - 0x0660 + 0x30); // ٠–٩
      } else if (u >= 0x06F0 && u <= 0x06F9) {
        buffer.writeCharCode(u - 0x06F0 + 0x30); // ۰–۹
      } else {
        buffer.writeCharCode(u);
      }
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Eastern digits count as digits everywhere below (1:1 length map,
    // so the caret math is unaffected).
    final ascii = normalizeDigits(newValue.text);
    // `1/` means "day is 1, done" — pad before stripping separators.
    final closed = ascii.replaceAllMapped(
      _closedSingle,
      (m) => '0${m.group(1)}',
    );
    final raw = closed.replaceAll(_nonDigit, '');

    final segments = order.segments;
    // Raw-digit indexes that had a zero injected before them (caret math).
    final padsAt = <int>[];
    final parts = <String>[];
    var i = 0;
    for (final seg in segments) {
      if (i >= raw.length) break;
      String part;
      if (seg.length == 2) {
        final first = raw.codeUnitAt(i) - 0x30;
        if (first > seg.padOver) {
          part = '0${raw[i]}';
          padsAt.add(i);
          i++;
        } else {
          final end = i + 2 > raw.length ? raw.length : i + 2;
          part = raw.substring(i, end);
          i = end;
        }
        if (part.length == 2) {
          final v = int.parse(part);
          if (v == 0 || v > seg.maxValue) return oldValue;
        }
      } else {
        final end = i + seg.length > raw.length ? raw.length : i + seg.length;
        part = raw.substring(i, end);
        i = end;
      }
      parts.add(part);
      // Digits beyond a full date are dropped (the loop consumes at most
      // the segments' total).
    }
    final formatted = parts.join(separator);

    // Caret: count digits before the caret in the (normalized) input, add
    // the zero-pads that landed before them, then map onto the formatted
    // text. `ascii` is a 1:1 mapping of the original, so offsets agree.
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
