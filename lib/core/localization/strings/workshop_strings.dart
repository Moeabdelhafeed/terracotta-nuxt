import '../../../data/models/terracotta/workshop/workshop_audience.dart';
import '../../../generated/l10n.dart';
import '../tr.dart';

/// Workshops — the browse tab, the accordion detail, the wallet and gift cards.
class WorkshopStrings {
  WorkshopStrings._();

  static String get title => Tr.t('workshop_title', S.current.workshop_title);

  static String get subtitle =>
      Tr.t('workshop_subtitle', S.current.workshop_subtitle);

  static String get tabMine =>
      Tr.t('workshop_tab_mine', S.current.workshop_tab_mine);

  static String get tabBook =>
      Tr.t('workshop_tab_book', S.current.workshop_tab_book);

  static String get book => Tr.t('workshop_book', S.current.workshop_book);

  static String get location =>
      Tr.t('workshop_location', S.current.workshop_location);

  static String pricePerPerson(String price) => Tr.t(
    'workshop_price_per_person',
    S.current.workshop_price_per_person(price),
  );

  static String seatsPerSession(String count) => Tr.t(
    'workshop_seats_per_session',
    S.current.workshop_seats_per_session(count),
  );

  static String get durationHour =>
      Tr.t('workshop_duration_hour', S.current.workshop_duration_hour);

  static String durationMinutes(int minutes) => Tr.t(
    'workshop_duration_minutes',
    S.current.workshop_duration_minutes(minutes),
  );

  static String get gift => Tr.t('workshop_gift', S.current.workshop_gift);

  static String get walletBalance =>
      Tr.t('workshop_wallet_balance', S.current.workshop_wallet_balance);

  static String get viewTransactions =>
      Tr.t('workshop_view_transactions', S.current.workshop_view_transactions);

  /// A fact the CMS has not filled in — a price, a duration, a
  /// description. Printed rather than left blank: an empty chip reads
  /// as a screen that failed to load.
  static String get notSpecified =>
      Tr.t('workshop_not_specified', S.current.workshop_not_specified);

  /// The catalogue came back, and it is empty — a different sentence
  /// from one that failed to arrive.
  static String get empty => Tr.t('workshop_empty', S.current.workshop_empty);

  // ─── The studio's own location ─────────────────────────────

  static String get studioLocation =>
      Tr.t('workshop_studio_location', S.current.workshop_studio_location);

  static String get openInMaps =>
      Tr.t('workshop_open_in_maps', S.current.workshop_open_in_maps);

  /// Shown ON the placeholder, so the empty panel says why it is
  /// empty rather than looking like a map that failed to load.
  static String get mapPending =>
      Tr.t('workshop_map_pending', S.current.workshop_map_pending);

  /// `location_url` is null on every workshop the studio has published
  /// so far, so this is the state the sheet actually opens in today.
  static String get noLocation =>
      Tr.t('workshop_no_location', S.current.workshop_no_location);

  /// «حسب القطعة» — what a catalogue workshop costs.
  ///
  /// `paint_your_piece` and `make_your_candle` carry a seat price of
  /// `"0.00"` because the money is in the products the customer picks,
  /// so the chip read «٠ ريال للشخص» — which says free, and is the
  /// opposite of true.
  static String get pricePerPiece =>
      Tr.t('workshop_price_per_piece', S.current.workshop_price_per_piece);

  /// «أمامك ٧ أيام لاستلام قطعتك» — the collection window, promised
  /// BEFORE booking.
  ///
  /// From `piece_warning_days` on the workshop, which the studio sets
  /// per workshop and which is what the booking's own
  /// `pickup_deadline` is later computed from. Said as a span rather
  /// than a bare number so «يوم واحد» reads properly — see
  /// `BookingStrings.daysAndHours`.
  static String pieceHold(String days) =>
      Tr.t('workshop_piece_hold', S.current.workshop_piece_hold(days));

  /// WHO THE SESSION IS FOR. Nothing on the server checks a booking
  /// against this — the app never asks anybody's gender — so being
  /// able to read it is the whole of what keeps a customer out of the
  /// wrong room.
  static String audience(WorkshopAudience audience) => switch (audience) {
    WorkshopAudience.womenOnly => Tr.t(
      'workshop_audience_women',
      S.current.workshop_audience_women,
    ),
    WorkshopAudience.menOnly => Tr.t(
      'workshop_audience_men',
      S.current.workshop_audience_men,
    ),
    WorkshopAudience.couples => Tr.t(
      'workshop_audience_couples',
      S.current.workshop_audience_couples,
    ),
    WorkshopAudience.kids => Tr.t(
      'workshop_audience_kids',
      S.current.workshop_audience_kids,
    ),
    WorkshopAudience.families => Tr.t(
      'workshop_audience_families',
      S.current.workshop_audience_families,
    ),
    WorkshopAudience.mixed => Tr.t(
      'workshop_audience_mixed',
      S.current.workshop_audience_mixed,
    ),
  };
}
