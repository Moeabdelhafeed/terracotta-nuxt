import 'package:dio/dio.dart';

import '../../../core/constants/enums/api/request_type.dart';
import '../../../core/types/result.dart';
import '../../models/api/envelope_list.dart';
import '../../models/terracotta/booking/booking.dart';
import '../../models/terracotta/core/price_quote.dart';
import '../../models/terracotta/workshop/availability_calendar.dart';
import '../../models/terracotta/workshop/workshop.dart';
import '../../models/terracotta/workshop/workshop_detail.dart';
import '../../models/terracotta/workshop/workshop_slot.dart';
import '../api_service.dart';
import '../endpoints/terracotta_endpoints.dart';

/// Workshop API calls — the public catalogue, availability, price
/// quotes, bookings, payment, piece photos, and how a finished piece
/// is received.
///
/// Every method returns an `AsyncResult<...>` — pattern-match at the
/// call site. Nothing here throws.
///
/// **Buying a seat is THREE calls, never one:**
/// [getBookingPrice] quotes (creates nothing, holds nothing) →
/// [createBooking] creates the booking UNPAID and reserves the seat →
/// [payBooking] settles it. Read `amount_due` off the create response
/// first: `"0.00"` means wallet or a 100% discount already settled it
/// and [payBooking] must be **skipped**. [payBooking] is idempotent —
/// a retry must never double-charge.
///
/// **Money is a decimal STRING** (`"65.00"`), never a number — never
/// round-trip it through `double`. **VAT is INCLUSIVE**: `vat_amount`
/// is already contained in `total_price`, adding them overcharges.
/// **Slot times are already Asia/Riyadh** — display them as given, no
/// client-side timezone conversion.
///
/// Three workshop types: `make_your_piece`, `paint_your_piece` (needs
/// `products`), `make_your_candle` (has **no** delivery step at all —
/// [getDeliveryQuote] and [chooseDelivery] 422 for it).
class WorkshopApis {
  WorkshopApis._();

  // ─── Per-endpoint log flags ───────────────────────────────

  static ApiLogConfig logListWorkshops = kApiLogVerbose;
  static ApiLogConfig logListWorkshopsPaginated = kApiLogVerbose;
  static ApiLogConfig logGetWorkshop = kApiLogVerbose;
  static ApiLogConfig logGetAvailability = kApiLogVerbose;
  static ApiLogConfig logGetAvailabilityCalendar = kApiLogVerbose;
  static ApiLogConfig logGetBookingPrice = kApiLogVerbose;
  static ApiLogConfig logCreateBooking = kApiLogVerbose;
  static ApiLogConfig logPayBooking = kApiLogVerbose;
  static ApiLogConfig logListBookings = kApiLogVerbose;
  static ApiLogConfig logListBookingsPaginated = kApiLogVerbose;
  static ApiLogConfig logGetBooking = kApiLogVerbose;
  static ApiLogConfig logRescheduleBooking = kApiLogVerbose;
  static ApiLogConfig logCancelBooking = kApiLogVerbose;
  static ApiLogConfig logUploadBookingImages = kApiLogVerbose;
  static ApiLogConfig logGetDeliveryQuote = kApiLogVerbose;
  static ApiLogConfig logChooseDelivery = kApiLogVerbose;

  // ─── Mock setup ───────────────────────────────────────────

  /// Register mock responses for every GET endpoint in this class.
  /// Call once at app init when [ApiService.useMock] is true.
  ///
  /// Mocks are keyed by the exact path, so the ones carrying an id
  /// only answer for workshop `1` and booking `10` — the ids the API
  /// docs use in their examples.
  static void installMocks() {
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.workshops,
      type: RequestType.get,
      data: [
        {
          'id': 1,
          'type': 'make_your_piece',
          'title': 'Make Your Own Cup',
          'price': '35.00',
          'celebration_price': '25.00',
          'has_delivery': true,
        },
      ],
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.workshop('1'),
      type: RequestType.get,
      data: {
        'id': 1,
        'type': 'make_your_piece',
        'title': 'Make Your Own Cup',
        'price': '35.00',
        'capacity_per_session': 6,
        'max_people_per_booking': 3,
        'duration_minutes': 90,
        'celebration_price': '25.00',
        'cancellation_window_hours': 24,
        'has_delivery': true,
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.workshopAvailability('1'),
      type: RequestType.get,
      data: [
        {
          'workshop_slot_id': 3,
          'start_time': '10:00',
          'end_time': '12:00',
          'capacity': 6,
          'booked': 2,
          'remaining': 4,
          'is_full': false,
        },
      ],
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.workshopPrice('1'),
      type: RequestType.get,
      data: {
        'workshop_id': 1,
        'workshop_slot_id': 3,
        'people_count': 2,
        'unit_price': '35.00',
        'has_celebration': false,
        'celebration_price': '25.00',
        'total_price': '70.00',
        'vat_rate': '15.00',
        'vat_amount': '9.13',
        'total_excluding_vat': '60.87',
        'wallet_applied': '0.00',
        'amount_due': '70.00',
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.bookings,
      type: RequestType.get,
      data: [
        {
          'id': 10,
          'workshop_id': 1,
          'workshop_title': 'Make Your Own Cup',
          'booking_date': '2026-07-04',
          'start_time': '13:00',
          'end_time': '15:00',
          'people_count': 2,
          'total_price': '70.00',
          'amount_due': '0.00',
          'status': 'confirmed',
          'payment_status': 'paid',
        },
      ],
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.booking('10'),
      type: RequestType.get,
      data: {
        'id': 10,
        'workshop_id': 1,
        'workshop_title': 'Make Your Own Cup',
        'booking_date': '2026-07-04',
        'start_time': '13:00',
        'end_time': '15:00',
        'people_count': 2,
        'unit_price': '35.00',
        'total_price': '70.00',
        'wallet_applied': '0.00',
        'amount_due': '0.00',
        'status': 'confirmed',
        'payment_status': 'paid',
        'qr_value': '48392017',
        'checkin_code': '48392017',
        'can_edit': true,
        'can_cancel': true,
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.bookingDeliveryQuote('10'),
      type: RequestType.get,
      data: {
        'subtotal': '15.00',
        'discount_amount': '0.00',
        'discount_code': null,
        'delivery_fee': '15.00',
        'delivery_zone': 'Riyadh',
        'total_price': '15.00',
        'vat_rate': '15.00',
        'vat_amount': '1.96',
        'total_excluding_vat': '13.04',
        'wallet_applied': '0.00',
        'amount_due': '15.00',
        'already_paid': false,
      },
    );
  }

  // ─── API methods ──────────────────────────────────────────

  /// The whole active workshop catalogue, unpaginated — `data` comes
  /// back as an array.
  ///
  /// Sending `per_page` flips `data` to a Laravel paginator OBJECT,
  /// which this parse rejects — use [listWorkshopsPaginated] instead.
  static AsyncResult<List<Workshop>> listWorkshops({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<Workshop>(
      TerracottaEndpoints.workshops,
      fromJson: Workshop.fromJson,
      logRequest: logListWorkshops.request,
      logResponse: logListWorkshops.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// One page of the workshop catalogue — `data` is the raw Laravel
  /// paginator (`current_page`, `data`, `last_page`, `total`, …), not
  /// the `items` / `meta` envelope, so it is returned as a map.
  static AsyncResult<Map<String, dynamic>> listWorkshopsPaginated({
    required int perPage,
    int? page,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<Map<String, dynamic>>(
      TerracottaEndpoints.workshops,
      queryParameters: {
        'per_page': perPage,
        if (page != null) 'page': page,
      },
      fromJson: (json) => json,
      logRequest: logListWorkshopsPaginated.request,
      logResponse: logListWorkshopsPaginated.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// One workshop's detail. Returns `has_delivery` as a flag only —
  /// **never a delivery price**; the fee depends on the customer's
  /// city and comes from [getDeliveryQuote].
  static AsyncResult<WorkshopDetail> getWorkshop(
    String workshopId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<WorkshopDetail>(
      TerracottaEndpoints.workshop(workshopId),
      fromJson: WorkshopDetail.fromJson,
      logRequest: logGetWorkshop.request,
      logResponse: logGetWorkshop.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Bookable slots on one calendar date (`Y-m-d`), with remaining
  /// seats. `start_time` / `end_time` are already Asia/Riyadh — show
  /// them as given, never shifted into the device timezone.
  ///
  /// `date` is what makes `data` an array. Omitting it returns the
  /// calendar-preview OBJECT instead — see [getAvailabilityCalendar].
  static AsyncResult<List<WorkshopSlot>> getAvailability(
    String workshopId, {
    required String date,
    int? peopleCount,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<WorkshopSlot>(
      TerracottaEndpoints.workshopAvailability(workshopId),
      queryParameters: {
        'date': date,
        if (peopleCount != null) 'people_count': peopleCount,
      },
      fromJson: WorkshopSlot.fromJson,
      logRequest: logGetAvailability.request,
      logResponse: logGetAvailability.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Calendar preview for the next `days` days — `max_available_seats`
  /// plus the `blocked_dates` to grey out. Same endpoint as
  /// [getAvailability] with no `date`, which is what switches the
  /// response from an array of slots to this object.
  static AsyncResult<AvailabilityCalendar> getAvailabilityCalendar(
    String workshopId, {
    int? days,
    int? peopleCount,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<AvailabilityCalendar>(
      TerracottaEndpoints.workshopAvailability(workshopId),
      queryParameters: {
        if (days != null) 'days': days,
        if (peopleCount != null) 'people_count': peopleCount,
      },
      fromJson: AvailabilityCalendar.fromJson,
      logRequest: logGetAvailabilityCalendar.request,
      logResponse: logGetAvailabilityCalendar.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// QUOTE step (1 of 3) — prices a prospective booking. Creates
  /// nothing and holds nothing; the seat is only reserved once
  /// [createBooking] runs.
  ///
  /// `vat_amount` is already inside `total_price` — never add them.
  /// `amount_due` is what the customer still owes after the wallet and
  /// any discount; the charge in [createBooking] must match this quote
  /// field for field. A discount code never touches a delivery fee.
  ///
  /// `products` is `paint_your_piece` only — a list of
  /// `{'workshop_product_id': int, 'quantity': int}` maps, or
  /// `{'workshop_booking_piece_id': int}` for one of the customer's
  /// own pieces brought back to be painted.
  ///
  /// **Send `bookingDate`.** The price does not depend on it, but when
  /// it is sent the server checks it against the schedule with exactly
  /// the rules [createBooking] applies — so quoting a session on a day
  /// the workshop does not run is refused HERE rather than showing a
  /// price the next call turns down.
  static AsyncResult<PriceQuote> getBookingPrice(
    String workshopId, {
    required int workshopSlotId,
    required int peopleCount,
    String? bookingDate,
    bool? withCelebration,
    bool? useWallet,
    List<Map<String, dynamic>>? products,
    String? discountCode,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<PriceQuote>(
      TerracottaEndpoints.workshopPrice(workshopId),
      queryParameters: {
        'workshop_slot_id': workshopSlotId,
        'people_count': peopleCount,
        if (bookingDate != null) 'booking_date': bookingDate,
        if (withCelebration != null) 'with_celebration': withCelebration,
        if (useWallet != null) 'use_wallet': useWallet,
        if (discountCode != null) 'discount_code': discountCode,
        ..._productsQuery(products),
      },
      fromJson: PriceQuote.fromJson,
      logRequest: logGetBookingPrice.request,
      logResponse: logGetBookingPrice.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// CREATE step (2 of 3) — books the workshop UNPAID and reserves the
  /// seat, the wallet hold and the discount-code use. Settle it with
  /// [payBooking].
  ///
  /// **Check `amount_due` on the response first** — `"0.00"` means the
  /// wallet or a 100% discount already settled it and [payBooking]
  /// must be skipped entirely. An abandoned hold expires server-side
  /// and gives the seat back.
  ///
  /// `bookingDate` is `Y-m-d` and must fall on the slot's day of week.
  /// `peopleCount` is capped at the workshop's
  /// `max_people_per_booking`. `products` is required for
  /// `paint_your_piece` and is a list of
  /// `{'workshop_product_id': int, 'quantity': int}` maps.
  static AsyncResult<Booking> createBooking(
    String workshopId, {
    required int workshopSlotId,
    required String bookingDate,
    required int peopleCount,
    bool? withCelebration,
    bool? useWallet,
    List<Map<String, dynamic>>? products,
    String? discountCode,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Booking>(
      TerracottaEndpoints.workshopBookings(workshopId),
      data: {
        'workshop_slot_id': workshopSlotId,
        'booking_date': bookingDate,
        'people_count': peopleCount,
        if (withCelebration != null) 'with_celebration': withCelebration,
        if (useWallet != null) 'use_wallet': useWallet,
        if (products != null) 'products': products,
        if (discountCode != null) 'discount_code': discountCode,
      },
      fromJson: Booking.fromJson,
      logRequest: logCreateBooking.request,
      logResponse: logCreateBooking.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// PAY step (3 of 3) — settles a held booking.
  ///
  /// **Idempotent**: calling it twice must not double-charge, so a
  /// retry after a dropped connection is safe. Do not call it at all
  /// when [createBooking] came back with `amount_due` of `"0.00"` —
  /// that booking already settled.
  static AsyncResult<Map<String, dynamic>> payBooking(
    String bookingId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.bookingPay(bookingId),
      fromJson: (json) => json,
      logRequest: logPayBooking.request,
      logResponse: logPayBooking.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// The caller's own bookings, unpaginated — `data` is an array.
  /// Sending `per_page` returns a paginator object instead; use
  /// [listBookingsPaginated] for that.
  ///
  /// ## Why this one keeps the envelope's `meta`
  ///
  /// This endpoint answers with `meta.status_counts` beside `data` — a
  /// tally of the customer's WHOLE history:
  ///
  /// ```json
  /// "meta": {"status_counts": {"all": 5, "confirmed": 2, "cancelled": 3, …}}
  /// ```
  ///
  /// It is deliberately independent of the rows returned: the same
  /// numbers come back with `?status=cancelled` applied and with
  /// `per_page` paginating, so «ورشاتي»' filter chips can say how many
  /// of each the customer has without the tally changing under the
  /// filter that reads it. `data` is a sibling of it, which is why the
  /// call goes through `getListWithMeta` — a `fromJson` is handed
  /// `data` alone and can never see it. Verified live 2026-09-10.
  ///
  /// ## `?status=` and `?sort=` are not sent, on purpose
  ///
  /// The endpoint also takes `?status=confirmed,cancelled` (422 on an
  /// unknown one) and `?sort=` — `newest` (the default), `oldest`,
  /// `session_soonest`, `session_latest`. The app sends neither: this
  /// call is UNPAGINATED, so the whole history is already on the
  /// device and filtering it there is instant where a round trip per
  /// chip is not. Send them the day this list starts paginating.
  ///
  /// **The order changed under us on 2026-09-13** — newest BOOKED
  /// first, where it used to be by session date, so the class somebody
  /// just paid for is at the top instead of buried under one booked
  /// weeks ago. Nothing here had to change for that, and the reason is
  /// worth keeping: this feature has never re-sorted the rows it was
  /// given. Sort them locally and the server's order stops mattering,
  /// along with every future decision it makes about them.
  static AsyncResult<EnvelopeList<Booking>> listBookings({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getListWithMeta<Booking>(
      TerracottaEndpoints.bookings,
      fromJson: Booking.fromJson,
      logRequest: logListBookings.request,
      logResponse: logListBookings.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// One page of the caller's bookings — `data` is the raw Laravel
  /// paginator object, returned as a map.
  static AsyncResult<Map<String, dynamic>> listBookingsPaginated({
    required int perPage,
    int? page,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<Map<String, dynamic>>(
      TerracottaEndpoints.bookings,
      queryParameters: {
        'per_page': perPage,
        if (page != null) 'page': page,
      },
      fromJson: (json) => json,
      logRequest: logListBookingsPaginated.request,
      logResponse: logListBookingsPaginated.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// One booking of the caller's. Someone else's id must come back
  /// 404, never 200. Times are Asia/Riyadh already; every money field
  /// is a decimal string snapshotted at purchase — later CMS price
  /// changes must not move it.
  static AsyncResult<Booking> getBooking(
    String bookingId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<Booking>(
      TerracottaEndpoints.booking(bookingId),
      fromJson: Booking.fromJson,
      logRequest: logGetBooking.request,
      logResponse: logGetBooking.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Reschedules a booking onto a new slot / date, and optionally
  /// changes the head count. Only allowed while `can_edit` is true and
  /// `editable_until` has not passed.
  ///
  /// Written as PUT on purpose — the method-override interceptor
  /// rewrites it to POST at send time. Do not hand-write the override.
  static AsyncResult<Booking> rescheduleBooking(
    String bookingId, {
    required int workshopSlotId,
    required String bookingDate,
    int? peopleCount,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().put<Booking>(
      TerracottaEndpoints.booking(bookingId),
      data: {
        'workshop_slot_id': workshopSlotId,
        'booking_date': bookingDate,
        if (peopleCount != null) 'people_count': peopleCount,
      },
      fromJson: Booking.fromJson,
      logRequest: logRescheduleBooking.request,
      logResponse: logRescheduleBooking.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Cancels a booking and refunds the full total to the wallet — the
  /// response carries the new `wallet_balance`. Only while
  /// `can_cancel` is true (inside the workshop's
  /// `cancellation_window_hours`).
  ///
  /// Written as DELETE on purpose — the method-override interceptor
  /// rewrites it to POST at send time.
  static AsyncResult<Map<String, dynamic>> cancelBooking(
    String bookingId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().delete<Map<String, dynamic>>(
      TerracottaEndpoints.booking(bookingId),
      fromJson: (json) => json,
      logRequest: logCancelBooking.request,
      logResponse: logCancelBooking.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Uploads photos of the finished piece onto a booking and returns
  /// the updated booking. Defaults to the long upload timeout.
  ///
  /// ## What makes two photos one piece
  ///
  /// **[keys], not the label.** The server used to group photographs by
  /// MATCHING LABEL TEXT — so two friends who both wrote «mug» ended up
  /// with one piece between them, and the second object could never be
  /// brought back to paint. Since 2026-09-13 `piece_keys[]` decides:
  /// photos sharing a key are one piece, different keys are different
  /// pieces whatever the labels say, and the label is only the name the
  /// customer reads.
  ///
  /// The key is any string the app likes — it is an identifier within
  /// ONE request, not something the server stores. [labels] and [keys]
  /// are both one entry per image, in the same order.
  ///
  /// **[ids] is for a LATER call**: an existing piece id from the
  /// booking's `pieces` list, to add another angle to a piece that is
  /// already there. Null for a photo falls back to its [keys] entry.
  ///
  /// Sending no keys still groups by label, which is only kept so an
  /// older build does not break — never rely on it.
  ///
  /// ## The caps
  ///
  /// Cumulative across calls: **4 photos per person** (`images`), and
  /// for the CATALOGUE types the number of pieces may not exceed the
  /// products bought — a fifth key answers 422, because that would be
  /// an object nobody paid for. `make_your_piece` has no ceiling: its
  /// `expected_piece_count` counts the people who checked in and is a
  /// guide, since one person making three things is normal.
  ///
  /// A count mismatch on `piece_keys` or `piece_ids`, and a
  /// `piece_ids` naming a piece from another booking, are all 422 keyed
  /// to the field.
  static AsyncResult<Booking> uploadBookingImages(
    String bookingId, {
    required List<MultipartFile> images,
    required List<String> labels,
    List<String>? keys,
    List<String?>? ids,
    void Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Booking>(
      TerracottaEndpoints.bookingImages(bookingId),
      data: _imagesForm(images, labels, keys, ids),
      fromJson: Booking.fromJson,
      logRequest: logUploadBookingImages.request,
      logResponse: logUploadBookingImages.response,
      onSendProgress: onSendProgress,
      cancelToken: cancelToken,
      timeout: timeout ?? kApiUploadTimeout,
    ),
  );

  /// Renames a PIECE.
  ///
  /// ## This verb is not in the spec yet
  ///
  /// `/docs.openapi` lists exactly three write operations on a piece —
  /// `POST .../images` creates, `DELETE .../images/{id}` removes one
  /// photograph, `DELETE .../pieces/{id}` removes the piece — and no
  /// rename. `piece_labels[]` is read when a piece is MADE and never
  /// again: sent alongside `piece_ids[]` the server attaches the
  /// photograph to the piece whose label is already set.
  ///
  /// It is written anyway, against the shape the rename obviously
  /// wants, because the alternative is worse in every direction. Doing
  /// it client-side would mean deleting the piece and re-uploading its
  /// photographs — which the app cannot do, since it holds urls rather
  /// than files — and would mint a new piece id, breaking the
  /// `own_pieces` and `painting_session` references pointing at the
  /// old one.
  ///
  /// **Until the backend ships it this answers 404 or 405**, and the
  /// caller shows the server's own message. The moment it exists, this
  /// works with nothing else to change. See `docs/api-contract.md`
  /// §23.
  ///
  /// Written as PATCH and rewritten to POST with
  /// `X-HTTP-Method-Override` by the interceptor, because production
  /// blocks the verb.
  ///
  /// Expected to be `attending`-only, like the two deletes beside it.
  static AsyncResult<Booking> renamePiece(
    String bookingId,
    String pieceId, {
    required String label,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().patch<Booking>(
      TerracottaEndpoints.bookingPiece(bookingId, pieceId),
      data: {'label': label},
      fromJson: Booking.fromJson,
      logRequest: logUploadBookingImages.request,
      logResponse: logUploadBookingImages.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Removes one photograph from a booking and returns the updated
  /// booking.
  ///
  /// **Only while the session is running.** Anything but `attending`
  /// answers 422 `api.workshop_booking_not_attending` with a null
  /// `errors` map; a photograph belonging to another booking answers
  /// 404 `api.workshop_booking_image_not_found`.
  ///
  /// Removing a piece's LAST photograph removes the piece too — a
  /// piece is its photographs, not a row of its own.
  static AsyncResult<Booking> deleteBookingImage(
    String bookingId,
    String imageId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().delete<Booking>(
      TerracottaEndpoints.bookingImage(bookingId, imageId),
      fromJson: Booking.fromJson,
      logRequest: logUploadBookingImages.request,
      logResponse: logUploadBookingImages.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Removes a whole piece — and every photograph of it — returning
  /// the updated booking.
  ///
  /// Same window as [deleteBookingImage]: `attending` only.
  static AsyncResult<Booking> deleteBookingPiece(
    String bookingId,
    String pieceId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().delete<Booking>(
      TerracottaEndpoints.bookingPiece(bookingId, pieceId),
      fromJson: Booking.fromJson,
      logRequest: logUploadBookingImages.request,
      logResponse: logUploadBookingImages.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// QUOTE step for the piece's delivery — prices getting it to a
  /// saved address. Creates nothing.
  ///
  /// Pass `addressId` for the REAL fee: the fee is carried by the
  /// address's city, and without one the app-wide fallback is quoted.
  /// `vat_amount` is inside `total_price`, and a discount code never
  /// reduces the delivery fee. `already_paid: true` means there is
  /// nothing left to settle.
  ///
  /// **422s for a `make_your_candle` booking** — that type has no
  /// pickup/delivery step at all; the customer takes it home the same
  /// day.
  static AsyncResult<PriceQuote> getDeliveryQuote(
    String bookingId, {
    bool? useWallet,
    int? addressId,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().get<PriceQuote>(
      TerracottaEndpoints.bookingDeliveryQuote(bookingId),
      queryParameters: {
        if (useWallet != null) 'use_wallet': useWallet,
        if (addressId != null) 'address_id': addressId,
      },
      fromJson: PriceQuote.fromJson,
      logRequest: logGetDeliveryQuote.request,
      logResponse: logGetDeliveryQuote.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// CREATE step for the piece's delivery — chooses `pickup` or
  /// `delivery` and, unlike the booking flow, is **settled by this
  /// same call**; there is no separate delivery pay endpoint.
  ///
  /// Prefer `addressId`: it carries the city that carries the fee.
  /// `lat` / `lng` / `phone` are required only when `method` is
  /// `delivery` and no `addressId` is given — the pin is for the
  /// driver and does not change the price. `address` is a display-only
  /// label. `useWallet` applies to the delivery fee and is honoured on
  /// the first choice only.
  ///
  /// **422s for a `make_your_candle` booking**, which is never
  /// delivered.
  static AsyncResult<Booking> chooseDelivery(
    String bookingId, {
    required String method,
    int? addressId,
    double? lat,
    double? lng,
    String? phone,
    bool? useWallet,
    String? address,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Booking>(
      TerracottaEndpoints.bookingDelivery(bookingId),
      data: {
        'method': method,
        if (addressId != null) 'address_id': addressId,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        if (phone != null) 'phone': phone,
        if (useWallet != null) 'use_wallet': useWallet,
        if (address != null) 'address': address,
      },
      fromJson: Booking.fromJson,
      logRequest: logChooseDelivery.request,
      logResponse: logChooseDelivery.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  // ─── Helpers ──────────────────────────────────────────────

  /// Builds the multipart body for [uploadBookingImages].
  ///
  /// The part names have to be bracketed — `images[]`,
  /// `piece_labels[]`, `piece_keys[]`, `piece_ids[]`: PHP keeps only
  /// the LAST value of a repeated plain field, so repeating `images`
  /// would upload one photo and repeating `piece_labels` would label
  /// them all the same. Built by hand rather than through
  /// `FormData.fromMap`, whose bracket handling depends on the list
  /// format passed to it.
  ///
  /// Every list is written in step, because the server pairs them by
  /// POSITION — entry `i` belongs to photo `i`.
  ///
  /// `piece_ids[]` is sent ONLY when at least one photo names an
  /// existing piece. An all-null list would still have to be one entry
  /// per photo to pass validation, and sending a column of nulls to say
  /// "none of these" is a request to be misread.
  static FormData _imagesForm(
    List<MultipartFile> images,
    List<String> labels,
    List<String>? keys,
    List<String?>? ids,
  ) {
    final form = FormData();
    for (final image in images) {
      form.files.add(MapEntry('images[]', image));
    }
    for (final label in labels) {
      form.fields.add(MapEntry('piece_labels[]', label));
    }
    for (final key in keys ?? const <String>[]) {
      form.fields.add(MapEntry('piece_keys[]', key));
    }
    if (ids != null && ids.any((id) => id != null)) {
      for (final id in ids) {
        form.fields.add(MapEntry('piece_ids[]', id ?? ''));
      }
    }
    return form;
  }

  /// Flattens `products` into the bracketed query keys Laravel parses
  /// — `products[0][workshop_product_id]`, `products[0][quantity]`. A
  /// nested list cannot survive Dio's flat query encoding otherwise.
  static Map<String, dynamic> _productsQuery(
    List<Map<String, dynamic>>? products,
  ) {
    if (products == null || products.isEmpty) return const {};
    final query = <String, dynamic>{};
    for (var i = 0; i < products.length; i++) {
      products[i].forEach((key, value) {
        if (value != null) query['products[$i][$key]'] = value;
      });
    }
    return query;
  }
}
