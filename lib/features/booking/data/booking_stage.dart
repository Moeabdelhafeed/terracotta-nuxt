import '../../../core/constants/colors/workshop_family_colors.dart';
import '../../../core/localization/strings/booking_strings.dart';
import '../../../core/localization/strings/delivery_strings.dart';
import '../../../data/models/terracotta/booking/booking_status.dart';
import '../../../data/models/terracotta/booking/delivery_status.dart';

/// One FRAME of the booking's life, as the design draws it.
///
/// **Not the same thing as the status.** The studio's design has nine
/// frames for «صناعة كوبك» alone, and two of them can sit on the same
/// wire status and still differ inside — a confirmed booking days away
/// and a confirmed booking starting in an hour are the same `status`
/// and not the same screen.
///
/// So the page is driven by the STAGE, and the status is one of the
/// things that decides which stage a booking is in. When
/// `GET /api/bookings/{id}` is bound, that mapping is the only thing
/// that has to be written; every frame below is already drawn.
enum BookingStage {
  /// «الحجز مؤكد» — paid and waiting. The QR is the thing to do next.
  confirmed,

  /// «حاضرة» — scanned in, at the wheel. The workshop is happening
  /// right now, so there is nothing left to reschedule and the only
  /// thing to offer is somewhere to put a photograph of the piece.
  attending,

  /// «لم تحضر» — the session started without them. Not cancelled: the
  /// booking stands and the studio has not written it off, which is
  /// why nothing here is red.
  absent,

  /// «قيد التحضير» — the session is over and the piece is in the kiln.
  /// Nothing for the customer to do but wait, so this frame carries no
  /// buttons at all.
  preparing,

  /// «القطعة جاهزة» — fired, glazed and waiting at the studio. The one
  /// frame with three things to offer: take it home, have it sent, or
  /// book it in to be painted.
  ready,

  /// «قيد التغليف» — wrapped for the courier.
  /// `delivery_status: getting_ready`.
  packing,

  /// «خرجت للتوصيل» — handed to the courier.
  /// `delivery_status: on_the_way`.
  onTheWay,

  /// «مسلمة» — collected or delivered. The end of both legs, which is
  /// why its drawing is a MARK rather than a picture of a van: it has
  /// to serve the customer who drove to the studio as well as the one
  /// who waited at home.
  handedOver,

  /// «ملغاة» — called off by the customer or the studio. The only
  /// frame in the set that is red.
  cancelled;

  /// The BOOKING's own `status`, exactly as the backend words it.
  ///
  /// Taken from `BookingStatus` rather than typed out, so a literal
  /// here can never drift from the vocabulary the spec defines:
  /// `pending_payment`, `confirmed`, `attending`, `absent`,
  /// `preparing`, `completed`, `cancelled`.
  ///
  /// **«لم تحضر» IS a status.** `POST /api/scan/sessions/start` writes
  /// `absent` on everyone who had not checked in — and it is
  /// reversible, because a late arrival scanned in afterwards flips
  /// straight back to `attending`. That is why this frame keeps
  /// offering the code instead of closing the booking off.
  String get wireStatus => switch (this) {
    confirmed => BookingStatus.confirmed.wire,
    attending => BookingStatus.attending.wire,
    absent => BookingStatus.absent.wire,
    preparing => BookingStatus.preparing.wire,
    ready => BookingStatus.completed.wire,
    // ALL THREE handover frames are a `completed` booking. What
    // separates them is [deliveryStatus], not this.
    packing => BookingStatus.completed.wire,
    onTheWay => BookingStatus.completed.wire,
    handedOver => BookingStatus.completed.wire,
    cancelled => BookingStatus.cancelled.wire,
  };

  /// Where the piece is on its way to the customer, or null when the
  /// booking has no handover leg yet.
  ///
  /// The spec states the vocabulary outright: pickup runs
  /// `awaiting_pickup → completed`, delivery runs `getting_ready →
  /// on_the_way → completed`. «القطعة جاهزة» is the frame BEFORE a
  /// choice is made, so it has none.
  String? get deliveryStatus => switch (this) {
    packing => DeliveryStatus.gettingReady.wire,
    onTheWay => DeliveryStatus.onTheWay.wire,
    handedOver => DeliveryStatus.completed.wire,
    _ => null,
  };

  /// The same mapping the other way: which frame a `completed` booking
  /// is on, given its `delivery_status`.
  ///
  /// **A booking's `status` cannot answer this.** It stays `completed`
  /// for the whole handover leg, so a piece waiting at the studio, a
  /// piece being packed, a piece on a van and a piece in the
  /// customer's hands are four screens and one status. Mapping
  /// `completed` straight to [ready] — which is what the app did —
  /// told a customer whose piece was already out for delivery that it
  /// was sitting at the studio, and offered them the three ways to get
  /// it that they had already chosen between.
  ///
  /// Lives HERE, beside [deliveryStatus], so the two directions cannot
  /// drift apart.
  ///
  /// Two values answer [ready] rather than a frame of their own:
  ///
  ///   * **null** — no handover chosen yet, which is what [ready] IS;
  ///   * `awaiting_pickup` — chosen collection, still at the studio.
  ///     The same screen, and the banner saying so is driven by
  ///     `delivery_method`. That asymmetry is why [deliveryStatus]
  ///     answers null for [ready] and this does not round-trip.
  ///
  /// [DeliveryStatus.unknown] also answers [ready]: the CMS drives
  /// this leg by hand and can grow a stage, and `ready` is the only
  /// frame that offers a way forward.
  static BookingStage forDelivery(DeliveryStatus? status) => switch (status) {
    null || DeliveryStatus.awaitingPickup => ready,
    DeliveryStatus.gettingReady => packing,
    DeliveryStatus.onTheWay => onTheWay,
    DeliveryStatus.completed => handedOver,
    DeliveryStatus.unknown => ready,
  };

  /// The same, for a booking in THIS family.
  ///
  /// «صناعة شمعك» has no delivery record at all — nothing is sent, so
  /// there is nothing for a `delivery_status` to describe. Its «مسلمة»
  /// is a `completed` booking and nothing more.
  String? deliveryStatusFor(WorkshopFamily family) =>
      family == WorkshopFamily.makeYourCandle ? null : deliveryStatus;

  /// The frames this FAMILY actually has.
  ///
  /// «صناعة شمعك» has five of the nine. A candle is finished and taken
  /// home at the end of the session — the spec gives that family a null
  /// `delivery_fee` and `has_delivery: false` — so there is no kiln to
  /// wait on, no piece to collect later, and no courier leg: no
  /// «قيد التحضير», «القطعة جاهزة», «قيد التغليف» or «خرجت للتوصيل».
  /// «مسلمة» is still the last frame, because the piece IS in the
  /// customer's hands; it just got there without a journey.
  static List<BookingStage> forFamily(WorkshopFamily family) =>
      family == WorkshopFamily.makeYourCandle
      ? const [confirmed, attending, absent, handedOver, cancelled]
      : values;

  /// How tall the drawing stands.
  ///
  /// PER STAGE, not one number for all of them: the line drawings are
  /// not the same shape. The calendar is a wide, flat loop and the
  /// potter at her wheel is a figure — given the same box the figure
  /// comes out half the size and the page looks like it lost its
  /// picture.
  double get illustrationHeight => switch (this) {
    confirmed => 132,
    attending => 240,
    absent => 210,
    // The kiln flame is the one PORTRAIT drawing in the set — tall and
    // narrow where the others are wide.
    preparing => 260,
    ready => 200,
    packing => 170,
    onTheWay => 190,
    // The mark sizes itself; this is the band it sits in.
    handedOver => 240,
    cancelled => 150,
  };

  /// The line drawing at the head of the page.
  String get illustration => switch (this) {
    confirmed => 'assets/images/workshop-illustration-1-1.png',
    attending => 'assets/images/workshop-illustration-2-1.png',
    // Pots, one of them broken. The studio's own way of saying a
    // session went by — gentler than a red cross, which is what the
    // CANCELLED frame uses.
    absent => 'assets/images/workshop-illustration-3.png',
    // The kiln. Warm, and the only drawing in the set with a fill
    // rather than a line — the piece is being made, not waited on.
    preparing => 'assets/images/workshop-illustration-4.png',
    // The finished vessel, alone on its horizon.
    ready => 'assets/images/workshop-illustration-5.png',
    // The wrapped gift.
    packing => 'assets/images/workshop-illustration-6.png',
    // The van.
    onTheWay => 'assets/images/workshop-illustration-7.png',
    // A MARK, not a drawing — see [showsSuccessMark]. This is the
    // flourish at the STARTING corner; [endIllustration] is the other.
    handedOver => 'assets/images/workshop-illustration-2.png',
    // The calendar with a red cross, the twin of the confirmed
    // frame's green tick.
    cancelled => 'assets/images/workshop-illustration-8.png',
  };

  /// The drawing for this stage IN THIS FAMILY.
  ///
  /// Only «حاضرة» differs: the design draws the customer doing the
  /// thing they came for, and that is a different picture in each of
  /// the three workshops — the potter at her wheel, the painter with
  /// her palette, the candle-maker at her flame. Every other frame is
  /// about the PIECE (the kiln, the van, the calendar) and is drawn
  /// once for all three.
  String illustrationFor(WorkshopFamily family) =>
      this == attending ? _attendingArt(family) : illustration;

  static String _attendingArt(WorkshopFamily family) => switch (family) {
    WorkshopFamily.makeYourPiece =>
      'assets/images/workshop-illustration-2-1.png',
    // The painter, beret and palette.
    WorkshopFamily.paintYourPiece =>
      'assets/images/workshop-illustration-9.png',
    // The candle, lit.
    WorkshopFamily.makeYourCandle =>
      'assets/images/workshop-illustration-10.png',
  };

  /// The second flourish, at the ending corner — only «مسلمة» has one.
  ///
  /// Two DIFFERENT drawings: a brush and tube at one side, the glaze
  /// jar at the other. One asset mirrored read as the same picture
  /// twice.
  String? get endIllustration =>
      this == handedOver ? 'assets/images/workshop-illustration-1.png' : null;

  /// Whether the head of the page is a SUCCESS MARK rather than a line
  /// drawing.
  ///
  /// Only «مسلمة». Every other frame draws the thing that is happening
  /// — a kiln, a van, a calendar — but the end of the story is not a
  /// thing, it is a fact, and the design draws it as one.
  bool get showsSuccessMark => this == handedOver;

  String get heading => switch (this) {
    confirmed => BookingStrings.detailConfirmed,
    attending => BookingStrings.attendingTitle,
    absent => BookingStrings.absentTitle,
    preparing => BookingStrings.preparingTitle,
    ready => DeliveryStrings.pieceReady,
    packing => BookingStrings.packingTitle,
    onTheWay => BookingStrings.onTheWayTitle,
    handedOver => BookingStrings.handedOverTitle,
    cancelled => BookingStrings.cancelledTitle,
  };

  /// The line under the heading. [hoursAway] is only read by the
  /// confirmed frame, which counts down to the session; [readyIn] only
  /// by «قيد التحضير», and only when the studio has given one.
  String body(int hoursAway, {int? readyIn}) => switch (this) {
    confirmed => BookingStrings.scanOnArrival(hoursAway),
    attending => BookingStrings.attendingBody,
    absent => BookingStrings.absentBody,
    // THE STUDIO'S OWN ESTIMATE, or nothing about timing at all. See
    // [BookingStrings.preparingBody].
    preparing =>
      readyIn == null
          ? BookingStrings.preparingBody
          : BookingStrings.preparingBodyIn(
              BookingStrings.daysAndHours(readyIn),
            ),
    ready => DeliveryStrings.pieceReadyBody,
    packing => BookingStrings.packingBody,
    onTheWay => BookingStrings.onTheWayBody,
    handedOver => BookingStrings.handedOverBody,
    cancelled => BookingStrings.cancelledBody,
  };

  /// The line under the heading, IN THIS FAMILY.
  ///
  /// Only «قيد التحضير» differs. The «صناعة كوبك» frame can carry the
  /// studio's estimate of how long the piece takes to dry and fire;
  /// the «تلوين كوبك» one cannot, because what is being arranged there
  /// is the painting of a piece that already exists.
  ///
  /// «لم تحضر» reads the same in every family DESPITE the design
  /// wording its two frames differently: the refund is not a family
  /// policy. `POST /api/scan/check-in` states it outright — a no-show
  /// has "already been refunded" once the session is finished, and a
  /// partial check-in refunds the missing seats automatically. So the
  /// fuller sentence is the true one everywhere, and the shorter one
  /// was the earlier draft.
  String bodyFor(WorkshopFamily family, int hoursAway, {int? readyIn}) =>
      this == preparing && family == WorkshopFamily.paintYourPiece
      ? BookingStrings.preparingBodyPainted
      : body(hoursAway, readyIn: readyIn);

  /// Whether «القطعة جاهزة» offers to book the piece in to be PAINTED,
  /// on top of the two ways of taking it home.
  ///
  /// Only «صناعة كوبك». It is an upsell into the studio's other
  /// workshop, and a piece that has just BEEN painted has nowhere
  /// further to go — the design draws two buttons on that frame where
  /// this one has three. «صناعة شمعك» never reaches this frame at all:
  /// a candle goes home the same day.
  bool showsPaintUpsellFor(WorkshopFamily family) =>
      this == ready && family == WorkshopFamily.makeYourPiece;

  /// The scan chip, filled in the workshop's own colour.
  ///
  /// **Kept for the whole life of a booking.** It used to disappear
  /// the moment the session ended, on the reasoning that there was
  /// nothing left at the desk to scan it against — but the code is
  /// also the booking's REFERENCE, the eight digits a customer reads
  /// out at the counter when they come to collect a piece or ask what
  /// happened to it. Taking it away at `preparing` removed it exactly
  /// when the collection conversation starts.
  ///
  /// Gone on «ملغاة» alone: a cancelled booking has no counter
  /// conversation left, and a code that opens onto nothing is worse
  /// than no code.
  bool get showsQr => this != cancelled;

  /// The dashed well for a photograph of the piece. Only while the
  /// workshop is actually happening.
  bool get showsUpload => this == attending;

  /// Reschedule and cancel. Gone the moment the session starts — there
  /// is nothing left to move.
  bool get canModify => this == confirmed;

  /// Where the studio is. Offered while there is still a reason to go.
  bool get showsLocation => this == confirmed;

  /// Take it home, have it sent, or book it in to be painted. Only
  /// once the piece is out of the kiln.
  bool get showsHandover => this == ready;

  /// The collection-deadline warning — the red mark by the drawing,
  /// and the sheet it opens.
  ///
  /// **[ready] only, and NOT because `pickup_deadline` is null
  /// otherwise.** The server goes on sending a deadline after the
  /// piece has left: booking 51 came back `delivery_status:
  /// on_the_way` with `pickup_deadline` still set, so a mark gated on
  /// that field alone warned a customer that the studio would stop
  /// holding a piece which was already on a van.
  ///
  /// There is nothing to collect on any other frame. Before [ready]
  /// the piece is not finished; after it, it has been packed, sent or
  /// handed over.
  bool get showsPickupDeadline => this == ready;

  /// Which way the pair of stars sits around the heading.
  ///
  /// One high on the starting side and one low on the ending side, and
  /// the two swap from frame to frame — so a customer flicking between
  /// their bookings sees the page change even when the words are
  /// nearly the same length.
  bool get starsLeadHigh => switch (this) {
    confirmed => true,
    attending => false,
    absent => true,
    preparing => false,
    ready => true,
    packing => false,
    onTheWay => true,
    handedOver => false,
    cancelled => true,
  };
}
