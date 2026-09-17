// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import 'order_item.dart';
import 'order_status.dart';

part 'order.freezed.dart';
part 'order.g.dart';

/// A placed shop order — `GET /api/shop/orders` (list),
/// `GET /api/shop/orders/{order}` (detail, byte-identical shape) and
/// the object `POST /api/shop/cart/checkout` returns when it turns the
/// cart into an order and empties it.
///
/// Also the subject of `POST /api/shop/orders/{order}/pay` and
/// `DELETE /api/shop/orders/{order}` (cancel).
///
/// **EVERY MONETARY FIELD IS A DECIMAL STRING** (`"83.00"`), never a
/// double. [amountDue] is the number the payment step charges — see
/// [isAlreadySettled] before calling pay at all.
///
/// **VAT IS INCLUSIVE**, exactly as in `PriceQuote`: [vatAmount] is
/// already inside [totalPrice]. It is disclosure, not a line to add.
///
/// **[status] is decoded through [OrderStatus.fromWire] and cannot
/// throw.** The live server returns `awaiting_payment`, a value the
/// published spec does not even list — a strict enum decoder would have
/// crashed the orders screen on day one. New CMS statuses land as
/// `OrderStatus.unknown`.
///
/// **[canCancel] is the server's answer, not yours.** Do not infer
/// cancellability from [status]; the API decides (it allows `pending`
/// and `preparing`, and refunds any wallet amount applied at checkout).
/// Both captured orders are `awaiting_payment` with
/// `"can_cancel": false`.
///
/// **[paymentExpiresAt] is a deadline, not a timestamp to display.**
/// An `awaiting_payment` order that is not paid before it lapses stops
/// being payable. It is typed nullable because every captured order was
/// unpaid, so no capture proves what a paid order sends — and the
/// documented order shape omits the key entirely.
///
/// Nullability rule used throughout: `required` only where the field is
/// present and non-null in BOTH live captures AND present in the
/// published order shape. Anything the two disagree about
/// ([vatRate], [vatAmount], [paymentStatus], [paymentExpiresAt],
/// [deliveryFee], [deliveryZone], [deliveryAddress]) is nullable, as is
/// anything null in the captures ([deliveryShortAddress],
/// [cancelledAt]) or optional at creation ([discountCode],
/// [deliveryNotes]).
@freezed
abstract class Order with _$Order {
  const factory Order({
    /// Order id — the `{order}` of `/api/shop/orders/{order}`. This is
    /// the human-facing order number the CMS emails about.
    required int id,

    /// Lifecycle state. Decoded non-throwing; unknown wire values
    /// become [OrderStatus.unknown].
    @JsonKey(fromJson: OrderStatus.fromWire, toJson: OrderStatus.toWire)
    required OrderStatus status,

    // ---- money: all decimal strings ----
    /// Line items before delivery, discount, VAT and wallet.
    required String subtotal,

    /// Taken off by [discountCode]. `"0.00"` when none.
    required String discountAmount,

    /// The promo code applied at checkout, null when none was used.
    String? discountCode,

    /// What the order costs. VAT-INCLUSIVE — never add [vatAmount].
    required String totalPrice,

    /// VAT percentage as a decimal string (`"0.00"` in the live data —
    /// VAT is currently switched off, which is not the same as absent).
    String? vatRate,

    /// VAT already contained in [totalPrice]. Display only.
    String? vatAmount,

    /// Wallet credit consumed at checkout. Refunded if the order is
    /// cancelled.
    required String walletApplied,

    /// [totalPrice] minus [walletApplied] — what the pay call charges.
    required String amountDue,

    /// `"unpaid"` is the only value observed live. Left as a String
    /// rather than an enum because no capture shows the paid or
    /// refunded spelling, and guessing an enum here would be fiction.
    String? paymentStatus,

    /// Deadline for paying an `awaiting_payment` order. Full ISO-8601
    /// with offset. See the class doc.
    DateTime? paymentExpiresAt,

    /// What actually came back when the order was cancelled.
    ///
    /// **`null` is not zero.** The server distinguishes "nothing was
    /// ever paid, so there is nothing to refund" (null, an abandoned
    /// `awaiting_payment` hold) from "the refund was `0.00`" — so show
    /// this number or say nothing, and never compute what a customer
    /// gets back from [totalPrice] or [walletApplied].
    ///
    /// A decimal STRING like every other money field.
    String? refundedAmount,

    // ---- delivery ----
    /// Shipping charge folded into [totalPrice]. Decimal string.
    String? deliveryFee,

    /// Human-readable zone the fee was priced for (`"Riyadh"`).
    String? deliveryZone,

    /// Drop-off latitude as a decimal STRING (`"24.7136000"`) — the API
    /// sends coordinates as strings, not numbers. `double.parse` it
    /// only at the point you hand it to a map.
    required String deliveryLat,

    /// Drop-off longitude as a decimal string (`"46.6753000"`).
    required String deliveryLng,

    /// Contact number for the courier, E.164 (`"+966500000000"`).
    required String deliveryPhone,

    /// The readable address line, as the address book supplied it.
    String? deliveryAddress,

    /// Saudi National Address short code. Null in every capture — the
    /// customer had not set one.
    String? deliveryShortAddress,

    /// Free-text note for the courier (`"blue door"`), null when the
    /// customer left it empty.
    String? deliveryNotes,

    // ---- lifecycle ----
    /// Whether the API will accept `DELETE /api/shop/orders/{order}`
    /// right now. Authoritative — do not second-guess it from
    /// [status].
    required bool canCancel,

    /// When the order was placed. Full ISO-8601 with offset.
    required DateTime createdAt,

    /// When it was cancelled, null while it has not been.
    DateTime? cancelledAt,

    /// The ordered lines. An order always has at least one.
    required List<OrderItem> items,
  }) = _Order;

  const Order._();

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  /// Nothing left to charge — the wallet or a full discount covered it.
  ///
  /// When true the caller MUST skip `POST /api/shop/orders/{order}/pay`;
  /// paying `"0.00"` is an error, not a no-op. Mirrors
  /// `PriceQuote.isAlreadySettled`.
  bool get isAlreadySettled => amountDue == '0.00';
}
