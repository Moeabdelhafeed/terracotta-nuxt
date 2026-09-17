import 'dart:ui' show Color;

import 'package:freezed_annotation/freezed_annotation.dart';

/// Converts between [Color] and JSON string/int representations.
///
/// Supports:
/// - Hex strings: `"#FF5733"`, `"#FFFF5733"`, `"FF5733"`, `"FFFF5733"`
/// - RGB string: `"rgb(255, 87, 51)"`
/// - RGBA string: `"rgba(255, 87, 51, 0.8)"`
/// - Integer: `4294926131` (Color.value)
///
/// Serializes to `"#AARRGGBB"` hex format.
class ColorConverter extends JsonConverter<Color, dynamic> {
  const ColorConverter();

  @override
  Color fromJson(dynamic json) {
    if (json is int) {
      return Color(json);
    }
    if (json is String) {
      return _parseColorString(json);
    }
    throw FormatException('Cannot parse Color from: $json');
  }

  @override
  String toJson(Color object) {
    return '#${object.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  static Color _parseColorString(String value) {
    var s = value.trim();

    // rgb(r, g, b) or rgba(r, g, b, a)
    if (s.startsWith('rgb')) {
      return _parseRgb(s);
    }

    // Hex: strip leading # if present
    if (s.startsWith('#')) {
      s = s.substring(1);
    }

    // 6-char hex (no alpha) → add FF alpha
    if (s.length == 6) {
      s = 'FF$s';
    }

    // 8-char hex (with alpha)
    if (s.length == 8) {
      final value = int.tryParse(s, radix: 16);
      if (value != null) return Color(value);
    }

    // 3-char shorthand (#F53 → #FF5533)
    if (s.length == 3) {
      final r = s[0], g = s[1], b = s[2];
      final expanded = 'FF$r$r$g$g$b$b';
      final value = int.tryParse(expanded, radix: 16);
      if (value != null) return Color(value);
    }

    throw FormatException('Invalid hex color: "$value"');
  }

  static Color _parseRgb(String value) {
    final match = RegExp(
      r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+)\s*)?\)',
    ).firstMatch(value);
    if (match == null) {
      throw FormatException('Invalid rgb/rgba color: "$value"');
    }

    final r = int.parse(match.group(1)!);
    final g = int.parse(match.group(2)!);
    final b = int.parse(match.group(3)!);
    final a = match.group(4) != null
        ? (double.parse(match.group(4)!) * 255).round()
        : 255;

    return Color.fromARGB(a, r, g, b);
  }
}

/// Converts a nullable [Color].
class NullableColorConverter extends JsonConverter<Color?, dynamic> {
  const NullableColorConverter();

  @override
  Color? fromJson(dynamic json) {
    if (json == null) return null;
    return const ColorConverter().fromJson(json);
  }

  @override
  dynamic toJson(Color? object) {
    if (object == null) return null;
    return const ColorConverter().toJson(object);
  }
}
