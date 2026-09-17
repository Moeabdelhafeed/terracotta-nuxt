import 'package:flutter/services.dart';

/// IBAN — uppercases, strips non-alphanumerics, groups into blocks of 4.
/// Caret is preserved by character count, so mid-edit doesn't jump the
/// cursor to the end.
class IbanInputFormatter extends TextInputFormatter {
  static final _invalid = RegExp(r'[^A-Z0-9]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var clean = newValue.text.toUpperCase().replaceAll(_invalid, '');
    if (clean.length > 34) clean = clean.substring(0, 34);

    final buffer = StringBuffer();
    for (var i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    final formatted = buffer.toString();

    final rawCaret = newValue.selection.baseOffset.clamp(
      0,
      newValue.text.length,
    );
    final charsBeforeCaret = newValue.text
        .substring(0, rawCaret)
        .toUpperCase()
        .replaceAll(_invalid, '')
        .length
        .clamp(0, clean.length);

    var caret = formatted.length;
    if (charsBeforeCaret == 0) {
      caret = 0;
    } else {
      var seen = 0;
      for (var i = 0; i < formatted.length; i++) {
        if (formatted[i] != ' ') {
          seen++;
          if (seen == charsBeforeCaret) {
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
}
