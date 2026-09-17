/// Controls the vibrancy/saturation level of the color palette.
enum ColorSaturation {
  /// Muted — desaturated, easier on the eyes.
  muted,

  /// Normal — default colors as defined.
  normal,

  /// Vibrant — supersaturated, bold and colorful.
  vibrant,
  ;

  String get key => switch (this) {
    ColorSaturation.muted => 'muted',
    ColorSaturation.normal => 'normal',
    ColorSaturation.vibrant => 'vibrant',
  };

  String get label => switch (this) {
    ColorSaturation.muted => 'Muted',
    ColorSaturation.normal => 'Normal',
    ColorSaturation.vibrant => 'Vibrant',
  };

  /// The saturation multiplier applied to base colors.
  double get multiplier => switch (this) {
    ColorSaturation.muted => 0.5,
    ColorSaturation.normal => 1.0,
    ColorSaturation.vibrant => 1.35,
  };
}
