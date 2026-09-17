import 'package:flutter/foundation.dart';

import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../data/models/terracotta/booking/booking.dart';
import '../../../data/models/terracotta/booking/booking_status.dart';
import '../../../data/models/terracotta/booking/paintable_workshop.dart';
import '../widgets/clock_time.dart';
import 'booking_stage.dart';

/// One of the customer's bookings, as the detail page needs it.
///
/// A VIEW MODEL, not the wire shape. `Booking` carries thirty-odd
/// fields — VAT, wallet, discount, delivery — and this page reads eight
/// of them; binding it is a change of SOURCE, not a rewrite.
@immutable
class MyBooking {
  const MyBooking({
    required this.id,
    required this.title,
    required this.stage,
    required this.price,
    required this.people,
    required this.date,
    required this.time,
    this.hasCelebration = false,
    this.checkinCode = '',
    this.locationUrl,
    this.hoursAway = 0,
    this.readyHoursLeft,
    this.pickupHoursLeft,
    this.deliveryMethod,
    this.family = WorkshopFamily.makeYourPiece,
    this.wireColor,
    this.canCancel = true,
    this.canEdit = true,
    this.paintableAt = const <PaintableWorkshop>[],
  });

  final int id;
  final String title;

  /// Which FRAME of its life this booking is in. Not the status — see
  /// [BookingStage].
  final BookingStage stage;

  /// A decimal STRING. Money is decimal on this API and a double rounds
  /// totals wrong.
  final String price;

  final int people;

  /// «يونيو ٤ الثلاثاء» and «٣ م الى ٤ م». Asia/Riyadh, printed as
  /// received — the workshop happens at the studio, not wherever the
  /// customer is standing.
  final String date;
  final String time;

  final bool hasCelebration;

  /// `checkin_code` — and `qr_value`, which the server sends as the
  /// SAME 8-digit value. The studio types it in when a camera fails,
  /// which is the whole reason it is printed under the symbol.
  final String checkinCode;

  /// The studio's map link for this workshop, or null when the CMS has
  /// not given one. On the VIEW model rather than read off the server's
  /// row, so the location button can be drawn on the first frame
  /// instead of appearing once the detail call lands.
  final String? locationUrl;

  /// How many HOURS until the session. Only the confirmed frame counts
  /// it down, and it prints the biggest unit still true — six hours
  /// away used to read «٠ أيام», which sounds like it has passed.
  final int hoursAway;

  /// How long the studio will hold a finished piece, in HOURS, from
  /// `pickup_deadline`. NULL when there is no deadline running — only
  /// a piece waiting to be collected or sent has one.
  final int? pickupHoursLeft;

  /// HOW LONG UNTIL THE PIECE IS FINISHED, in hours, from `ready_at`.
  ///
  /// **Null on every booking the server sends today** — see
  /// [Booking.readyAt]. Null means «قيد التحضير» says nothing about
  /// timing, which is the honest answer while the studio has not
  /// given one.
  final int? readyHoursLeft;

  /// `pickup` or `delivery`, or null before the customer has chosen.
  ///
  /// Re-choosable right up until `delivery_status` reaches
  /// `completed` — so a booking already on the road still carries the
  /// method that put it there.
  final String? deliveryMethod;

  final WorkshopFamily family;
  final String? wireColor;

  /// THE SERVER'S VERDICT, not this app's arithmetic.
  ///
  /// A workshop has a `cancellation_window_hours`, and whether a given
  /// booking is still inside it is a question only the server can
  /// answer — it knows the session's clock, the studio's timezone and
  /// its own rules. `Booking.canCancel` / `canEdit` say so directly;
  /// `editable_until` is a timestamp the model's own doc warns against
  /// trusting instead.
  ///
  /// The buttons are not DRAWN when these are false, rather than drawn
  /// and refused: offering to cancel a booking that cannot be
  /// cancelled is a promise the next tap breaks.
  final bool canCancel;
  final bool canEdit;

  /// The paint workshops that accept a piece made here, as the SERVER
  /// answers it.
  ///
  /// Empty until the studio marks the booking completed, which means
  /// FIRED — so the upsell cannot appear the moment a session ends,
  /// and the app does not have to guess which workshop "the painting
  /// one" is. There can be more than one.
  final List<PaintableWorkshop> paintableAt;

  /// The ones «لوّن قطعتك» can actually open.
  ///
  /// An option with no id names nowhere to go — see
  /// [PaintableWorkshop.isReachable] — so it is dropped here rather
  /// than drawing a button that dead-ends, and a list of nothing but
  /// those takes the button with it.
  List<PaintableWorkshop> get paintableOptions => [
    for (final option in paintableAt)
      if (option.isReachable) option,
  ];
}

/// Placeholder bookings, so every frame the design draws can be looked
/// at before `GET /api/bookings/{id}` is wired.
///
/// **Ids match the design's frame numbers**, so «workshop 7» in the
/// file is booking 7 here and the two can be compared side by side.
///
/// Shaped like the real thing on purpose — decimal-string prices, raw
/// party counts, Asia/Riyadh times displayed as received. Delete this
/// the moment the cubit lands.
class MyBookingSample {
  MyBookingSample._();

  /// «صناعة كوبك» — all NINE frames the design draws for this family.
  static const _title = 'ورشة صناعة كوبك';

  /// «تلوين كوبك» — the catalogue-priced family, whose frames the
  /// design draws separately. All NINE of them, like the family above:
  /// what differs between the two sets is the «حاضرة» drawing, what
  /// «قيد التحضير» promises, and the third button «القطعة جاهزة» does
  /// not offer. Everything else is one design serving both.
  static const _paintTitle = 'ورشة تلوين كوبك';

  /// «صناعة شمعك» — five frames, because this family's piece never
  /// leaves with a courier. See `BookingStage.forFamily`.
  static const _candleTitle = 'ورشة صناعة شمعك';

  static final List<MyBooking> entries = [
    // ── 7 · «الحجز مؤكد» — paid, three days out. The only one of the
    // three that can still be moved.
    const MyBooking(
      id: 7,
      title: _title,
      stage: BookingStage.confirmed,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079300',
      locationUrl: _studioMap,
      hoursAway: 72,
    ),
    // ── 8 · «حاضرة» — scanned in, at the wheel. Nothing left to
    // reschedule; the only thing on offer is somewhere to put a
    // photograph of the piece.
    const MyBooking(
      id: 8,
      title: _title,
      stage: BookingStage.attending,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079300',
      locationUrl: _studioMap,
    ),
    // ── 9 · «لم تحضر» — the session started without them. NOT
    // cancelled: the booking stands, which is why nothing here is red
    // and the scan chip is still offered.
    const MyBooking(
      id: 9,
      title: _title,
      stage: BookingStage.absent,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079300',
      locationUrl: _studioMap,
    ),
    // ── 10 · «قيد التحضير» — in the kiln. Nothing to do but wait, so
    // the frame carries no buttons at all.
    const MyBooking(
      id: 10,
      title: _title,
      stage: BookingStage.preparing,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079300',
      locationUrl: _studioMap,
    ),
    // ── 11 · «القطعة جاهزة» — fired and waiting at the studio. The one
    // frame with three things on offer, and the only one WITHOUT a
    // celebration: it is also the proof that the second row closes up
    // when there is no cake.
    const MyBooking(
      id: 11,
      title: _title,
      stage: BookingStage.ready,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      checkinCode: '38079300',
      locationUrl: _studioMap,
      pickupHoursLeft: 7 * 24,
      // «لوني الكوب» is drawn on this frame in the design, and the
      // button is only offered when the SERVER names somewhere for the
      // piece to go — `paintable_at` is empty until the booking is
      // marked completed, which means fired.
      paintableAt: [PaintableWorkshop(id: 3, title: _paintTitle)],
    ),
    // ── 12 · «ملغاة» — called off. The only red frame in the set.
    const MyBooking(
      id: 12,
      title: _title,
      stage: BookingStage.cancelled,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079300',
      locationUrl: _studioMap,
    ),
    // ── 37 · «قيد التغليف» — `delivery_status: getting_ready`. The
    // booking's own status is `completed` for this and the two below;
    // the handover leg is what separates them.
    const MyBooking(
      id: 37,
      title: _title,
      stage: BookingStage.packing,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079300',
      locationUrl: _studioMap,
    ),
    // ── 38 · «خرجت للتوصيل» — `delivery_status: on_the_way`.
    const MyBooking(
      id: 38,
      title: _title,
      stage: BookingStage.onTheWay,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079300',
      locationUrl: _studioMap,
    ),
    // ── 36 · «مسلمة» — `delivery_status: completed`. The end of BOTH
    // legs: collected from the studio, or delivered to the door.
    const MyBooking(
      id: 36,
      title: _title,
      stage: BookingStage.handedOver,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079300',
      locationUrl: _studioMap,
    ),
    // ── «تلوين كوبك» ────────────────────────────────────────────────
    //
    // The same three frames again for the paint family. Nearly all of
    // it is shared: what changes is the drawing on «حاضرة» — the
    // painter rather than the potter — and what «لم تحضر» says about
    // the money. See `BookingStage.illustrationFor` / `bodyFor`.
    //
    // Ids follow ON from the set above rather than matching design
    // frame numbers, which were not given for these.
    const MyBooking(
      id: 13,
      title: _paintTitle,
      stage: BookingStage.confirmed,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079301',
      locationUrl: _studioMap,
      hoursAway: 72,
      family: WorkshopFamily.paintYourPiece,
    ),
    const MyBooking(
      id: 14,
      title: _paintTitle,
      stage: BookingStage.attending,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079301',
      locationUrl: _studioMap,
      family: WorkshopFamily.paintYourPiece,
    ),
    const MyBooking(
      id: 15,
      title: _paintTitle,
      stage: BookingStage.absent,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079301',
      locationUrl: _studioMap,
      family: WorkshopFamily.paintYourPiece,
    ),
    // ── 26 · «قيد التحضير» — the kiln again, and the same flame, but
    // no five-to-seven days: the piece already exists and what is
    // being arranged is the painting.
    const MyBooking(
      id: 26,
      title: _paintTitle,
      stage: BookingStage.preparing,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079301',
      locationUrl: _studioMap,
      family: WorkshopFamily.paintYourPiece,
    ),
    // ── 45 · «القطعة جاهزة» — TWO ways out rather than three: there is
    // no painting to book a painted piece in for.
    const MyBooking(
      id: 45,
      title: _paintTitle,
      stage: BookingStage.ready,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079301',
      locationUrl: _studioMap,
      pickupHoursLeft: 7 * 24,
      family: WorkshopFamily.paintYourPiece,
    ),
    // ── 42 · «قيد التغليف» — `delivery_status: getting_ready`. The
    // handover leg reads the same in both families: what is being
    // wrapped is a finished piece either way.
    const MyBooking(
      id: 42,
      title: _paintTitle,
      stage: BookingStage.packing,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079301',
      locationUrl: _studioMap,
      family: WorkshopFamily.paintYourPiece,
    ),
    // ── 43 · «خرجت للتوصيل» — `delivery_status: on_the_way`.
    const MyBooking(
      id: 43,
      title: _paintTitle,
      stage: BookingStage.onTheWay,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079301',
      locationUrl: _studioMap,
      family: WorkshopFamily.paintYourPiece,
    ),
    // ── 44 · «مسلمة» — `delivery_status: completed`, and the end of
    // both legs: collected from the studio, or delivered to the door.
    const MyBooking(
      id: 44,
      title: _paintTitle,
      stage: BookingStage.handedOver,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079301',
      locationUrl: _studioMap,
      family: WorkshopFamily.paintYourPiece,
    ),
    // ── 27 · «ملغاة» — the only red frame in this set too.
    const MyBooking(
      id: 27,
      title: _paintTitle,
      stage: BookingStage.cancelled,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079301',
      locationUrl: _studioMap,
      family: WorkshopFamily.paintYourPiece,
    ),
    // ── «صناعة شمعك» ────────────────────────────────────────────────
    //
    // FIVE frames, not nine: a candle is finished and taken home at the
    // end of the session, so there is no kiln to wait on and no
    // courier leg. See `BookingStage.forFamily`.
    //
    // What differs from the two families above is the «حاضرة» drawing
    // — the candle-maker at her flame — and nothing else: every word on
    // these five frames is the one already written.
    const MyBooking(
      id: 60,
      title: _candleTitle,
      stage: BookingStage.confirmed,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079302',
      locationUrl: _studioMap,
      hoursAway: 72,
      family: WorkshopFamily.makeYourCandle,
    ),
    const MyBooking(
      id: 64,
      title: _candleTitle,
      stage: BookingStage.attending,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079302',
      locationUrl: _studioMap,
      family: WorkshopFamily.makeYourCandle,
    ),
    const MyBooking(
      id: 65,
      title: _candleTitle,
      stage: BookingStage.absent,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079302',
      locationUrl: _studioMap,
      family: WorkshopFamily.makeYourCandle,
    ),
    // ── 70 · «مسلمة» — the piece is in the customer's hands. It got
    // there at the end of the session rather than by courier, which is
    // why this family's last frame carries no delivery status.
    const MyBooking(
      id: 70,
      title: _candleTitle,
      stage: BookingStage.handedOver,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079302',
      locationUrl: _studioMap,
      family: WorkshopFamily.makeYourCandle,
    ),
    const MyBooking(
      id: 67,
      title: _candleTitle,
      stage: BookingStage.cancelled,
      price: '800.00',
      people: 2,
      date: 'يونيو ٤ الثلاثاء',
      time: '٣ م الى ٤ م',
      hasCelebration: true,
      checkinCode: '38079302',
      locationUrl: _studioMap,
      family: WorkshopFamily.makeYourCandle,
    ),
  ];

  /// The studio's map link, on every fixture. The live rows carry
  /// `location_url` and the button is hidden without one.
  static const _studioMap =
      'https://maps.google.com/?q=Terracotta+Pottery+Studio';

  /// The booking with this id, or the first one — so a route opened
  /// without an id still renders something rather than throwing.
  static MyBooking byId(int? id) => entries.firstWhere(
    (b) => b.id == id,
    orElse: () => entries.first,
  );
}

/// The server's row, in the shape this screen already draws.
///
/// ## Why an adapter and not a rewrite
///
/// `MyBooking` is a VIEW model: it holds a stage rather than a status,
/// a formatted date rather than `Y-m-d`, and a workshop family for the
/// hue. The detail screen is built around it and reads well. What was
/// wrong was its SOURCE — `MyBookingSample.byId`, a fixture — not its
/// shape. So the fixture is replaced and the screen is untouched.
///
/// ## What the server does not send
///
/// `GET /api/workshops/bookings/{id}` carries no workshop `type` and
/// no `color`, so the FAMILY cannot be resolved from a booking alone.
/// The catalogue has both and the app already holds it — until this is
/// handed one, every booking wears the pottery hue, which is the
/// family three of the four workshops belong to.
extension BookingToMyBooking on Booking {
  /// [family] and [wireColor] come from the CATALOGUE, which the
  /// booking payload does not carry — see the extension's own note.
  MyBooking toMyBooking({
    WorkshopFamily family = WorkshopFamily.makeYourPiece,
    String? wireColor,
    required String locale,
  }) => MyBooking(
    id: id,
    title: workshopTitle,
    stage: _stage,
    // A decimal STRING, as it arrived. Money is never parsed here.
    price: totalPrice,
    people: peopleCount,
    date: formatBookingDate(bookingDate, locale),
    time: BookingStrings.slotLabel(
      formatClock(startTime, locale),
      formatClock(endTime, locale),
    ),
    hasCelebration: hasCelebration,
    // The server sends the same eight digits as `qr_value` and
    // `checkin_code`; the studio types this one in when a camera
    // fails.
    checkinCode: checkinCode,
    locationUrl: locationUrl,
    hoursAway: _hoursAway,
    pickupHoursLeft: _pickupHoursLeft,
    readyHoursLeft: _readyHoursLeft,
    // HOW IT LEAVES, as the server has it. Declared on [MyBooking]
    // from the start and never passed — so the detail page had no way
    // to know a choice had already been made, and drew the
    // un-chosen state over a piece that was already on a van.
    deliveryMethod: deliveryMethod,
    family: family,
    wireColor: wireColor,
    canCancel: canCancel,
    canEdit: canEdit,
    paintableAt: paintableAt,
  );

  /// Which FRAME of its life, from the status the server words.
  ///
  /// The delivery half of the set — ready, packing, on the way, handed
  /// over — is not reachable from `status` alone: they all report
  /// `completed`, and `delivery_status` is what separates them. A
  /// finished booking therefore lands on [BookingStage.ready], the
  /// first of that run, until the delivery leg is bound.
  BookingStage get _stage => switch (statusEnum) {
    BookingStatus.attending => BookingStage.attending,
    BookingStatus.absent => BookingStage.absent,
    BookingStatus.preparing => BookingStage.preparing,
    // FOUR FRAMES SHARE THIS ONE STATUS, and `delivery_status` is what
    // separates them — see [_handoverStage].
    BookingStatus.completed => _handoverStage,
    BookingStatus.cancelled => BookingStage.cancelled,
    // `pending_payment` is a held seat, and the screen that shows it
    // is the checkout rather than this one.
    _ => BookingStage.confirmed,
  };

  /// Which of the four `completed` frames this booking is on.
  ///
  /// The mapping itself lives on [BookingStage.forDelivery], next to
  /// the one that goes the other way, so the two cannot drift.
  BookingStage get _handoverStage =>
      BookingStage.forDelivery(deliveryStatusEnum);

  /// Whole hours from now to the session's START, floored at zero.
  ///
  /// The session's own clock is Asia/Riyadh and `start_time` is
  /// already in it, so the instant is built as UTC and compared to the
  /// reader's `now` — which is the same moment wherever they are
  /// standing. Counting calendar days instead is what produced «٠
  /// أيام» for a session six hours away.
  int get _hoursAway {
    // THE SESSION'S OWN CLOCK, turned into a real instant.
    //
    // `booking_date` and `start_time` are plain Asia/Riyadh values
    // with no offset on them, so parsing them gives a DateTime in
    // whatever zone the DEVICE is in — right in Riyadh and wrong by
    // the difference anywhere else. Reading them as UTC and taking the
    // studio's offset back off makes the instant true wherever the
    // reader is standing, which is what a countdown has to be.
    final wall = DateTime.tryParse('${bookingDate}T${startTime}Z');
    if (wall == null) return 0;
    final at = wall.subtract(kStudioOffset);
    final hours = at.difference(DateTime.now().toUtc()).inHours;
    return hours < 0 ? 0 : hours;
  }

  /// HOW LONG THE STUDIO WILL STILL HOLD THE PIECE.
  ///
  /// `pickup_deadline` is an offset-bearing timestamp, so it needs
  /// none of the correction [_hoursAway] does. Null when no deadline
  /// is running; zero once it has passed, which is what
  /// `is_pickup_overdue` reports separately.
  int? get _pickupHoursLeft {
    final deadline = pickupDeadline;
    if (deadline == null) return null;
    final hours = deadline.difference(DateTime.now()).inHours;
    return hours < 0 ? 0 : hours;
  }

  /// HOW LONG UNTIL IT IS FINISHED, on the same terms — offset-bearing,
  /// so no correction, and floored at zero rather than counting
  /// backwards past a date the studio has not caught up with.
  int? get _readyHoursLeft {
    final at = readyAt;
    if (at == null) return null;
    final hours = at.difference(DateTime.now()).inHours;
    return hours < 0 ? 0 : hours;
  }
}
