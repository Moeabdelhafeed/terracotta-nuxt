import 'package:flutter/material.dart';

import '../enums/app/app_role.dart';

/// Terracotta brand. `primary` is the app chrome — bottom nav, auth CTAs,
/// prices — and never varies. The three WORKSHOP FAMILY hues live in
/// `workshop_family_colors.dart`; they are a property of the booking on
/// screen, not of the signed-in person, so they do not ride AppRole.
///
/// ## The dark brand is chosen so its LABEL works
///
/// `#81341A` is too dark to read on a dark ground, so dark lifts it.
/// How far is settled by the thing sitting on top of it: at `#D65E35`
/// the dark ink cleared 4.88:1 and white only 3.81 — so a filled
/// button had no label that passed either way round. `#E0703F` gives
/// the ink 5.81:1 and reads 5.81:1 as text on the scaffold, which is
/// the same number from both directions and the reason it is this hue
/// and not a darker one.
///
/// `secondary` is lifted for the same reason: `#429179` measured
/// 4.13:1 as text on `container`, under the bar on the one ground it
/// is most often written on.
@immutable
class PrimaryColors {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color primaryHighContrast;
  final Color border;

  /// The CHROME — the floating nav bar's slab, and anything else that
  /// is the app's own furniture rather than a control on a page.
  ///
  /// **It does not move between themes**, which is the one colour in
  /// here that does not. `#81341A` is the identity: CLAUDE.md says the
  /// chrome stays it throughout, and a workshop family re-theming the
  /// booking flow leaves it alone for the same reason.
  ///
  /// Dark cannot use [primary] for this. That value is lifted to read
  /// as TEXT and as a button fill on a dark ground, which makes it a
  /// LIGHT surface — and the design's white nav labels measure 3.2:1
  /// on it. The brown is already dark, so it sits on a dark page as a
  /// slab (21 L\* above the scaffold) and carries the design's own
  /// white at 8.9:1, in both themes, unchanged.
  final Color chrome;

  const PrimaryColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.primaryHighContrast,
    required this.border,
    this.chrome = const Color(0xFF81341A),
  });

  // ─── Fallback ──────────────────────────────────────────────

  static const PrimaryColors fallbackLight = PrimaryColors(
    primary: Color(0xFF81341A),
    secondary: Color(0xFF3A7F6A),
    accent: Color(0xFFE7938D),
    primaryHighContrast: Color(0xFF290802),
    border: Color(0x1A000000),
  );

  static const PrimaryColors fallbackDark = PrimaryColors(
    primary: Color(0xFFDE7D54),
    secondary: Color(0xFF55B998),
    accent: Color(0xFFE7938D),
    primaryHighContrast: Color(0xFFF9F5F2),
    border: Color(0x33FFFFFF),
  );

  // ─── User role ─────────────────────────────────────────────

  static const PrimaryColors userLight = PrimaryColors(
    primary: Color(0xFF81341A),
    secondary: Color(0xFF3A7F6A),
    accent: Color(0xFFE7938D),
    primaryHighContrast: Color(0xFF290802),
    border: Color(0x1A000000),
  );

  static const PrimaryColors userDark = PrimaryColors(
    primary: Color(0xFFDE7D54),
    secondary: Color(0xFF55B998),
    accent: Color(0xFFE7938D),
    primaryHighContrast: Color(0xFFF9F5F2),
    border: Color(0x33FFFFFF),
  );

  // ─── Guest role — Terracotta ships ONE palette (intake Q9), so
  //     guest is the same bag as user. Kept so the resolver stays
  //     total and a future guest skin has somewhere to land.

  static const PrimaryColors guestLight = PrimaryColors(
    primary: Color(0xFF81341A),
    secondary: Color(0xFF3A7F6A),
    accent: Color(0xFFE7938D),
    primaryHighContrast: Color(0xFF290802),
    border: Color(0x1A000000),
  );

  static const PrimaryColors guestDark = PrimaryColors(
    primary: Color(0xFFDE7D54),
    secondary: Color(0xFF55B998),
    accent: Color(0xFFE7938D),
    primaryHighContrast: Color(0xFFF9F5F2),
    border: Color(0x33FFFFFF),
  );

  // ─── Convenience aliases ───────────────────────────────────

  static const PrimaryColors light = userLight;
  static const PrimaryColors dark = userDark;

  // ─── Resolver ──────────────────────────────────────────────

  static PrimaryColors getColors({
    required AppRole appRole,
    required bool isDark,
  }) => switch (appRole) {
    AppRole.guest => isDark ? guestDark : guestLight,
    AppRole.user => isDark ? userDark : userLight,
  };
}
