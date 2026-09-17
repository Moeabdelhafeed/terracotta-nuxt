import 'package:flutter/foundation.dart';

/// The two sides of the workshops control.
///
/// BOOK first, and first in the design too: it is the tab the reader
/// lands on. `mine` is the customer's own bookings.
enum WorkshopsTab {
  book,
  mine;

  /// Resolves the `?tab=` the route carries.
  ///
  /// A QUERY PARAMETER rather than an extra, because this is where the
  /// booking-confirmed screen sends the customer — and an extra does
  /// not survive the restart that a deep link into «ورشاتي» would.
  /// Anything unrecognised lands on [book], which is the tab the
  /// reader would otherwise have got.
  static WorkshopsTab fromWire(String? value) =>
      value == mine.name ? mine : book;

  /// The tab a screen elsewhere has ASKED for, or null.
  ///
  /// ## Why a request and not a route parameter
  ///
  /// `?tab=mine` is read when the page is BUILT. But «تتبع الحجز» on
  /// the confirmation goes to `/workshops`, and the booking flow
  /// started there — so GoRouter does not build anything: it pops back
  /// to the route already on the stack. The logs show it plainly:
  ///
  /// ```text
  /// pop: booking confirmed → workshops
  /// pop: booking checkout  → workshops
  /// pop: booking schedule  → workshops
  /// ```
  ///
  /// Three pops, no build, and the surviving `State` keeps the tab it
  /// had. The parameter is still read on a cold arrival — a deep link,
  /// or a push from somewhere else — and this covers the pop.
  ///
  /// Consumed once: the page takes it and clears it, so returning to
  /// «ورشاتي» later does not silently move the reader again.
  static final ValueNotifier<WorkshopsTab?> requested =
      ValueNotifier<WorkshopsTab?>(null);

  /// Ask for [tab] the next time the workshops page is looked at.
  static void request(WorkshopsTab tab) => requested.value = tab;

  /// Take the pending request, if any, and clear it.
  static WorkshopsTab? takeRequest() {
    final tab = requested.value;
    requested.value = null;
    return tab;
  }
}
