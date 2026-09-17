import 'dart:math';

import 'package:flutter/services.dart';

/// Live-groups a national phone number as it's typed: digits only, split
/// into [groups] separated by spaces — `7912345678` → `791 234 5678` with
/// the default `[3, 3, 4]`. Overflow beyond the defined groups keeps
/// chunking by the last group size. Caret position is preserved by digit
/// count, so edits mid-number don't jump the cursor.
///
/// Generic by design — real per-country patterns are libphonenumber
/// territory; pass custom [groups] where a specific market needs them.
class PhoneGroupingInputFormatter extends TextInputFormatter {
  PhoneGroupingInputFormatter({
    this.groups = const [3, 3, 4],
    this.maxDigits = 15, // E.164 upper bound
    this.trunkZeroExtra = false,
    this.groupsAreNsn = false,
  }) : assert(groups.isNotEmpty, 'groups must not be empty');

  final List<int> groups;
  final int maxDigits;

  /// When [maxDigits] bounds the NATIONAL significant number (trunk zero
  /// excluded — per-country `CountryCode.maxLength`), a user typing the
  /// local form spends one extra digit on the trunk zero (`0791234567` is
  /// 10 keystrokes for Jordan's 9-digit NSN). `true` grants that extra
  /// digit while the input starts with `0`.
  final bool trunkZeroExtra;

  /// `true` when [groups] describe the NSN (trunk zero excluded — e.g.
  /// `CountryCode.groupSizes`, France `[1,2,2,2,2]` → `6 12 34 56 78`).
  /// A typed trunk zero is then absorbed into the FIRST group
  /// (`06 12 34 56 78`) instead of shifting every boundary.
  final bool groupsAreNsn;

  static final _nonDigit = RegExp(r'\D');
  static final _digit = RegExp(r'\d');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(_nonDigit, '');
    final cap = (trunkZeroExtra && digits.startsWith('0'))
        ? maxDigits + 1
        : maxDigits;
    if (digits.length > cap) digits = digits.substring(0, cap);

    // How many digits sit before the caret in the raw input — the caret
    // lands after the same count in the formatted output.
    final rawCaret = newValue.selection.baseOffset.clamp(
      0,
      newValue.text.length,
    );
    final digitsBeforeCaret = newValue.text
        .substring(0, rawCaret)
        .replaceAll(_nonDigit, '')
        .length
        .clamp(0, digits.length);

    final formatted = _group(digits);

    var caret = formatted.length;
    if (digitsBeforeCaret == 0) {
      caret = 0;
    } else {
      var seen = 0;
      for (var i = 0; i < formatted.length; i++) {
        if (_digit.hasMatch(formatted[i])) {
          seen++;
          if (seen == digitsBeforeCaret) {
            caret = i + 1;
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

  String _group(String digits) => group(
    digits,
    groups: groups,
    absorbLeadingZero: groupsAreNsn && digits.startsWith('0'),
  );

  /// The pure grouping — `group('7912345678')` → `'791 234 5678'`.
  /// Static so callers can format non-input text the same way (e.g. a
  /// ghost placeholder template matching the live grouping).
  /// [absorbLeadingZero] widens the FIRST group by one so a trunk zero
  /// rides along with NSN-defined groups (`[2,3,4]` + `079…` → `079 …`).
  static String group(
    String digits, {
    List<int> groups = const [3, 3, 4],
    bool absorbLeadingZero = false,
  }) {
    if (digits.isEmpty) return '';
    final effective = absorbLeadingZero
        ? [groups.first + 1, ...groups.skip(1)]
        : groups;
    final buffer = StringBuffer();
    var index = 0;
    var groupIndex = 0;
    while (index < digits.length) {
      final size = groupIndex < effective.length
          ? effective[groupIndex]
          : effective.last;
      final end = min(index + size, digits.length);
      if (index > 0) buffer.write(' ');
      buffer.write(digits.substring(index, end));
      index = end;
      groupIndex++;
    }
    return buffer.toString();
  }
}
