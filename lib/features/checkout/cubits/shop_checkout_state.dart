import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/account/address.dart';
import '../../../data/models/terracotta/commerce/order.dart';
import '../../../data/models/terracotta/content/discount_code.dart';
import '../../../data/models/terracotta/core/price_quote.dart';

/// «الدفع» for a shop order — everything the server needs to be asked,
/// and everything it answered.
///
/// **The total is the SERVER's.** `POST /api/shop/cart/quote` applies
/// the discount to the goods subtotal, adds the delivery fee on top (a
/// promo never discounts delivery), then lets the wallet cover what it
/// can — in that order. Nothing here is summed on this side, because
/// anything summed here would disagree with what is charged.
@immutable
class ShopCheckoutState {
  const ShopCheckoutState({
    this.addresses = const [],
    this.addressId,
    this.quote,
    this.codes = const [],
    this.discountCode,
    this.discountError,
    this.useWallet = false,
    this.method = 0,
    this.order,
    this.loading = true,
    this.quoting = false,
    this.placing = false,
    this.openOrder = false,
    this.error,
  });

  /// The customer's saved addresses. The delivery FEE comes from the
  /// chosen one's city, so this is a price input and not decoration.
  final List<Address> addresses;

  /// Which one it is going to. Null until they are loaded, and on an
  /// account with none saved.
  final int? addressId;

  /// The server's answer. Null before the first one comes back.
  final PriceQuote? quote;

  /// What the hold created, once it has. Kept so a failed settle is
  /// retried against the SAME order rather than making a second one —
  /// which the server would refuse anyway.
  final Order? order;

  /// The codes worth OFFERING — public, live, and with room left for
  /// this customer. The server does that filtering; an empty list means
  /// there is nothing to advertise, not that codes do not exist.
  final List<DiscountCode> codes;

  /// The code the customer typed and the server ACCEPTED. Cleared when
  /// it is rejected, so a bad code never travels with the order.
  final String? discountCode;

  /// Why the last code was refused, keyed to the field it was typed in.
  final String? discountError;

  final bool useWallet;

  /// Which of the three wallets is selected — an index into
  /// `PaymentMethodRow.brands`.
  final int method;

  /// The FIRST load, which has nothing to show.
  final bool loading;

  /// A re-quote — a code applied, the wallet toggled, the address
  /// changed. The figures on screen stay while it runs.
  final bool quoting;

  /// The HOLD and the SETTLE, which are one press to the customer.
  final bool placing;

  /// The server refused because there is ALREADY an order awaiting
  /// payment. One at a time is its rule, and the way out is the order
  /// that is open, not a retry — so this is told apart from every other
  /// failure and answered with somewhere to go.
  final bool openOrder;

  final AppException? error;

  Address? get address => addresses.where((a) => a.id == addressId).firstOrNull;

  /// Whether the order can be placed. The server settles in ONE step
  /// when `amount_due` is `"0.00"` — the wallet or a full discount
  /// covered it — so that is not a reason to hold the button.
  bool get canSubmit => quote != null && !quoting && !loading && !placing;

  ShopCheckoutState copyWith({
    List<Address>? addresses,
    List<DiscountCode>? codes,
    int? addressId,
    PriceQuote? quote,
    Order? order,
    String? discountCode,
    String? discountError,
    bool clearDiscountCode = false,
    bool clearDiscountError = false,
    bool? useWallet,
    int? method,
    bool? loading,
    bool? quoting,
    bool? placing,
    bool? openOrder,
    AppException? error,
    bool clearError = false,
  }) => ShopCheckoutState(
    addresses: addresses ?? this.addresses,
    codes: codes ?? this.codes,
    addressId: addressId ?? this.addressId,
    quote: quote ?? this.quote,
    order: order ?? this.order,
    discountCode: clearDiscountCode ? null : discountCode ?? this.discountCode,
    discountError: clearDiscountError
        ? null
        : discountError ?? this.discountError,
    useWallet: useWallet ?? this.useWallet,
    method: method ?? this.method,
    loading: loading ?? this.loading,
    quoting: quoting ?? this.quoting,
    placing: placing ?? this.placing,
    openOrder: openOrder ?? this.openOrder,
    error: clearError ? null : error ?? this.error,
  );
}
