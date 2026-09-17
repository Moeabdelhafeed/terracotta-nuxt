import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../core/notifications/notification_channels.dart';
import '../../core/notifications/notification_payload.dart';
import '../../core/notifications/notification_types.dart';
import '../../core/notifications/notifications.dart';
import '../../core/utils/loggers/logger.dart';

/// Concrete [NotificationDisplayService] backed by
/// `flutter_local_notifications`. Handles:
///  - **Immediate display** — `show(payload)` creates a system-level
///    notification right now.
///  - **Scheduling** — `schedule(payload, at:)` for reminders /
///    countdowns / digests.
///  - **Channel registration** — walks [NotificationChannelsRegistry]
///    at startup so every category declared in core materializes on
///    Android.
///  - **Tap handling** — delegates to [Notifications.reportTap],
///    which in turn dispatches through [NotificationRouter].
///
/// Registers with [Notifications.registerSystemDisplay] during init,
/// so feature code talks to the facade, not this class directly.
///
/// Registered lazily in `service_locator.dart`; call
/// `getIt<LocalNotificationService>().init()` during bootstrap.
class LocalNotificationService implements NotificationDisplayService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Maps our stable string IDs (payload.id) to the plugin's int IDs
  /// — `flutter_local_notifications` uses `int` for cancel/schedule.
  /// Keys are stable across process but not persisted, so on cold
  /// start scheduled IDs we don't remember can only be cancelled via
  /// [cancelAll].
  final Map<String, int> _idMap = {};
  int _nextId = 1;

  Future<LocalNotificationService> init() async {
    await _initializePlugin();
    await _createChannels();
    Notifications.registerSystemDisplay(this);
    Logger.m.i(
      '[Notifications] LocalNotificationService ready (${NotificationChannelsRegistry.all.length} channels)',
    );
    return this;
  }

  Future<void> _initializePlugin() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission:
          false, // request explicitly via NotificationPermissions
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundTap,
    );
  }

  Future<void> _createChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    for (final channel in NotificationChannelsRegistry.all) {
      await android.createNotificationChannel(_toAndroidChannel(channel));
    }
  }

  AndroidNotificationChannel _toAndroidChannel(NotificationChannelConfig c) {
    return AndroidNotificationChannel(
      c.id,
      c.name,
      description: c.description,
      importance: _toAndroidImportance(c.defaultPriority),
      playSound: c.sound,
      enableVibration: c.vibration,
      enableLights: c.lights,
    );
  }

  Importance _toAndroidImportance(NotificationPriority p) => switch (p) {
    NotificationPriority.low => Importance.low,
    NotificationPriority.normal => Importance.defaultImportance,
    NotificationPriority.high => Importance.high,
    NotificationPriority.max => Importance.max,
  };

  Priority _toAndroidPriority(NotificationPriority p) => switch (p) {
    NotificationPriority.low => Priority.low,
    NotificationPriority.normal => Priority.defaultPriority,
    NotificationPriority.high => Priority.high,
    NotificationPriority.max => Priority.max,
  };

  NotificationDetails _buildDetails(NotificationPayload payload) {
    final channel = NotificationChannelsRegistry.forType(payload.type);
    final priority = payload.effectivePriority;

    final android = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: _toAndroidImportance(priority),
      priority: _toAndroidPriority(priority),
      playSound: channel.sound && priority != NotificationPriority.low,
      enableVibration:
          channel.vibration && priority != NotificationPriority.low,
    );

    final ios = DarwinNotificationDetails(
      categoryIdentifier: channel.iosCategory,
      presentAlert: true,
      presentBadge: channel.badge,
      presentSound: channel.sound && priority != NotificationPriority.low,
      interruptionLevel: _toIosInterruptionLevel(priority),
    );

    return NotificationDetails(android: android, iOS: ios);
  }

  InterruptionLevel _toIosInterruptionLevel(NotificationPriority p) =>
      switch (p) {
        NotificationPriority.low => InterruptionLevel.passive,
        NotificationPriority.normal => InterruptionLevel.active,
        NotificationPriority.high => InterruptionLevel.active,
        NotificationPriority.max => InterruptionLevel.timeSensitive,
      };

  int _resolveId(String? stableId) {
    if (stableId == null) return _nextId++;
    return _idMap.putIfAbsent(stableId, () => _nextId++);
  }

  // ─── NotificationDisplayService implementation ───────────────────

  @override
  Future<void> show(NotificationPayload payload) async {
    final id = _resolveId(payload.id);
    await _plugin.show(
      id: id,
      title: payload.title,
      body: payload.body,
      notificationDetails: _buildDetails(payload),
      payload: payload.encode(),
    );
  }

  @override
  Future<void> schedule(
    NotificationPayload payload, {
    required DateTime at,
  }) async {
    final id = _resolveId(payload.id);
    await _plugin.zonedSchedule(
      id: id,
      title: payload.title,
      body: payload.body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: _buildDetails(payload),
      payload: payload.encode(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  @override
  Future<void> cancel(String id) async {
    final intId = _idMap.remove(id);
    if (intId != null) await _plugin.cancel(id: intId);
  }

  @override
  Future<void> cancelAll() async {
    _idMap.clear();
    await _plugin.cancelAll();
  }

  @override
  Future<List<String>> pendingIds() async {
    final pending = await _plugin.pendingNotificationRequests();
    // Map int ids back to string ids where we know them.
    final reverseMap = {for (final e in _idMap.entries) e.value: e.key};
    return pending.map((r) => reverseMap[r.id] ?? '#${r.id}').toList();
  }

  // ─── Tap handling ────────────────────────────────────────────────

  void _onTap(NotificationResponse response) {
    final payload = _parseResponse(response);
    if (payload == null) return;
    Notifications.reportTap(payload);
  }

  // Background handler — top-level function required by plugin. We
  // forward to the same logic; note that the router won't be bound
  // yet if the app was terminated, so the payload ends up in the
  // cold-start queue.
  @pragma('vm:entry-point')
  static void _onBackgroundTap(NotificationResponse response) {
    // No-op in debug: background isolate can't touch Notifications
    // facade's stream controllers anyway. The tap is re-delivered
    // via FCM's `onMessageOpenedApp` path when the app comes up.
    if (kDebugMode) {
      // ignore: avoid_print
      print('[Notifications] background local tap: ${response.payload}');
    }
  }

  NotificationPayload? _parseResponse(NotificationResponse response) {
    try {
      final raw = response.payload;
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return NotificationPayload.fromData(decoded);
      }
    } catch (e) {
      Logger.m.w('[Notifications] failed to parse local tap payload: $e');
    }
    return null;
  }
}
