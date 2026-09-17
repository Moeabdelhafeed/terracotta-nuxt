import 'dart:ui';

import 'strings/color_strings.dart';

/// A readable name for a colour the API sent as a bare hex string.
///
/// **The name is DERIVED, not received.** `GET /api/shop/products/{id}`
/// answers `colors: ["#c96f4a", "#345a4a", "#2b2b2b"]` — a flat list of
/// strings with no id, no label and no per-colour anything. There is no
/// name on the wire to print, so the nearest of a small reference set is
/// named instead.
///
/// Nearest by straight RGB distance, which is not perceptually uniform
/// and does not need to be: the set is coarse (sixteen entries a person
/// would actually say out loud), the swatch is on screen beside the
/// word, and the word is a label rather than a specification. If the CMS
/// ever grows real colour names, delete this and print them.
class ColorName {
  ColorName._();

  /// The reference set. Ordinary words, not paint-chart poetry — the
  /// point is that a customer recognises the answer.
  static final List<(int rgb, String Function() name)> _reference = [
    (0x000000, () => ColorStrings.black),
    (0x2B2B2B, () => ColorStrings.black),
    (0xFFFFFF, () => ColorStrings.white),
    (0x9E9E9E, () => ColorStrings.grey),
    (0xE8DCC8, () => ColorStrings.beige),
    (0x6D4C36, () => ColorStrings.brown),
    (0xC96F4A, () => ColorStrings.terracotta),
    (0xFF8C1A, () => ColorStrings.orange),
    (0xD32F2F, () => ColorStrings.red),
    (0xE9738D, () => ColorStrings.pink),
    (0x7B3FA0, () => ColorStrings.purple),
    (0x1F3057, () => ColorStrings.navy),
    (0x2F6FD0, () => ColorStrings.blue),
    (0x2E8B8B, () => ColorStrings.teal),
    (0x2E7D32, () => ColorStrings.green),
    (0x345A4A, () => ColorStrings.olive),
    (0xE3C441, () => ColorStrings.yellow),
  ];

  /// `"#c96f4a"` → an opaque colour, or null when the string is not one.
  ///
  /// Six digits, no alpha — the wire never sends one, so the alpha byte
  /// is supplied here.
  static Color? parse(String hex) {
    final digits = hex.trim().replaceFirst('#', '');
    if (digits.length != 6) return null;
    final value = int.tryParse(digits, radix: 16);
    return value == null ? null : Color(value | 0xFF000000);
  }

  /// The nearest reference name to [hex], or null when it is not a
  /// colour at all.
  static String? of(String hex) {
    final color = parse(hex);
    return color == null ? null : nameOf(color);
  }

  /// The nearest reference name to [color].
  static String nameOf(Color color) {
    final r = (color.r * 255).round();
    final g = (color.g * 255).round();
    final b = (color.b * 255).round();

    var best = _reference.first;
    var bestDistance = 1 << 30;
    for (final entry in _reference) {
      final dr = ((entry.$1 >> 16) & 0xFF) - r;
      final dg = ((entry.$1 >> 8) & 0xFF) - g;
      final db = (entry.$1 & 0xFF) - b;
      final distance = dr * dr + dg * dg + db * db;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = entry;
      }
    }
    return best.$2();
  }
}
