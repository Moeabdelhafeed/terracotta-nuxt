import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/theme_colors_extension.dart';
import '../../core/localization/number_formatter.dart';
import '../../core/tokens/extensions.dart';

/// One chip on a [FilterChipRail].
@immutable
class FilterChipSpec {
  const FilterChipSpec({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.tint,
  });

  final String label;

  /// The TALLY, which is half of what a chip like this is for: «ملغاة
  /// ١» answers "how many did I cancel?" without the reader filtering
  /// at all.
  ///
  /// **Null draws no number**, for the case where the app genuinely
  /// does not know one — an older server sending no `meta`. A zero
  /// would be a claim, and «الحجوزات ٠» beside a tab that turns out to
  /// hold nine is worse than «الحجوزات».
  final int? count;

  final bool selected;

  /// The colour when it is on. Null takes the brand's primary.
  final Color? tint;

  final VoidCallback onTap;
}

/// A horizontal strip of counted filter chips.
///
/// «ورشاتي» filters bookings by status and the inbox filters
/// notifications by tone, and those are the same object: a rail of
/// labelled tallies, one of them on. One widget, so a change to how
/// they sit is a change in one place.
///
/// ## Where its edges are
///
/// A rail has to reach the screen or it reads as broken — the reader
/// pushes it and the last chip stops short with page still visible
/// beside it. But most pages that carry one are already inside a
/// gutter, and a strip laid out in there can only scroll between those
/// two edges.
///
/// So [escape] is how far the rail may reach BEYOND the width it was
/// handed — the parent's own gutter — and [pad] is the inset it then
/// puts back on its own content, which scrolls with it. Together they
/// line the first chip up with whatever is below it while letting the
/// last one scroll clear of the screen edge.
///
/// `OverflowBox` is what lets the child exceed its given width while
/// the strip still OCCUPIES the parent's width for layout, so nothing
/// else in the column moves. It is CENTRED, so the extra is split
/// between the two edges: aligned to the start it all went to one end
/// and the other stayed clipped against the gutter.
///
/// A page with NO gutter passes `escape: 0` — reaching past a width
/// that is already the screen only pushes the first and last chip off
/// it.
class FilterChipRail extends StatelessWidget {
  const FilterChipRail({
    required this.chips,
    this.escape = 0,
    this.pad,
    super.key,
  });

  final List<FilterChipSpec> chips;

  /// The parent's horizontal gutter, which this rail reaches back out
  /// through. Zero on a page that has none.
  final double escape;

  /// Horizontal padding on the rail's own content. Defaults to
  /// `spacing.md`, which is the app's gutter.
  final double? pad;

  static const height = 40.0;

  @override
  Widget build(BuildContext context) {
    if (chips.isEmpty) return const SizedBox.shrink();

    final inset = pad ?? context.spacing.md;

    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) => OverflowBox(
          maxWidth: double.infinity,
          child: SizedBox(
            width: constraints.maxWidth + escape * 2,
            // NOT `ListView.separated`: a builder is a VIRTUALISED
            // collection, which is `GlobalList` territory and trips
            // the adoption guard for it. A strip of a handful of
            // chips gains nothing from virtualising them, and every
            // one is built for the tally on it anyway.
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsetsDirectional.symmetric(horizontal: inset),
              children: [
                for (final (i, chip) in chips.indexed) ...[
                  if (i > 0) SizedBox(width: context.spacing.xs),
                  _Chip(spec: chip),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.spec});

  final FilterChipSpec spec;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final accent = spec.tint ?? context.primaryColors.primary;
    // WHITE, on every selected chip, whatever it is tinted with.
    //
    // This measured the fill and picked whichever of white and the
    // app's near-black read better on it — which is defensible per
    // chip and wrong for the ROW. The tints differ by status, so the
    // labels came out white on «مؤكدة» and near-black on «ملغاة»,
    // and a strip where the selected chip changes ink as it moves
    // reads as a rendering fault rather than as a selection.
    //
    // The cost is «قيد الانتظار»: white on the amber measures 3.1:1,
    // under AA. That is the design's own amber and the design's own
    // white label — it is in `docs/contrast-report.md` alongside the
    // five other pairs shipped as drawn.
    const ink = Colors.white;
    final radius = BorderRadius.circular(context.radii.full);

    return Material(
      color: spec.selected ? accent : context.backgroundColors.container,
      borderRadius: radius,
      child: InkWell(
        onTap: spec.onTap,
        borderRadius: radius,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: spacing.md,
            vertical: spacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                spec.label,
                style: context.textTheme.labelLarge?.copyWith(
                  color: spec.selected ? ink : context.textColors.primary,
                ),
              ),
              if (spec.count != null) ...[
                SizedBox(width: spacing.xs),
                Text(
                  AppNumbers.localizeDigits('${spec.count}'),
                  style: context.textTheme.labelMedium?.copyWith(
                    color: spec.selected
                        ? ink.withValues(alpha: 0.8)
                        : context.textColors.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
