import 'package:flutter/material.dart';

import '../enums/app/app_role.dart';

/// Icons ship as SVG (27 glyphs from 20 different Iconify collections —
/// no single icon font can serve this design). The 23 monochrome ones
/// tint from here; the 4 brand marks must never be tinted.
@immutable
class IconColors {
  final Color primary;
  final Color secondary;
  final Color onPrimary;

  const IconColors({
    required this.primary,
    required this.secondary,
    required this.onPrimary,
  });

  // ─── Fallback ──────────────────────────────────────────────

  static const IconColors fallbackLight = IconColors(
    primary: Color(0xFF290802),
    secondary: Color(0xFF81341A),
    onPrimary: Color(0xFFFFFFFF),
  );

  static const IconColors fallbackDark = IconColors(
    primary: Color(0xFFF3EFEC),
    secondary: Color(0xFFDE7D54),
    onPrimary: Color(0xFF1D1713),
  );

  // ─── User role ─────────────────────────────────────────────

  static const IconColors userLight = IconColors(
    primary: Color(0xFF290802),
    secondary: Color(0xFF81341A),
    onPrimary: Color(0xFFFFFFFF),
  );

  static const IconColors userDark = IconColors(
    primary: Color(0xFFF3EFEC),
    secondary: Color(0xFFDE7D54),
    onPrimary: Color(0xFF1D1713),
  );

  // ─── Guest role — Terracotta ships ONE palette (intake Q9), so
  //     guest is the same bag as user. Kept so the resolver stays
  //     total and a future guest skin has somewhere to land.

  static const IconColors guestLight = IconColors(
    primary: Color(0xFF290802),
    secondary: Color(0xFF81341A),
    onPrimary: Color(0xFFFFFFFF),
  );

  static const IconColors guestDark = IconColors(
    primary: Color(0xFFF3EFEC),
    secondary: Color(0xFFDE7D54),
    onPrimary: Color(0xFF1D1713),
  );

  // ─── Convenience aliases ───────────────────────────────────

  static const IconColors light = userLight;
  static const IconColors dark = userDark;

  // ─── Resolver ──────────────────────────────────────────────

  static IconColors getColors({
    required AppRole appRole,
    required bool isDark,
  }) => switch (appRole) {
    AppRole.guest => isDark ? guestDark : guestLight,
    AppRole.user => isDark ? userDark : userLight,
  };
}
