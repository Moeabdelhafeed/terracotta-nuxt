// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

// Project imports:
import '../core/api_image.dart';
import 'booking_piece.dart';
import 'booking_product.dart';
import 'booking_status.dart';
import 'delivery_status.dart';
import 'paintable_workshop.dart';

part 'booking.freezed.dart';
part 'booking.g.dart';

/// A workshop booking — the single largest payload in Terracotta, and
/// the same 45-key shape from both
/// `GET /api/workshops/bookings` (list) and
/// `GET /api/workshops/bookings/{id}` (detail). The detail endpoint
/// adds nothing; one model serves both, and a list row can be pushed
/// straight into the detail screen without a second fetch.
///
/// It carries five concerns at once — the slot, the money, the
/// check-in, the pickup and the delivery — because a booking outlives
/// the session: you book a slot, you pay, you check in, your piece is
/// fired for a week, then you collect it or have it shipped.
///
/// ## Traps
///
/// **[subtotal] IS NOT `unitPrice * peopleCount`.** Booking 22 in the
/// live capture has `unit_price: "0.00"`, `people_count: 1` and
/// `subtotal: "22.00"` — the seat is free and the money comes from
/// [products] (a 10.00 jar plus a 12.00 jar). The catalogue-priced
/// families (`make_your_candle`, `paint_your_piece`) price this way;
/// `make_your_piece` charges per seat. **Never recompute any total
/// client-side.** Render the server's [subtotal], [totalPrice] and
/// [amountDue] verbatim.
///
/// **EVERY MONETARY FIELD IS A DECIMAL STRING** (`"50.00"`), never a
/// double and never a num — [unitPrice], [celebrationPrice],
/// [subtotal], [discountAmount], [totalPrice], [vatRate], [vatAmount],
/// [walletApplied], [amountDue] and the three `deliveryFee*` fields.
/// Parse to `Decimal` or minor units if you must do arithmetic; binary
/// floats round the total you show away from the total you charge.
///
/// **VAT IS INCLUSIVE**, as in `PriceQuote`: [vatAmount] is already
/// contained in [totalPrice]. It is disclosure, not a line to add.
///
/// **[amountDue] of `"0.00"` means already settled** — the wallet or a
/// full discount covered it. Skip the pay call entirely; see
/// [isAlreadySettled].
///
/// **[bookingDate], [startTime] and [endTime] are NOT DateTimes.**
/// [bookingDate] is a bare date (`"2026-08-28"`) and the two times are
/// bare **Asia/Riyadh clock strings** (`"13:00"`, `"14:30"`) with no
/// date and no zone. `DateTime.parse("13:00")` throws. To get an
/// instant you must combine the date, the time and the studio's zone
/// yourself — and do NOT infer that zone from [locationUrl], which
/// points at Amman in the demo data while the CMS, the currency and
/// the delivery zones are all Saudi.
///
/// **[qrValue] and [checkinCode] are Strings, not ints.** They are
/// eight digits (`"38079300"`) and identical to each other in every
/// capture, but they are opaque tokens: parsing them to int destroys a
/// leading zero and a future alphanumeric code. The API sends both, so
/// the studio can key one in when a scan fails — show [checkinCode],
/// encode [qrValue].
///
/// **The whole `delivery_*` block stays null until delivery is
/// requested.** It is null even on a booking whose workshop has
/// `has_delivery: true`, because the leg is arranged after firing via
/// `POST /api/workshops/bookings/{id}/delivery/quote`. Gate that
/// section of the UI on [hasDeliveryLeg], not on the workshop.
///
/// **[deliveryLat] / [deliveryLng] are decimal STRINGS**
/// (`"24.7136000"`, as the sibling order payload shows), not doubles.
/// Parse them at the map call site.
///
/// **[status], [paymentStatus] and [deliveryStatus] keep the raw wire
/// string on purpose.** Only `pending_payment` and `unpaid` have ever
/// been seen live, so any enum mapping is partly guesswork; keeping
/// the string means a CMS-invented value is still displayable. Read
/// them typed through [statusEnum] and [deliveryStatusEnum], which
/// fall back instead of throwing.
///
/// ## Nullability
///
/// Taken from the two live captures, with one deliberate widening:
/// both sampled bookings are in the SAME state (`pending_payment`,
/// unpaid, no check-in, no delivery), so a field that only exists
/// *because* of that state has not actually been observed in the
/// others. [editableUntil] and [paymentExpiresAt] are therefore
/// nullable despite being non-null in both samples — they are windows,
/// and a window that has closed is a null, not a past timestamp. Every
/// other field follows the samples exactly.
@freezed
abstract class Booking with _$Booking {
  const factory Booking({
    // ---- identity ----
    /// The booking's own id — the `{id}` in
    /// `GET /api/workshops/bookings/{id}`.
    required int id,

    // ---- the workshop and the slot ----
    /// The workshop this booking is for.
    required int workshopId,

    /// Already-localized workshop name. Display as-is.
    required String workshopTitle,

    /// Workshop cover art. **Null in every capture** — as is `image`
    /// on the workshop payloads themselves — so the shape is unproven.
    /// [ApiImage] is the bet because it is the shape behind every
    /// other image key in this API. Paint via `image.display`.
    ApiImage? workshopImage,

    /// The specific dated session that was booked.
    required int workshopSlotId,

    /// Bare calendar date, `"2026-08-28"`. A String, not a DateTime —
    /// see the class doc.
    required String bookingDate,

    /// Asia/Riyadh clock string, `"13:00"`. NOT a DateTime; parsing it
    /// as one throws.
    required String startTime,

    /// Asia/Riyadh clock string, `"14:30"`. NOT a DateTime.
    required String endTime,

    /// Maps link for the studio. Hand it to `launchUrl` with
    /// `LaunchMode.externalApplication`.
    ///
    /// NULLABLE — verified live on 2026-08-30. The CMS leaves it empty
    /// on a workshop that is not open for booking, and declared
    /// required it threw inside `fromJson` and took the whole payload
    /// with it. Show the map link only when there is one.
    String? locationUrl,

    /// Seats booked. Capped by the workshop's `max_people_per_booking`.
    required int peopleCount,

    // ---- money: all decimal strings ----
    /// Price of ONE seat. `"0.00"` on the catalogue-priced families —
    /// that is not an error, see the class doc.
    required String unitPrice,

    /// Whether the celebration add-on was bought.
    required bool hasCelebration,

    /// Cost of the celebration add-on. Quoted whether or not
    /// [hasCelebration] is true — check the flag before showing it.
    required String celebrationPrice,

    /// Seats + products + celebration, before discount, VAT and
    /// wallet. Server-computed; do not recompute.
    required String subtotal,

    /// Amount taken off by [discountCode]. `"0.00"` when none.
    required String discountAmount,

    /// The code that was applied, or null when none was.
    String? discountCode,

    /// What the booking costs. VAT-INCLUSIVE — never add [vatAmount].
    required String totalPrice,

    /// VAT percentage as a decimal string (`"0.00"` in the captures —
    /// the demo tenant has tax switched off).
    required String vatRate,

    /// VAT already INSIDE [totalPrice]. Disclosure only.
    required String vatAmount,

    /// Wallet credit consumed. `"0.00"` when none.
    required String walletApplied,

    /// [totalPrice] minus [walletApplied] — what the payment step
    /// charges. `"0.00"` means settled; see [isAlreadySettled].
    required String amountDue,

    // ---- state ----
    /// Raw lifecycle value (`"pending_payment"`). Read it typed via
    /// [statusEnum]; keep this string for display.
    required String status,

    /// Raw payment value (`"unpaid"` is the only one captured). Left
    /// as a String deliberately — the vocabulary is unverified, so no
    /// enum here would be honest.
    required String paymentStatus,

    /// When the customer scanned in at the studio. Null until they do.
    DateTime? checkedInAt,

    /// When the booking was created. Full ISO-8601 with offset.
    required DateTime createdAt,

    /// End of the edit window — creation + the workshop's
    /// `cancellation_window_hours`. Nullable: see the class doc.
    /// **[canEdit] is the authority, not this timestamp** — the
    /// captures show `can_edit: false` while this is still in the
    /// future, because an unpaid booking cannot be edited at all.
    DateTime? editableUntil,

    /// End of the payment window — only ~15 minutes after
    /// [createdAt] in the captures. The seat is released after it.
    /// Nullable: a paid booking has nothing left to expire.
    DateTime? paymentExpiresAt,

    /// Opaque token to encode into the check-in QR. A String — never
    /// parse it to int.
    required String qrValue,

    /// The same token, for the studio to key in by hand when a scan
    /// fails. Identical to [qrValue] in every capture, but do not
    /// assume that holds.
    required String checkinCode,

    /// Server's verdict on editability. Trust this, not [editableUntil].
    required bool canEdit,

    /// Server's verdict on cancellability. Trust this, not the clock.
    required bool canCancel,

    /// Photos attached to the booking. `[]` in every capture, so the
    /// element shape is unproven — [ApiImage] is the bet, matching
    /// every other image list in this API.
    @Default(<ApiImage>[]) List<ApiImage> images,

    /// Catalogue items picked at booking time. Empty for the flat-rate
    /// `make_your_piece` family; the source of [subtotal] for the
    /// others.
    @Default(<BookingProduct>[]) List<BookingProduct> products,

    /// The pieces made in this session, grouped by the labels the
    /// customer typed when uploading photographs.
    @Default(<BookingPiece>[]) List<BookingPiece> pieces,

    /// How many pieces this booking is expected to end up with.
    ///
    /// A CEILING for the catalogue types — the sum of the quantities
    /// bought, enforced server-side, because a key past it would be an
    /// object nobody paid for.
    ///
    /// A GUIDE for «صمم قطعتك», where nothing is bought per object.
    /// **Since 2026-09-13 it counts who actually CHECKED IN**, falling
    /// back to the booked `people_count` until the desk records
    /// attendance: a party of four that arrives as two expects two.
    /// It used to be the booked count always, which told a complete
    /// booking it was short. Never a ceiling there — one person making
    /// three things at a wheel is normal and accepted.
    @JsonKey(name: 'expected_piece_count') int? expectedPieceCount,

    /// The paint workshops that accept a piece made here.
    ///
    /// Empty until the studio marks this booking **completed**, which
    /// means fired — see [PaintableWorkshop].
    @JsonKey(name: 'paintable_at')
    @Default(<PaintableWorkshop>[])
    List<PaintableWorkshop> paintableAt,

    // ---- pickup of the fired piece ----
    /// WHEN THE STUDIO EXPECTS THE PIECE TO BE FINISHED.
    ///
    /// **NOT IMPLEMENTED SERVER-SIDE — always null today.** Probed on
    /// 2026-09-15 against booking 55 (`status: preparing`): the row
    /// carries no readiness estimate of any kind, and `/docs.openapi`
    /// has no `ready_at`, `ready_in`, `estimated_*` or `preparing_*`
    /// anywhere. `piece_warning_days` exists but is the workshop's
    /// COLLECTION warning window, not how long firing takes.
    ///
    /// It is modelled anyway because the alternative is the app
    /// promising a number it invented: «قيد التحضير» read "ready in 5
    /// to 7 days" for every booking of every workshop, which is a
    /// commitment the studio never made. The line now states the span
    /// only when the server sends one and says nothing about timing
    /// otherwise — so the day this field appears, the promise becomes
    /// true without another change here.
    ///
    /// Offset-bearing, like every other timestamp on this row. See
    /// `unverified_models_test.dart`.
    DateTime? readyAt,

    /// Deadline to collect the finished piece from the studio. Null in
    /// every capture — it is set once the piece is fired and ready.
    DateTime? pickupDeadline,

    /// Whether [pickupDeadline] has passed with the piece
    /// uncollected. Present and non-null even while
    /// [pickupDeadline] is null (it is simply false then).
    required bool isPickupOverdue,

    // ---- delivery of the fired piece: null until requested ----
    /// How the piece leaves the studio. Null in every capture; left a
    /// raw String because no value has been observed to build an enum
    /// from. See [hasDeliveryLeg].
    String? deliveryMethod,

    /// Raw shipping stage. Read it typed via [deliveryStatusEnum].
    /// Null means "no delivery leg", NOT "unknown stage".
    String? deliveryStatus,

    /// Destination latitude as a decimal STRING (`"24.7136000"`), not
    /// a double. Parse at the map call site.
    String? deliveryLat,

    /// Destination longitude as a decimal STRING, not a double.
    String? deliveryLng,

    /// Contact number for the courier, in E.164 (`"+966500000000"`).
    String? deliveryPhone,

    /// Free-text destination address.
    String? deliveryAddress,

    /// Human-readable zone NAME the fee was priced for (`"Riyadh"`),
    /// not a zone id — same as the shop order payload.
    String? deliveryZone,

    /// Shipping charge as a decimal string. Priced from the zone in
    /// `GET /api/delivery-zones`.
    String? deliveryFee,

    /// Wallet credit consumed by the delivery charge. A SEPARATE
    /// settlement from [walletApplied] — the piece and its shipping
    /// are paid at different times.
    String? deliveryFeeWalletApplied,

    /// [deliveryFee] minus [deliveryFeeWalletApplied] — what the
    /// delivery payment step charges. Separate from [amountDue]; do
    /// not add the two together and show one number.
    String? deliveryFeeAmountDue,
  }) = _Booking;

  const Booking._();

  factory Booking.fromJson(Map<String, dynamic> json) =>
      _$BookingFromJson(json);

  /// [status] resolved to a [BookingStatus], falling back to
  /// [BookingStatus.unknown] for a value this build does not model
  /// rather than throwing. Show the raw [status] when it is unknown.
  BookingStatus get statusEnum => BookingStatus.fromWire(status);

  /// [deliveryStatus] resolved to a [DeliveryStatus], or null when
  /// there is no delivery leg at all. Never throws on an unrecognised
  /// value — it falls back to [DeliveryStatus.unknown].
  DeliveryStatus? get deliveryStatusEnum =>
      deliveryStatus == null ? null : DeliveryStatus.fromWire(deliveryStatus);

  /// Whether delivery has been arranged for this booking.
  ///
  /// The whole `delivery_*` block is null until the customer requests
  /// delivery after firing — gate that UI on this, never on the
  /// workshop's `has_delivery`.
  bool get hasDeliveryLeg => deliveryStatus != null || deliveryMethod != null;

  /// Nothing left to charge for the booking itself — the wallet or a
  /// full discount covered it. The caller MUST skip the pay call;
  /// posting a payment for zero either 422s or opens a payment sheet
  /// for nothing. Mirrors `PriceQuote.isAlreadySettled`.
  ///
  /// Says nothing about [deliveryFeeAmountDue], which settles
  /// separately.
  bool get isAlreadySettled => amountDue == '0.00';
}
