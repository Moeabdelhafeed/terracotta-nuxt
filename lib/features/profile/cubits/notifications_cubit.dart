import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/types/result.dart';
import '../../../data/api/calls/inbox_apis.dart';
import '../../../data/models/api/envelope_list.dart';
import '../../../data/models/terracotta/account/app_notification.dart';
import '../../../data/models/terracotta/account/notification_filter.dart';
import '../../../data/models/terracotta/account/notification_inbox.dart';
import '../../_shared/locale_scoped_load.dart';
import 'notifications_state.dart';

typedef InboxFetch =
    AsyncResult<EnvelopeOne<NotificationInbox>> Function({
      bool? unreadOnly,
      NotificationFilter? filter,
      int? perPage,
      int? page,
      CancelToken? cancelToken,
    });

typedef MarkAllRead =
    AsyncResult<Map<String, dynamic>> Function({CancelToken? cancelToken});

typedef MarkOneRead =
    AsyncResult<Map<String, dynamic>> Function(
      String notificationId, {
      CancelToken? cancelToken,
    });

/// The notification inbox.
///
/// `LocaleScopedLoad`, unlike the wallet beside it: `title` and `body`
/// arrive PRE-RENDERED and pre-translated from the server, so a
/// language change means every row on screen is in the wrong one and
/// nothing in the app can fix it without asking again.
class NotificationsCubit extends Cubit<NotificationsState>
    with LocaleScopedLoad {
  NotificationsCubit({
    InboxFetch? fetch,
    MarkAllRead? markAll,
    MarkOneRead? markOne,
  }) : _fetch = fetch ?? InboxApis.getNotifications,
       _markAll = markAll ?? _defaultMarkAll,
       _markOne = markOne ?? _defaultMarkOne,
       super(const NotificationsState());

  final InboxFetch _fetch;
  final MarkAllRead _markAll;
  final MarkOneRead _markOne;
  final _cancel = CancelToken();

  /// One page. `per_page` is sent whatever the number — omitting it
  /// returns the WHOLE inbox as a bare array.
  static const perPage = 30;

  static AsyncResult<Map<String, dynamic>> _defaultMarkAll({
    CancelToken? cancelToken,
  }) => InboxApis.markAllNotificationsRead(cancelToken: cancelToken);

  static AsyncResult<Map<String, dynamic>> _defaultMarkOne(
    String id, {
    CancelToken? cancelToken,
  }) => InboxApis.markNotificationRead(id, cancelToken: cancelToken);

  @override
  bool get hasData => state.loaded;

  @override
  Future<void> load() async {
    emit(state.copyWith(loading: true, clearError: true));

    final result = await _fetch(
      filter: state.filter,
      perPage: perPage,
      cancelToken: _cancel,
    );
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(
          state.copyWith(
            items: value.value.notifications,
            unread: value.value.unreadCount,
            // BESIDE `data`, not inside it — see [EnvelopeOne]. The
            // tallies are for the whole inbox whatever slice this was,
            // so they survive a filtered load unchanged.
            counts: value.intMap('filter_counts'),
            loading: false,
            loaded: true,
          ),
        );
      case Failure(:final error):
        // A failed REFRESH keeps the rows already on screen; only a
        // failed FIRST load leaves the page with nothing.
        emit(state.copyWith(loading: false, error: error));
    }
  }

  /// Switch tabs.
  ///
  /// **The SERVER filters, not the page.** The inbox paginates, so
  /// narrowing the rows already fetched would show a handful of
  /// bookings out of nine and call it the bookings tab. Re-asking is
  /// also what keeps `filter_counts` fresh.
  ///
  /// A repeat of the current filter is a no-op rather than a reload:
  /// tapping the tab you are on should do nothing.
  Future<void> showFilter(NotificationFilter filter) async {
    if (filter == state.filter) return;
    // THE ROWS GO WITH THE TAB. Left in place they would sit under the
    // new chip as though they belonged to it — «الحجوزات» showing
    // orders for as long as the request takes, which is the one moment
    // a reader is looking to see what changed.
    emit(state.copyWith(filter: filter, items: const [], loading: true));
    await load();
  }

  Future<void> refresh(String locale) => refreshIn(locale);

  /// Signed out: there is nothing to show, and what is here belongs to
  /// whoever was signed in before.
  ///
  /// **`invalidate()` alone was not enough.** It clears the mark that
  /// says which language the data arrived in, so the next
  /// `ensureLoaded` asks again — but the ROWS and the unread NUMBER
  /// stayed in the state, and this is a `getIt` singleton the bell in
  /// every bar reads. A guest therefore went on wearing the last
  /// customer's badge, and opening the inbox showed their
  /// notifications, until something happened to reload it. Nothing
  /// does: the page does not ask without a session.
  void clear() {
    invalidate();
    emit(const NotificationsState(loading: false));
  }

  /// Re-read the inbox in whatever language it was last read in.
  ///
  /// For a caller with no `BuildContext` and therefore no locale — a
  /// PUSH arriving. Every push is also a row here and the badge counts
  /// rows, but `unread_count` only ever changes when this endpoint is
  /// asked again: the number the bell was holding does not move
  /// because a notification landed. A push that arrives before
  /// anything has been loaded is left alone — there is nothing on
  /// screen to be stale.
  Future<void> refreshNow() async {
    final locale = loadedLocale;
    if (locale == null) return;
    await refreshIn(locale);
  }

  /// Mark everything read.
  ///
  /// The badge is taken from the RESPONSE, not zeroed locally — a call
  /// that failed would otherwise leave the badge lying.
  Future<void> markAllRead() async {
    if (state.unread == 0) return;

    final before = state;
    emit(
      state.copyWith(
        unread: 0,
        items: [for (final n in state.items) n.copyWith(isRead: true)],
      ),
    );

    final result = await _markAll(cancelToken: _cancel);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        emit(state.copyWith(unread: _countFrom(value) ?? 0));
      case Failure():
        emit(before);
    }
  }

  /// Mark ONE read — what opening a notification does.
  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;

    final before = state;
    emit(
      state.copyWith(
        items: [
          for (final n in state.items)
            if (n.id == notification.id) n.copyWith(isRead: true) else n,
        ],
        unread: (state.unread - 1).clamp(0, state.unread),
      ),
    );

    final result = await _markOne('${notification.id}', cancelToken: _cancel);
    if (isClosed) return;

    switch (result) {
      case Success(:final value):
        // The server's own count, when it sent one. A local decrement
        // drifts the moment two devices read the same row.
        final fresh = _countFrom(value);
        if (fresh != null) emit(state.copyWith(unread: fresh));
      case Failure():
        emit(before);
    }
  }

  /// `unread_count` out of a `data: {...}` body, or null when the
  /// server sent none — these two routes answer a bare map.
  static int? _countFrom(Map<String, dynamic> body) {
    final value = body['unread_count'];
    return value is int ? value : int.tryParse('$value');
  }

  @override
  Future<void> close() {
    _cancel.cancel('notifications closed');
    return super.close();
  }
}
