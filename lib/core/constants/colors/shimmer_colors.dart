import 'package:flutter/material.dart';

import '../enums/app/app_role.dart';

/// A skeleton has to be seen MOVING, or it is just a grey box.

/// The design draws no skeleton state; these are derived from the two
/// neutrals it does use so a shimmer reads as the same material.
@immutable
class ShimmerColors {
  final Color baseColor;
  final Color highlight;
  final Color containerBackground;

  const ShimmerColors({
    required this.baseColor,
    required this.highlight,
    required this.containerBackground,
  });

  // ─── Fallback ──────────────────────────────────────────────

  static const ShimmerColors fallbackLight = ShimmerColors(
    baseColor: Color(0xFFEDEDED),
    highlight: Color(0xFFFAF7F6),
    containerBackground: Color(0xFFFFFFFF),
  );

  static const ShimmerColors fallbackDark = ShimmerColors(
    baseColor: Color(0xFF271F1B),
    highlight: Color(0xFF3A302B),
    containerBackground: Color(0xFF271F1B),
  );

  // ─── User role ─────────────────────────────────────────────

  static const ShimmerColors userLight = ShimmerColors(
    baseColor: Color(0xFFEDEDED),
    highlight: Color(0xFFFAF7F6),
    containerBackground: Color(0xFFFFFFFF),
  );

  static const ShimmerColors userDark = ShimmerColors(
    baseColor: Color(0xFF271F1B),
    highlight: Color(0xFF3A302B),
    containerBackground: Color(0xFF271F1B),
  );

  // ─── Guest role — Terracotta ships ONE palette (intake Q9), so
  //     guest is the same bag as user. Kept so the resolver stays
  //     total and a future guest skin has somewhere to land.

  static const ShimmerColors guestLight = ShimmerColors(
    baseColor: Color(0xFFEDEDED),
    highlight: Color(0xFFFAF7F6),
    containerBackground: Color(0xFFFFFFFF),
  );

  static const ShimmerColors guestDark = ShimmerColors(
    baseColor: Color(0xFF271F1B),
    highlight: Color(0xFF3A302B),
    containerBackground: Color(0xFF271F1B),
  );

  // ─── Convenience aliases ───────────────────────────────────

  static const ShimmerColors light = userLight;
  static const ShimmerColors dark = userDark;

  // ─── Resolver ──────────────────────────────────────────────

  static ShimmerColors getColors({
    required AppRole appRole,
    required bool isDark,
  }) => switch (appRole) {
    AppRole.guest => isDark ? guestDark : guestLight,
    AppRole.user => isDark ? userDark : userLight,
  };
}
