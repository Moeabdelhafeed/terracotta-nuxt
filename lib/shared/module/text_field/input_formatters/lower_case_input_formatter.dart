import 'package:flutter/services.dart';

/// Lower-cases everything as it's typed or pasted. Length is unchanged, so
/// the selection/composing ranges stay valid.
///
/// Used by e.g. `EmailField(lowercaseInput: true)` for case-normalized
/// identifiers (emails, usernames, handles).
class LowerCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}
