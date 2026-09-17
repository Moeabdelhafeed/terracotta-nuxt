import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/notifications/notification_payload.dart';
import '../../core/notifications/notifications.dart';
import '../../core/utils/loggers/logger.dart';
import 'notification_model.dart';

/// Persistent inbox of received notifications. Listens to
/// [Notifications.onDelivered] and writes each one to the existing
/// [NotificationDatabase] (SQLite) for display in an in-app
/// notifications screen.
///
/// Exposes the live list as a [ValueListenable] so UI can bind via
/// `ValueListenableBuilder` without any state-management framework.
///
/// Registered lazily in `service_locator.dart`; call
/// `getIt<NotificationHistoryService>().init()` during bootstrap
/// (only when `NotificationsConfig.bootstrap(enableHistory: true)`).
class NotificationHistoryService {
  final ValueNotifier<List<NotificationModel>> items =
      ValueNotifier<List<NotificationModel>>(const []);
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  StreamSubscription<NotificationPayload>? _deliveredSub;

  Future<NotificationHistoryService> init() async {
    // sqflite has no web implementation. Skip DB ops on web — the
    // in-memory `items` notifier still receives live deliveries via
    // the stream listener, but persistence is disabled.
    if (!kIsWeb) {
      await refreshFromDb();
    }
    _deliveredSub = Notifications.onDelivered.listen(_onDelivered);
    Logger.m.i(
      '[Notifications] HistoryService ready (${items.value.length} items)'
      '${kIsWeb ? ' — persistence disabled on web' : ''}',
    );
    return this;
  }

  void dispose() {
    _deliveredSub?.cancel();
    items.dispose();
    unreadCount.dispose();
  }

  Future<void> _onDelivered(NotificationPayload payload) async {
    final model = NotificationModel(
      title: payload.title,
      body: payload.body,
      timestamp: payload.receivedAt ?? DateTime.now(),
      data: payload.data,
    );
    if (kIsWeb) {
      // No DB on web — append to the in-memory list only.
      items.value = [model, ...items.value];
      _recomputeUnread();
      return;
    }
    try {
      await NotificationDatabase.insertNotification(model);
      await refreshFromDb();
    } catch (e) {
      Logger.m.w('[Notifications] history insert failed: $e');
    }
  }

  Future<void> refreshFromDb() async {
    if (kIsWeb) return;
    try {
      items.value = await NotificationDatabase.getNotifications();
      _recomputeUnread();
    } catch (e) {
      Logger.m.w('[Notifications] history fetch failed: $e');
      items.value = const [];
    }
  }

  Future<void> markAsRead(int id) async {
    await NotificationDatabase.markAsRead(id);
    await refreshFromDb();
  }

  Future<void> markAllAsRead() async {
    await NotificationDatabase.markAllAsRead();
    await refreshFromDb();
  }

  Future<void> delete(int id) async {
    await NotificationDatabase.deleteNotification(id);
    await refreshFromDb();
  }

  Future<void> clear() async {
    await NotificationDatabase.deleteAllNotifications();
    await refreshFromDb();
  }

  void _recomputeUnread() {
    unreadCount.value = items.value.where((n) => !n.isRead).length;
  }
}
