import 'package:flutter/services.dart';

import '../../../../core/utils/card_brand.dart';

/// Formats a card number as it's typed, following the detected network:
/// spaces every 4 for most brands, embossing groups for Amex (`4-6-5`)
/// and Diners (`4-6-4`), digit cap from the brand's real max length
/// (19 for Visa/UnionPay — not a hard 16). Caret is preserved by digit
/// count, so mid-number edits don't jump the cursor.
class CreditCardInputFormatter extends TextInputFormatter {
  CreditCardInputFormatter({this.detector});

  /// Override the network detection (domestic BIN tables — mada, RuPay…).
  /// Null → [CardBrand.detect].
  final CardBrand Function(String digits)? detector;

  static final _nonDigit = RegExp(r'\D');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(_nonDigit, '');
    final brand = (detector ?? CardBrand.detect)(digits);
    if (digits.length > brand.maxLength) {
      digits = digits.substring(0, brand.maxLength);
    }

    final groups = brand.groups;
    final buffer = StringBuffer();
    var index = 0;
    var groupIndex = 0;
    while (index < digits.length) {
      final size = groupIndex < groups.length
          ? groups[groupIndex]
          : groups.last;
      final end = (index + size) > digits.length ? digits.length : index + size;
      if (index > 0) buffer.write(' ');
      buffer.write(digits.substring(index, end));
      index = end;
      groupIndex++;
    }
    final formatted = buffer.toString();

    final rawCaret = newValue.selection.baseOffset.clamp(
      0,
      newValue.text.length,
    );
    final digitsBeforeCaret = newValue.text
        .substring(0, rawCaret)
        .replaceAll(_nonDigit, '')
        .length
        .clamp(0, digits.length);

    var caret = formatted.length;
    if (digitsBeforeCaret == 0) {
      caret = 0;
    } else {
      var seen = 0;
      for (var i = 0; i < formatted.length; i++) {
        if (formatted[i] != ' ') {
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
}
