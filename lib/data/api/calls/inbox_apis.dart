import 'package:dio/dio.dart';

import '../../../core/constants/enums/api/request_type.dart';
import '../../../core/types/result.dart';
import '../../models/api/envelope_list.dart';
import '../../models/terracotta/account/complaint.dart';
import '../../models/terracotta/account/notification_filter.dart';
import '../../models/terracotta/account/notification_inbox.dart';
import '../api_service.dart';
import '../endpoints/terracotta_endpoints.dart';

/// Inbox API calls — notifications, the realtime channel handshake and
/// complaints.
///
/// Every method returns an `AsyncResult<...>` — pattern-match at the
/// call site; nothing here throws.
///
/// House rules that touch this group:
/// - **Notifications belong to the caller.** A guest browsing without a
///   token gets **401** here, same as cart and favourites. Draw the
///   signed-out state rather than firing the call.
/// - **Timestamps come back in `Asia/Riyadh` already** (a workshop
///   reminder's `start_time` included). Display them as-is — a second
///   client-side conversion is what makes a time look hours off.
/// - **Money inside a notification payload is a decimal STRING**
///   (`"65.00"`). Never round-trip it through `double`, and remember
///   `vat_amount` is INCLUSIVE — already inside `total_price`.
/// - **Nothing in this group buys anything.** Purchases are always
///   three steps (quote → create → pay) on their own endpoints; an
///   order notification only ever links back to one.
class InboxApis {
  InboxApis._();

  // ─── Per-endpoint log flags ───────────────────────────────

  static ApiLogConfig logGetNotifications = kApiLogVerbose;
  static ApiLogConfig logMarkAllNotificationsRead = kApiLogVerbose;
  static ApiLogConfig logMarkNotificationRead = kApiLogVerbose;
  static ApiLogConfig logAuthorizeBroadcastChannel = kApiLogVerbose;
  static ApiLogConfig logGetComplaints = kApiLogVerbose;
  static ApiLogConfig logSendComplaint = kApiLogVerbose;

  // ─── Mock setup ───────────────────────────────────────────

  /// Register mock responses for the GET endpoints in this class.
  /// Call once at app init when [ApiService.useMock] is true.
  static void installMocks() {
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.notifications,
      type: RequestType.get,
      data: {
        'unread_count': 1,
        'notifications': [
          {
            'id': 5,
            'type': 'shop_order_out_for_delivery',
            'title': 'Your order is on the way',
            'body': 'Order #12 has left the shop.',
            'data': {'shop_order_id': 12},
            'is_read': false,
            'read_at': null,
            'created_at': '2026-08-16T12:00:00+00:00',
          },
        ],
      },
    );
    ApiService.registerMock(
      endpoint: TerracottaEndpoints.complaints,
      type: RequestType.get,
      data: [
        {
          'id': 12,
          'type': 'delivery',
          'message': 'My order arrived with a cracked cup.',
          'reference': '48392017',
          'status': 'resolved',
          'created_at': '2026-08-17T09:00:00+00:00',
          'resolved_at': '2026-08-18T10:00:00+00:00',
        },
      ],
    );
  }

  // ─── API methods ──────────────────────────────────────────

  /// The caller's notifications, newest first, with `unread_count`
  /// sitting beside the `notifications` list in the same object — and
  /// the tab tallies beside `data` rather than inside it.
  ///
  /// Auth only — a guest session gets 401.
  ///
  /// **The tallies are a SIBLING of `data`.** `meta.filter_counts`
  /// carries a number for every [NotificationFilter], always across
  /// the whole inbox and never across the slice being viewed, which is
  /// what lets a tab be labelled before anyone opens it. A parser
  /// handed `data` alone cannot see them, hence [EnvelopeOne] — the
  /// same shape `GET /api/workshops/bookings` needed for
  /// `meta.status_counts`.
  ///
  /// [filter] is validated server-side: anything outside the enum is a
  /// **422 keyed to `filter`**. [NotificationFilter.all] is sent as
  /// nothing at all — the same answer with one less thing to be wrong.
  ///
  /// [unreadOnly] is the older spelling of `filter=unread` and still
  /// works; pass one or the other, not both.
  ///
  /// Trap: **omitting [perPage] returns EVERYTHING.** Pass it to
  /// paginate, and note that when you do, `data` becomes Laravel's
  /// paginator and the rows move down a level.
  static AsyncResult<EnvelopeOne<NotificationInbox>> getNotifications({
    bool? unreadOnly,
    NotificationFilter? filter,
    int? perPage,
    int? page,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getSingleWithMeta<NotificationInbox>(
      TerracottaEndpoints.notifications,
      queryParameters: {
        if (unreadOnly != null) 'unread_only': unreadOnly,
        if (filter != null && filter != NotificationFilter.all)
          'filter': filter.wire,
        if (perPage != null) 'per_page': perPage,
        if (page != null) 'page': page,
      },
      fromJson: NotificationInbox.fromJson,
      logRequest: logGetNotifications.request,
      logResponse: logGetNotifications.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Mark every notification read in one call.
  ///
  /// Returns the authoritative `unread_count` (`0`) — take the badge
  /// from the response rather than zeroing it locally, so a failed
  /// call can't leave the badge lying.
  static AsyncResult<Map<String, dynamic>> markAllNotificationsRead({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.notificationsReadAll,
      fromJson: (json) => json,
      logRequest: logMarkAllNotificationsRead.request,
      logResponse: logMarkAllNotificationsRead.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Mark one notification read, returning the fresh `unread_count`.
  ///
  /// Safe to repeat — a second call on an already-read notification
  /// just re-reports the same count. Drive the badge from the
  /// response, never from a local decrement.
  static AsyncResult<Map<String, dynamic>> markNotificationRead(
    String notificationId, {
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.notificationRead(notificationId),
      fromJson: (json) => json,
      logRequest: logMarkNotificationRead.request,
      logResponse: logMarkNotificationRead.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// Authorise the socket for a private broadcast channel — the
  /// handshake Pusher/Echo makes before it can subscribe.
  ///
  /// [socketId] is generated client-side by the socket library; pass
  /// its value straight through, don't synthesise one.
  ///
  /// Trap: this endpoint answers with a **bare** `{"auth": "..."}`
  /// body — it is the one route in this group that does NOT use the
  /// standard `{success, message, errors, data}` envelope, so the
  /// shared envelope parser will reject it as "expected `data` on a
  /// successful response". Until a raw-body path exists on
  /// [ApiService], treat a failure here as "handshake not wired" and
  /// read the token off the wire another way.
  static AsyncResult<Map<String, dynamic>> authorizeBroadcastChannel({
    required String channelName,
    required String socketId,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Map<String, dynamic>>(
      TerracottaEndpoints.broadcastingAuth,
      data: {
        'channel_name': channelName,
        'socket_id': socketId,
      },
      fromJson: (json) => json,
      logRequest: logAuthorizeBroadcastChannel.request,
      logResponse: logAuthorizeBroadcastChannel.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// The complaints the caller has filed, with their `status` and
  /// `resolved_at`.
  ///
  /// Auth only — unlike [sendComplaint], which is public. Same path,
  /// split auth: you can complain signed out, you can only list your
  /// own signed in.
  static AsyncResult<List<Complaint>> getComplaints({
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().getList<Complaint>(
      TerracottaEndpoints.complaints,
      fromJson: Complaint.fromJson,
      logRequest: logGetComplaints.request,
      logResponse: logGetComplaints.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );

  /// File a complaint. Public — a signed-out visitor can send one.
  ///
  /// [type] is one of `order`, `workshop`, `delivery`, `payment`,
  /// `other`. [reference] is an order number, booking code or anything
  /// else that helps find it.
  ///
  /// Traps:
  /// - [name] and [contact] are **required when there is no bearer
  ///   token** (`required_without_bearer`) and **ignored when signed
  ///   in** — the server takes those from the account instead. Send
  ///   them only for a guest, or the 422 lands on fields the form
  ///   isn't showing.
  /// - This POST sits on the strict `auth` rate limiter — **5 per
  ///   minute**, not the usual 60 — so a retry loop here turns into a
  ///   429 fast.
  static AsyncResult<Complaint> sendComplaint({
    required String type,
    required String message,
    String? name,
    String? contact,
    String? reference,
    CancelToken? cancelToken,
    Duration? timeout,
  }) => ApiService.call(
    () => ApiService().post<Complaint>(
      TerracottaEndpoints.complaints,
      data: {
        'type': type,
        'message': message,
        if (name != null) 'name': name,
        if (contact != null) 'contact': contact,
        if (reference != null) 'reference': reference,
      },
      fromJson: Complaint.fromJson,
      logRequest: logSendComplaint.request,
      logResponse: logSendComplaint.response,
      cancelToken: cancelToken,
      timeout: timeout,
    ),
  );
}
