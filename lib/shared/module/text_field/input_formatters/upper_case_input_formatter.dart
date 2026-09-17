import 'package:flutter/services.dart';

/// Upper-cases everything as it's typed or pasted. Length is unchanged, so
/// the selection/composing ranges stay valid.
///
/// Used by e.g. `PassportNumberField` (ICAO 9303 documents are canonical
/// in uppercase) and other code-style identifiers (SWIFT, promo codes).
class UpperCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
