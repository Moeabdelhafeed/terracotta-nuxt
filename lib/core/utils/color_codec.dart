import 'package:flutter/painting.dart' show Color, HSLColor, HSVColor;

import 'color_spaces.dart';
import 'css_colors.dart';

/// The textual formats a color input can round-trip through. The picker at the
/// end of `ColorField` switches between them; [ColorCodec] parses / encodes /
/// validates each.
enum ColorFormat {
  /// `#RRGGBB` — opaque hex.
  hex,

  /// `#RRGGBBAA` — hex with a trailing alpha byte (CSS order).
  hex8,

  /// `rgb(255, 87, 51)` — 0–255 channels.
  rgb,

  /// `rgba(255, 87, 51, 0.5)` — channels + 0–1 alpha.
  rgba,

  /// `hsl(9, 100%, 60%)` — hue 0–360, sat/light 0–100%.
  hsl,

  /// `hsla(9, 100%, 60%, 0.5)` — HSL + 0–1 alpha.
  hsla,

  /// `hsv(9, 80%, 100%)` — hue / saturation / value (a.k.a. HSB).
  hsv,

  /// `hwb(9, 20%, 0%)` — hue / whiteness / blackness (CSS Color 4).
  hwb,

  /// `cmyk(0%, 61%, 68%, 0%)` — print (cyan / magenta / yellow / key).
  cmyk,

  /// `lab(60, 63, 55)` — CIE L*a*b* (L 0–100, a/b ≈ ±128). Not segmentable.
  lab,

  /// `lch(60, 84, 41)` — CIE LCh (L 0–100, C 0–~150, H 0–360). Not segmentable.
  lch,

  /// `oklab(0.7, 0.15, 0.09)` — OKLab (L 0–1, a/b ≈ ±0.4). Not segmentable.
  oklab,

  /// `oklch(0.7, 0.19, 34)` — OKLCh (L 0–1, C 0–~0.4, H 0–360). Not segmentable.
  oklch,

  /// CSS named color (`tomato`, `rebeccapurple`). No channels (not segmentable).
  named;

  /// Short picker label (technical, locale-agnostic).
  String get label => switch (this) {
    ColorFormat.hex => 'HEX',
    ColorFormat.hex8 => 'HEX8',
    ColorFormat.rgb => 'RGB',
    ColorFormat.rgba => 'RGBA',
    ColorFormat.hsl => 'HSL',
    ColorFormat.hsla => 'HSLA',
    ColorFormat.hsv => 'HSV',
    ColorFormat.hwb => 'HWB',
    ColorFormat.cmyk => 'CMYK',
    ColorFormat.lab => 'LAB',
    ColorFormat.lch => 'LCH',
    ColorFormat.oklab => 'OKLAB',
    ColorFormat.oklch => 'OKLCH',
    ColorFormat.named => 'NAME',
  };

  /// Placeholder shown when the field is empty.
  String get hint => switch (this) {
    ColorFormat.hex => '#FF5733',
    ColorFormat.hex8 => '#FF5733FF',
    ColorFormat.rgb => 'rgb(255, 87, 51)',
    ColorFormat.rgba => 'rgba(255, 87, 51, 0.5)',
    ColorFormat.hsl => 'hsl(9, 100%, 60%)',
    ColorFormat.hsla => 'hsla(9, 100%, 60%, 0.5)',
    ColorFormat.hsv => 'hsv(9, 80%, 100%)',
    ColorFormat.hwb => 'hwb(9, 20%, 0%)',
    ColorFormat.cmyk => 'cmyk(0%, 66%, 80%, 0%)',
    ColorFormat.lab => 'lab(60, 63, 55)',
    ColorFormat.lch => 'lch(60, 84, 41)',
    ColorFormat.oklab => 'oklab(0.7, 0.15, 0.09)',
    ColorFormat.oklch => 'oklch(0.7, 0.19, 34)',
    ColorFormat.named => 'tomato',
  };

  /// Whether the format carries an alpha channel.
  bool get hasAlpha =>
      this == ColorFormat.hex8 ||
      this == ColorFormat.rgba ||
      this == ColorFormat.hsla;

  bool get _isHex => this == ColorFormat.hex || this == ColorFormat.hex8;

  /// One entry per editable channel — drives the SEGMENTED color field (a
  /// small box per channel, joined). Order matches [ColorCodec.channelsOf] /
  /// [ColorCodec.colorFromChannels].
  List<ColorChannel> get channels => switch (this) {
    ColorFormat.hex => const [
      ColorChannel('R', maxLen: 2, isHex: true),
      ColorChannel('G', maxLen: 2, isHex: true),
      ColorChannel('B', maxLen: 2, isHex: true),
    ],
    ColorFormat.hex8 => const [
      ColorChannel('R', maxLen: 2, isHex: true),
      ColorChannel('G', maxLen: 2, isHex: true),
      ColorChannel('B', maxLen: 2, isHex: true),
      ColorChannel('A', maxLen: 2, isHex: true),
    ],
    ColorFormat.rgb => const [
      ColorChannel('R', maxLen: 3, isHex: false),
      ColorChannel('G', maxLen: 3, isHex: false),
      ColorChannel('B', maxLen: 3, isHex: false),
    ],
    ColorFormat.rgba => const [
      ColorChannel('R', maxLen: 3, isHex: false),
      ColorChannel('G', maxLen: 3, isHex: false),
      ColorChannel('B', maxLen: 3, isHex: false),
      ColorChannel('A', maxLen: 4, isHex: false),
    ],
    ColorFormat.hsl => const [
      ColorChannel('H', maxLen: 3, isHex: false),
      ColorChannel('S', maxLen: 3, isHex: false),
      ColorChannel('L', maxLen: 3, isHex: false),
    ],
    ColorFormat.hsla => const [
      ColorChannel('H', maxLen: 3, isHex: false),
      ColorChannel('S', maxLen: 3, isHex: false),
      ColorChannel('L', maxLen: 3, isHex: false),
      ColorChannel('A', maxLen: 4, isHex: false),
    ],
    ColorFormat.hsv => const [
      ColorChannel('H', maxLen: 3, isHex: false),
      ColorChannel('S', maxLen: 3, isHex: false),
      ColorChannel('V', maxLen: 3, isHex: false),
    ],
    ColorFormat.hwb => const [
      ColorChannel('H', maxLen: 3, isHex: false),
      ColorChannel('W', maxLen: 3, isHex: false),
      ColorChannel('B', maxLen: 3, isHex: false),
    ],
    ColorFormat.cmyk => const [
      ColorChannel('C', maxLen: 3, isHex: false),
      ColorChannel('M', maxLen: 3, isHex: false),
      ColorChannel('Y', maxLen: 3, isHex: false),
      ColorChannel('K', maxLen: 3, isHex: false),
    ],
    // Perceptual spaces carry negative / decimal channels — single-line
    // only, not segmented.
    ColorFormat.lab ||
    ColorFormat.lch ||
    ColorFormat.oklab ||
    ColorFormat.oklch ||
    ColorFormat.named => const [],
  };
}

/// One editable channel of a color (`R` / `H` / `A` …) for the segmented
/// field: its label (hint), max input length, and whether it's hex.
class ColorChannel {
  const ColorChannel(this.label, {required this.maxLen, required this.isHex});

  final String label;
  final int maxLen;
  final bool isHex;
}

/// Pure parse / encode / validate for every [ColorFormat]. No Flutter widgets
/// — unit-testable in isolation.
abstract final class ColorCodec {
  static final _numbers = RegExp(r'-?\d*\.?\d+');
  static final _hexChars = RegExp(r'^[0-9a-fA-F]+$');

  /// Parse [text] STRICTLY as [format]; null when it doesn't match / is out of
  /// range. Tolerant of a missing `#` (hex), hex shorthand (`#F53`), a missing
  /// `rgb(...)` wrapper, space or comma separators, and `%` channels.
  static Color? parse(String text, ColorFormat format) {
    final t = text.trim();
    if (t.isEmpty) return null;
    if (format == ColorFormat.named) return CssColors.byName(t);
    if (format._isHex) return _parseHex(t, format == ColorFormat.hex8);
    final nums = _numbers
        .allMatches(t)
        .map((m) => double.tryParse(m.group(0)!))
        .toList();
    if (nums.contains(null)) return null;
    final v = nums.cast<double>();
    // r/g/b are percentages only when EACH channel has a `%` (≥3) — a lone
    // `%` belongs to a `/ 50%` alpha, not the channels.
    final percent = '%'.allMatches(t).length >= 3;
    final hasPercent = t.contains('%');
    return switch (format) {
      ColorFormat.rgb => _rgb(v, alpha: false, percent: percent),
      ColorFormat.rgba => _rgb(
        v,
        alpha: true,
        percent: percent,
        alphaPercent: hasPercent,
      ),
      ColorFormat.hsl => _hsl(v, alpha: false),
      ColorFormat.hsla => _hsl(v, alpha: true),
      ColorFormat.hsv => _hsv(v),
      ColorFormat.hwb => _hwb(v),
      ColorFormat.cmyk => _cmyk(v),
      ColorFormat.lab => _lab(v),
      ColorFormat.lch => _lch(v),
      ColorFormat.oklab => _oklab(v),
      ColorFormat.oklch => _oklch(v),
      _ => null,
    };
  }

  /// Build a color from the per-channel strings of [format] (the segmented
  /// field's boxes). Null when a channel is empty or the assembled value is
  /// out of range — reuses [parse] so range checks stay in one place.
  static Color? colorFromChannels(ColorFormat format, List<String> values) {
    final channels = format.channels;
    if (channels.isEmpty) return null; // named — not segmentable
    if (values.length != channels.length) return null;
    if (values.any((v) => v.trim().isEmpty)) return null;
    // Hex channels must be FULL 2-char pairs (don't let 'F','5','3' collapse
    // into the #F53 shorthand — that's incomplete segment entry).
    if ((format == ColorFormat.hex || format == ColorFormat.hex8) &&
        values.any((v) => v.trim().length != 2)) {
      return null;
    }
    final assembled = switch (format) {
      ColorFormat.hex || ColorFormat.hex8 => '#${values.join()}',
      ColorFormat.rgb => 'rgb(${values.join(',')})',
      ColorFormat.rgba => 'rgba(${values.join(',')})',
      ColorFormat.hsl => 'hsl(${values[0]}, ${values[1]}%, ${values[2]}%)',
      ColorFormat.hsla =>
        'hsla(${values[0]}, ${values[1]}%, ${values[2]}%, ${values[3]})',
      ColorFormat.hsv => 'hsv(${values[0]}, ${values[1]}%, ${values[2]}%)',
      ColorFormat.hwb => 'hwb(${values[0]}, ${values[1]}%, ${values[2]}%)',
      ColorFormat.cmyk =>
        'cmyk(${values[0]}%, ${values[1]}%, ${values[2]}%, ${values[3]}%)',
      // Not segmentable — never reached (channels empty → early return above).
      ColorFormat.lab ||
      ColorFormat.lch ||
      ColorFormat.oklab ||
      ColorFormat.oklch ||
      ColorFormat.named => '',
    };
    return parse(assembled, format);
  }

  /// Decompose [color] into the per-channel strings for [format] (fills the
  /// segmented field's boxes). Inverse of [colorFromChannels].
  static List<String> channelsOf(ColorFormat format, Color color) {
    final argb = color.toARGB32();
    final a = (argb >> 24) & 0xFF;
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    String hh(int v) => v.toRadixString(16).toUpperCase().padLeft(2, '0');
    switch (format) {
      case ColorFormat.hex:
        return [hh(r), hh(g), hh(b)];
      case ColorFormat.hex8:
        return [hh(r), hh(g), hh(b), hh(a)];
      case ColorFormat.rgb:
        return ['$r', '$g', '$b'];
      case ColorFormat.rgba:
        return ['$r', '$g', '$b', _alpha(a / 255)];
      case ColorFormat.hsl:
        final h = HSLColor.fromColor(color);
        return [
          '${h.hue.round()}',
          '${(h.saturation * 100).round()}',
          '${(h.lightness * 100).round()}',
        ];
      case ColorFormat.hsla:
        final h = HSLColor.fromColor(color);
        return [
          '${h.hue.round()}',
          '${(h.saturation * 100).round()}',
          '${(h.lightness * 100).round()}',
          _alpha(a / 255),
        ];
      case ColorFormat.hsv:
        final h = HSVColor.fromColor(color);
        return [
          '${h.hue.round()}',
          '${(h.saturation * 100).round()}',
          '${(h.value * 100).round()}',
        ];
      case ColorFormat.hwb:
        final (h, w, bl) = ColorSpaces.rgbToHwb(color);
        return [
          '${h.round()}',
          '${(w * 100).round()}',
          '${(bl * 100).round()}',
        ];
      case ColorFormat.cmyk:
        final (c, m, y, k) = ColorSpaces.rgbToCmyk(color);
        return [
          '${(c * 100).round()}',
          '${(m * 100).round()}',
          '${(y * 100).round()}',
          '${(k * 100).round()}',
        ];
      case ColorFormat.lab:
      case ColorFormat.lch:
      case ColorFormat.oklab:
      case ColorFormat.oklch:
      case ColorFormat.named:
        return const [];
    }
  }

  /// Best-effort parse across ALL formats — used by the live swatch, which
  /// should light up for whatever the user typed regardless of the picker.
  /// The format whose function name the text starts with (`lab(` → lab) is
  /// tried FIRST, so `lab(...)` isn't mis-read as `rgb(...)` (both are just
  /// three numbers to the fallback scan).
  static Color? parseAny(String text) {
    final hinted = _prefixFormat(text.trim());
    if (hinted != null) {
      final c = parse(text, hinted);
      if (c != null) return c;
    }
    for (final f in ColorFormat.values) {
      final c = parse(text, f);
      if (c != null) return c;
    }
    return null;
  }

  /// The format implied by the text's leading token (`#` / `rgb(` / `lab(` …),
  /// or null when there's no recognizable prefix.
  static ColorFormat? _prefixFormat(String t) {
    if (t.startsWith('#')) {
      return t.length > 7 ? ColorFormat.hex8 : ColorFormat.hex;
    }
    final name = RegExp(r'^([a-z]+)\(').firstMatch(t.toLowerCase())?.group(1);
    return switch (name) {
      'rgb' => ColorFormat.rgb,
      'rgba' => ColorFormat.rgba,
      'hsl' => ColorFormat.hsl,
      'hsla' => ColorFormat.hsla,
      'hsv' || 'hsb' => ColorFormat.hsv,
      'hwb' => ColorFormat.hwb,
      'cmyk' => ColorFormat.cmyk,
      'lab' => ColorFormat.lab,
      'lch' => ColorFormat.lch,
      'oklab' => ColorFormat.oklab,
      'oklch' => ColorFormat.oklch,
      _ => null,
    };
  }

  /// True when [text] is a valid [format] color.
  static bool isValid(String text, ColorFormat format) =>
      parse(text, format) != null;

  /// Render [color] as [format] text (the canonical form for that format).
  static String encode(Color color, ColorFormat format) {
    final argb = color.toARGB32();
    final a = (argb >> 24) & 0xFF;
    final r = (argb >> 16) & 0xFF;
    final g = (argb >> 8) & 0xFF;
    final b = argb & 0xFF;
    String hh(int v) => v.toRadixString(16).toUpperCase().padLeft(2, '0');
    switch (format) {
      case ColorFormat.hex:
        return '#${hh(r)}${hh(g)}${hh(b)}';
      case ColorFormat.hex8:
        return '#${hh(r)}${hh(g)}${hh(b)}${hh(a)}';
      case ColorFormat.rgb:
        return 'rgb($r, $g, $b)';
      case ColorFormat.rgba:
        return 'rgba($r, $g, $b, ${_alpha(a / 255)})';
      case ColorFormat.hsl:
        final h = HSLColor.fromColor(color);
        return 'hsl(${h.hue.round()}, ${(h.saturation * 100).round()}%, '
            '${(h.lightness * 100).round()}%)';
      case ColorFormat.hsla:
        final h = HSLColor.fromColor(color);
        return 'hsla(${h.hue.round()}, ${(h.saturation * 100).round()}%, '
            '${(h.lightness * 100).round()}%, ${_alpha(a / 255)})';
      case ColorFormat.hsv:
        final h = HSVColor.fromColor(color);
        return 'hsv(${h.hue.round()}, ${(h.saturation * 100).round()}%, '
            '${(h.value * 100).round()}%)';
      case ColorFormat.hwb:
        final (h, w, bl) = ColorSpaces.rgbToHwb(color);
        return 'hwb(${h.round()}, ${(w * 100).round()}%, ${(bl * 100).round()}%)';
      case ColorFormat.cmyk:
        final (c, m, y, k) = ColorSpaces.rgbToCmyk(color);
        return 'cmyk(${(c * 100).round()}%, ${(m * 100).round()}%, '
            '${(y * 100).round()}%, ${(k * 100).round()}%)';
      case ColorFormat.lab:
        final (l, aa, bb) = ColorSpaces.rgbToLab(color);
        return 'lab(${l.round()}, ${aa.round()}, ${bb.round()})';
      case ColorFormat.lch:
        final (l, c, h) = ColorSpaces.rgbToLch(color);
        return 'lch(${l.round()}, ${c.round()}, ${h.round()})';
      case ColorFormat.oklab:
        final (l, aa, bb) = ColorSpaces.rgbToOklab(color);
        return 'oklab(${_dec(l)}, ${_dec(aa)}, ${_dec(bb)})';
      case ColorFormat.oklch:
        final (l, c, h) = ColorSpaces.rgbToOklch(color);
        return 'oklch(${_dec(l)}, ${_dec(c)}, ${h.round()})';
      case ColorFormat.named:
        return CssColors.exactName(color) ?? CssColors.nearestName(color);
    }
  }

  /// Short 3-decimal string, trailing zeros trimmed (for OKLab/OKLCh).
  static String _dec(double v) {
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }

  // ── internals ──────────────────────────────────────────────────────
  static Color? _parseHex(String text, bool withAlpha) {
    var hex = text.startsWith('#') ? text.substring(1) : text;
    if (!_hexChars.hasMatch(hex)) return null;
    // Shorthand: #RGB → #RRGGBB, #RGBA → #RRGGBBAA (double each nibble).
    if (hex.length == (withAlpha ? 4 : 3)) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    final want = withAlpha ? 8 : 6;
    if (hex.length != want) return null;
    if (!withAlpha) return Color(0xFF000000 | int.parse(hex, radix: 16));
    // CSS #RRGGBBAA → ARGB.
    final rgba = int.parse(hex, radix: 16);
    final rgb = rgba >> 8;
    final alpha = rgba & 0xFF;
    return Color((alpha << 24) | rgb);
  }

  static Color? _rgb(
    List<double> v, {
    required bool alpha,
    bool percent = false,
    bool alphaPercent = false,
  }) {
    if (v.length != (alpha ? 4 : 3)) return null;
    var r = v[0], g = v[1], b = v[2];
    if (percent) {
      if (![r, g, b].every((c) => c >= 0 && c <= 100)) return null;
      r *= 2.55;
      g *= 2.55;
      b *= 2.55;
    } else if (![
      r,
      g,
      b,
    ].every((c) => c >= 0 && c <= 255 && c == c.roundToDouble())) {
      return null;
    }
    var a = 1.0;
    if (alpha) {
      a = v[3];
      // `/ 50%` percentage alpha → 0–1 (only when a `%` was actually present).
      if (a > 1 && alphaPercent) a /= 100;
      if (a < 0 || a > 1) return null;
    }
    return Color.fromARGB((a * 255).round(), r.round(), g.round(), b.round());
  }

  static Color? _hsl(List<double> v, {required bool alpha}) {
    if (v.length != (alpha ? 4 : 3)) return null;
    final h = v[0], s = v[1], l = v[2];
    if (h < 0 || h > 360 || s < 0 || s > 100 || l < 0 || l > 100) return null;
    var a = 1.0;
    if (alpha) {
      a = v[3];
      if (a < 0 || a > 1) return null;
    }
    return HSLColor.fromAHSL(a, h % 360, s / 100, l / 100).toColor();
  }

  static Color? _hsv(List<double> v) {
    if (v.length != 3) return null;
    final h = v[0], s = v[1], vv = v[2];
    if (h < 0 || h > 360 || s < 0 || s > 100 || vv < 0 || vv > 100) return null;
    return HSVColor.fromAHSV(1, h % 360, s / 100, vv / 100).toColor();
  }

  static Color? _hwb(List<double> v) {
    if (v.length != 3) return null;
    final h = v[0], w = v[1], b = v[2];
    if (h < 0 || h > 360 || w < 0 || w > 100 || b < 0 || b > 100) return null;
    return ColorSpaces.hwbToColor(h % 360, w / 100, b / 100);
  }

  static Color? _cmyk(List<double> v) {
    if (v.length != 4) return null;
    if (!v.every((c) => c >= 0 && c <= 100)) return null;
    return ColorSpaces.cmykToColor(
      v[0] / 100,
      v[1] / 100,
      v[2] / 100,
      v[3] / 100,
    );
  }

  static Color? _lab(List<double> v) {
    if (v.length != 3) return null;
    final l = v[0];
    if (l < 0 || l > 100 || v[1].abs() > 160 || v[2].abs() > 160) return null;
    return ColorSpaces.labToColor(l, v[1], v[2]);
  }

  static Color? _lch(List<double> v) {
    if (v.length != 3) return null;
    final l = v[0], c = v[1], h = v[2];
    if (l < 0 || l > 100 || c < 0 || c > 260 || h < 0 || h > 360) return null;
    return ColorSpaces.lchToColor(l, c, h % 360);
  }

  static Color? _oklab(List<double> v) {
    if (v.length != 3) return null;
    final l = v[0];
    if (l < 0 || l > 1 || v[1].abs() > 0.6 || v[2].abs() > 0.6) return null;
    return ColorSpaces.oklabToColor(l, v[1], v[2]);
  }

  static Color? _oklch(List<double> v) {
    if (v.length != 3) return null;
    final l = v[0], c = v[1], h = v[2];
    if (l < 0 || l > 1 || c < 0 || c > 0.6 || h < 0 || h > 360) return null;
    return ColorSpaces.oklchToColor(l, c, h % 360);
  }

  /// 0–1 alpha as a trim-zeroed string (`0.5`, `1`, `0.25`).
  static String _alpha(double a) {
    var s = a.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    }
    return s;
  }
}
