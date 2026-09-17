import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/error/app_exception.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/extensions/theme_colors_extension.dart';
import '../../../core/localization/strings/auth_strings.dart';
import '../../../core/localization/strings/checkout_strings.dart';
import '../../../core/localization/strings/delivery_strings.dart';
import '../../../core/tokens/extensions.dart';
import '../../../core/types/result.dart';
import '../../../data/api/calls/address_apis.dart';
import '../../../data/models/terracotta/account/address.dart';
import '../../../shared/module/buttons/global_filled_button.dart';
import '../../../shared/module/image/global_image.dart';
import '../../../shared/module/scrollable/global_scrollable.dart';
import '../../../shared/module/toast/global_toast.dart';
import '../../_shared/screen_entrance.dart';
import '../../_shared/terracotta_cta_style.dart';
import '../../_shared/terracotta_page_bar.dart';
import '../../_shared/terracotta_widgets.dart';
import '../../profile/cubits/addresses_cubit.dart';
import '../../profile/cubits/wallet_cubit.dart';
import '../../profile/cubits/wallet_state.dart';
import '../../workshops/widgets/booking_card.dart';
import '../cubits/delivery_checkout_cubit.dart';
import '../widgets/checkout_widgets.dart';
import '../widgets/wallet_toggle.dart';

/// «الدفع» for delivering a finished piece.
///
/// Charged only when the customer chooses delivery over pickup — and
/// only the FIRST time: switching to pickup and back is free, and the
/// fee already applied is never refunded.
///
/// `GET /api/workshops/bookings/{id}/delivery/quote` with an
/// `address_id` gives the real fee. The workshop endpoint deliberately
/// returns `has_delivery` as a boolean and NO price, because the price
/// depends on the customer's city — which is why the address is chosen
/// before this page opens.
///
/// `make_your_candle` has no delivery step at all: the candle goes home
/// the same day, and calling these endpoints on one is a 422.
class DeliveryCheckoutPage extends StatefulWidget {
  const DeliveryCheckoutPage({
    this.bookingId,
    this.address,
    this.fetchAddresses,
    this.cubit,
    super.key,
  });

  /// The booking whose piece is being delivered. Null after a hot
  /// restart, where a path parameter does survive but the page can be
  /// built without one in a test.
  final String? bookingId;

  /// The address the customer picked in the sheet. Its `delivery_fee`
  /// is what this page charges.
  final Address? address;

  /// Injectable, so a test can render the page without a network —
  /// the fetch below leaves a request timer pending after the tree is
  /// disposed otherwise, which is a test failure and not a warning.
  final AddressesFetch? fetchAddresses;

  /// A cubit to use instead of making one — the seam a widget test
  /// needs, since the page quotes on mount.
  final DeliveryCheckoutCubit? cubit;

  @override
  State<DeliveryCheckoutPage> createState() => _DeliveryCheckoutPageState();
}

class _DeliveryCheckoutPageState extends State<DeliveryCheckoutPage> {
  late final _checkout =
      widget.cubit ??
      DeliveryCheckoutCubit(
        bookingId: widget.bookingId ?? '0',
        address: widget.address,
      );

  /// The balance the toggle offers to spend. The QUOTE says how much of
  /// it this fee takes; the purse says how much there is.
  late final _wallet = getIt<WalletCubit>();

  @override
  void initState() {
    super.initState();
    unawaited(_checkout.load());
    unawaited(_wallet.ensureLoaded());
    // A hot restart drops the route's `extra`, and a delivery page that
    // cannot say where it is delivering to is a page asking for money
    // without saying what for. The DEFAULT address stands in, and the
    // quote is re-asked against it.
    if (widget.address == null) unawaited(_loadDefault());
  }

  @override
  void dispose() {
    // Only what this page MADE.
    if (widget.cubit == null) unawaited(_checkout.close());
    super.dispose();
  }

  Future<void> _loadDefault() async {
    final fetch = widget.fetchAddresses ?? AddressApis.getAddresses;
    if (await fetch() case Success(:final value)) {
      if (!mounted || value.isEmpty) return;
      final fallback =
          value.where((a) => a.isDefault).firstOrNull ?? value.first;
      _checkout.selectAddress(fallback);
    }
  }

  /// CHOOSE, which is also the settle — there is no `delivery/pay`.
  Future<void> _confirm() async {
    final booking = await _checkout.confirm();
    if (!mounted) return;
    if (booking == null) {
      GlobalToast.error(
        _checkout.state.error?.spokenMessage ?? AuthStrings.errorGeneric,
      );
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<DeliveryCheckoutCubit, DeliveryCheckoutState>(
        bloc: _checkout,
        builder: _body,
      );

  Widget _body(BuildContext context, DeliveryCheckoutState state) {
    final spacing = context.spacing;
    // The piece came out of a pottery workshop, so the flow keeps that
    // family's colour the whole way — same as the booking checkout.
    final fam = WorkshopFamilyColors.resolve(
      family: WorkshopFamily.makeYourPiece,
      isDark: context.isDarkMode,
    );
    final address = state.address;

    return Scaffold(
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
            // STAGGERED as the page settles — the rows arrive one after
            // another rather than the whole block appearing at once.
            children: ScreenEntrance.stage([
              SizedBox(height: spacing.md),
              // The same card the booking wears, so the customer
              // recognises what they are paying for.
              BookingCard(
                title: DeliveryStrings.feeLine,
                meta: address == null
                    ? ''
                    : '${address.deliveryZone} · ${address.street}',
                price: state.fee,
              ),
              SizedBox(height: spacing.md),
              _Line(label: DeliveryStrings.feeLine, amount: state.fee),
              SizedBox(height: spacing.md),
              PaymentMethodRow(
                selected: state.method,
                onSelect: _checkout.selectMethod,
              ),
              SizedBox(height: spacing.md),
              // The BALANCE is the wallet's own; how much of it this fee
              // takes, and what is left, are the quote's. Neither is
              // worked out here.
              BlocBuilder<WalletCubit, WalletState>(
                bloc: _wallet,
                builder: (context, purse) => WalletToggle(
                  balance: purse.balance ?? '0.00',
                  applied: state.walletApplied,
                  due: state.amountDue,
                  enabled: state.useWallet,
                  onChanged: _checkout.toggleWallet,
                ),
              ),
              // «الملخص». No discount line and no code field: the
              // delivery quote takes `use_wallet` and `address_id` and
              // nothing else, which is the wire saying what the
              // contract says in words — a promo comes off the goods
              // and never off the delivery.
              if (state.quote case final priced?) ...[
                SizedBox(height: spacing.md),
                QuoteBreakdown(
                  deliveryFee: priced.deliveryFee ?? state.fee,
                  vatRate: priced.vatRate,
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
      // PINNED, like every other checkout: a confirm button at the foot
      // of a scrolling summary is one the customer goes looking for.
      bottomNavigationBar: Material(
        color: context.backgroundColors.scaffoldBackground,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: spacing.md,
              vertical: spacing.sm,
            ),
            child: GlobalFilledButton(
              text: DeliveryStrings.confirmAndPay,
              // ALREADY PAID is not a second charge: the fee is taken
              // once, and switching to pickup and back is free.
              enabled: state.canSubmit,
              isLoading: state.paying,
              onPressed: () => unawaited(_confirm()),
              // The chosen wallet's own mark in the arrow's slot, so
              // the button says which of the three above it charges.
              style: terracottaCtaStyle(showArrow: false).copyWith(
                backgroundColor: fam.primary,
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
    );
  }
}

/// One priced line.
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
