/// Static size constants — concerns NOT covered by bucket-aware
/// `AppTokens` (those live in `lib/core/tokens/`).
///
/// Kept here:
/// - **Typography metrics** (font sizes, letter spacing, line height) —
///   pulled directly into theme `TextStyle`s where context isn't
///   available; per-bucket scaling is handled by `AppTypographyScale`.
/// - **Opacity / alpha** levels.
/// - **Border widths**.
/// - **Component-shape constants** that are concept-tied (`buttonRadiusMd`,
///   `inputFieldRadius`, `sheetRadius`, `splashRadius`).
/// - Layout/misc primitives that don't live in the token system
///   (`bottomNavHeight`, `progressBarHeight`, `errorMaxLines`).
///
/// **Do NOT add a generic spacing/radius/icon/elevation scale here.**
/// Those duplicate `context.spacing`, `context.radii`, `context.iconSizes`,
/// and `context.elevation`. Use the tokens.
class AppSizes {
  const AppSizes._();

  // ═══════════════════════════════════════════════════════════
  // COMPONENT-SHAPE RADII
  // ═══════════════════════════════════════════════════════════

  /// Button corner radius — filled, outlined, text AND icon.
  ///
  /// The design's own value, taken from the CTA bar in the `auth` and
  /// onboarding frames. It was 24, a near-pill that made an icon button
  /// a circle and put a very different corner beside the 9pt text
  /// fields it sits among.
  static const double buttonRadiusMd = 11.0;

  /// Input fields, dropdowns, text fields. The design's own value —
  /// see the `auth` frames, where the password box is drawn at 9.
  static const double inputFieldRadius = 9.0;

  /// Bottom-sheet top radius.
  static const double sheetRadius = 20.0;

  /// Splash radius for icon buttons / checkboxes.
  static const double splashRadius = 20.0;

  // ═══════════════════════════════════════════════════════════
  // INPUT FIELD PADDING
  // ═══════════════════════════════════════════════════════════

  static const double inputFieldPaddingHorizontal = 16.0;
  static const double inputFieldPaddingVertical = 16.0;

  // ═══════════════════════════════════════════════════════════
  // BORDER WIDTH
  // ═══════════════════════════════════════════════════════════

  static const double borderWidthThin = 1.0;
  static const double borderWidthMedium = 2.0;

  // ═══════════════════════════════════════════════════════════
  // LAYOUT
  // ═══════════════════════════════════════════════════════════

  static const double bottomNavHeight = 65.0;

  // ═══════════════════════════════════════════════════════════
  // FONT SIZES (raw — `AppTypographyScale.factor` multiplies in theme)
  // ═══════════════════════════════════════════════════════════

  // Display
  static const double fontDisplayLg = 57.0;
  static const double fontDisplayMd = 45.0;
  static const double fontDisplaySm = 36.0;

  // Headline
  static const double fontHeadlineLg = 32.0;
  static const double fontHeadlineMd = 28.0;
  static const double fontHeadlineSm = 24.0;

  // Title
  static const double fontTitleLg = 20.0;
  static const double fontTitleMd = 18.0;
  static const double fontTitleSm = 16.0;

  // Body
  static const double fontBodyLg = 16.0;
  static const double fontBodyMd = 14.0;
  static const double fontBodySm = 12.0;

  // Label
  static const double fontLabelLg = 14.0;
  static const double fontLabelMd = 12.0;
  static const double fontLabelSm = 11.0;

  // ═══════════════════════════════════════════════════════════
  // LETTER SPACING (Material 3 design tokens)
  // ═══════════════════════════════════════════════════════════

  static const double letterSpacingTight = -0.5;
  static const double letterSpacingDense = -0.25;
  static const double letterSpacingSm = 0.1;
  static const double letterSpacingMd = 0.15;
  static const double letterSpacingLg = 0.25;
  static const double letterSpacingXl = 0.4;
  static const double letterSpacingWide = 0.5;
  static const double letterSpacingXWide = 0.75;
  static const double letterSpacingXxWide = 1.0;

  // ═══════════════════════════════════════════════════════════
  // LINE HEIGHT (Material 3 design tokens)
  // ═══════════════════════════════════════════════════════════

  static const double lineHeightTight = 1.1;
  static const double lineHeightDense = 1.15;
  static const double lineHeightCompact = 1.2;
  static const double lineHeightNormal = 1.25;
  static const double lineHeightMd = 1.3;
  static const double lineHeightRelaxed = 1.4;
  static const double lineHeightLoose = 1.5;

  // ═══════════════════════════════════════════════════════════
  // OPACITY / ALPHA
  // ═══════════════════════════════════════════════════════════

  static const double opacitySubtle = 0.04;
  static const double opacityLight = 0.08;
  static const double opacityMuted = 0.1;
  static const double opacityIndicator = 0.15;
  static const double opacityOverlay = 0.2;
  static const double opacityMedium = 0.4;
  static const double opacityHigh = 0.5;
  static const double opacityStrong = 0.85;

  // ═══════════════════════════════════════════════════════════
  // MISC
  // ═══════════════════════════════════════════════════════════

  static const double progressBarHeight = 4.0;
  static const int errorMaxLines = 3;
}
