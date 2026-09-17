import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/assets/assets.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/checkout_strings.dart';
import '../../../core/localization/strings/gift_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/image/global_image.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../gift/data/gift_draft.dart';
import '../../gift/widgets/gift_hero_card.dart';
import '../../profile/cubits/wallet_cubit.dart';
import '../../profile/cubits/wallet_state.dart';
import '../cubits/gift_checkout_cubit.dart';
import '../widgets/checkout_widgets.dart';
import '../widgets/wallet_toggle.dart';

/// «الدفع» for a gift.
///
/// `POST /api/gifts/quote` → `POST /api/gifts` →
/// `POST /api/gifts/{id}/pay`.
///
/// Built on the booking checkout's anatomy — hero, one line per thing
/// being bought, the wallets, the balance, a pinned bar — because the
/// design draws them as the same screen. What differs is that there is
/// nothing to configure here: the amount is admin-set and the note was
/// written on the sheet, so this page only takes payment.
///
/// **The buyer's discount does not change the gift's face value.** A
/// 200 gift bought for 180 still credits the recipient 200 — so the
/// breakdown here is about what the BUYER pays, and the gift amount
/// shown to the recipient is a separate number.
///
/// Gifts carry no VAT on purchase; the tax lands on whatever the wallet
/// is later spent on.
///
/// Bound to [GiftCheckoutCubit]: the face value is the studio's, every
/// other figure is the quote's, and the button holds then settles.
class GiftCheckoutPage extends StatefulWidget {
  const GiftCheckoutPage({this.draft, this.cubit, super.key});

  /// What the sheet collected. Null after a hot restart, where a route
  /// extra does not survive — and the CTA refuses then, because a gift
  /// needs a name on it.
  final GiftDraft? draft;

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page quotes on mount. Null in the app.
  final GiftCheckoutCubit? cubit;

  @override
  State<GiftCheckoutPage> createState() => _GiftCheckoutPageState();
}

class _GiftCheckoutPageState extends State<GiftCheckoutPage> {
  late final _checkout =
      (widget.cubit ?? GiftCheckoutCubit(draft: widget.draft))..load();

  /// The BALANCE the toggle offers to spend. What this purchase takes
  /// off it is the quote's answer, not a subtraction done here.
  late final _wallet = getIt<WalletCubit>()..ensureLoaded();

  @override
  void dispose() {
    // Only what this page MADE.
    if (widget.cubit == null) unawaited(_checkout.close());
    super.dispose();
  }

  /// HOLD, then SETTLE — one press, and only one call when the wallet
  /// already covered it.
  Future<void> _confirm() async {
    final gift = await _checkout.confirm();
    if (!mounted) return;

    if (gift == null) {
      // `message` REFUSES HTML rather than stripping it, and the
      // sentence saying so sits under that key — the envelope's own
      // message is boilerplate. There is no box on this screen to put
      // it under, so it is said here.
      GlobalToast.error(
        _checkout.state.error?.spokenMessage ?? AuthStrings.errorGeneric,
      );
      return;
    }
    context.pushNamed('gift-purchased');
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final coral = context.primaryColors.accent;

    return BlocBuilder<GiftCheckoutCubit, GiftCheckoutState>(
      bloc: _checkout,
      builder: (context, quote) => Scaffold(
        backgroundColor: context.backgroundColors.scaffoldBackground,
        appBar: TerracottaPageBar(
          title: CheckoutStrings.title,
          pinned: true,
        ),
        body: GlobalScrollable(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              // STAGGERED as the page settles.
              //
              // The pinned CTA at the foot is NOT in here: a hero
              // flies it between the steps of this flow, and an
              // entrance replaying on top of a landed flight is the
              // thing `ScreenEntrance` stands down for.
              children: ScreenEntrance.stage([
                SizedBox(height: spacing.md),
                // The same card the sheet was headed by — the customer is
                // paying for the thing they were just reading about.
                GiftHeroCard(amount: quote.faceValue),
                SizedBox(height: spacing.md),
                _Line(
                  // The label says the same money the row's own price
                  // does, so it is formatted the same way — «٢٠٠ ريال»,
                  // not «200.00».
                  label: GiftStrings.amount(
                    '${PriceText.format(quote.faceValue)} '
                    '${HomeStrings.currency}',
                  ),
                  // The FACE VALUE is what the recipient is credited;
                  // the figure beside it is what the BUYER is charged,
                  // and a discount moves only the second.
                  amount: quote.quote?.totalPrice ?? quote.faceValue,
                ),
                SizedBox(height: spacing.md),
                // THE PROMO CODE. `POST /api/gifts/quote` takes
                // `discount_code`, and it moves what the BUYER pays
                // without touching the face value the recipient is
                // credited — so a code makes a gift cheaper to give
                // and no smaller to receive.
                // Nothing advertised, nothing drawn — see
                // [DiscountCodeList].
                if (quote.codes.isNotEmpty) ...[
                  DiscountCodeField(
                    applied: quote.discountCode,
                    error: quote.discountError,
                    // THE GIFT'S OWN CORAL, like the hero card at the
                    // head of this flow and the sheet it came from.
                    tint: context.primaryColors.accent,
                    onApply: _checkout.applyDiscount,
                  ),
                  SizedBox(height: spacing.sm),
                  DiscountCodeList(
                    codes: quote.codes,
                    applied: quote.discountCode,
                    tint: context.primaryColors.accent,
                    onPick: _checkout.applyDiscount,
                  ),
                  SizedBox(height: spacing.md),
                ],
                PaymentMethodRow(
                  selected: quote.method,
                  tint: context.primaryColors.accent,
                  onSelect: _checkout.selectMethod,
                ),
                SizedBox(height: spacing.md),
                BlocBuilder<WalletCubit, WalletState>(
                  bloc: _wallet,
                  builder: (context, purse) => WalletToggle(
                    balance: purse.balance ?? '0.00',
                    applied: quote.quote?.walletApplied ?? '0.00',
                    due: quote.quote?.amountDue ?? '0.00',
                    enabled: quote.useWallet,
                    onChanged: _checkout.toggleWallet,
                  ),
                ),
                // «الملخص» — the buyer's side of it, every figure the
                // server's own.
                if (quote.quote case final priced?) ...[
                  SizedBox(height: spacing.md),
                  QuoteBreakdown(
                    subtotal: priced.subtotal,
                    discount: priced.discountAmount,
                    total: priced.totalPrice,
                    walletApplied: priced.walletApplied,
                    amountDue: priced.amountDue,
                  ),
                ],
                SizedBox(height: spacing.xxl),
              ]),
            ),
          ),
        ),
        bottomNavigationBar: Material(
          color: context.backgroundColors.scaffoldBackground,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                spacing.md,
                spacing.sm,
                spacing.md,
                spacing.sm,
              ),
              child: GlobalFilledButton(
                text: GiftStrings.confirmAndPay,
                enabled: quote.canSubmit,
                isLoading: quote.paying,
                onPressed: () => unawaited(_confirm()),
                // Coral, not the brand's brown: gifting is the one flow
                // in the app the design colours, and the bar has to
                // belong to the card above it.
                //
                // The studio's OWN gift glyph leads — the same one on the
                // tile that opened this flow, not a Material lookalike —
                // and the chosen wallet's mark rides in the arrow's slot,
                // so the bar says both what it buys and what it charges.
                style: terracottaCtaStyle(showArrow: false).copyWith(
                  backgroundColor: coral,
                  leading: _Mark(
                    asset: Assets.icons.gift.defaultPath,
                    height: 20,
                  ),
                  trailing: _Mark(
                    asset: PaymentMethodRow.brands[quote.method],
                    height: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single-colour SVG in one of the CTA's slots.
class _Mark extends StatelessWidget {
  const _Mark({required this.asset, required this.height});

  final String asset;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: GlobalImage.a(
      asset,
      placeholder: const SizedBox.shrink(),
      style: ImageStyle(
        fit: BoxFit.contain,
        borderRadius: BorderRadius.zero,
        color: context.textColors.onPrimary,
        overlayBlendMode: BlendMode.srcIn,
      ),
    ),
  );
}

/// One row of the breakdown: what it is, and what it costs.
class _Line extends StatelessWidget {
  const _Line({required this.label, required this.amount});

  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) => TerracottaCard(
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.textColors.primary,
            ),
          ),
        ),
        PriceText(amount: amount),
      ],
    ),
  );
}
