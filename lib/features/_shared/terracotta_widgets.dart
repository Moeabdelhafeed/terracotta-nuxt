import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/theme_colors_extension.dart';
import '../../core/localization/number_formatter.dart';
import '../../core/localization/strings/home_strings.dart';
import '../../core/tokens/extensions.dart';
import '../../shared/module/buttons/global_text_button.dart';
import '../../shared/module/container/global_container.dart';
import '../shop/cubits/product_counts_cubit.dart';

/// A section heading with an optional "see all" on the far side.
///
/// The action sits at the END of the row, so it lands on the left in
/// Arabic (as the design draws it) and the right in English, from one
/// `Row` in logical order.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.actionCount,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;

  /// How many are behind the action, drawn after its label as
  /// «عرض الكل (٤)».
  ///
  /// NULL is the answer that has not arrived, or one that failed —
  /// the label is then the plain one. Zero is drawn: a section can be
  /// empty and saying so is a fact, not a gap.
  final int? actionCount;

  final VoidCallback? onAction;

  /// Tall enough for the label and its chevron, and no taller. The
  /// row's height should come from the HEADING.
  ///
  /// 32 rather than the label's own ~20: with the module's 48pt target
  /// switched off below, THIS is the tap target, and it has to stand on
  /// its own. WCAG 2.1's Target Size (Minimum) at AA is 24×24, which
  /// this clears; 44×44 is the AAA figure and is what the module was
  /// reserving.
  static const _seeAllHeight = 32.0;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: context.textTheme.titleSmall?.copyWith(
            color: context.textColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      if (actionLabel != null && onAction != null)
        // Not a flex child: without shrinkWidth the Row hands it
        // unbounded width and layout fails.
        GlobalTextButton(
          text: actionCount == null
              ? actionLabel!
              : HomeStrings.seeAllCount(actionCount!),
          onPressed: onAction!,
          shrinkWidth: true,
          // The module reserves a 48×48 hit area around every button,
          // and `MinTouchTarget` TAKES that space in layout even though
          // it does not stretch what the button paints — so a 32pt
          // control was making a 48pt row and the section heading grew
          // to match.
          //
          // Off here, and the height above is sized to be the target
          // instead. A "see all" is a way through to a list, sitting
          // inline with a heading; it is not a primary action, and the
          // design draws it small.
          enforceMinTouchTarget: false,
          // COMPACT, and quieter than the heading beside it — this is a
          // way through, not a call to action.
          size: ButtonSize.small,
          style: ButtonStateStyle(
            // The button module gives every size a MINIMUM height meant
            // for a thing you press with a thumb, and at `small` that
            // is still taller than the heading it sits beside — so the
            // whole section header was as tall as the button rather
            // than as tall as its title. Pinned to the line height of
            // the label instead.
            height: _seeAllHeight,
            padding: EdgeInsetsDirectional.only(start: context.spacing.xs),
            textStyle: context.textTheme.labelSmall,
            // A chevron pointing the way the reader is going. The
            // `_rounded` forward glyph is one Flutter mirrors, so it
            // points left in Arabic without being told.
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: context.iconSizes.xs,
              color: context.primaryColors.primary,
            ),
          ),
        ),
    ],
  );
}

/// A [SectionHeader] whose «عرض الكل» says how many are behind it.
///
/// Watches [ProductCountsCubit] and nothing else, so the number
/// arriving one request later repaints the header rather than the
/// section under it. [pick] chooses which of the two counts this
/// heading is about — a null answer draws the plain label, which is
/// what a count that has not landed or that failed looks like.
class CountedSectionHeader extends StatelessWidget {
  const CountedSectionHeader({
    required this.counts,
    required this.pick,
    required this.title,
    required this.onAction,
    super.key,
  });

  /// Handed in rather than looked up: `lib/features` widgets take their
  /// dependencies as parameters.
  final ProductCountsCubit counts;

  final int? Function(ProductCounts) pick;
  final String title;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ProductCountsCubit, ProductCounts>(
        bloc: counts,
        buildWhen: (a, b) => pick(a) != pick(b),
        builder: (context, state) => SectionHeader(
          title: title,
          actionLabel: HomeStrings.seeAll,
          actionCount: pick(state),
          onAction: onAction,
        ),
      );
}

/// A money amount.
///
/// Prices arrive from the API as DECIMAL STRINGS (`"65.00"`) and are
/// rendered as they came — never parsed to a double, which would round
/// totals, and never reformatted, because the server has already
/// applied the studio's currency rules.
///
/// [was] draws the struck-through original beside it, which is how the
/// design shows an offer.
class PriceText extends StatelessWidget {
  const PriceText({
    required this.amount,
    this.was,
    this.large = false,
    this.color,
    super.key,
  });

  /// The decimal string exactly as the API sent it.
  final String amount;

  /// The pre-discount price, if this is an offer.
  final String? was;

  final bool large;

  /// The ink. Null takes the brand's brown, which is right on a page
  /// and wrong on a card painted in a workshop's own colour.
  final Color? color;

  /// `"65.00"` → `"٦٥"`, `"35.50"` → `"٣٥٫٥"`, in Arabic.
  ///
  /// Done as STRING surgery, never by parsing to a number. Money is
  /// decimal on this API and a `double` is the wrong type for it — and
  /// nothing here needs its value, only its digits.
  ///
  /// The trailing zeros go because every price on this tenant is quoted
  /// to two places, so ".00" is noise on every card. A price that
  /// genuinely has a half — "35.50" — keeps the "5".
  ///
  /// `localizeDigits` is what turns 65 into ٦٥: plain `ar` formats in
  /// WESTERN digits, and `AppNumbers` maps it to `ar_EG` for
  /// exactly this reason.
  static String format(String amount) {
    var trimmed = amount.trim();
    if (trimmed.contains('.')) {
      trimmed = trimmed.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return AppNumbers.localizeDigits(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final base = large
        ? context.textTheme.titleLarge
        : context.textTheme.titleMedium;
    final style = base?.copyWith(
      color: color ?? context.primaryColors.primary,
      // The design sets prices at w900 — Kufam ships that weight.
      fontWeight: FontWeight.w900,
    );
    // The amount and its currency, in that order — «٦٥ ريال».
    final priced = '${format(amount)} ${HomeStrings.currency}';
    if (was == null) return Text(priced, style: style);
    return Wrap(
      spacing: context.spacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          format(was!),
          style: context.textTheme.bodySmall?.copyWith(
            color: context.textColors.disabled,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        Text(priced, style: style),
      ],
    );
  }
}

/// A read-only fact chip — price, capacity, duration, date, time.
///
/// The design draws these as the workshop family's hue at 9% alpha with
/// the full-opacity hue for the glyph and label.
class InfoChip extends StatelessWidget {
  const InfoChip({
    required this.label,
    required this.icon,
    this.color,
    super.key,
  });

  final String label;
  final IconData icon;

  /// The workshop family hue. Falls back to the app primary.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.primaryColors.primary;
    final spacing = context.spacing;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(context.radii.lg),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: spacing.sm,
          vertical: spacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: context.iconSizes.md, color: c),
            SizedBox(height: spacing.xs),
            Text(
              label,
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(
                color: context.textColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The status ribbon on a booking card — «مؤكد», «ملغاة».
///
/// Only confirmed and cancelled carry a colour in the design; every
/// other lifecycle state is drawn in plain ink. [color] null means the
/// neutral treatment, which is deliberate rather than an oversight.
class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, this.color, super.key});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? context.backgroundColors.container;
    final fg = color == null
        ? context.textColors.primary
        : context.textColors.onPrimary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(context.radii.sm),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: context.spacing.sm,
          vertical: context.spacing.xs,
        ),
        child: Text(
          label,
          style: context.textTheme.bodySmall?.copyWith(
            color: fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// A card surface: white, hairline border, no shadow.
///
/// The design has NO shadows anywhere — elevation is expressed purely
/// as a 10%-black hairline, so this is the only card treatment.
class TerracottaCard extends StatelessWidget {
  const TerracottaCard({
    required this.child,
    this.padding,
    this.color,
    this.bordered = true,
    this.borderColor,
    this.dashed = false,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsets? padding;
  final Color? color;

  /// The hairline. On by default — it is the card's whole treatment on
  /// a page-coloured tile.
  ///
  /// Off for a FILLED panel, where an outline on top of a fill is a
  /// second edge doing nothing.
  final bool bordered;

  /// The hairline's ink. Null takes the palette's own — a card only
  /// names one when it is saying something, like a cart line the studio
  /// can no longer fill.
  final Color? borderColor;

  /// A DASHED hairline instead of a solid one.
  ///
  /// For a card that is a coupon — the ticket edge is what says «this
  /// is a voucher you can take» before a word of it is read, and it is
  /// the one place in the app where an outline is doing more than
  /// separating a panel from the page.
  ///
  /// It goes through `borderLineStyle`, which is the ONLY path that
  /// reaches `_StyledBorderPainter` — `borderColor` and `borderWidth`
  /// are dead on a plain container, which is why the solid case below
  /// builds a real `Border` instead.
  final bool dashed;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GlobalContainer(
    onTap: onTap,
    style: ContainerStyle(
      backgroundColor: color ?? context.backgroundColors.cardBackground,
      // `border`, NOT `borderColor` + `borderWidth`.
      //
      // Those two are DEAD on a plain container: the decoration reads
      // `rs.border` — a `Border` object — and the resolver passes the
      // caller's `border` straight through, while `borderColor` and
      // `borderWidth` are only ever consumed by `_StyledBorderPainter`,
      // which is reached only when `borderLineStyle` is set. So this
      // card asked for a hairline in the two fields that cannot draw
      // one, and has been borderless in all of its usages.
      border: bordered && !dashed
          ? Border.all(
              color: borderColor ?? context.primaryColors.border,
              // A card that is SAYING something wears a heavier line —
              // a hairline in red reads as a rendering artefact.
              width: borderColor == null ? 1 : 1.5,
            )
          : null,
      // The painted path. `borderColor` / `borderWidth` only mean
      // anything once `borderLineStyle` is set, so all three travel
      // together or none of them do.
      borderLineStyle: bordered && dashed
          ? ContainerBorderLineStyle.dashed
          : null,
      borderColor: dashed ? borderColor ?? context.primaryColors.border : null,
      borderWidth: dashed ? 1.5 : null,
      borderDashWidth: dashed ? 5 : null,
      borderDashGap: dashed ? 4 : null,
      // FLAT. `ContainerStyle.shadow` defaults to null, and null means
      // "one soft shadow in the palette's scrim" — so every card has
      // also been carrying a drop shadow nobody asked for, under a doc
      // comment claiming the hairline was the only treatment. `const []`
      // is the module's documented way to say none.
      shadow: const [],

      borderRadius: BorderRadius.circular(context.radii.md),
      padding: padding ?? EdgeInsets.all(context.spacing.md),
    ),
    child: child,
  );
}
