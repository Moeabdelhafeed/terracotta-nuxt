import 'package:flutter/foundation.dart';

/// A list response AND the envelope's own `meta` beside it.
///
/// Most list endpoints answer `data: [...]` and nothing else, and
/// `getList` is right for those. A few carry a side-band that is a
/// SIBLING of `data` rather than part of it — `GET
/// /api/workshops/bookings` sends `meta.status_counts`, a tally of the
/// customer's whole history that does not move when `?status=` filters
/// the rows — and a parser handed only `data` cannot see it.
///
/// [meta] is raw because the key holds a different shape per endpoint.
/// Read one value out of it with [intMap] rather than modelling it.
@immutable
class EnvelopeList<T> {
  const EnvelopeList({required this.items, this.meta});

  final List<T> items;

  /// The envelope's `meta`, or null when the server sent none.
  final Map<String, dynamic>? meta;

  /// A `{"confirmed": 1, "cancelled": 3}` block under [key], with
  /// anything unreadable dropped.
  ///
  /// Total on purpose: a tally is decoration on top of a list, and a
  /// server that starts sending a string where a number was must not
  /// take the bookings down with it.
  Map<String, int> intMap(String key) => _readIntMap(meta, key);
}

/// The same side-band beside a `data` that is an OBJECT rather than a
/// list.
///
/// `GET /api/notifications` is the one that forced this: `data` is
/// `{unread_count, notifications}` and the tab tallies arrive as a
/// SIBLING, `meta.filter_counts` — counts for the whole inbox, which is
/// the entire point of them, since they have to label a tab nobody has
/// opened yet. A parser handed only `data` cannot see them, and
/// counting the rows on screen answers a different question.
@immutable
class EnvelopeOne<T> {
  const EnvelopeOne({required this.value, this.meta});

  final T value;

  /// The envelope's `meta`, or null when the server sent none.
  final Map<String, dynamic>? meta;

  /// As [EnvelopeList.intMap].
  Map<String, int> intMap(String key) => _readIntMap(meta, key);
}

Map<String, int> _readIntMap(Map<String, dynamic>? meta, String key) {
  final raw = meta?[key];
  if (raw is! Map) return const {};
  return {
    for (final entry in raw.entries)
      if (entry.value is int) entry.key.toString(): entry.value as int,
  };
}
