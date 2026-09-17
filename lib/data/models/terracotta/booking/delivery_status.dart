/// How far along the handover leg of a finished piece is, as
/// `delivery_status` reports it on `GET /api/workshops/bookings` and
/// `GET /api/workshops/bookings/{id}`.
///
/// **Read off the live OpenAPI spec, which states the vocabulary
/// outright** (verified 2026-09-06):
///
/// > `delivery_status`: `pickup` runs `awaiting_pickup → completed`;
/// > `delivery` runs `getting_ready → on_the_way → completed`.
///
/// So there are FOUR values and the two legs share the last one. Which
/// leg a booking is on is `delivery_method` (`pickup` or `delivery`),
/// chosen through `POST /workshops/bookings/{id}/delivery` and
/// re-choosable right up until `delivery_status` reaches `completed`.
///
/// This enum used to carry six INVENTED members — `pending`,
/// `preparing`, `ready`, `out_for_delivery`, `delivered`, `cancelled`.
/// Not one of them is a value the server sends. `out_for_delivery` is
/// the SHOP's order vocabulary, which is a different lifecycle on a
/// different resource.
///
/// **The booking's own `status` stays `completed` for this entire
/// leg.** A piece being packed, a piece on a van and a piece in the
/// customer's hands are three different screens and one booking
/// status — which is why the app is driven by a stage.
///
/// `delivery_status == null` means "no handover chosen yet" — a
/// different thing from [unknown], which means "there is one, but this
/// build does not recognise its stage". Keep them distinct.
///
/// [fromWire] falls back to [unknown] instead of throwing.
enum DeliveryStatus {
  /// PICKUP leg: waiting at the studio for the customer to come.
  awaitingPickup('awaiting_pickup'),

  /// DELIVERY leg: being packed for the courier.
  gettingReady('getting_ready'),

  /// DELIVERY leg: handed to the courier and on the road.
  onTheWay('on_the_way'),

  /// Both legs end here — collected from the studio, or delivered to
  /// the door. The piece is the customer's.
  completed('completed'),

  /// A value this build does not model. Show the raw
  /// `delivery_status` string instead of this name.
  unknown('unknown');

  const DeliveryStatus(this.wire);

  /// The `delivery_status` value exactly as it arrives from the API.
  final String wire;

  /// Resolves a wire value, falling back to [unknown] for anything
  /// unrecognised instead of throwing — the CMS drives this leg by
  /// hand and can grow a stage at any time.
  static DeliveryStatus fromWire(String? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => unknown);
}
