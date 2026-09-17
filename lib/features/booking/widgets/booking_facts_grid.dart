import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/assets/assets.dart';
import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../workshops/widgets/gift_backdrop.dart';
import 'confetti_strip.dart';
import 'fact_dialog.dart';

/// The six facts of a booking, in the design's three-across grid.
///
/// A GRID, not a `Wrap`: the design puts them in even columns and a
/// wrap would reflow them into ragged rows the moment one label runs
/// long — «حجز لشخصين» is wider than «٨٠٠ ريال» and the two must still
/// line up.
///
/// The scan chip is the only one that is a BUTTON, and it is filled in
/// the workshop's own colour rather than tinted — it is the thing to do
/// next, and the other five are things to read.
class BookingFactsGrid extends StatelessWidget {
  const BookingFactsGrid({
    required this.price,
    required this.people,
    required this.date,
    required this.time,
    this.hasCelebration = false,
    this.onScan,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    super.key,
  });

  /// A decimal STRING. Money is decimal on this API.
  final String price;

  /// Already composed — «حجز لشخصين».
  final String people;

  /// «يونيو ٤ الثلاثاء» and «٣ م الى ٤ م», Asia/Riyadh, as received.
  final String date;
  final String time;

  final bool hasCelebration;

  /// Null hides the scan chip entirely — a cancelled booking has
  /// nothing to scan.
  final VoidCallback? onScan;

  final WorkshopFamily family;
  final String? wireColor;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final fam = WorkshopFamilyColors.resolve(
      family: family,
      isDark: context.isDarkMode,
      wireColor: wireColor,
    );

    // ORDER AS DRAWN. The design reads date · people · price across
    // the first row and scan · time · celebration across the second —
    // so in Arabic the date lands under the reader's thumb on the
    // right and the price on the left. Written logically, it mirrors
    // itself in English.
    //
    // The plain chips print their label in the page's own ink, not in
    // the workshop's colour: six coloured labels read as six buttons,
    // and only one of these is a thing to press.
    final ink = context.textColors.primary;

    final row1 = <Widget>[
      _Fact(
        label: date,
        icon: Icons.event_rounded,
        tint: fam.primary,
        labelColor: ink,
      ),
      _Fact(
        label: people,
        icon: Icons.people_rounded,
        tint: fam.primary,
        labelColor: ink,
      ),
      _Fact(
        label: '${PriceText.format(price)} ${HomeStrings.currency}',
        icon: Icons.sell_rounded,
        tint: fam.primary,
        labelColor: ink,
      ),
    ];

    final row2 = <Widget>[
      if (onScan != null)
        _Fact(
          label: BookingStrings.scanCode,
          icon: Icons.qr_code_2_rounded,
          // The DESIGN's mark — a boxicons glyph with a scatter of
          // dots. `Icons.qr_code_2` is a plain three-corner square and
          // reads as a different symbol beside it.
          iconAsset: Assets.icons.qrScan.defaultPath,
          tint: fam.primary,
          filled: true,
          onTap: onScan,
          // The house loop behind it — the same drawing the gift tile
          // wears, so the one chip that is a BUTTON reads as a surface
          // rather than a swatch.
          backdrop: GiftBackdrop(
            tint: context.textColors.onPrimary.withValues(alpha: 0.22),
          ),
        ),
      _Fact(
        label: time,
        icon: Icons.schedule_rounded,
        tint: fam.primary,
        labelColor: ink,
      ),
      if (hasCelebration)
        _Fact(
          label: BookingStrings.withCelebration,
          icon: Icons.cake_rounded,
          // The celebration ramp, NOT the error ramp — same family of
          // reds, opposite meaning. A celebration is not a warning.
          tint: context.primaryColors.accent,
          labelColor: const Color(0xFFF57373),
          // Confetti down BOTH edges, mirrored, exactly as the add-a-
          // celebration bar wears it — one treatment for one idea.
          backdrop: const Stack(
            children: [
              ConfettiStrip(edge: AlignmentDirectional.centerStart),
              ConfettiStrip(edge: AlignmentDirectional.centerEnd),
            ],
          ),
        ),
    ];

    // ROWS OF EXPANDED, not a `LayoutBuilder` measuring the width.
    //
    // The page wraps this in an `IntrinsicHeight` so the whole column
    // can stretch to the viewport and space itself out — and
    // `LayoutBuilder` refuses to report an intrinsic dimension, which
    // threw «LayoutBuilder does not support returning intrinsic
    // dimensions» before a single frame drew. Flex does the same
    // even-column arithmetic and is intrinsic-safe.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Row(cells: row1),
        SizedBox(height: spacing.sm),
        // NO PADDING CELL when there is no celebration. A booking
        // without one leaves a hole in the second row, and a hole reads
        // as something that failed to load — so the two chips that ARE
        // there share the width instead.
        _Row(cells: row2),
      ],
    );
  }
}

/// One row of the grid, its cells sharing the width evenly.
class _Row extends StatelessWidget {
  const _Row({required this.cells});

  final List<Widget> cells;

  @override
  Widget build(BuildContext context) => Row(
    // NOT stretch: the height here is unbounded while the page measures
    // its intrinsic size, and a stretching Row hands its children
    // h=Infinity. Each chip owns its own height.
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final (index, cell) in cells.indexed) ...[
        if (index > 0) SizedBox(width: context.spacing.sm),
        Expanded(child: cell),
      ],
    ],
  );
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.icon,
    required this.tint,
    this.iconAsset,
    this.labelColor,
    this.filled = false,
    this.onTap,
    this.backdrop,
  });

  final String label;

  /// The Material fallback, used when [iconAsset] is null.
  final IconData icon;

  /// The design's own glyph, when the app ships one. Preferred: the
  /// scan mark in particular is a boxicons drawing with a scatter of
  /// dots that `Icons.qr_code_2` does not have.
  final String? iconAsset;

  final Color tint;
  final Color? labelColor;

  /// Solid in the workshop's colour, with the label reversed out — the
  /// one chip that is a thing to DO.
  final bool filled;

  final VoidCallback? onTap;

  /// Artwork behind the label — the house loop, or the party pattern.
  /// Clipped to the chip and never in the way of a tap.
  final Widget? backdrop;

  /// The design's chip. Near enough SQUARE in a three-across row, and
  /// deep enough for a label that runs to two lines — «حجز لشخصين» and
  /// «مع احتفال» both do.
  static const _height = 96.0;

  /// The glyph, and the band it lives in.
  ///
  /// FIXED, not centred with the words: a column that centres its pair
  /// puts the icon lower on a chip whose label runs to two lines than
  /// on one whose label is a single line, so a row of six chips had its
  /// glyphs at three different heights. The icon sits in a band of its
  /// own and the label takes the rest, so every glyph in the grid lines
  /// up with every other.
  static const _iconBand = 40.0;
  static const _iconSize = 26.0;

  @override
  Widget build(BuildContext context) {
    // The GLYPH keeps the workshop's colour whatever the label does —
    // it is what makes a row of six chips read as this workshop's, and
    // greying it out along with the words took the family's hue off
    // the page entirely.
    final glyphInk = filled ? context.textColors.onPrimary : tint;
    final wordInk = filled
        ? context.textColors.onPrimary
        : (labelColor ?? tint);
    final radius = BorderRadius.circular(context.radii.md);

    return Material(
      color: filled ? tint : tint.withValues(alpha: 0.12),
      borderRadius: radius,
      // The artwork has to stop at the chip's own corners.
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // ITS OWN JOB FIRST. «امسح الرمز» is a button and has
        // somewhere to go; every other chip is a FACT, and the only
        // thing a fact can do is finish saying itself — see
        // [FactDialog], and the ellipsis it exists to undo.
        onTap:
            onTap ??
            () => unawaited(
              showFactDialog(
                context,
                label: label,
                icon: icon,
                iconAsset: iconAsset,
                tint: tint,
              ),
            ),
        borderRadius: radius,
        child: SizedBox(
          height: _height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (backdrop != null) Positioned.fill(child: backdrop!),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.spacing.xs,
                  vertical: context.spacing.md,
                ),
                child: Column(
                  // FILLS the tile. `min` sized the column to its own
                  // contents and the Stack then centred it — so a chip
                  // whose label wrapped had a TALLER column, which sat
                  // higher, which put its glyph above its neighbours'.
                  // The band alone did not fix that: it pinned the icon
                  // inside a box that was itself moving.
                  children: [
                    SizedBox(
                      height: _iconBand,
                      child: Center(
                        child: iconAsset != null
                            ? SvgPicture.asset(
                                iconAsset!,
                                width: _iconSize,
                                height: _iconSize,
                                colorFilter: ColorFilter.mode(
                                  glyphInk,
                                  BlendMode.srcIn,
                                ),
                              )
                            : Icon(icon, size: _iconSize, color: glyphInk),
                      ),
                    ),
                    Expanded(
                      child: Align(
                        // Under the glyph, not floating in the middle
                        // of what is left.
                        // CENTRED in what is left, not tucked under the
                        // glyph. The design sets the words low in the
                        // tile — roughly two thirds down — and top-
                        // aligning them pulled every label up against
                        // its icon.
                        alignment: Alignment.center,
                        // ONE LINE, CUT SHORT — and the whole of it is
                        // one tap away.
                        //
                        // Two lines fitted «حجز لشخصين» and «مع
                        // احتفال», and made every tile in the row as
                        // tall as the longest label in it — so a grid
                        // of three short facts sat in boxes sized for
                        // a fact that was not there.
                        //
                        // This was a marquee for a while, which only
                        // moved when the label actually overflowed.
                        // The motion is the problem: six chips in a
                        // grid, two of them sliding their text back
                        // and forth, is a page that will not sit
                        // still — and a reader has to WAIT for the
                        // end of a sentence that is already on
                        // screen everywhere else. An ellipsis says
                        // there is more; [showFactDialog] is where
                        // the more is.
                        child: Text(
                          label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: context.textTheme.labelSmall?.copyWith(
                            color: wordInk,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
