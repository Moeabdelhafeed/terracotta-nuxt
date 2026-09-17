import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/checkout_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/workshop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../_shared/terracotta_widgets.dart';

/// «رصيد تيراكوتا» — spend the balance on this booking, or don't.
///
/// **A yes/no, not an amount.** `use_wallet` on
/// `GET /api/workshops/{id}/price` is a boolean: the server applies as
/// much of the balance as the booking costs and answers with
/// `wallet_applied` and `amount_due`. A balance smaller than the total
/// therefore covers PART of it and the rest is charged — which is the
/// "pay some of it with the balance" case, without the customer having
/// to pick a number or this screen having to do arithmetic on money.
///
/// What the toggle owes them is the consequence, in words: how much it
/// takes off, and what is left.
class WalletToggle extends StatelessWidget {
  const WalletToggle({
    required this.balance,
    required this.applied,
    required this.due,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  /// All decimal STRINGS, exactly as the API sends money.
  final String balance;
  final String applied;
  final String due;

  final bool enabled;
  final ValueChanged<bool> onChanged;

  /// Whether the balance covers the whole booking.
  bool get _settled =>
      enabled && PriceText.format(due) == PriceText.format('0');

  /// Whether there is anything in the purse to offer.
  ///
  /// Compared through [PriceText.format] rather than parsed: money is a
  /// decimal STRING on this API, and `"0.00"`, `"0.0"` and `"0"` are
  /// the same empty purse written three ways.
  bool get _hasBalance =>
      balance.isNotEmpty && PriceText.format(balance) != PriceText.format('0');

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    // NOTHING AT ALL when the purse is empty.
    //
    // A toggle offering «٠٫٠٠ ريال» is a control that cannot do
    // anything, sitting between the reader and the button they came
    // to press — and it invites the tap that proves it. The wallet
    // appears when there is a balance to spend, and the customer who
    // has never had one never learns it exists from a dead row.
    if (!_hasBalance) return const SizedBox.shrink();

    return TerracottaCard(
      padding: EdgeInsets.all(spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ProfileWalletLabel.of(context),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.textColors.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ProfileWalletLabel.have(balance),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: context.textColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(value: enabled, onChanged: onChanged),
            ],
          ),
          // Only once it is ON, and only the two numbers that follow
          // from it — what it took, and what is left. Shown as a
          // CONSEQUENCE rather than as a form: there is nothing here to
          // fill in.
          if (enabled) ...[
            SizedBox(height: spacing.sm),
            _Consequence(
              label: CheckoutStrings.walletCovers(
                '${PriceText.format(applied)} ${HomeStrings.currency}',
              ),
              value: _settled ? CheckoutStrings.alreadySettled : null,
            ),
            if (!_settled) ...[
              SizedBox(height: spacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      CheckoutStrings.leftToPay,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.textColors.primary,
                      ),
                    ),
                  ),
                  PriceText(amount: due),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _Consequence extends StatelessWidget {
  const _Consequence({required this.label, this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.textColors.secondary,
          ),
        ),
      ),
      if (value != null)
        Text(
          value!,
          style: context.textTheme.labelSmall?.copyWith(
            color: context.statusColors.success,
            fontWeight: FontWeight.w700,
          ),
        ),
    ],
  );
}

/// «رصيد تيراكوتا», and how much of it there is.
class ProfileWalletLabel {
  ProfileWalletLabel._();

  static String of(BuildContext context) => WorkshopStrings.walletBalance;

  static String have(String balance) =>
      '${PriceText.format(balance)} ${HomeStrings.currency}';
}
