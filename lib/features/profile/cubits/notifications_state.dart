import 'package:flutter/foundation.dart';

import '../../../core/error/app_exception.dart';
import '../../../data/models/terracotta/account/app_notification.dart';
import '../../../data/models/terracotta/account/notification_filter.dart';

/// «الاشعارات» — the inbox and its badge.
@immutable
class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.unread = 0,
    this.loading = true,
    this.error,
    this.loaded = false,
    this.filter = NotificationFilter.initial,
    this.counts = const <String, int>{},
  });

  final List<AppNotification> items;

  /// From `unread_count` on the same call — NEVER from counting unread
  /// rows, which paginate while the count does not.
  final int unread;

  final bool loading;
  final AppException? error;

  /// Whether an answer has ever arrived. Separates "nothing yet" from
  /// "nothing there", which are different screens.
  final bool loaded;

  /// Which slice [items] is. The SERVER filtered them — the list
  /// paginates, so filtering the page on screen would hide rows that
  /// simply had not been fetched.
  final NotificationFilter filter;

  /// `meta.filter_counts`, keyed by [NotificationFilter.wire].
  ///
  /// Always across the WHOLE inbox, never across [filter] — which is
  /// what lets a tab be labelled before anyone opens it. Empty until
  /// the first answer, and on an older server that sends no `meta`;
  /// [countFor] returns null there so a tab shows no number rather
  /// than a wrong one.
  final Map<String, int> counts;

  /// The tally behind one tab, or null when the server sent none.
  ///
  /// A tab with nothing behind it is `0`, not missing — so a missing
  /// key means an older server, not an empty tab.
  int? countFor(NotificationFilter which) => counts[which.wire];

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unread,
    bool? loading,
    AppException? error,
    bool? loaded,
    NotificationFilter? filter,
    Map<String, int>? counts,
    bool clearError = false,
  }) => NotificationsState(
    items: items ?? this.items,
    unread: unread ?? this.unread,
    loading: loading ?? this.loading,
    error: clearError ? null : error ?? this.error,
    loaded: loaded ?? this.loaded,
    filter: filter ?? this.filter,
    counts: counts ?? this.counts,
  );
}
