import 'dart:math' show min;

import 'package:flutter/services.dart';

/// Mask input formatter.
/// `#` = digit, `A` = letter, `*` = any character.
/// Other characters in the mask are literal separators.
class MaskInputFormatter extends TextInputFormatter {
  final String mask;

  MaskInputFormatter(this.mask);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final unmasked = _extractRaw(newValue.text);
    final result = _applyMask(unmasked);

    final rawBeforeCursor = _extractRaw(
      newValue.text.substring(
        0,
        min(newValue.selection.baseOffset, newValue.text.length),
      ),
    ).length;

    var rawSeen = 0;
    var cursorPos = result.length;
    for (var i = 0; i < result.length; i++) {
      if (i < mask.length && _isMaskSlot(mask[i])) {
        rawSeen++;
        if (rawSeen >= rawBeforeCursor) {
          cursorPos = i + 1;
          break;
        }
      }
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(
        offset: cursorPos.clamp(0, result.length),
      ),
    );
  }

  String _extractRaw(String text) {
    final buffer = StringBuffer();
    var maskIdx = 0;
    for (var i = 0; i < text.length; i++) {
      if (maskIdx < mask.length &&
          !_isMaskSlot(mask[maskIdx]) &&
          text[i] == mask[maskIdx]) {
        maskIdx++;
        continue;
      }
      if (maskIdx < mask.length && _isMaskSlot(mask[maskIdx])) {
        if (_charMatchesSlot(text[i], mask[maskIdx])) {
          buffer.write(text[i]);
          maskIdx++;
        }
      } else if (maskIdx < mask.length) {
        if (_charMatchesAnySlot(text[i])) {
          buffer.write(text[i]);
        }
      } else {
        break;
      }
    }
    return buffer.toString();
  }

  String _applyMask(String raw) {
    final buffer = StringBuffer();
    var rawIdx = 0;

    for (var i = 0; i < mask.length && rawIdx < raw.length; i++) {
      if (_isMaskSlot(mask[i])) {
        if (_charMatchesSlot(raw[rawIdx], mask[i])) {
          buffer.write(raw[rawIdx]);
          rawIdx++;
        } else {
          break;
        }
      } else {
        buffer.write(mask[i]);
      }
    }

    return buffer.toString();
  }

  bool _isMaskSlot(String c) => c == '#' || c == 'A' || c == '*';

  bool _charMatchesSlot(String c, String slot) {
    switch (slot) {
      case '#':
        return RegExp(r'\d').hasMatch(c);
      case 'A':
        return RegExp(r'[a-zA-Z]').hasMatch(c);
      case '*':
        return true;
      default:
        return false;
    }
  }

  bool _charMatchesAnySlot(String c) {
    return RegExp(r'[\da-zA-Z]').hasMatch(c);
  }
}
