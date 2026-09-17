import '../../../generated/l10n.dart';
import '../number_formatter.dart';
import '../tr.dart';

/// Home screen — greeting, sections, the active-booking card.
class HomeStrings {
  HomeStrings._();

  static String greeting(String name) =>
      Tr.t('home_greeting', S.current.home_greeting(name));

  static String get continueWorkshop =>
      Tr.t('home_continue_workshop', S.current.home_continue_workshop);

  // ─── the two LIVE strips, above the hero ──────────────────
  //
  // They sit at the very top because they are the only things on this
  // page that are true RIGHT NOW — an order on its way, and a session
  // the customer is sitting in. Everything below is browsing.

  static String get liveOrder =>
      Tr.t('home_live_order', S.current.home_live_order);

  static String get liveWorkshop =>
      Tr.t('home_live_workshop', S.current.home_live_workshop);

  static String liveOrderEta(String when) =>
      Tr.t('home_live_order_eta', S.current.home_live_order_eta(when));

  static String liveWorkshopUntil(String time) => Tr.t(
    'home_live_workshop_until',
    S.current.home_live_workshop_until(time),
  );

  /// The check-in code the desk scans. The one thing a customer who is
  /// already AT the studio needs from this app.
  /// «ورشتك القادمة» — the seat already booked, above the page.
  ///
  /// Its own words, not «استكمل ورشتك»: that was a section heading
  /// under a card, and this is a chip beside one. It sits next to
  /// «يحدث الآن» and has to read as the same kind of fact.
  static String get nextBooking =>
      Tr.t('home_next_booking', S.current.home_next_booking);

  /// «الخميس ٣ سبتمبر · ٧:٠٠ م» — when it is.
  static String nextBookingWhen(String date, String time) => Tr.t(
    'home_next_booking_when',
    S.current.home_next_booking_when(date, time),
  );

  static String get liveShowCode =>
      Tr.t('home_live_show_code', S.current.home_live_show_code);

  static String liveItems(int count) =>
      Tr.t('home_live_items', S.current.home_live_items(count));

  static String get featured => Tr.t('home_featured', S.current.home_featured);

  static String get offers => Tr.t('home_offers', S.current.home_offers);

  static String get browseCategories =>
      Tr.t('home_browse_categories', S.current.home_browse_categories);

  static String get seeAll => Tr.t('home_see_all', S.current.home_see_all);

  /// «عرض الكل (٤)» — the same way through, saying how many are behind
  /// it.
  ///
  /// The number is the server's `total` for the filter the button
  /// applies, so it is the length of the list that opens rather than
  /// the length of the rail it sits above — a rail shows a handful and
  /// «عرض الكل» is a promise about the rest.
  static String seeAllCount(int count) => Tr.t(
    'home_see_all_count',
    S.current.home_see_all_count(AppNumbers.localizeDigits('$count')),
  );

  static String get badgeFeatured =>
      Tr.t('home_badge_featured', S.current.home_badge_featured);

  /// The bar's title once the greeting has scrolled away.
  static String get title => Tr.t('home_title', S.current.home_title);

  /// The currency every price is quoted in. One tenant, one currency —
  /// the API sends no currency code alongside the amount.
  static String get currency =>
      Tr.t('money_currency', S.current.money_currency);
}
