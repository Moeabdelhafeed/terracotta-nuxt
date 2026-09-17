import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/extensions/theme_colors_extension.dart';
import '../../core/localization/number_formatter.dart';

/// The little number on an app-bar button.
///
/// **One object, so the cart and the bell cannot drift apart.** They
/// were two copies: the cart's was a coral disc with «٩+» past nine,
/// the bell's a red pill with a ring round it and a different cap, a
/// different size and a different corner. Two badges on one bar, half
/// an inch apart, reading as two different kinds of thing.
///
/// The cart's design won because it is the one the studio drew.
///
/// **[cap] keeps it round.** Past it the badge says `+9` rather than
/// growing wider than the button it sits on — a three-digit pill on a
/// 40pt glyph is a label, not a badge.
class TerracottaCountBadge extends StatelessWidget {
  const TerracottaCountBadge({required this.count, this.cap = 9, super.key});

  final int count;

  /// The highest number printed as itself.
  final int cap;

  /// Where it sits on the glyph, for the `Stack` that carries it.
  static const top = 2.0;
  static const end = 2.0;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.primaryColors.accent,
      shape: BoxShape.circle,
    ),
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
        child: Center(
          child: Text(
            // LOCALIZED DIGITS on both halves. The cap used to be
            // written «+٩» as a literal, so an English build showed an
            // Arabic nine.
            count > cap
                ? '+${AppNumbers.localizeDigits('$cap')}'
                : AppNumbers.localizeDigits('$count'),
            textAlign: TextAlign.center,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.textColors.onPrimary,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    ),
  );
}
