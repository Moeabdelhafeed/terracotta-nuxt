import 'package:flutter/material.dart';

import '../enums/app/app_role.dart';

/// Bottom sheets and dialogs sit on a 20%-black scrim in the design; the
/// dim used behind a fullscreen overlay is 30%.
@immutable
class OverlayColors {
  final Color barrier;
  final Color scrim;
  final Color modalBackground;

  const OverlayColors({
    required this.barrier,
    required this.scrim,
    required this.modalBackground,
  });

  // ─── Fallback ──────────────────────────────────────────────

  static const OverlayColors fallbackLight = OverlayColors(
    barrier: Color(0x33000000),
    scrim: Color(0x33000000),
    modalBackground: Color(0xFFFFFFFF),
  );

  static const OverlayColors fallbackDark = OverlayColors(
    barrier: Color(0xB3000000),
    scrim: Color(0xB3000000),
    modalBackground: Color(0xFF271F1B),
  );

  // ─── User role ─────────────────────────────────────────────

  static const OverlayColors userLight = OverlayColors(
    barrier: Color(0x33000000),
    scrim: Color(0x33000000),
    modalBackground: Color(0xFFFFFFFF),
  );

  static const OverlayColors userDark = OverlayColors(
    barrier: Color(0xB3000000),
    scrim: Color(0xB3000000),
    modalBackground: Color(0xFF271F1B),
  );

  // ─── Guest role — Terracotta ships ONE palette (intake Q9), so
  //     guest is the same bag as user. Kept so the resolver stays
  //     total and a future guest skin has somewhere to land.

  static const OverlayColors guestLight = OverlayColors(
    barrier: Color(0x33000000),
    scrim: Color(0x33000000),
    modalBackground: Color(0xFFFFFFFF),
  );

  static const OverlayColors guestDark = OverlayColors(
    barrier: Color(0xB3000000),
    scrim: Color(0xB3000000),
    modalBackground: Color(0xFF271F1B),
  );

  // ─── Convenience aliases ───────────────────────────────────

  static const OverlayColors light = userLight;
  static const OverlayColors dark = userDark;

  // ─── Resolver ──────────────────────────────────────────────

  static OverlayColors getColors({
    required AppRole appRole,
    required bool isDark,
  }) => switch (appRole) {
    AppRole.guest => isDark ? guestDark : guestLight,
    AppRole.user => isDark ? userDark : userLight,
  };
}
