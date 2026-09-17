import 'package:flutter/services.dart';

/// Live title-casing for name input: the first letter of every word is
/// uppercased as it's typed OR pasted — `john doe` → `John Doe`,
/// `mary-jane` → `Mary-Jane`.
///
/// Why a formatter: `TextCapitalization.words` is advisory — only the
/// soft keyboard honours it; hardware keyboards and paste bypass it.
///
/// Rules:
/// * Word starts = string start / after whitespace / after `-`.
/// * Only the FIRST letter is touched — the rest keep their typed case,
///   so `McDonald` and `O'Brien` survive.
/// * Caseless scripts (Arabic, CJK…) are naturally untouched
///   (`toUpperCase()` is the identity).
/// * Case-only mapping (1:1 length) — the caret never moves.
class NameCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cased = titleCase(newValue.text);
    if (cased == newValue.text) return newValue;
    return newValue.copyWith(text: cased);
  }

  /// The pure mapping — exposed for prefill / programmatic writes.
  static String titleCase(String input) {
    if (input.isEmpty) return input;
    final buffer = StringBuffer();
    var atWordStart = true;
    for (final rune in input.runes) {
      final char = String.fromCharCode(rune);
      if (atWordStart) {
        buffer.write(char.toUpperCase());
      } else {
        buffer.write(char);
      }
      atWordStart = char.trim().isEmpty || char == '-';
    }
    return buffer.toString();
  }
}
