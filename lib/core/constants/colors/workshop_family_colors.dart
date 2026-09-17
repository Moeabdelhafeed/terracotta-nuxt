import 'package:flutter/material.dart';

import '../../a11y/contrast_checker.dart';

/// The three workshop types, and the hue each one paints its booking
/// flow in.
///
/// The design draws the booking flow THREE TIMES — once per workshop
/// type — and the only thing that changes is this hue. It drives the
/// CTA fill, the selected date chip, the selected time slot, the QR
/// chip, the day numeral, the 9%-alpha info-chip tint and the
/// decorative swash. Everything else holds still: the bottom nav stays
/// [PrimaryColors.primary], and success, celebration and destructive
/// never vary.
///
/// This is a SECOND theming axis, deliberately NOT folded into
/// `AppRole`. The family is a property of the booking on screen, not of
/// the signed-in person — one customer moves between all three in a
/// session, and `getColors(appRole:)` cannot express that.
///
/// The wire value is the `type` field on a workshop from
/// `GET /api/workshops`. Build the flow ONCE and drive it from here;
/// do not fork three copies.
///
/// ## The server also sends a colour, and it wins
///
/// `GET /api/workshops` returns a `color` hex **per workshop**, set by
/// an admin in the CMS — not per type. Two `make_your_piece` workshops
/// came back with different colours on the live dev server, so keying
/// the accent off [WorkshopFamily] alone does NOT reproduce what the
/// backend intends.
///
/// Resolution order is therefore:
///   1. the workshop's own `color`, when the CMS has set one
///   2. this family bag, as the brand-correct fallback
///
/// Use [resolve] rather than [getColors] at a call site that has a
/// workshop in hand. The family bag stays the fallback because the
/// seeded values are Tailwind defaults (`#f97316`, `#10b981`,
/// `#f59e0b`, `#0ea5e9`) that belong to no Terracotta palette — until
/// the studio sets real ones, falling back keeps the app on-brand.
enum WorkshopFamily {
  /// صناعة كوبك — make your piece. Flat price per person, no catalogue.
  /// The fired piece is collected later, so this family has the full
  /// pickup/delivery tail.
  makeYourPiece('make_your_piece'),

  /// تلوين كوبك — paint your piece. Price comes from the pieces picked,
  /// same pickup/delivery tail afterwards.
  paintYourPiece('paint_your_piece'),

  /// صناعة شمعك — make your candle. Catalogue-priced, but finished and
  /// taken home the same day: no packing, no delivery, and the API
  /// returns a null `delivery_fee`.
  makeYourCandle('make_your_candle');

  const WorkshopFamily(this.wire);

  /// The `type` value as it arrives from the API.
  final String wire;

  /// Whether booking this family goes through the CATALOGUE step.
  ///
  /// Mirrors `Workshop::CATALOG_TYPES` on the server: these two are
  /// priced from the pieces the customer picks, so the schedule screen
  /// hands off to «اختيار القطع» instead of straight to payment.
  /// [makeYourPiece] is a flat rate per person and has nothing to pick.
  bool get needsCatalogue => this == paintYourPiece || this == makeYourCandle;

  /// Resolves a wire value, falling back to [makeYourPiece] for an
  /// unknown type rather than throwing — a new workshop type added in
  /// the CMS must not crash a shipped build.
  static WorkshopFamily fromWire(String? value) => values.firstWhere(
    (f) => f.wire == value,
    orElse: () => makeYourPiece,
  );
}

/// The per-family colour bag.
///
/// [container] is the family hue at 9% alpha — the wash behind every
/// read-only info chip (price, capacity, date, time). [onContainer] is
/// the full-opacity hue that sits on it.
@immutable
class WorkshopFamilyColors {
  final Color primary;
  final Color container;
  final Color onContainer;
  final Color onPrimary;
  final Color panel;

  const WorkshopFamilyColors({
    required this.primary,
    required this.container,
    required this.onContainer,
    required this.onPrimary,
    required this.panel,
  });

  // ─── Light — verbatim from the Pencil design ───────────────

  static const WorkshopFamilyColors makeYourPieceLight = WorkshopFamilyColors(
    primary: Color(0xFF3A7F6A),
    container: Color(0x173A7F6A),
    onContainer: Color(0xFF3A7F6A),
    onPrimary: Color(0xFFFFFFFF),
    panel: Color(0xFFEDF3F2),
  );

  static const WorkshopFamilyColors paintYourPieceLight = WorkshopFamilyColors(
    primary: Color(0xFFA85724),
    container: Color(0x17A85724),
    onContainer: Color(0xFFA85724),
    onPrimary: Color(0xFFFFFFFF),
    panel: Color(0xFFF7F0EB),
  );

  static const WorkshopFamilyColors makeYourCandleLight = WorkshopFamilyColors(
    primary: Color(0xFFAE9353),
    container: Color(0x17AE9353),
    onContainer: Color(0xFFAE9353),
    onPrimary: Color(0xFFFFFFFF),
    panel: Color(0xFFF8F5EF),
  );

  // ─── Dark — the same three hues, lifted onto the dark ground ───
  //
  // Each clears 4.5:1 as TEXT on `surface` and as text on its own
  // panel, and the dark ink clears it on the fill. Labels flip to that
  // ink rather than white, because a hue lifted enough to read on a
  // dark ground is itself a LIGHT ground.
  //
  // The panels sit ~7 L* above the scaffold — the same lift every
  // other raised surface gets, tinted toward the family rather than
  // toward the app's own warm neutral, so a booking flow reads as its
  // own room without leaving the building.

  static const WorkshopFamilyColors makeYourPieceDark = WorkshopFamilyColors(
    primary: Color(0xFF55B998),
    container: Color(0x2455B998),
    onContainer: Color(0xFF55B998),
    onPrimary: Color(0xFF1D1713),
    panel: Color(0xFF1F2D29),
  );

  static const WorkshopFamilyColors paintYourPieceDark = WorkshopFamilyColors(
    primary: Color(0xFFDE7D54),
    container: Color(0x24DE7D54),
    onContainer: Color(0xFFDE7D54),
    onPrimary: Color(0xFF1D1713),
    panel: Color(0xFF2F231E),
  );

  static const WorkshopFamilyColors makeYourCandleDark = WorkshopFamilyColors(
    primary: Color(0xFFCDB170),
    container: Color(0x24CDB170),
    onContainer: Color(0xFFCDB170),
    onPrimary: Color(0xFF1D1713),
    panel: Color(0xFF2E291F),
  );

  // ─── Resolver ──────────────────────────────────────────────

  /// The accent for a workshop, preferring the CMS-set colour and
  /// falling back to the family bag.
  ///
  /// [wireColor] is the `color` field straight off the workshop
  /// payload — pass it through untouched, including null. Anything that
  /// is not a `#RRGGBB` / `#AARRGGBB` string is ignored rather than
  /// throwing: a malformed colour in the CMS must not crash the app.
  static WorkshopFamilyColors resolve({
    required WorkshopFamily family,
    required bool isDark,
    String? wireColor,
  }) {
    final base = getColors(family: family, isDark: isDark);
    final parsed = parseWireColor(wireColor);
    if (parsed == null) return base;
    return WorkshopFamilyColors(
      primary: parsed,
      container: parsed.withValues(alpha: isDark ? 0.14 : 0.09),
      onContainer: parsed,
      // WHITE, ALWAYS — the studio's own call, made 2026-09-16.
      //
      // It used to be chosen by measured contrast between the app's
      // near-black and white, which is why a red workshop card came
      // back with dark type on it. That reads as a different card from
      // every other one in the list: the design writes white on a
      // filled band everywhere it draws one, and a colour the studio
      // picked is a brand surface, not a contrast problem to solve.
      //
      // The trade is real and deliberate — white on `#ff0000` is
      // 4.0:1, where the near-black was 5.25:1, so a pale CMS colour
      // can drop below AA. [onWireColor] still measures, for the
      // scanner sheet, which is not a brand surface.
      onPrimary: const Color(0xFFFFFFFF),
      panel: base.panel,
    );
  }

  /// The ink that reads best on [background] — whichever of the app's
  /// near-black and white has the greater contrast ratio.
  ///
  /// Measured, not guessed from luminance: a mid-toned hue can fall on
  /// the dark side of a threshold and still be far too light for white
  /// type.
  static Color onWireColor(Color background) {
    const dark = Color(0xFF1D1713);
    const light = Color(0xFFFFFFFF);
    return ContrastChecker.ratio(dark, background) >=
            ContrastChecker.ratio(light, background)
        ? dark
        : light;
  }

  /// Parses `#RGB`, `#RRGGBB` or `#AARRGGBB`. Returns null for anything
  /// else, including null and the empty string.
  static Color? parseWireColor(String? value) {
    if (value == null) return null;
    var hex = value.trim();
    if (!hex.startsWith('#')) return null;
    hex = hex.substring(1);
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length == 6) hex = 'FF$hex';
    if (hex.length != 8) return null;
    final v = int.tryParse(hex, radix: 16);
    return v == null ? null : Color(v);
  }

  static WorkshopFamilyColors getColors({
    required WorkshopFamily family,
    required bool isDark,
  }) => switch (family) {
    WorkshopFamily.makeYourPiece =>
      isDark ? makeYourPieceDark : makeYourPieceLight,
    WorkshopFamily.paintYourPiece =>
      isDark ? paintYourPieceDark : paintYourPieceLight,
    WorkshopFamily.makeYourCandle =>
      isDark ? makeYourCandleDark : makeYourCandleLight,
  };
}
