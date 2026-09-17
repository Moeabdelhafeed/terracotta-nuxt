import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/gift_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../workshops/widgets/gift_backdrop.dart';

/// «اهداء رصيد ٢٠٠ ريال» — the coral panel the gift flow is headed by.
///
/// The SAME card on the sheet and on the checkout, because it is the
/// same thing being bought and the design draws it identically on both.
/// It is the flow's one piece of colour: gifting is the only thing in
/// the app that is coral rather than the brand's brown, and the tile on
/// the workshops page that opens it wears the same drawn loop behind
/// the same hue.
class GiftHeroCard extends StatelessWidget {
  const GiftHeroCard({required this.amount, super.key});

  /// The package's face value as a decimal STRING, exactly as the wire
  /// sends it (`"200.00"`). Formatted HERE — `PriceText.format` is the
  /// same string surgery the rest of the app prints money with:
  /// localized digits, trailing zeros gone, never parsed to a number.
  final String amount;

  /// The line work is HAIRLINE — the same alpha the workshops tile
  /// uses, which is what makes a blown-up 121pt drawing readable at
  /// this size.
  static const _patternAlpha = 0.55;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final onCoral = context.textColors.onPrimary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(context.radii.md),
      child: ColoredBox(
        color: context.primaryColors.accent,
        child: Stack(
          children: [
            // BEHIND the words and ignored by hit testing — a texture,
            // not a picture anyone is meant to look at.
            Positioned.fill(
              child: GiftBackdrop(
                tint: onCoral.withValues(alpha: _patternAlpha),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: spacing.md,
                vertical: spacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    GiftStrings.amount(
                      '${PriceText.format(amount)} ${HomeStrings.currency}',
                    ),
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleLarge?.copyWith(
                      color: onCoral,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: spacing.sm),
                  Text(
                    GiftStrings.heroBody,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: onCoral,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
