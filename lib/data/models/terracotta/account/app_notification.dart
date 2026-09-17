// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

/// One inbox entry — `GET /api/notifications` →
/// `data.notifications[]`, alongside the `unread_count` the bell badge
/// reads. Newest first. `?unread_only=true` filters the list;
/// `POST /api/notifications/read-all` clears every [readAt].
///
/// **[title] and [body] were rendered server-side, in the language the
/// account had at the moment the notification was created.** They do
/// NOT re-translate when the app's language changes, and they are not
/// ARB keys — display them verbatim, never look them up through `Tr.t`.
///
/// **[data] is the tap target and its shape depends on [type].** It is
/// a free-form bag: `{"gift_id": 4, "type": "gift_redeemed"}` in the
/// capture, `{"shop_order_id": 12, ...}` for an order notification. It
/// is typed as a raw map on purpose — modelling it would mean one
/// class per notification type, all of them speculative. Route on
/// [type], then read the one id you need with a null-safe lookup.
///
/// **[data] repeats [type].** The nested copy exists so the FCM push
/// payload (which carries only `data`) can route the same way as an
/// inbox tap. They have always agreed; prefer the top-level [type].
///
/// [type] is an OPEN set defined by the backend — `gift_redeemed` and
/// `shop_order_out_for_delivery` are the two seen. There is no enum
/// here deliberately: a `switch` over CMS-driven strings would either
/// throw or silently swallow a new kind. Match the ones you handle and
/// fall through to a plain "open the inbox" tap for the rest.
///
/// Timestamps on this endpoint carry an OFFSET
/// (`2026-08-26T11:43:34+00:00`) where `GET /api/user` sends microseconds
/// and a `Z` (`2026-08-26T11:33:05.000000Z`). Both are valid ISO-8601
/// and `DateTime.parse` takes either; both are UTC, so convert with
/// `.toLocal()` before formatting.
///
/// [readAt] is null while unread — the capture's two rows are both
/// read, but `unread_count` proves the other state exists.
@freezed
abstract class AppNotification with _$AppNotification {
  const factory AppNotification({
    required int id,

    /// Machine-readable kind (`"gift_redeemed"`). Open set — routes the
    /// tap. See the class doc.
    required String type,

    /// Pre-rendered, pre-translated headline. Display verbatim.
    required String title,

    /// Pre-rendered, pre-translated body. Display verbatim.
    required String body,

    /// Free-form routing payload, shaped by [type]. Nullable: a
    /// notification with nothing to open carries no bag.
    Map<String, dynamic>? data,

    required bool isRead,

    /// When it was read. Null while unread.
    DateTime? readAt,

    required DateTime createdAt,
  }) = _AppNotification;

  const AppNotification._();

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  /// Reads one id out of [data] without assuming its shape.
  ///
  /// Returns null when the bag is absent, the key is missing, or the
  /// value is not an int — a routing miss must not throw.
  int? routeId(String key) {
    final Object? value = data?[key];
    return value is int ? value : null;
  }
}
