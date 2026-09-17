import 'package:flutter/material.dart';

import '../enums/app/app_role.dart';

/// `secondary` is DELIBERATELY the same ink as `primary` **in light**
/// (intake Q2): the design draws no second text colour at all —
/// supporting copy is the same hue at a smaller size. Express hierarchy
/// with size and weight, not colour, or the app will drift away from
/// the design.
///
/// **DARK breaks that tie, and has to.** The design is light-only, so
/// there is nothing to be faithful to here; and near-white at 15:1 on
/// every line of a dark screen is glare, not hierarchy — the trick the
/// light theme plays with size and weight stops working when every
/// weight is shouting. `secondary` is therefore dimmed to `#C9C0BA`
/// (9.4:1 on `surface`), which still clears AA comfortably and lets
/// `primary` mean something again.
///
/// NOTE `onPrimary` FLIPS in dark: the brand is lifted to clear contrast on
/// a dark ground, so labels ON it must be dark, not white.
///
/// `disabled` is the ONE value here that is not the design's. The design
/// uses #9C9C9C, but only for an elapsed date tile and a full time slot —
/// it never draws a disabled BUTTON label, so there is nothing to be
/// faithful to. #9C9C9C is 2.75:1 on white and fails the project's own
/// >= 4.5:1 rule (test/buttons/disabled_contrast_test.dart). These warm
/// greys clear it on both the surface and the disabled fill.
@immutable
class TextColors {
  final Color primary;
  final Color secondary;
  final Color disabled;
  final Color onPrimary;
  final Color onAccent;
  final Color link;
  final Color primaryHighContrast;

  const TextColors({
    required this.primary,
    required this.secondary,
    required this.disabled,
    required this.onPrimary,
    required this.onAccent,
    required this.link,
    required this.primaryHighContrast,
  });

  // ─── Fallback ──────────────────────────────────────────────

  static const TextColors fallbackLight = TextColors(
    primary: Color(0xFF290802),
    secondary: Color(0xFF290802),
    disabled: Color(0xFF776862),
    onPrimary: Color(0xFFFFFFFF),
    onAccent: Color(0xFFFFFFFF),
    link: Color(0xFF81341A),
    primaryHighContrast: Color(0xFF290802),
  );

  static const TextColors fallbackDark = TextColors(
    primary: Color(0xFFF3EFEC),
    secondary: Color(0xFFCFC5BF),
    disabled: Color(0xFFA3968F),
    onPrimary: Color(0xFF1D1713),
    onAccent: Color(0xFF1D1713),
    link: Color(0xFFDE7D54),
    primaryHighContrast: Color(0xFFFFFFFF),
  );

  // ─── User role ─────────────────────────────────────────────

  static const TextColors userLight = TextColors(
    primary: Color(0xFF290802),
    secondary: Color(0xFF290802),
    disabled: Color(0xFF776862),
    onPrimary: Color(0xFFFFFFFF),
    onAccent: Color(0xFFFFFFFF),
    link: Color(0xFF81341A),
    primaryHighContrast: Color(0xFF290802),
  );

  static const TextColors userDark = TextColors(
    primary: Color(0xFFF3EFEC),
    secondary: Color(0xFFCFC5BF),
    disabled: Color(0xFFA3968F),
    onPrimary: Color(0xFF1D1713),
    onAccent: Color(0xFF1D1713),
    link: Color(0xFFDE7D54),
    primaryHighContrast: Color(0xFFFFFFFF),
  );

  // ─── Guest role — Terracotta ships ONE palette (intake Q9), so
  //     guest is the same bag as user. Kept so the resolver stays
  //     total and a future guest skin has somewhere to land.

  static const TextColors guestLight = TextColors(
    primary: Color(0xFF290802),
    secondary: Color(0xFF290802),
    disabled: Color(0xFF776862),
    onPrimary: Color(0xFFFFFFFF),
    onAccent: Color(0xFFFFFFFF),
    link: Color(0xFF81341A),
    primaryHighContrast: Color(0xFF290802),
  );

  static const TextColors guestDark = TextColors(
    primary: Color(0xFFF3EFEC),
    secondary: Color(0xFFCFC5BF),
    disabled: Color(0xFFA3968F),
    onPrimary: Color(0xFF1D1713),
    onAccent: Color(0xFF1D1713),
    link: Color(0xFFDE7D54),
    primaryHighContrast: Color(0xFFFFFFFF),
  );

  // ─── Convenience aliases ───────────────────────────────────

  static const TextColors light = userLight;
  static const TextColors dark = userDark;

  // ─── Resolver ──────────────────────────────────────────────

  static TextColors getColors({
    required AppRole appRole,
    required bool isDark,
  }) => switch (appRole) {
    AppRole.guest => isDark ? guestDark : guestLight,
    AppRole.user => isDark ? userDark : userLight,
  };
}
