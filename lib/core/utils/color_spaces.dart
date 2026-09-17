import 'dart:math' as math;

import 'package:flutter/painting.dart' show Color;

/// Pure color-space conversions used by the extended color formats
/// (HWB / CMYK / LAB / LCH / OKLAB / OKLCH). sRGB, D65. All channel doubles
/// are in the natural range of their space; RGB is clamped 0–255 on the way
/// back (out-of-gamut spaces get clipped).
abstract final class ColorSpaces {
  // ── sRGB channel helpers (0–1) ──────────────────────────────────────
  static (double, double, double) _rgb01(Color c) {
    final argb = c.toARGB32();
    return (
      ((argb >> 16) & 0xFF) / 255,
      ((argb >> 8) & 0xFF) / 255,
      (argb & 0xFF) / 255,
    );
  }

  static Color _color01(double r, double g, double b, [double a = 1]) =>
      Color.fromARGB(
        (a.clamp(0.0, 1.0) * 255).round(),
        (r.clamp(0.0, 1.0) * 255).round(),
        (g.clamp(0.0, 1.0) * 255).round(),
        (b.clamp(0.0, 1.0) * 255).round(),
      );

  static double _lin(double c) =>
      c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  static double _gam(double c) => c <= 0.0031308
      ? c * 12.92
      : 1.055 * math.pow(c, 1 / 2.4).toDouble() - 0.055;
  static double _cbrt(double x) =>
      x < 0 ? -math.pow(-x, 1 / 3).toDouble() : math.pow(x, 1 / 3).toDouble();

  // ── HWB (hue, whiteness, blackness) — 0–360, 0–1, 0–1 ───────────────
  static (double h, double w, double b) rgbToHwb(Color c) {
    final (r, g, b) = _rgb01(c);
    final max = [r, g, b].reduce(math.max);
    final min = [r, g, b].reduce(math.min);
    return (_hue(r, g, b, max, min), min, 1 - max);
  }

  static Color hwbToColor(double h, double w, double bl) {
    var white = w, black = bl;
    if (white + black > 1) {
      final s = white + black;
      white /= s;
      black /= s;
    }
    final v = 1 - black;
    final sat = v == 0 ? 0.0 : 1 - white / v;
    return _hsvToColor(h, sat, v);
  }

  // ── CMYK — each 0–1 ─────────────────────────────────────────────────
  static (double c, double m, double y, double k) rgbToCmyk(Color color) {
    final (r, g, b) = _rgb01(color);
    final k = 1 - [r, g, b].reduce(math.max);
    if (k >= 1) return (0, 0, 0, 1);
    return (
      (1 - r - k) / (1 - k),
      (1 - g - k) / (1 - k),
      (1 - b - k) / (1 - k),
      k,
    );
  }

  static Color cmykToColor(double c, double m, double y, double k) =>
      _color01((1 - c) * (1 - k), (1 - m) * (1 - k), (1 - y) * (1 - k));

  // ── CIE LAB (L 0–100, a/b ~ ±128) + LCH ─────────────────────────────
  static const _xn = 0.95047, _yn = 1.0, _zn = 1.08883;

  static (double x, double y, double z) _rgbToXyz(Color color) {
    final (sr, sg, sb) = _rgb01(color);
    final r = _lin(sr), g = _lin(sg), b = _lin(sb);
    return (
      0.4124564 * r + 0.3575761 * g + 0.1804375 * b,
      0.2126729 * r + 0.7151522 * g + 0.0721750 * b,
      0.0193339 * r + 0.1191920 * g + 0.9503041 * b,
    );
  }

  static Color _xyzToColor(double x, double y, double z) {
    final r = 3.2404542 * x - 1.5371385 * y - 0.4985314 * z;
    final g = -0.9692660 * x + 1.8760108 * y + 0.0415560 * z;
    final b = 0.0556434 * x - 0.2040259 * y + 1.0572252 * z;
    return _color01(_gam(r), _gam(g), _gam(b));
  }

  static double _labF(double t) =>
      t > 0.008856 ? _cbrt(t) : 7.787 * t + 16 / 116;
  static double _labFinv(double t) {
    final t3 = t * t * t;
    return t3 > 0.008856 ? t3 : (t - 16 / 116) / 7.787;
  }

  static (double l, double a, double b) rgbToLab(Color color) {
    final (x, y, z) = _rgbToXyz(color);
    final fx = _labF(x / _xn), fy = _labF(y / _yn), fz = _labF(z / _zn);
    return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz));
  }

  static Color labToColor(double l, double a, double b) {
    final fy = (l + 16) / 116, fx = fy + a / 500, fz = fy - b / 200;
    return _xyzToColor(
      _xn * _labFinv(fx),
      _yn * _labFinv(fy),
      _zn * _labFinv(fz),
    );
  }

  static (double l, double c, double h) rgbToLch(Color color) {
    final (l, a, b) = rgbToLab(color);
    return (l, math.sqrt(a * a + b * b), _deg(math.atan2(b, a)));
  }

  static Color lchToColor(double l, double c, double h) {
    final r = h * math.pi / 180;
    return labToColor(l, c * math.cos(r), c * math.sin(r));
  }

  // ── OKLAB (L 0–1, a/b ~ ±0.4) + OKLCH ───────────────────────────────
  static (double l, double a, double b) rgbToOklab(Color color) {
    final (sr, sg, sb) = _rgb01(color);
    final r = _lin(sr), g = _lin(sg), b = _lin(sb);
    final l = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    final m = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    return (
      0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
      1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
      0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    );
  }

  static Color oklabToColor(double L, double A, double B) {
    final l_ = L + 0.3963377774 * A + 0.2158037573 * B;
    final m_ = L - 0.1055613458 * A - 0.0638541728 * B;
    final s_ = L - 0.0894841775 * A - 1.2914855480 * B;
    final l = l_ * l_ * l_, m = m_ * m_ * m_, s = s_ * s_ * s_;
    final r = 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s;
    final g = -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s;
    final b = -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s;
    return _color01(_gam(r), _gam(g), _gam(b));
  }

  static (double l, double c, double h) rgbToOklch(Color color) {
    final (l, a, b) = rgbToOklab(color);
    return (l, math.sqrt(a * a + b * b), _deg(math.atan2(b, a)));
  }

  static Color oklchToColor(double l, double c, double h) {
    final r = h * math.pi / 180;
    return oklabToColor(l, c * math.cos(r), c * math.sin(r));
  }

  // ── shared ──────────────────────────────────────────────────────────
  static double _hue(double r, double g, double b, double max, double min) {
    if (max == min) return 0;
    final d = max - min;
    double h;
    if (max == r) {
      h = (g - b) / d + (g < b ? 6 : 0);
    } else if (max == g) {
      h = (b - r) / d + 2;
    } else {
      h = (r - g) / d + 4;
    }
    return h * 60;
  }

  static double _deg(double rad) {
    var d = rad * 180 / math.pi;
    return d < 0 ? d + 360 : d;
  }

  static Color _hsvToColor(double h, double s, double v) {
    final c = v * s;
    final x = c * (1 - (((h / 60) % 2) - 1).abs());
    final m = v - c;
    double r = 0, g = 0, b = 0;
    if (h < 60) {
      r = c;
      g = x;
    } else if (h < 120) {
      r = x;
      g = c;
    } else if (h < 180) {
      g = c;
      b = x;
    } else if (h < 240) {
      g = x;
      b = c;
    } else if (h < 300) {
      r = x;
      b = c;
    } else {
      r = c;
      b = x;
    }
    return _color01(r + m, g + m, b + m);
  }
}
