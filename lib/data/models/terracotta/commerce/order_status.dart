/// Where a shop order is in its lifecycle — the `status` string of
/// `GET /api/shop/orders`, `GET /api/shop/orders/{order}` and
/// `POST /api/shop/cart/checkout`.
///
/// The happy path is linear, and the values below are declared in that
/// order so `index` can drive a stepper:
///
/// ```text
/// awaitingPayment -> pending -> preparing -> outForDelivery -> completed
///                                   \
///                                    `-> cancelled  (off-flow, any time
///                                        the server still allows it)
/// ```
///
/// - [awaitingPayment] — created but not paid. The order holds a
///   `payment_expires_at`; miss it and the server drops the order.
///   Note this value is NOT in the published OpenAPI spec (which
///   documents checkout as starting at `pending`) — the live server
///   returns it. That divergence is the whole reason [fromWire] must
///   not throw.
/// - [pending] — paid, waiting for the studio to pick it up.
/// - [preparing] — being packed. Still cancellable per the API docs
///   (`DELETE /api/shop/orders/{order}` allows `pending` or
///   `preparing`), but trust the order's own `can_cancel` flag over
///   this enum — the server owns that decision.
/// - [outForDelivery] — with the courier. No longer cancellable.
/// - [completed] — delivered. Terminal.
/// - [cancelled] — cancelled by the customer or the studio; any wallet
///   amount applied at checkout is refunded. Terminal.
/// - [unknown] — NOT a server value. It is what [fromWire] returns for
///   a string this build has never heard of, so a CMS that adds
///   `refunded` next month shows an unstyled chip instead of crashing
///   a shipped app.
///
/// Serialization is explicit on purpose: annotate the field with
/// `@JsonKey(fromJson: OrderStatus.fromWire, toJson: OrderStatus.toWire)`.
/// There are deliberately no `@JsonValue` annotations, so forgetting
/// that annotation fails loudly at BUILD time rather than quietly
/// generating a decoder that throws on an unknown status in a
/// customer's hands.
enum OrderStatus {
  /// `"awaiting_payment"` — created, unpaid, on a payment clock.
  awaitingPayment('awaiting_payment'),

  /// `"pending"` — paid, not yet picked up by the studio.
  pending('pending'),

  /// `"preparing"` — being packed.
  preparing('preparing'),

  /// `"out_for_delivery"` — with the courier.
  outForDelivery('out_for_delivery'),

  /// `"completed"` — delivered. Terminal.
  completed('completed'),

  /// `"cancelled"` — cancelled, wallet refunded. Terminal.
  cancelled('cancelled'),

  /// Fallback for a status this build does not know. Never sent by the
  /// server, never sent back to it in a filter.
  unknown('unknown');

  const OrderStatus(this.wire);

  /// The exact string the API uses. Send this, not [name].
  final String wire;

  /// Decode a server status without ever throwing.
  ///
  /// Anything unrecognised — a new CMS value, a null, a typo — maps to
  /// [unknown]. Use it as `@JsonKey(fromJson: OrderStatus.fromWire)`.
  static OrderStatus fromWire(String? wire) {
    for (final status in OrderStatus.values) {
      if (status.wire == wire) return status;
    }
    return OrderStatus.unknown;
  }

  /// Encode back to the wire string. Pair with [fromWire] via
  /// `@JsonKey(toJson: OrderStatus.toWire)`.
  static String toWire(OrderStatus status) => status.wire;

  /// The order is finished — nothing more will happen to it. Stop
  /// polling, and drop the payment/cancel affordances.
  bool get isTerminal =>
      this == OrderStatus.completed || this == OrderStatus.cancelled;

  /// The order still needs paying — show the pay CTA and the
  /// `payment_expires_at` countdown.
  bool get needsPayment => this == OrderStatus.awaitingPayment;
}
