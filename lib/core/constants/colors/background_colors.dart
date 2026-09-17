import 'package:flutter/material.dart';

import '../enums/app/app_role.dart';

/// Every one of the 83 design frames is opaque white with a 10%-black
/// hairline; there are NO shadows anywhere in the file, so elevation is
/// expressed as `outlineVariant`, not as a drop shadow.
///
/// ## The dark ground is a WARM NEUTRAL, not a brown
///
/// The first dark ramp took the brand's own brown down to near-black —
/// `#150B08`, 62% saturated at L\* 3.8 — and painted `surface`,
/// `container`, `cardBackground` and `inputBackground` the SAME
/// `#241611`. Two things went wrong with that.
///
/// The colour read as **mud**: at that lightness a heavily saturated
/// hue has no room to be a hue, so it arrives as a dirty red-black
/// rather than as terracotta. And with four grounds collapsed into one
/// value, a card, a tile and a text field were indistinguishable — on
/// a design whose only elevation cue is the hairline, that is a flat
/// field with writing on it.
///
/// ## Where this ramp sits, and why it is not near-black
///
/// Hue 22° at 16–20% saturation, stepping 8.3 → 12.5 → 15.4 → 17.4 in
/// L\*. Two deliberate choices in that.
///
/// **The base is not a void.** An earlier pass put the scaffold at
/// L\* 5.8 — all but pure black — on the reasoning that darker is
/// safer. It is not: a near-black base leaves the ladder above it
/// nowhere to go, so the cards had to crowd into eight points of
/// lightness, and everything coloured had to shout to be seen against
/// it. Starting at L\* 8.3 costs nothing and gives the other three
/// grounds room.
///
/// **The warmth is committed to.** At 14% saturation this read as
/// plain dark grey and the studio's own colour never arrived. At
/// 16–20% it is unglazed clay in low light, which is the thing the
/// app is about — and it is still a GROUND: the hue is doing the work
/// at the bottom of the scale, where the eye reads it as temperature
/// rather than as colour.
///
/// **The hairline is the load-bearing one.** `outline` sits 19 L\*
/// above `surface`, where the light theme's own 10%-black rule sits
/// 8.7 L\* below white — so it is nearly twice as legible as the
/// design's, which is the right side to err on when it is carrying the
/// whole structure. It does not reach WCAG's 3:1 for UI graphics, and
/// nor does the light one (1.25:1): a hairline separating two surfaces
/// is judged by eye, and a stroke bright enough to measure 3:1 here
/// reads as a wireframe.
@immutable
class BackgroundColors {
  final Color background;
  final Color surface;
  final Color scaffoldBackground;
  final Color container;
  final Color cardBackground;
  final Color inputBackground;
  final Color outline;
  final Color outlineVariant;

  const BackgroundColors({
    required this.background,
    required this.surface,
    required this.scaffoldBackground,
    required this.container,
    required this.cardBackground,
    required this.inputBackground,
    required this.outline,
    required this.outlineVariant,
  });

  // ─── Fallback ──────────────────────────────────────────────

  static const BackgroundColors fallbackLight = BackgroundColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    scaffoldBackground: Color(0xFFFFFFFF),
    container: Color(0xFFFAF7F6),
    cardBackground: Color(0xFFFFFFFF),
    inputBackground: Color(0xFFFFFFFF),
    outline: Color(0xFFE5E5E5),
    outlineVariant: Color(0x1A000000),
  );

  static const BackgroundColors fallbackDark = BackgroundColors(
    background: Color(0xFF1D1713),
    surface: Color(0xFF271F1B),
    scaffoldBackground: Color(0xFF1D1713),
    container: Color(0xFF322924),
    cardBackground: Color(0xFF271F1B),
    inputBackground: Color(0xFF2D2521),
    outline: Color(0xFF544740),
    outlineVariant: Color(0x24FFFFFF),
  );

  // ─── User role ─────────────────────────────────────────────

  static const BackgroundColors userLight = BackgroundColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    scaffoldBackground: Color(0xFFFFFFFF),
    container: Color(0xFFFAF7F6),
    cardBackground: Color(0xFFFFFFFF),
    inputBackground: Color(0xFFFFFFFF),
    outline: Color(0xFFE5E5E5),
    outlineVariant: Color(0x1A000000),
  );

  static const BackgroundColors userDark = BackgroundColors(
    background: Color(0xFF1D1713),
    surface: Color(0xFF271F1B),
    scaffoldBackground: Color(0xFF1D1713),
    container: Color(0xFF322924),
    cardBackground: Color(0xFF271F1B),
    inputBackground: Color(0xFF2D2521),
    outline: Color(0xFF544740),
    outlineVariant: Color(0x24FFFFFF),
  );

  // ─── Guest role — Terracotta ships ONE palette (intake Q9), so
  //     guest is the same bag as user. Kept so the resolver stays
  //     total and a future guest skin has somewhere to land.

  static const BackgroundColors guestLight = BackgroundColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    scaffoldBackground: Color(0xFFFFFFFF),
    container: Color(0xFFFAF7F6),
    cardBackground: Color(0xFFFFFFFF),
    inputBackground: Color(0xFFFFFFFF),
    outline: Color(0xFFE5E5E5),
    outlineVariant: Color(0x1A000000),
  );

  static const BackgroundColors guestDark = BackgroundColors(
    background: Color(0xFF1D1713),
    surface: Color(0xFF271F1B),
    scaffoldBackground: Color(0xFF1D1713),
    container: Color(0xFF322924),
    cardBackground: Color(0xFF271F1B),
    inputBackground: Color(0xFF2D2521),
    outline: Color(0xFF544740),
    outlineVariant: Color(0x24FFFFFF),
  );

  // ─── Convenience aliases ───────────────────────────────────

  static const BackgroundColors light = userLight;
  static const BackgroundColors dark = userDark;

  // ─── Resolver ──────────────────────────────────────────────

  static BackgroundColors getColors({
    required AppRole appRole,
    required bool isDark,
  }) => switch (appRole) {
    AppRole.guest => isDark ? guestDark : guestLight,
    AppRole.user => isDark ? userDark : userLight,
  };
}
