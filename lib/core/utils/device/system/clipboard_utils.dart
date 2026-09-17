import 'package:flutter/services.dart';

import '../device_services.dart';

/// Clipboard read/write operations.
class ClipboardUtils {
  ClipboardUtils._();

  /// Copy text to the clipboard. False if the platform refused —
  /// which callers showing a "Copied" toast want to know about.
  static Future<bool> copy(String text) => deviceGuard(
    'clipboard.copy',
    () async {
      await Clipboard.setData(ClipboardData(text: text));
      return true;
    },
    fallback: false,
  );

  /// Read text from the clipboard. Returns null if empty or unavailable.
  static Future<String?> paste() => deviceGuard(
    'clipboard.paste',
    () async => (await Clipboard.getData(Clipboard.kTextPlain))?.text,
    fallback: null,
  );

  /// True if the clipboard currently has text.
  static Future<bool> hasText() =>
      deviceGuard('clipboard.hasText', Clipboard.hasStrings, fallback: false);

  /// Clear the clipboard (sets an empty string).
  static Future<bool> clear() => copy('');
}
