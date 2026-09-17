import 'package:flutter/material.dart';

import '../enums/app/app_role.dart';

/// The design never draws a DISABLED button. `disabled` reuses the pair it
/// does establish for an elapsed date tile and a full time slot
/// (#EDEDED fill, #9C9C9C label) rather than inventing a new one.
///
/// In dark the disabled fill is the `container` ground, so a dead
/// button is a raised surface with nothing on it rather than a second
/// grey the ramp does not otherwise contain.
@immutable
class ButtonsColors {
  final Color primary;
  final Color secondary;
  final Color disabled;
  final Color outline;

  const ButtonsColors({
    required this.primary,
    required this.secondary,
    required this.disabled,
    required this.outline,
  });

  // ─── Fallback ──────────────────────────────────────────────

  static const ButtonsColors fallbackLight = ButtonsColors(
    primary: Color(0xFF81341A),
    secondary: Color(0xFF3A7F6A),
    disabled: Color(0xFFEDEDED),
    outline: Color(0xFFE5E5E5),
  );

  static const ButtonsColors fallbackDark = ButtonsColors(
    primary: Color(0xFFDE7D54),
    secondary: Color(0xFF55B998),
    disabled: Color(0xFF322924),
    outline: Color(0xFF544740),
  );

  // ─── User role ─────────────────────────────────────────────

  static const ButtonsColors userLight = ButtonsColors(
    primary: Color(0xFF81341A),
    secondary: Color(0xFF3A7F6A),
    disabled: Color(0xFFEDEDED),
    outline: Color(0xFFE5E5E5),
  );

  static const ButtonsColors userDark = ButtonsColors(
    primary: Color(0xFFDE7D54),
    secondary: Color(0xFF55B998),
    disabled: Color(0xFF322924),
    outline: Color(0xFF544740),
  );

  // ─── Guest role — Terracotta ships ONE palette (intake Q9), so
  //     guest is the same bag as user. Kept so the resolver stays
  //     total and a future guest skin has somewhere to land.

  static const ButtonsColors guestLight = ButtonsColors(
    primary: Color(0xFF81341A),
    secondary: Color(0xFF3A7F6A),
    disabled: Color(0xFFEDEDED),
    outline: Color(0xFFE5E5E5),
  );

  static const ButtonsColors guestDark = ButtonsColors(
    primary: Color(0xFFDE7D54),
    secondary: Color(0xFF55B998),
    disabled: Color(0xFF322924),
    outline: Color(0xFF544740),
  );

  // ─── Convenience aliases ───────────────────────────────────

  static const ButtonsColors light = userLight;
  static const ButtonsColors dark = userDark;

  // ─── Resolver ──────────────────────────────────────────────

  static ButtonsColors getColors({
    required AppRole appRole,
    required bool isDark,
  }) => switch (appRole) {
    AppRole.guest => isDark ? guestDark : guestLight,
    AppRole.user => isDark ? userDark : userLight,
  };
}
