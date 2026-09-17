import 'package:freezed_annotation/freezed_annotation.dart';

import '../core/paginated_rows.dart';
import 'app_notification.dart';

part 'notification_inbox.freezed.dart';
part 'notification_inbox.g.dart';

/// `GET /api/notifications` — the inbox and its unread badge.
///
/// The payload is `{"unread_count": n, "notifications": [...]}`, so the
/// badge count comes from the same call as the list. The home screen's
/// bell reads [unreadCount] rather than counting unread rows itself —
/// the list may be paginated, the count never is.
@freezed
abstract class NotificationInbox with _$NotificationInbox {
  const factory NotificationInbox({
    @Default(0) int unreadCount,

    /// The rows, from a bare list OR from the paginator `per_page`
    /// turns them into — see [readPaginatedRows]. Declared as a list
    /// alone this threw inside `fromJson` and took `unread_count`, the
    /// field the badge is driven from, down with it.
    @JsonKey(fromJson: _readNotifications)
    @Default(<AppNotification>[])
    List<AppNotification> notifications,
  }) = _NotificationInbox;

  const NotificationInbox._();

  factory NotificationInbox.fromJson(Map<String, dynamic> json) =>
      _$NotificationInboxFromJson(json);

  bool get hasUnread => unreadCount > 0;
}

List<AppNotification> _readNotifications(Object? json) =>
    readPaginatedRows(json, AppNotification.fromJson);
