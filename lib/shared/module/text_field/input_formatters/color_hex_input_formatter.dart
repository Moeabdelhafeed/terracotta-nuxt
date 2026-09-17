import 'package:flutter/services.dart';

/// Hex color — forces a leading `#`, uppercases, clamps to [digits] hex
/// characters (`6` → `#RRGGBB`, `8` → `#RRGGBBAA`).
class ColorHexInputFormatter extends TextInputFormatter {
  const ColorHexInputFormatter({this.digits = 6});

  /// Hex characters kept after the `#` (6 opaque, 8 with a trailing alpha).
  final int digits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.toUpperCase();

    if (text.isNotEmpty && !text.startsWith('#')) {
      text = '#$text';
    }

    if (text.length > 1) {
      final hex = text.substring(1).replaceAll(RegExp(r'[^0-9A-F]'), '');
      text = '#${hex.length > digits ? hex.substring(0, digits) : hex}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
