import 'package:flutter/services.dart';

/// Formats an amount as it's typed: thousands separators on the integer
/// part (`49999` → `49,999`) and a decimal cap from the currency
/// ([decimalDigits] — JOD 3, USD 2, JPY 0). Caret is preserved by
/// significant-character count, so mid-number edits don't jump the
/// cursor to the end.
class CurrencyInputFormatter extends TextInputFormatter {
  CurrencyInputFormatter({this.decimalDigits = 2}) : assert(decimalDigits >= 0);

  /// Max fraction digits — typing beyond it is rejected.
  final int decimalDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return newValue.copyWith(text: '');

    final pattern = decimalDigits == 0
        ? RegExp(r'^\d*$')
        : RegExp('^\\d*\\.?\\d{0,$decimalDigits}\$');
    if (!pattern.hasMatch(raw)) return oldValue;

    final dot = raw.indexOf('.');
    final integerPart = dot < 0 ? raw : raw.substring(0, dot);
    final decimalPart = dot < 0 ? '' : raw.substring(dot);

    final formatted = _group(integerPart) + decimalPart;

    // Caret by significant characters (digits + the dot) — commas are
    // presentation only.
    final rawCaret = newValue.selection.baseOffset.clamp(
      0,
      newValue.text.length,
    );
    final sigBeforeCaret = newValue.text
        .substring(0, rawCaret)
        .replaceAll(',', '')
        .length;

    var caret = formatted.length;
    if (sigBeforeCaret == 0) {
      caret = 0;
    } else {
      var seen = 0;
      for (var i = 0; i < formatted.length; i++) {
        if (formatted[i] != ',') {
          seen++;
          if (seen == sigBeforeCaret) {
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

  String _group(String digits) {
    if (digits.length <= 3) return digits;
    final buffer = StringBuffer();
    final mod = digits.length % 3;
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (i - mod) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
