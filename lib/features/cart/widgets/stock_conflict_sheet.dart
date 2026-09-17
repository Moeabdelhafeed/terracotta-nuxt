import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/cart_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/buttons/global_outlined_button.dart';
import '../../../shared/module/sheet/global_sheet.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../data/cart_stock_check.dart';

/// What the customer decided about a basket the studio can no longer
/// fill.
enum StockDecision {
  /// Lower what can be lowered, take out what is gone.
  fix,

  /// Leave it alone. Checkout stays shut until they change it
  /// themselves — which is a state they can see, on the lines
  /// themselves.
  keep,
}

/// «نفدت بعض القطع» — shown when a cart re-read finds a line the studio
/// can no longer fill.
///
/// **It names every piece and what happened to it**, because "some
/// items are unavailable" is the kind of sentence that sends a customer
/// hunting through six rows to find out which. Then two ways out:
/// let the app sort it, or keep it and fix it by hand.
///
/// Returns null on a dismissal, which means neither — the basket is
/// left exactly as it was and the lines keep their warning.
Future<StockDecision?> showStockConflictSheet(
  BuildContext context, {
  required List<StockProblem> problems,
}) => GlobalBottomSheet.show<StockDecision>(
  context: context,
  showCloseButton: false,
  content: _Body(problems: problems),
);

class _Body extends StatelessWidget {
  const _Body({required this.problems});

  final List<StockProblem> problems;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Padding(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            CartStrings.stockTitle,
            style: context.textTheme.titleMedium?.copyWith(
              color: context.textColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: spacing.xs),
          Text(
            CartStrings.stockBody,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textColors.secondary,
            ),
          ),
          SizedBox(height: spacing.md),
          // Every piece, by name. Nobody can act on "some items".
          for (final problem in problems) ...[
            _Line(problem: problem),
            SizedBox(height: spacing.xs),
          ],
          SizedBox(height: spacing.sm),
          // The RECOMMENDED way out leads, and both say what they will
          // do rather than making the customer guess from a verb.
          GlobalFilledButton(
            text: CartStrings.stockFix,
            onPressed: () => Navigator.of(context).pop(StockDecision.fix),
            style: terracottaCtaStyle(showArrow: false),
          ),
          SizedBox(height: spacing.xs),
          _Note(CartStrings.stockFixNote),
          SizedBox(height: spacing.sm),
          GlobalOutlinedButton(
            text: CartStrings.stockKeep,
            onPressed: () => Navigator.of(context).pop(StockDecision.keep),
            style: terracottaCtaStyle(showArrow: false).copyWith(
              textStyle: TextStyle(
                fontSize: kTerracottaCtaLabelSize,
                color: context.primaryColors.primary,
              ),
            ),
          ),
          SizedBox(height: spacing.xs),
          _Note(CartStrings.stockKeepNote),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.problem});

  final StockProblem problem;

  @override
  Widget build(BuildContext context) {
    // Gone is the error ink; merely short is the warning one — the
    // first can only be removed, the second can be lowered.
    final ink = problem.isGone
        ? context.statusColors.error
        : context.statusColors.warning;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(
            problem.isGone
                ? Icons.remove_circle_outline_rounded
                : Icons.error_outline_rounded,
            size: context.iconSizes.sm,
            color: ink,
          ),
        ),
        SizedBox(width: context.spacing.xs),
        Expanded(
          child: Text(
            problem.sentence,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.textColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: context.textTheme.labelSmall?.copyWith(
      color: context.textColors.secondary,
    ),
  );
}
