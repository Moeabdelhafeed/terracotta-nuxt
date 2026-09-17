import '../../../generated/l10n.dart';
import '../tr.dart';

/// Booking flow — slot picking, piece selection, confirmation, the detail states, QR check-in, reschedule and cancel.
class BookingStrings {
  BookingStrings._();

  static String get pickSlot =>
      Tr.t('booking_pick_slot', S.current.booking_pick_slot);

  static String peopleCount(String count) =>
      Tr.t('booking_people_count', S.current.booking_people_count(count));

  static String sessionTime(String start, String end) =>
      Tr.t('booking_session_time', S.current.booking_session_time(start, end));

  static String seatsLeft(String left, String total) =>
      Tr.t('booking_seats_left', S.current.booking_seats_left(left, total));

  static String forPeople(String count) =>
      Tr.t('booking_for_people', S.current.booking_for_people(count));

  static String get pickPieces =>
      Tr.t('booking_pick_pieces', S.current.booking_pick_pieces);

  static String selectedPieces(int count) =>
      Tr.t('booking_selected_pieces', S.current.booking_selected_pieces(count));

  /// How many pieces this booking may carry IN TOTAL — the workshop's
  /// per-person bounds already multiplied by the party. The server
  /// checks the total and says so in the same words.
  static String piecesRange(int min, int max) =>
      Tr.t('booking_pieces_range', S.current.booking_pieces_range(min, max));

  /// The same rule when the floor IS the ceiling — «اختر من ١ الى ١
  /// قطعة» is a range of one, and the studio's live workshop is
  /// exactly that.
  static String piecesExact(int count) =>
      Tr.t('booking_pieces_exact', S.current.booking_pieces_exact(count));

  /// The same rule on a workshop the CMS gave a floor but no ceiling.
  static String piecesMinOnly(int min) => Tr.t(
    'booking_pieces_min_only',
    S.current.booking_pieces_min_only(min),
  );

  static String get piecesTotal =>
      Tr.t('booking_pieces_total', S.current.booking_pieces_total);

  static String get piecesEmpty =>
      Tr.t('booking_pieces_empty', S.current.booking_pieces_empty);

  /// What to call a product the CMS saved with no name in this
  /// language. It is a real row with a real price — drawn nameless it
  /// reads as a broken card.
  static String get pieceUntitled =>
      Tr.t('booking_piece_untitled', S.current.booking_piece_untitled);

  /// Where a piece is going next, on the card for it.
  ///
  /// **This is also why nothing is nagging them to collect it.** While
  /// the paint session is upcoming the studio is HOLDING the piece,
  /// and the server sends `pickup_deadline: null` and keeps
  /// `is_pickup_overdue` false for that reason. Without this line the
  /// countdown simply vanishes with nothing saying why — which reads
  /// as the app having lost track of the piece.
  static String piecePaintingOn(String workshop, String date) => Tr.t(
    'booking_piece_painting_on',
    S.current.booking_piece_painting_on(workshop, date),
  );

  /// The same fact once that session has run: the piece is painted,
  /// not waiting.
  static String piecePaintedAt(String workshop) => Tr.t(
    'booking_piece_painted_at',
    S.current.booking_piece_painted_at(workshop),
  );

  /// «قطعي» — the customer's own pieces, brought back to be painted.
  static String get ownPieces =>
      Tr.t('booking_own_pieces', S.current.booking_own_pieces);

  static String get ownPiecesHint =>
      Tr.t('booking_own_pieces_hint', S.current.booking_own_pieces_hint);

  /// When a piece was made — what tells two similar cups apart.
  static String ownPieceMadeOn(String date) => Tr.t(
    'booking_own_piece_made_on',
    S.current.booking_own_piece_made_on(date),
  );

  static String get confirmedTitle =>
      Tr.t('booking_confirmed_title', S.current.booking_confirmed_title);

  /// «يمكنك الإلغاء أو تغيير الموعد حتى …».
  ///
  /// The deadline is the BOOKING's, not a constant. It was the
  /// sentence "within 3 hours of confirming", which was wrong twice
  /// over: the window is the workshop's own
  /// `cancellation_window_hours`, and it is measured back from the
  /// SESSION's start rather than forward from the moment of paying.
  static String confirmedBody(String when) => Tr.t(
    'booking_confirmed_body',
    S.current.booking_confirmed_body(when),
  );

  /// The same line for a booking that never had a window — one made
  /// inside it has no cancellation right at all.
  static String get confirmedBodyFinal => Tr.t(
    'booking_confirmed_body_final',
    S.current.booking_confirmed_body_final,
  );

  static String get track => Tr.t('booking_track', S.current.booking_track);

  static String get detailConfirmed =>
      Tr.t('booking_detail_confirmed', S.current.booking_detail_confirmed);

  /// «والمتبقي على موعدها …» — how long until the session, in the
  /// biggest unit that is still true.
  ///
  /// [hours] is the whole picture and [daysAndHours] words it. A
  /// countdown that only counts DAYS said «٠ أيام» for a session six
  /// hours away, which reads as "already over" rather than "today".
  static String scanOnArrival(int hours) {
    if (hours < 1) return scanOnArrivalSoon;
    return Tr.t(
      'booking_scan_on_arrival',
      S.current.booking_scan_on_arrival(daysAndHours(hours)),
    );
  }

  /// A SPAN, in the biggest units that are still true — «١٥ ساعة»,
  /// «٤ أيام», «٤ أيام و١٥ ساعة».
  ///
  /// Counting only whole days rounded «٤ أيام و١٥ ساعة» down to «٤
  /// أيام» — nearly a whole day thrown away, and the countdown then
  /// appeared not to move for a day at a time. A round number of days
  /// says just the days, because «و٠ ساعة» is noise.
  static String daysAndHours(int hours) {
    if (hours < 24) return hourCount(hours);

    final days = hours ~/ 24;
    final rest = hours % 24;
    if (rest == 0) return dayCount(days);

    return Tr.t(
      'booking_unit_days_hours',
      S.current.booking_unit_days_hours(dayCount(days), hourCount(rest)),
    );
  }

  /// «٤ أيام» — the unit on its own, for a sentence that pairs it with
  /// another.
  static String dayCount(int count) =>
      Tr.t('booking_unit_days', S.current.booking_unit_days(count));

  /// «١٥ ساعة».
  static String hourCount(int count) =>
      Tr.t('booking_unit_hours', S.current.booking_unit_hours(count));

  /// Under an hour: no number is worth printing.
  static String get scanOnArrivalSoon => Tr.t(
    'booking_scan_on_arrival_soon',
    S.current.booking_scan_on_arrival_soon,
  );

  static String get scanCode =>
      Tr.t('booking_scan_code', S.current.booking_scan_code);

  static String get qrInstructions =>
      Tr.t('booking_qr_instructions', S.current.booking_qr_instructions);

  static String get reschedule =>
      Tr.t('booking_reschedule', S.current.booking_reschedule);

  static String get rescheduleTitle =>
      Tr.t('booking_reschedule_title', S.current.booking_reschedule_title);

  static String get change => Tr.t('booking_change', S.current.booking_change);

  /// The lifecycle, as words.
  ///
  /// The wire sends MACHINE KEYS — `pending_payment`, `checked_in` —
  /// and printing one raw is how a customer ends up reading
  /// `pending_payment` on their own booking. An unmodelled value falls
  /// back to nothing here, and the caller shows no chip rather than a
  /// key.
  static String? status(String wire) => switch (wire) {
    'pending_payment' => Tr.t(
      'booking_status_pending_payment',
      S.current.booking_status_pending_payment,
    ),
    'confirmed' => Tr.t(
      'booking_status_confirmed',
      S.current.booking_status_confirmed,
    ),
    'attending' => Tr.t(
      'booking_status_attending',
      S.current.booking_status_attending,
    ),
    'absent' => Tr.t(
      'booking_status_absent',
      S.current.booking_status_absent,
    ),
    'preparing' => Tr.t(
      'booking_status_preparing',
      S.current.booking_status_preparing,
    ),
    'completed' => Tr.t(
      'booking_status_completed',
      S.current.booking_status_completed,
    ),
    'cancelled' => Tr.t(
      'booking_status_cancelled',
      S.current.booking_status_cancelled,
    ),
    _ => null,
  };

  /// «شخص» / «شخصان» / «أشخاص» — the unit under a party-size tile.
  ///
  /// PLURALISED, because "1 people" is not a thing anybody says.
  /// Arabic counts in six buckets and uses four of them here: one,
  /// two, a few (3–10) and many (11+); English has the two it has.
  /// «شخص واحد» / «شخصان» / «٣ أشخاص» — the party, counted and named
  /// in one string.
  ///
  /// The count and the unit have to be pluralised TOGETHER: «١ اشخاص»
  /// is what you get from gluing a number to a fixed word, and it is
  /// wrong in both languages.
  static String party(int count) =>
      Tr.t('booking_party', S.current.booking_party(count));

  static String peopleUnit(int count) =>
      Tr.t('booking_people_unit', S.current.booking_people_unit(count));

  static String get pickPeople =>
      Tr.t('booking_pick_people', S.current.booking_pick_people);

  static String get noSlots =>
      Tr.t('booking_no_slots', S.current.booking_no_slots);

  static String get fullUp =>
      Tr.t('booking_full_up', S.current.booking_full_up);

  /// «٦ من ٨» — seats LEFT, of the session's capacity.
  ///
  /// Was a BACKSLASH between the two numbers, which read as "8\\8" —
  /// eight of eight, i.e. full — on a session that was in fact
  /// completely empty. The word between them is what makes the pair
  /// mean what it means.
  static String slotSeats(String left, String total) =>
      Tr.t('booking_slot_seats', S.current.booking_slot_seats(left, total));

  /// «ورشة من ٣ م الى ٤ م». The times are Asia/Riyadh and are shown
  /// exactly as the server sent them — a workshop happens at the
  /// studio, not wherever the customer is standing.
  static String slotLabel(String start, String end) =>
      Tr.t('booking_slot_label', S.current.booking_slot_label(start, end));

  static String get mineEmpty =>
      Tr.t('booking_mine_empty', S.current.booking_mine_empty);

  /// «٢ أشخاص · الثلاثاء ٤ يونيو · ٣ م الى ٤ م».
  static String meta(String people, String date, String time) =>
      Tr.t('booking_meta', S.current.booking_meta(people, date, time));

  static String get cancel => Tr.t('booking_cancel', S.current.booking_cancel);

  static String get cancelTitle =>
      Tr.t('booking_cancel_title', S.current.booking_cancel_title);

  static String get cancelConfirm =>
      Tr.t('booking_cancel_confirm', S.current.booking_cancel_confirm);

  /// «نقل الحجز؟» — the same question «الغاء» asks, for the same
  /// reason: moving a booking releases the seats it held and takes new
  /// ones, and a mis-tap on a slot list should not be able to do that
  /// silently.
  static String get rescheduleConfirmTitle => Tr.t(
    'booking_reschedule_confirm_title',
    S.current.booking_reschedule_confirm_title,
  );

  static String get rescheduleConfirmBody => Tr.t(
    'booking_reschedule_confirm_body',
    S.current.booking_reschedule_confirm_body,
  );

  static String get rescheduleConfirmYes => Tr.t(
    'booking_reschedule_confirm_yes',
    S.current.booking_reschedule_confirm_yes,
  );

  static String get yes => Tr.t('booking_yes', S.current.booking_yes);

  static String get no => Tr.t('booking_no', S.current.booking_no);

  static String get close => Tr.t('booking_close', S.current.booking_close);

  /// The celebration sheet's own copy.
  static String get celebrationTitle =>
      Tr.t('celebration_title', S.current.celebration_title);

  static String get celebrationBody =>
      Tr.t('celebration_body', S.current.celebration_body);

  static String celebrationAddPrice(String price) => Tr.t(
    'celebration_add_price',
    S.current.celebration_add_price(price),
  );

  static String get withCelebration =>
      Tr.t('booking_with_celebration', S.current.booking_with_celebration);

  static String get addCelebration =>
      Tr.t('booking_add_celebration', S.current.booking_add_celebration);

  static String get removeCelebration =>
      Tr.t('booking_remove_celebration', S.current.booking_remove_celebration);

  static String get myBookings =>
      Tr.t('booking_my_bookings', S.current.booking_my_bookings);

  static String get empty => Tr.t('booking_empty', S.current.booking_empty);

  static String get slotFull =>
      Tr.t('booking_slot_full', S.current.booking_slot_full);

  static String get slotConflict =>
      Tr.t('booking_slot_conflict', S.current.booking_slot_conflict);

  /// `pending_payment`, as the server sends it.
  ///
  /// Statuses arrive as MACHINE KEYS — `confirmed`, `on_the_way`,
  /// `pending_payment` — and CLAUDE.md is explicit that one must never
  /// reach the screen unmapped. This is that mapping for the one the
  /// home card shows.
  static String get statusPendingPayment => Tr.t(
    'booking_status_pending_payment',
    S.current.booking_status_pending_payment,
  );

  /// Joins a start and an end time — «٣ م الى ٤ م».
  static String get timeTo =>
      Tr.t('booking_time_to', S.current.booking_time_to);

  /// The lifecycle frames the design draws for one booking.
  ///
  /// «حاضرة» is the studio's own wording — the feminine form, as the
  /// design has it, because the workshop is «الورشة».
  static String get absentTitle =>
      Tr.t('booking_absent_title', S.current.booking_absent_title);
  static String get absentBody =>
      Tr.t('booking_absent_body', S.current.booking_absent_body);
  static String get attendingTitle =>
      Tr.t('booking_attending_title', S.current.booking_attending_title);
  static String get attendingBody =>
      Tr.t('booking_attending_body', S.current.booking_attending_body);

  /// The dashed well on an in-progress booking. The customer's own
  /// piece, photographed at the wheel.
  static String get uploadPiece =>
      Tr.t('booking_upload_piece', S.current.booking_upload_piece);

  /// «قيد التحضير» — the kiln frame. Distinct from the STATUS chip's
  /// «قيد التجهيز»: the chip labels a lifecycle value in one word, and
  /// the page's heading is the studio's own phrasing.
  static String get preparingTitle =>
      Tr.t('booking_preparing_title', S.current.booking_preparing_title);
  /// «جاري تجهيز قطعتك بعناية.» — with NO number in it.
  ///
  /// It used to promise "ready in 5 to 7 days" for every booking of
  /// every workshop. That is a commitment the studio never made and
  /// the app has no way to know: nothing on the booking row says when
  /// a piece will be fired. Use [preparingBodyIn] when the server
  /// actually sends one — see [Booking.readyAt].
  static String get preparingBody =>
      Tr.t('booking_preparing_body', S.current.booking_preparing_body);

  /// The same line WITH the studio's own estimate on it.
  static String preparingBodyIn(String span) => Tr.t(
    'booking_preparing_body_in',
    S.current.booking_preparing_body_in(span),
  );

  /// The same frame in «تلوين كوبك», where there is no five-to-seven
  /// days to promise: the piece already exists and what is being
  /// arranged is the painting. See `BookingStage.bodyFor`.
  static String get preparingBodyPainted => Tr.t(
    'booking_preparing_body_painted',
    S.current.booking_preparing_body_painted,
  );

  /// The four frames the handover leg draws, plus the cancelled one.
  static String get cancelledTitle =>
      Tr.t('booking_cancelled_title', S.current.booking_cancelled_title);
  static String get cancelledBody =>
      Tr.t('booking_cancelled_body', S.current.booking_cancelled_body);
  static String get packingTitle =>
      Tr.t('booking_packing_title', S.current.booking_packing_title);
  static String get packingBody =>
      Tr.t('booking_packing_body', S.current.booking_packing_body);
  static String get onTheWayTitle =>
      Tr.t('booking_on_the_way_title', S.current.booking_on_the_way_title);
  static String get onTheWayBody =>
      Tr.t('booking_on_the_way_body', S.current.booking_on_the_way_body);
  static String get handedOverTitle => Tr.t(
    'booking_handed_over_title',
    S.current.booking_handed_over_title,
  );
  static String get handedOverBody =>
      Tr.t('booking_handed_over_body', S.current.booking_handed_over_body);

  // ─── The cancellation window ───────────────────────────────
  //
  // A workshop's `cancellation_window_hours` is measured back from the
  // SESSION's start, so the same workshop is cancellable on next
  // week's slot and not on tomorrow's. The availability row says which
  // — `is_non_cancellable` and `cancel_until`.

  /// Asked BEFORE the money moves, because afterwards is too late to
  /// be told.
  static String get noCancelTitle =>
      Tr.t('booking_no_cancel_title', S.current.booking_no_cancel_title);

  static String get noCancelBody =>
      Tr.t('booking_no_cancel_body', S.current.booking_no_cancel_body);

  static String get noCancelConfirm =>
      Tr.t('booking_no_cancel_confirm', S.current.booking_no_cancel_confirm);

  /// «ألغِ قبل … ويعود المبلغ كاملاً إلى رصيدك» — the deadline and
  /// what happens to the money, on the screen that takes it.
  static String cancelPolicy(String when) => Tr.t(
    'booking_cancel_policy',
    S.current.booking_cancel_policy(when),
  );

  /// The same note when there is no window left at all.
  static String get cancelPolicyNone => Tr.t(
    'booking_cancel_policy_none',
    S.current.booking_cancel_policy_none,
  );

  // ─── Photographing the pieces ──────────────────────────────
  //
  // The server groups photos into PIECES by the label the customer
  // types, matched case- and whitespace-insensitively — so the same
  // name twice is one piece photographed twice. Two caps, both
  // cumulative: four photos per person, and (for the catalogue types)
  // no more distinct names than pieces paid for.

  static String get pieceLabel =>
      Tr.t('booking_piece_label', S.current.booking_piece_label);

  static String get pieceLabelHint =>
      Tr.t('booking_piece_label_hint', S.current.booking_piece_label_hint);

  /// The same collision, said about an OBJECT.
  ///
  /// On «صمم قطعتك» a label is a PERSON — the studio writes it on what
  /// that person made — so «هذا الاسم مأخوذ لشخص آخر» is right there.
  /// On the catalogue families the label names the piece the customer
  /// bought, and telling them the name belongs to another *person* is
  /// about somebody who does not exist in that flow.
  static String get pieceNameTaken => Tr.t(
    'booking_piece_name_taken',
    S.current.booking_piece_name_taken,
  );

  /// Whichever of the two this family calls a label.
  static String nameTakenFor({required bool person}) =>
      person ? nameTaken : pieceNameTaken;

  /// Two people with the same name leave the desk with two identical
  /// labels and nothing on either saying whose is whose.
  ///
  /// WHOSE name it is depends on the family — see [pieceNameTaken].
  static String get nameTaken =>
      Tr.t('booking_name_taken', S.current.booking_name_taken);

  static String get pieceLabelRequired => Tr.t(
    'booking_piece_label_required',
    S.current.booking_piece_label_required,
  );

  /// How many photographs the booking has left before its cap.
  static String photosLeft(String count) =>
      Tr.t('booking_photos_left', S.current.booking_photos_left(count));

  static String get photosFull =>
      Tr.t('booking_photos_full', S.current.booking_photos_full);




  static String pieceNumber(String index) => Tr.t(
    'booking_piece_number',
    S.current.booking_piece_number(index),
  );

  static String get pieceNeedsPhoto => Tr.t(
    'booking_piece_needs_photo',
    S.current.booking_piece_needs_photo,
  );

  // ─── One person at a time ─────────────────────────────────
  //
  // «صمم قطعتك» is booked for a NUMBER OF PEOPLE, and each of them
  // walks away with something. The sheet asks about ONE of them per
  // page: the field's own label says which, and a row of dots says
  // how many there are.
  //
  // It was two steps over everybody — name them all, then photograph
  // them all — which needed a step counter, a title, a sentence about
  // the party size and a note about the photo cap before the reader
  // reached the first field. Six lines of text for one name. A page
  // per person needs none of them: the dots are the count, the field
  // is the heading, and four empty slots are the cap.

  /// The field's own label — «الشخص ١» on the wheel, «القطعة ١» on the
  /// catalogue types.
  static String personHint(String index) =>
      Tr.t('booking_person_hint', S.current.booking_person_hint(index));

  static String pieceHint(String index) =>
      Tr.t('booking_piece_hint', S.current.booking_piece_hint(index));

  /// The placeholder INSIDE a name field on «صمم قطعتك».
  ///
  /// «كوبي» belongs to the catalogue types, where the thing being
  /// named is an object. Here it is a person, and prompting them with
  /// the name of a cup is what made the whole screen read as being
  /// about pieces.
  static String get personNameHint => Tr.t(
    'booking_person_name_hint',
    S.current.booking_person_name_hint,
  );

  static String get next => Tr.t('booking_next', S.current.booking_next);

  static String get back => Tr.t('booking_back', S.current.booking_back);

  /// Every person on the booking already has a piece, so there is
  /// nothing new to name — only angles to add to what is there.
  static String get allNamed =>
      Tr.t('booking_all_named', S.current.booking_all_named);

  // ─── Editing one piece ────────────────────────────────────


  static String get pieceName =>
      Tr.t('booking_piece_name', S.current.booking_piece_name);

  static String get save => Tr.t('booking_save', S.current.booking_save);

  static String get pieceRenamed =>
      Tr.t('booking_piece_renamed', S.current.booking_piece_renamed);

  /// «إضافة صور لـ سارة» — the sheet opened from ONE piece's card
  /// says whose it is in the title, so the page underneath does not
  /// have to repeat it above the pictures.
  static String addPhotosFor(String name) =>
      Tr.t('booking_add_photos_for', S.current.booking_add_photos_for(name));

  /// «تعديل اسم الشخص» — what the pencil actually does, rather than
  /// «تعديل», which could mean the photographs.
  static String get editPersonName =>
      Tr.t('booking_edit_person_name', S.current.booking_edit_person_name);

  static String get editPieceName =>
      Tr.t('booking_edit_piece_name', S.current.booking_edit_piece_name);

  /// The marker on a photograph the booking ALREADY holds, beside the
  /// «NEW» the picker puts on the ones about to be uploaded.
  static String get photosOld =>
      Tr.t('booking_photos_old', S.current.booking_photos_old);

  static String get done => Tr.t('booking_done', S.current.booking_done);

  /// The same well, said about a booking that is PART done — one
  /// person still without a piece, or a label deleted whole. «ارفع
  /// صورة قطعتك» reads as a first step, which is the wrong thing to
  /// tell somebody who has already uploaded three.
  static String get uploadRemaining =>
      Tr.t('booking_upload_remaining', S.current.booking_upload_remaining);

  static String get uploadPhotos =>
      Tr.t('booking_upload_photos', S.current.booking_upload_photos);

  static String get uploadSend =>
      Tr.t('booking_upload_send', S.current.booking_upload_send);


  static String get photosUploaded =>
      Tr.t('booking_photos_uploaded', S.current.booking_photos_uploaded);

  /// Says out loud that a repeated name is the way to photograph one
  /// piece twice — otherwise it reads as a mistake to avoid.

  /// The chip that clears the «ورشاتي» status filter.
  static String get filterAll =>
      Tr.t('booking_filter_all', S.current.booking_filter_all);

  // ─── The pieces already photographed ──────────────────────



  /// The well becomes this once there is something to add TO.
  static String get addMorePhotos =>
      Tr.t('booking_add_more_photos', S.current.booking_add_more_photos);

  static String get photoRemoved =>
      Tr.t('booking_photo_removed', S.current.booking_photo_removed);

  static String get pieceRemoved =>
      Tr.t('booking_piece_removed', S.current.booking_piece_removed);

  static String get removePhotoTitle => Tr.t(
    'booking_remove_photo_title',
    S.current.booking_remove_photo_title,
  );

  /// Says out loud that there is no replace — the API has a create and
  /// two deletes and nothing else.
  static String get removePhotoBody =>
      Tr.t('booking_remove_photo_body', S.current.booking_remove_photo_body);

  static String removePieceTitle(String label) => Tr.t(
    'booking_remove_piece_title',
    S.current.booking_remove_piece_title(label),
  );

  static String get removePieceBody =>
      Tr.t('booking_remove_piece_body', S.current.booking_remove_piece_body);

  static String piecePhotoCount(int count) => Tr.t(
    'booking_piece_photo_count',
    S.current.booking_piece_photo_count(count),
  );

  /// «موعدك الحالي» — the slot the booking is on NOW, in the
  /// reschedule sheet.
  ///
  /// It comes back with `has_conflict` like any other overlap, because
  /// the booking it clashes with is itself — so it read «لديك حجز
  /// يتعارض مع هذا الوقت», which is true and useless: the reader is
  /// looking at the sheet to MOVE that booking.
  static String get slotCurrent =>
      Tr.t('booking_slot_current', S.current.booking_slot_current);
}
