import 'package:flutter/material.dart';

import '../enums/app/app_role.dart';

/// `success` and `error` are real: the مؤكد and ملغاة booking chips.
/// `warning` is the only amber in the file (the تغير موعد button).
/// `info` has NO source — nothing in the design is informational-blue, and
/// the only blues present are the Visa and Google Pay brand marks, which
/// must never be repurposed. It takes the green family hue, which is how
/// every read-only info chip is actually drawn (intake Q9).
///
/// CONTRAST: white-on-success is 2.07:1 in the design as drawn. Shipped
/// as-is for fidelity — see docs/contrast-report.md.
///
/// **DARK lifts all four.** The light values are the design's and stay
/// exactly as drawn; the dark ones are not in the design at all, and
/// three of them were being reused unchanged. `#C18B00` is a dark gold
/// chosen to sit on white — on a dark ground it is a muddy brown
/// standing in for a warning. Each is lifted until it clears 4.5:1 as
/// TEXT on `container`, the busiest of the three grounds, and the dark
/// ink clears it on the fill.
///
/// **And they are levelled, and desaturated.** Left at the light
/// theme's saturation they were a fruit salad on a dark screen:
/// `#FF6F62` is a fully saturated red and `#FC8B8B` a 95% pink, both
/// of which glare, and the four sat anywhere from L\* 58 to 77 — so a
/// row of chips had no common ground and the brightest one won
/// whatever it said. Dark pulls saturation back to 46–72% and brings
/// all four into a 61–73 L\* band, where they read as one family and
/// none of them out-shouts the text above it.
@immutable
class StatusColors {
  final Color success;
  final Color warning;
  final Color error;
  final Color info;

  const StatusColors({
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
  });

  // ─── Fallback ──────────────────────────────────────────────

  static const StatusColors fallbackLight = StatusColors(
    success: Color(0xFF06CD90),
    warning: Color(0xFFC18B00),
    error: Color(0xFFE32D1F),
    info: Color(0xFF3A7F6A),
  );

  static const StatusColors fallbackDark = StatusColors(
    success: Color(0xFF59C59A),
    warning: Color(0xFFDBAB57),
    error: Color(0xFFE67265),
    info: Color(0xFF55B998),
  );

  // ─── User role ─────────────────────────────────────────────

  static const StatusColors userLight = StatusColors(
    success: Color(0xFF06CD90),
    warning: Color(0xFFC18B00),
    error: Color(0xFFE32D1F),
    info: Color(0xFF3A7F6A),
  );

  static const StatusColors userDark = StatusColors(
    success: Color(0xFF59C59A),
    warning: Color(0xFFDBAB57),
    error: Color(0xFFE67265),
    info: Color(0xFF55B998),
  );

  // ─── Guest role — Terracotta ships ONE palette (intake Q9), so
  //     guest is the same bag as user. Kept so the resolver stays
  //     total and a future guest skin has somewhere to land.

  static const StatusColors guestLight = StatusColors(
    success: Color(0xFF06CD90),
    warning: Color(0xFFC18B00),
    error: Color(0xFFE32D1F),
    info: Color(0xFF3A7F6A),
  );

  static const StatusColors guestDark = StatusColors(
    success: Color(0xFF59C59A),
    warning: Color(0xFFDBAB57),
    error: Color(0xFFE67265),
    info: Color(0xFF55B998),
  );

  // ─── Convenience aliases ───────────────────────────────────

  static const StatusColors light = userLight;
  static const StatusColors dark = userDark;

  // ─── Resolver ──────────────────────────────────────────────

  static StatusColors getColors({
    required AppRole appRole,
    required bool isDark,
  }) => switch (appRole) {
    AppRole.guest => isDark ? guestDark : guestLight,
    AppRole.user => isDark ? userDark : userLight,
  };
}
