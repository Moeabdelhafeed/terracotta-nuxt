import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/auth/account_scope.dart';
import '../../core/di/service_locator.dart';
import '../../core/notifications/notification_payload.dart';
import '../../core/notifications/notification_permissions.dart';
import '../../core/notifications/notifications.dart';
import '../../core/utils/loggers/logger.dart';
import '../../features/profile/cubits/notifications_cubit.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../models/terracotta/account/app_config.dart';
import '../services/gift_package_service.dart';
import 'notification_topics.dart';
import 'push_diagnostics.dart';
import 'topic_subscription.dart';

/// Firebase Cloud Messaging adapter — the "push" side of the
/// notification pipeline. Handles:
///
///  - **Token lifecycle** — fetch + refresh + persist + forward to
///    the backend.
///  - **Foreground delivery** — when a push arrives while the app is
///    open, parses into [NotificationPayload] and routes through
///    [Notifications.show] so the facade picks in-app vs. system
///    display.
///  - **Tap from background** — when the user taps a push that the
///    OS displayed, we dispatch through [Notifications.reportTap]
///    (which in turn invokes [NotificationRouter]).
///  - **Cold-start tap** — if the app was launched by a tap
///    (terminated state), `getInitialMessage()` hands us the payload;
///    we stash it in [Notifications.setInitialPayload] for the first
///    screen to consume.
///
/// The **background isolate** handler lives in
/// [notification_background_handler.dart] — it must be a top-level
/// function, so it's not a method on this class.
class FCMService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  AuthBloc get _auth => getIt<AuthBloc>();

  StreamSubscription<RemoteMessage>? _onMessageSub;
  StreamSubscription<RemoteMessage>? _onOpenSub;
  StreamSubscription<String>? _onTokenRefreshSub;

  Future<FCMService> init() async {
    await _fcm.setAutoInitEnabled(true);
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _requestPermission();
    await _loadToken();
    _onTokenRefreshSub = _fcm.onTokenRefresh.listen(_onTokenRefresh);
    _wireMessageHandlers();
    await _captureInitialMessage();

    Logger.m.i('[Notifications] FCMService ready');
    return this;
  }

  void dispose() {
    _onMessageSub?.cancel();
    _onOpenSub?.cancel();
    _onTokenRefreshSub?.cancel();
  }

  // ─── Permission ──────────────────────────────────────────────────

  Future<void> _requestPermission() async {
    final status = await NotificationPermissions.check();
    if (status == NotificationPermissionStatus.denied) {
      // Template default: don't prompt at startup. Features should
      // call `Notifications.requestPermission()` at a moment where
      // the value is obvious to the user (first useful push flow).
      Logger.m.d('[Notifications] FCM permission not yet granted');
    }
  }

  // ─── Token ───────────────────────────────────────────────────────

  Future<void> _loadToken() async {
    try {
      final token = await _fcm.getToken();
      PushDiagnostics.instance.recordToken(token);
      if (token != null) {
        _auth.add(AuthEvent.fcmTokenChanged(token));
        Logger.m.d(
          '[Notifications] FCM token loaded: ${token.substring(0, 8)}…',
        );
      }
    } catch (e) {
      // iOS can fail with "APNS token not set" during app launch;
      // onTokenRefresh catches it later.
      // Web fails until `web/firebase-messaging-sw.js`, the Firebase
      // web config in `web/index.html`, and the VAPID key in
      // `.env` (FCM_VAPID_KEY) are wired — see
      // `docs/setup/17-web-fcm-setup.md`. Surface a pointer instead
      // of a bare stack trace so the next reader knows the fix.
      if (kIsWeb) {
        Logger.m.w(
          '[Notifications] FCM web init failed — finish web push setup. '
          'See docs/setup/17-web-fcm-setup.md. Underlying: $e',
        );
      } else {
        Logger.m.w('[Notifications] FCM token fetch failed: $e');
      }
    }
  }

  void _onTokenRefresh(String token) {
    PushDiagnostics.instance.recordToken(token);
    _auth.add(AuthEvent.fcmTokenChanged(token));
    Logger.m.i('[Notifications] FCM token refreshed');

    // AND TRY THE TOPICS AGAIN.
    //
    // This app's API **422s any request whose `X-FCM-Token` header is
    // empty**, and that header is filled from the token this callback
    // delivers. So a token that arrives LATE — which is the normal
    // case on a cold radio, and is why this callback exists at all —
    // means every request fired before it failed, including the
    // `GET /api/config` the topic names come from.
    //
    // That failure used to be permanent: the config was asked for
    // once at boot and never again, so a device whose token was a
    // second slow spent the whole session on no broadcast topics.
    // Arriving here is the moment the app can finally make that call
    // succeed, so it does.
    unawaited(TopicSubscription.resync());

    // AND THE GIFT PACKAGE, for the same reason and with the same
    // symptom: it 422'd on the empty header at boot, so the sheet
    // showed «أهدِ رصيداً» with a blank where «٢٠٠ ريال» belongs, and
    // `is_active` — the switch that decides whether the gift surface
    // is drawn at all — stayed unknown.
    if (getIt.isRegistered<GiftPackageService>()) {
      unawaited(getIt<GiftPackageService>().ensureLoaded());
    }
  }

  // Adopter: to register the device with your backend, listen for
  // `AuthEvent.fcmTokenChanged(token)` in your auth bloc or a
  // dedicated service and POST to your `/devices/register` endpoint.
  // Wrap the call in `OfflineActionQueue` so it survives offline boot.

  /// Current token, freshly fetched. Returns null on failure.
  Future<String?> getCurrentToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      Logger.m.w('[Notifications] FCM token fetch failed: $e');
      return null;
    }
  }

  /// Delete the token — call on logout to stop receiving pushes for
  /// the previous user. Also clears the stored copy.
  Future<void> deleteToken() async {
    try {
      await _fcm.deleteToken();
      _auth.add(const AuthEvent.fcmTokenChanged(''));
      Logger.m.i('[Notifications] FCM token deleted');
    } catch (e) {
      Logger.m.w('[Notifications] FCM token delete failed: $e');
    }
  }

  // ─── Topics (server-side fan-out) ────────────────────────────────

  /// Subscribe the device to a topic (e.g. `'promos'`). The backend
  /// then broadcasts by topic instead of by device list.
  Future<void> subscribeToTopic(String topic) async {
    // RECORDED EITHER WAY. The catch below is deliberate — a device
    // that cannot reach Google's subscription endpoint still receives
    // everything addressed to it personally — but it means a failure
    // leaves no trace, and in a release build the warning does not
    // even print. FCM has no API to ask which topics a device is on,
    // so this is the only record there will ever be.
    try {
      await _fcm.subscribeToTopic(topic);
      PushDiagnostics.instance.recordTopic(
        TopicAttempt(topic: topic, subscribed: true, at: DateTime.now()),
      );
    } catch (e) {
      Logger.m.w('[Notifications] subscribe "$topic" failed: $e');
      PushDiagnostics.instance.recordTopic(
        TopicAttempt(
          topic: topic,
          subscribed: true,
          at: DateTime.now(),
          error: '$e',
        ),
      );
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      PushDiagnostics.instance.recordTopic(
        TopicAttempt(topic: topic, subscribed: false, at: DateTime.now()),
      );
    } catch (e) {
      Logger.m.w('[Notifications] unsubscribe "$topic" failed: $e');
      PushDiagnostics.instance.recordTopic(
        TopicAttempt(
          topic: topic,
          subscribed: false,
          at: DateTime.now(),
          error: '$e',
        ),
      );
    }
  }

  /// Put this device on the BROADCAST topics that describe it, and
  /// take it off the ones that no longer do.
  ///
  /// A push addressed to one customer reaches their token with no
  /// topic at all — which is why notifications work without this. A
  /// studio-wide ANNOUNCEMENT has no device list: it is published to a
  /// topic, and a device that never subscribed never hears it.
  ///
  /// **The names come from `GET /api/config`** and are never guessed —
  /// see [NotificationTopics] for what guessing them silently cost.
  /// Nothing happens when [published] is empty: a server with no
  /// topics sends no broadcasts, and inventing names to fill the gap
  /// is what went wrong before.
  ///
  /// Called on every language change AND on sign-in and sign-out: a
  /// reader who signs in moves off `guests` onto `users`, and one who
  /// switches language should stop being sent announcements they
  /// cannot read.
  ///
  /// Best-effort throughout. A device that cannot reach Google's
  /// subscription endpoint still receives everything addressed to it
  /// personally, which is all of the app's own notifications.
  Future<void> syncTopics({
    required List<FcmTopic> published,
    required String languageCode,
    required bool signedIn,
  }) async {
    if (published.isEmpty) return;

    final wanted = NotificationTopics.forReader(
      published,
      languageCode: languageCode,
      signedIn: signedIn,
    ).toSet();

    PushDiagnostics.instance
      ..recordPublished([for (final t in published) t.name])
      ..recordWanted(wanted.toList(growable: false));

    // WHAT TO TAKE THE DEVICE OFF.
    //
    // Within a run, the topics this run asked for. On the FIRST sync
    // of a run, every published topic that is not wanted — because a
    // subscription lives on Google's side, keyed to the token, and
    // SURVIVES the app being killed. A reader who used English
    // yesterday and Arabic today starts with an empty `_subscribed`,
    // so diffing against it alone would leave them on `all_en`
    // for ever, quietly receiving announcements in a language they
    // switched away from. Unsubscribing from the whole published set
    // once per run is a handful of idempotent calls and closes that.
    final leaving = _reconciled
        ? _subscribed.difference(wanted)
        : {for (final t in published) t.name}.difference(wanted);
    _reconciled = true;

    for (final topic in leaving) {
      await unsubscribeFromTopic(topic);
    }
    for (final topic in wanted.difference(_subscribed)) {
      await subscribeToTopic(topic);
    }
    _subscribed
      ..clear()
      ..addAll(wanted);
    Logger.m.i('[Notifications] topics: ${wanted.join(', ')}');
  }

  /// What this run has already asked for. FCM itself is idempotent, so
  /// this only saves the round trips — and makes the unsubscribe half
  /// possible, since there is no way to ASK which topics a device is
  /// on.
  final _subscribed = <String>{};

  /// Whether this run has already squared the device against the full
  /// published list. See the note in [syncTopics].
  bool _reconciled = false;

  // ─── Message handlers ───────────────────────────────────────────

  void _wireMessageHandlers() {
    // App is foreground — we get the raw message, render it
    // ourselves (via Notifications.show) so the display target picks
    // in-app vs system based on current state.
    _onMessageSub = FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // App is background or foreground and user tapped the OS
    // notification — dispatch through the router.
    _onOpenSub = FirebaseMessaging.onMessageOpenedApp.listen(
      _onMessageOpenedApp,
    );
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    // BEFORE the parse, and whatever the parse makes of it. `from`
    // says whether this came over a topic or to this device's token,
    // and that is the one thing that tells "we are not subscribed"
    // apart from "nothing was sent".
    PushDiagnostics.instance.recordMessage(message, stage: 'foreground');
    Logger.m.i(
      '[Notifications] push from ${message.from ?? "(unknown)"} '
      '— ${message.notification == null ? "data-only" : "notification"}',
    );
    final payload = _parseMessage(message);
    if (payload == null) return;
    Logger.m.d(
      '[Notifications] foreground push: ${payload.type} "${payload.title}"',
    );
    await Notifications.show(payload);
    _refreshInbox();
  }

  void _onMessageOpenedApp(RemoteMessage message) {
    PushDiagnostics.instance.recordMessage(message, stage: 'opened');
    final payload = _parseMessage(message);
    if (payload == null) return;
    Logger.m.i('[Notifications] tapped push from background: ${payload.type}');
    Notifications.reportTap(payload);
    _refreshInbox();
  }

  /// EVERY PUSH IS ALSO AN INBOX ROW, and the badge counts them.
  ///
  /// `unread_count` comes from `GET /api/notifications` and nothing
  /// else — a push arriving does not change a number the app is
  /// holding. So the bell went on saying what it said before the
  /// notification landed, and the inbox behind it was a screen out of
  /// date, until something else happened to reload it.
  ///
  /// Fired for a foreground push AND for a tap out of the background:
  /// the tap opens the inbox, and opening it onto the previous answer
  /// is exactly the moment the staleness shows.
  ///
  /// Guarded on registration and fired without waiting — this runs on
  /// a push, not on a screen, and nothing here is allowed to fail
  /// loudly.
  void _refreshInbox() {
    if (getIt.isRegistered<NotificationsCubit>()) {
      unawaited(getIt<NotificationsCubit>().refreshNow());
    }

    // AND EVERYTHING ELSE THE PUSH IS ABOUT.
    //
    // A notification is the server telling this device that something
    // changed — a booking confirmed, a piece fired, an order out for
    // delivery. The row in the inbox was the only thing that moved:
    // the screen the customer was looking at, and every list behind
    // it, went on showing what it showed before the push arrived.
    //
    // `ownedChanged` re-reads the account-scoped singletons AND bumps
    // a notifier the open page listens to, so the booking whose status
    // just changed updates under the reader rather than on their next
    // visit. See [AccountScope].
    AccountScope.ownedChanged();
  }

  Future<void> _captureInitialMessage() async {
    try {
      final msg = await _fcm.getInitialMessage();
      if (msg == null) return;
      PushDiagnostics.instance.recordMessage(msg, stage: 'cold-start');
      final payload = _parseMessage(msg);
      if (payload == null) return;
      Logger.m.i(
        '[Notifications] launched from notification tap: ${payload.type}',
      );
      // The router won't be bound yet — stash for the first screen
      // that comes up after GoRouter initializes.
      Notifications.setInitialPayload(payload);
    } catch (e) {
      Logger.m.w('[Notifications] getInitialMessage failed: $e');
    }
  }

  NotificationPayload? _parseMessage(RemoteMessage message) {
    try {
      return NotificationPayload.fromData(
        message.data,
        fallbackTitle: message.notification?.title,
        fallbackBody: message.notification?.body,
      );
    } catch (e) {
      if (kDebugMode) {
        Logger.m.w(
          '[Notifications] failed to parse push: $e (data: ${message.data})',
        );
      }
      return null;
    }
  }
}
