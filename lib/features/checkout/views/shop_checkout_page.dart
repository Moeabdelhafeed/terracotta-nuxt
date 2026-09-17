import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/account_scope.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/checkout_strings.dart';
import '../../../core/localization/strings/common_strings.dart';
import '../../../core/localization/strings/delivery_strings.dart';
import '../../../core/localization/strings/home_strings.dart';
import '../../../core/localization/strings/profile_strings.dart';
import '../../../core/localization/strings/shop_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../data/models/terracotta/commerce/cart_item.dart';
import '../../../data/models/terracotta/core/price_quote.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/empty_state/global_empty_state.dart';
import '../../../shared/module/image/global_image.dart';
import '../../../shared/module/refreshable/global_refreshable.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_image.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../cart/cubits/cart_cubit.dart';
import '../../cart/cubits/cart_state.dart';
import '../../delivery/widgets/delivery_details_sheet.dart';
import '../../profile/cubits/wallet_cubit.dart';
import '../../profile/cubits/wallet_state.dart';
import '../cubits/shop_checkout_cubit.dart';
import '../cubits/shop_checkout_state.dart';
import '../widgets/checkout_widgets.dart';
import '../widgets/wallet_toggle.dart';

/// «الدفع» for a shop order.
///
/// `POST /api/shop/cart/quote` → `POST /api/shop/cart/checkout` →
/// `POST /api/shop/orders/{id}/pay`.
///
/// **Every figure on this page is the server's.** The quote applies the
/// discount to the goods subtotal, adds the delivery fee on top and
/// then lets the wallet cover what it can, in that order — so the page
/// asks again after any change rather than doing that arithmetic
/// itself. The party's own words: it "returns the same numbers,
/// computed the same way, that checkout will charge".
///
/// The delivery fee comes from the ADDRESS's city (`delivery_zone_id`),
/// not from the map pin — the pin is for the driver and does not affect
/// price. A discount code never reduces the delivery fee, and the
/// free-delivery threshold is measured on the POST-discount goods
/// total, so a promo cannot tip an order into free delivery it did not
/// earn.
///
/// `vat_amount` is the VAT ALREADY INSIDE `total_price`, never an
/// addition — and both it and `vat_rate` are `"0.00"` when the studio
/// is not VAT-registered, which is when the line is not drawn at all.
class ShopCheckoutPage extends StatefulWidget {
  const ShopCheckoutPage({this.cubit, this.cart, super.key});

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page quotes on mount. Null in the app.
  final ShopCheckoutCubit? cubit;

  /// The app's cart. Null in the app, where it comes from `getIt`.
  final CartCubit? cart;

  @override
  State<ShopCheckoutPage> createState() => _ShopCheckoutPageState();
}

class _ShopCheckoutPageState extends State<ShopCheckoutPage> {
  late final _checkout = (widget.cubit ?? ShopCheckoutCubit())..load();
  late final _cart = widget.cart ?? getIt<CartCubit>();

  /// The BALANCE the toggle offers to spend.
  late final _wallet = getIt<WalletCubit>()..ensureLoaded();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The lines on this page are the CART's, and a cart line carries
    // the product's server-written name — so a language switch has to
    // re-ask for them here too, not only where the cart was opened.
    unawaited(
      _cart.ensureLoaded(Localizations.localeOf(context).languageCode),
    );
  }

  @override
  void dispose() {
    // Only what this page MADE. The cart is the app's and outlives it.
    if (widget.cubit == null) unawaited(_checkout.close());
    super.dispose();
  }

  /// HOLD, then SETTLE — one press to the customer, two calls to the
  /// server, and only one of them when the wallet already covered it.
  ///
  /// The cart is emptied by the PAY step, not by the hold, so backing
  /// out of a failed payment does not lose it.
  /// Whether «تاكيد الطلب» was pressed with no address chosen. Shown
  /// on the ROW, not only as a toast — a toast names the problem and
  /// then goes away, and the reader is left looking at a page with
  /// nothing marked on it.
  bool _addressMissing = false;

  Future<void> _confirm() async {
    // ASKED FOR HERE, before the server is troubled with it. The row
    // is what has to change, and only this page knows where the row
    // is.
    if (_checkout.state.addressId == null) {
      setState(() => _addressMissing = true);
      GlobalToast.error(CheckoutStrings.addressRequired);
      return;
    }
    if (_addressMissing) setState(() => _addressMissing = false);

    final order = await _checkout.confirm();
    if (!mounted) return;

    if (order == null) {
      // ONE OPEN ORDER AT A TIME. A retry cannot satisfy that rule, so
      // the customer is sent to the order that is already open rather
      // than told to press the same button again.
      if (_checkout.state.openOrder) {
        GlobalToast.error(CheckoutStrings.openOrder);
        // PUSHED on top of the checkout, not replacing it: this one is
        // a detour to look at the order already open, and the reader
        // may well want to come back.
        context.pushNamed('my-orders');
        return;
      }
      GlobalToast.error(
        _checkout.state.error?.spokenMessage ?? AuthStrings.errorGeneric,
      );
      return;
    }

    // The cart is the server's now — it was emptied by the pay call.
    unawaited(_cart.load());
    // And there is an order to chase that was not there before — the
    // live strip reads a singleton that would otherwise not re-ask
    // until the app was restarted.
    AccountScope.ownedChanged();
    // «تم تأكيد طلبك !» FIRST, and the order after it.
    //
    // This used to land straight on «طلباتي» — a list that looked no
    // different from the one before the money moved, with nothing on
    // it saying the payment had worked. The booking flow has had its
    // celebration since it was built; this is the same screen, and its
    // one control opens the order that was just paid for.
    context.pushNamed(
      'order-confirmed',
      pathParameters: {'orderId': '${order.id}'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Scaffold(
      backgroundColor: context.backgroundColors.scaffoldBackground,
      appBar: TerracottaPageBar(
        title: CheckoutStrings.title,
        pinned: true,
      ),
      body: BlocBuilder<ShopCheckoutCubit, ShopCheckoutState>(
        bloc: _checkout,
        builder: (context, state) => GlobalRefreshable(
          onRefresh: _checkout.refresh,
          child: GlobalScrollable(
            // The CALLER has to ask, or a page shorter than the
            // viewport drops the drag recogniser.
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
                  BlocBuilder<CartCubit, CartState>(
                    bloc: _cart,
                    builder: (context, cart) => _Lines(
                      items: cart.cart?.items ?? const [],
                    ),
                  ),
                  // What the studio is advertising, and only what this
                  // customer can still use — the server drops a code
                  // whose limit is spent, so a row here is a code that
                  // works. Nothing advertised, nothing drawn: see
                  // [DiscountCodeList].
                  if (state.codes.isNotEmpty) ...[
                    SizedBox(height: spacing.md),
                    DiscountCodeField(
                      applied: state.discountCode,
                      error: state.discountError,
                      onApply: _checkout.applyDiscount,
                    ),
                    SizedBox(height: spacing.sm),
                    DiscountCodeList(
                      codes: state.codes,
                      applied: state.discountCode,
                      onPick: _checkout.applyDiscount,
                    ),
                  ],
                  SizedBox(height: spacing.md),
                  _AddressRow(
                    state: state,
                    missing: _addressMissing,
                    onChange: () => unawaited(
                      showDeliveryDetailsSheet(
                        context,
                        onConfirm: (address) {
                          if (_addressMissing) {
                            setState(() => _addressMissing = false);
                          }
                          _checkout.selectAddress(address);
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: spacing.md),
                  if (state.quote case final quote?) ...[
                    // The BALANCE is the wallet's own; how much of it
                    // this order takes, and what is left, are the
                    // quote's. Neither is worked out here.
                    BlocBuilder<WalletCubit, WalletState>(
                      bloc: _wallet,
                      builder: (context, purse) => WalletToggle(
                        balance: purse.balance ?? '0.00',
                        applied: quote.walletApplied,
                        due: quote.amountDue,
                        enabled: state.useWallet,
                        onChanged: _checkout.toggleWallet,
                      ),
                    ),
                    SizedBox(height: spacing.md),
                    _Breakdown(quote: quote, quoting: state.quoting),
                  ] else
                    _QuoteState(state: state),
                  SizedBox(height: spacing.md),
                  PaymentMethodRow(
                    selected: state.method,
                    onSelect: _checkout.selectMethod,
                  ),
                  SizedBox(height: spacing.xxl),
                ]),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: BlocBuilder<ShopCheckoutCubit, ShopCheckoutState>(
        bloc: _checkout,
        builder: (context, state) => Material(
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
                text: ShopStrings.checkout,
                enabled: state.canSubmit,
                isLoading: state.quoting || state.placing,
                onPressed: () => unawaited(_confirm()),
                // The chosen wallet's own mark in the arrow's slot, so
                // the bar says which of the three above it will charge.
                style: terracottaCtaStyle(showArrow: false).copyWith(
                  trailing: SizedBox(
                    height: 18,
                    child: GlobalImage.a(
                      PaymentMethodRow.brands[state.method],
                      placeholder: const SizedBox.shrink(),
                      style: ImageStyle(
                        fit: BoxFit.contain,
                        borderRadius: BorderRadius.zero,
                        color: context.textColors.onPrimary,
                        overlayBlendMode: BlendMode.srcIn,
                      ),
                    ),
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

/// What is being bought, one row per line.
class _Lines extends StatelessWidget {
  const _Lines({required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    if (items.isEmpty) {
      return GlobalEmptyState(
        icon: Icons.shopping_bag_outlined,
        title: ShopStrings.cartEmpty,
        variant: EmptyStateVariant.compact,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items) ...[
          _OrderLine(item: item),
          SizedBox(height: spacing.sm),
        ],
        SizedBox(height: spacing.xs),
        _ItemTotals(items: items),
      ],
    );
  }
}

/// One thing being bought, as the design draws it: the photograph at
/// the reading start, the words beside it, and the count at the foot.
///
/// The shop's own row, not a receipt line — the customer is looking at
/// what they chose, and «مميز» is part of why they chose it. What it
/// COMES TO is the breakdown's job, below.
class _OrderLine extends StatelessWidget {
  const _OrderLine({required this.item});

  final CartItem item;

  /// The row's height comes from the picture.
  static const _imageBox = 132.0;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return TerracottaCard(
      bordered: true,
      padding: EdgeInsets.all(spacing.xs),
      // START, not stretch. The card sits in a scrolling column, where
      // stretch has no height to stretch TO and the row resolves to
      // infinity — the picture's own box is what sets the height, and
      // the words are given the same box so their footer can sit at
      // the bottom of it.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(context.radii.sm),
            child: SizedBox(
              width: _imageBox,
              height: _imageBox,
              child: TerracottaImage(image: item.product.image),
            ),
          ),
          SizedBox(width: spacing.md),
          Expanded(
            child: SizedBox(
              height: _imageBox,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: spacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleLarge?.copyWith(
                        color: context.textColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: spacing.xs),
                    // The UNIT price. A sale price struck through beside
                    // the live one, the same treatment the shop gives it.
                    PriceText(
                      amount: item.unitPrice,
                      was: item.product.salePrice == null
                          ? null
                          : item.product.price,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          // «عدد ٢» — the same badge the catalogue screen
                          // counts a piece with.
                          CommonStrings.count(item.quantity),
                          style: context.textTheme.labelLarge?.copyWith(
                            color: context.primaryColors.primary,
                          ),
                        ),
                        const Spacer(),
                        if (item.product.isFeatured) const _FeaturedTag(),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: spacing.xs),
        ],
      ),
    );
  }
}

/// «مميز».
class _FeaturedTag extends StatelessWidget {
  const _FeaturedTag();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.primaryColors.primary,
      borderRadius: BorderRadius.circular(context.radii.sm),
    ),
    child: Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: context.spacing.sm,
        vertical: 4,
      ),
      child: Text(
        HomeStrings.badgeFeatured,
        style: context.textTheme.labelSmall?.copyWith(
          color: context.textColors.onPrimary,
        ),
      ),
    ),
  );
}

/// «كوب تيراكوتا × ٥ — ٤٠٠ ريال» — what each line COMES TO.
///
/// Separate from the cards above, as the design draws it: the cards are
/// what was chosen, this is the arithmetic. The figure is the server's
/// `line_total` — quantity times unit price is a sum nobody here needs
/// to do.
class _ItemTotals extends StatelessWidget {
  const _ItemTotals({required this.items});

  final List<CartItem> items;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return TerracottaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, item) in items.indexed) ...[
            if (i > 0) ...[
              SizedBox(height: spacing.sm),
              Divider(color: context.primaryColors.border, height: 1),
              SizedBox(height: spacing.sm),
            ],
            _Row(
              label: '${item.product.title} × ${item.quantity}',
              amount: item.lineTotal,
            ),
          ],
        ],
      ),
    );
  }
}

/// Where it is going — and the city that sets the fee.
class _AddressRow extends StatelessWidget {
  const _AddressRow({
    required this.state,
    required this.onChange,
    this.missing = false,
  });

  final ShopCheckoutState state;
  final VoidCallback onChange;

  /// Pay was pressed with nothing chosen. The row wears the error ramp
  /// and says so underneath.
  final bool missing;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    final address = state.address;
    final error = context.statusColors.error;

    return TerracottaCard(
      onTap: onChange,
      borderColor: missing ? error : null,
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            color: context.primaryColors.primary,
            size: context.iconSizes.sm,
          ),
          SizedBox(width: spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address == null
                      ? ProfileStrings.addresses
                      : '${address.deliveryZone} · ${address.street}',
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.textColors.primary,
                  ),
                ),
                if (address == null) ...[
                  SizedBox(height: spacing.xs),
                  Text(
                    missing
                        ? CheckoutStrings.addressRequired
                        : DeliveryStrings.changeAddress,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: missing ? error : context.textColors.secondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_rounded,
            size: context.iconSizes.sm,
            color: context.iconColors.primary,
          ),
        ],
      ),
    );
  }
}

/// Subtotal, discount, delivery, VAT and the total — all of them the
/// server's.
class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.quote, required this.quoting});

  final PriceQuote quote;

  /// Dimmed while a fresh answer is on its way, rather than blanked: a
  /// total that vanishes on every keystroke reads as a broken page.
  final bool quoting;

  bool get _hasDiscount => quote.discountAmount != '0.00';
  bool get _hasVat => (quote.vatAmount ?? '0.00') != '0.00';

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;

    return Opacity(
      opacity: quoting ? 0.5 : 1,
      child: TerracottaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Row(label: CheckoutStrings.subtotal, amount: quote.subtotal),
            if (_hasDiscount) ...[
              SizedBox(height: spacing.sm),
              _Row(
                label: CheckoutStrings.discount,
                amount: quote.discountAmount,
                // The one line that comes OFF, so it is signed and
                // tinted rather than reading as another charge.
                negative: true,
              ),
            ],
            if (quote.deliveryFee case final fee?) ...[
              SizedBox(height: spacing.sm),
              _Row(label: CheckoutStrings.deliveryFee, amount: fee),
            ],
            SizedBox(height: spacing.sm),
            Divider(color: context.primaryColors.border, height: 1),
            SizedBox(height: spacing.sm),
            _Row(
              label: CheckoutStrings.total,
              amount: quote.totalPrice,
              strong: true,
            ),
            if (_hasVat) ...[
              SizedBox(height: spacing.xs),
              Text(
                // INSIDE the total, never added to it — and the rate is
                // read from the answer rather than hardcoded, because
                // the studio sets it.
                // «١٥», not «15.00» — the rate is a decimal string
                // like every other number on this payload.
                CheckoutStrings.vat(
                  PriceText.format(quote.vatRate ?? '0'),
                ),
                textAlign: TextAlign.end,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.textColors.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.amount,
    this.strong = false,
    this.negative = false,
  });

  final String label;
  final String amount;
  final bool strong;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final style = strong
        ? context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : context.textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: style?.copyWith(color: context.textColors.primary),
          ),
        ),
        Text(
          '${negative ? '−' : ''}${PriceText.format(amount)} '
          '${HomeStrings.currency}',
          style: style?.copyWith(
            color: negative
                ? context.statusColors.success
                : context.textColors.primary,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Waiting for the first quote, or saying why there is none.
class _QuoteState extends StatelessWidget {
  const _QuoteState({required this.state});

  final ShopCheckoutState state;

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    return GlobalEmptyState(
      icon: Icons.wifi_off_rounded,
      title: AuthStrings.errorGeneric,
      variant: EmptyStateVariant.compact,
    );
  }
}
