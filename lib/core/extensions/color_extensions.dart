import 'package:flutter/painting.dart' show Color, HSLColor;

/// Colors with saturation below this threshold are treated as neutral and
/// skipped by [ColorSaturationX] — tinting greys introduces unwanted
/// color casts.
const double _kNeutralSaturationThreshold = 0.03;

/// Saturation adjustments on [Color] — used by the theme system to apply
/// a user-configurable saturation preference across palette colors.
extension ColorSaturationX on Color {
  /// Scales the saturation of this color by [multiplier].
  ///
  /// - `multiplier < 1.0` → desaturates (muted)
  /// - `multiplier == 1.0` → no change
  /// - `multiplier > 1.0` → supersaturates (vibrant, capped at 1.0)
  ///
  /// Near-neutral colors (saturation < 3%) are returned unchanged so
  /// greys stay grey.
  Color scaleSaturation(double multiplier) {
    if (multiplier == 1.0) return this;
    final hsl = HSLColor.fromColor(this);
    if (hsl.saturation < _kNeutralSaturationThreshold) return this;
    final newSaturation = (hsl.saturation * multiplier).clamp(0.0, 1.0);
    return hsl.withSaturation(newSaturation).toColor().withValues(alpha: a);
  }

  /// Sets the saturation of this color to an **absolute** [saturation]
  /// value in `[0, 1]`. Use this when you want "force 40% saturation"
  /// rather than "scale the current saturation"; for scaling see
  /// [scaleSaturation].
  ///
  /// Near-neutral colors are still left alone — an absolute saturation on
  /// a grey would invent a hue that doesn't exist.
  Color withSaturation(double saturation) {
    final hsl = HSLColor.fromColor(this);
    if (hsl.saturation < _kNeutralSaturationThreshold) return this;
    return hsl
        .withSaturation(saturation.clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: a);
  }
}
