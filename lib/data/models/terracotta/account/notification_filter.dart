/// Which slice of the inbox `GET /api/notifications` should answer for.
///
/// The server owns this list — anything else is a **422 keyed to
/// `filter`** — so it is an enum rather than a free string, and
/// [wire] is the only spelling that ever goes out.
///
/// ## The counts are for the WHOLE inbox
///
/// `meta.filter_counts` carries a number for every one of these,
/// always across everything the customer has, never across the tab
/// being viewed. That is the point of them: a tab has to be labelled
/// before anyone opens it. A tab with nothing behind it is `0`, not
/// missing — so a missing key means an older server, not an empty tab.
///
/// Counting the rows on screen answers a different question, because
/// the list is paginated.
enum NotificationFilter {
  all('all'),
  unread('unread'),
  bookings('bookings'),
  reminders('reminders'),
  pieces('pieces'),
  orders('orders'),
  gifts('gifts'),
  wallet('wallet');

  const NotificationFilter(this.wire);

  /// What goes on the query string, and the key in `filter_counts`.
  final String wire;

  bool get isAll => this == NotificationFilter.all;

  bool get isUnread => this == NotificationFilter.unread;

  /// The default. Sent as nothing at all rather than `filter=all`,
  /// which is the same answer with one less thing to be wrong.
  static const NotificationFilter initial = NotificationFilter.all;
}
