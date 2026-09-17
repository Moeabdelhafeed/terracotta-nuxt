/// The lifecycle of a workshop booking, as `status` reports it on
/// `GET /api/workshops/bookings` and `GET /api/workshops/bookings/{id}`.
///
/// **Read off the live OpenAPI spec, not guessed.** Every member below
/// is named in `https://dev-cms.terracotta-ksa.com/docs.openapi` —
/// either as a `status:` example on a booking payload, or in the prose
/// of the three scanner endpoints that move a booking through its life
/// (`/api/scan/check-in`, `/api/scan/sessions/start`,
/// `/api/scan/sessions/finish`). Verified 2026-09-05.
///
/// Two values this file used to carry were INVENTIONS and are gone:
///
///  - **`checked_in`** — never a status. Every occurrence in the spec
///    is `checked_in_at`, `checked_in_count` or `already_checked_in`.
///    The status for a scanned-in customer is [attending].
///  - **`expired`** — the word appears forty-odd times in the spec and
///    not once as a booking status; it is OTP expiry and the shop
///    cart's payment hold. A booking whose window closes has its SEAT
///    released, which the spec never describes as a status of its own.
///
/// `pending_payment` is the only value observed on a live booking, and
/// the only one absent from the spec's examples — it comes from the
/// captured payload in `fixtures/samples/bookings_list.json`.
///
/// The raw string is still what `Booking.status` keeps, and this enum
/// is reached through a getter, so nothing is lost when the CMS invents
/// a value we do not model.
///
/// [fromWire] falls back to [unknown] rather than throwing. [unknown]
/// is NOT an error: it means "the server said something this build
/// does not model". Render the raw `status` string in that case and do
/// not gate destructive UI on it.
///
/// Never key payability off this enum alone — `payment_status`,
/// `amount_due`, `can_edit` and `can_cancel` are separate server-side
/// decisions and the server is the authority on all four.
enum BookingStatus {
  /// Created but not yet paid. The seat is held until
  /// `payment_expires_at` (15 minutes after creation), after which the
  /// server releases it. The only value observed on a live booking.
  pendingPayment('pending_payment'),

  /// Paid and holding a seat in the slot.
  confirmed('confirmed'),

  /// The desk scanned them in — `POST /api/scan/check-in`, which also
  /// sets `checked_in_at`. This is the ONLY window in which the piece
  /// photographs may be uploaded.
  attending('attending'),

  /// `POST /api/scan/sessions/start` locked the session in and they had
  /// not checked in.
  ///
  /// **Reversible.** A late arrival can still be scanned in afterwards,
  /// which flips them straight back to [attending] — which is why the
  /// «لم تحضر» screen keeps offering the code. Only
  /// `sessions/finish` settles a no-show, refunding their seats to the
  /// wallet, and after that they can no longer be checked in.
  absent('absent'),

  /// The session finished and the piece has to be fired before it can
  /// be collected. Where most pottery bookings land.
  preparing('preparing'),

  /// The session finished and there was nothing to fire — the customer
  /// took the piece home the same day (`make_your_candle`).
  completed('completed'),

  /// Cancelled by the customer inside the cancellation window, or by
  /// the studio.
  cancelled('cancelled'),

  /// A value this build does not model. See the class doc — show the
  /// raw string instead of this name.
  unknown('unknown');

  const BookingStatus(this.wire);

  /// The `status` value exactly as it arrives from the API.
  final String wire;

  /// Resolves a wire value, falling back to [unknown] for anything
  /// unrecognised (including `null`) instead of throwing — the CMS can
  /// add a status at any time and a shipped build must not crash on it.
  static BookingStatus fromWire(String? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => unknown);
}
