// Dart imports:
import 'dart:async';

// Package imports:
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:media_kit/media_kit.dart';

// Project imports:
import 'app/my_app.dart';
import 'core/auth/account_scope.dart';
import 'core/bootstrap/bootstrap_connectivity.dart';
import 'core/bootstrap/bootstrap_deep_links.dart';
import 'core/bootstrap/bootstrap_di.dart';
import 'core/bootstrap/bootstrap_firebase.dart';
import 'core/bootstrap/bootstrap_initial_state.dart';
import 'core/bootstrap/bootstrap_logging.dart';
import 'core/bootstrap/bootstrap_maintenance.dart';
import 'core/bootstrap/bootstrap_storage.dart';
import 'core/bootstrap/bootstrap_system_chrome.dart';
import 'core/bootstrap/bootstrap_update.dart';
import 'core/bootstrap/bootstrap_zone.dart';
import 'core/connectivity/connectivity_cubit.dart';
import 'core/connectivity/offline_action.dart';
import 'core/connectivity/offline_action_queue.dart';
import 'core/devtools/persistent_widget_inspector.dart';
import 'core/di/service_locator.dart';
import 'core/error/error_boundary.dart';
import 'core/error/ui_watchdog.dart';
import 'core/feedback/feedback_payload.dart';
import 'core/feedback/feedback_submitter.dart';
import 'core/feedback/feedback_type.dart';
import 'core/flavor/flavor.dart';
import 'core/flavor/flavor_config.dart';
import 'core/loading/loading_cubit.dart';
import 'core/localization/remote_translations.dart';
import 'core/localization/timeago_locales.dart';
import 'core/maintenance/maintenance_cubit.dart';
import 'core/navigation/go_router_config.dart';
import 'core/navigation/url_strategy_stub.dart'
    if (dart.library.js_util) 'core/navigation/url_strategy_web.dart';
import 'core/notifications/notification_routing.dart';
import 'core/splash/splash_warmer.dart';
import 'core/update_gate/update_cubit.dart';
import 'core/utils/device/device_policy.dart';
import 'core/utils/device/device_services.dart';
import 'core/utils/device/info/device_info_utils.dart';
import 'core/utils/device/system/system_ui_utils.dart';
import 'core/utils/loggers/logger.dart';
import 'data/api/api_service.dart';
import 'data/blocs/auth/auth_bloc.dart';
import 'data/blocs/auth/auth_state.dart';
import 'data/blocs/preferences/preferences_cubit.dart';
import 'data/notifications/notifications_config.dart';
import 'data/notifications/topic_subscription.dart';
import 'data/services/gift_package_service.dart';
import 'data/services/languages_service.dart';
import 'data/services/media/dynamic_assets.dart';
import 'data/services/remote_config_service.dart';
import 'data/services/remote_config_watcher.dart';
import 'data/stores/debug_overlay_prefs.dart';
import 'generated/l10n.dart';
import 'shared/module/system_pages/error_app.dart';
import 'shared/module/video/video_wakelock.dart';

/// Boots the app for the given [flavor]. Each `lib/main_<flavor>.dart`
/// entrypoint is a one-liner that calls `bootstrap(Flavor.X)`.
///
/// Each step lives in its own file under `core/bootstrap/`:
///   1. [runInBootstrapZone] — capture rogue `print()` + uncaught errors.
///   2. [setupLogging] / [setupErrorHooks] — logger config, error sinks.
///   3. [initFirebase] / [initSystemChrome] — Firebase, orientation, fonts.
///   4. [initStorage] / [initDi] / [wireDeepLinks] — storage, DI, deep
///      links, notifications.
///   5. [setupInitialState] — preferences restore.
Future<void> bootstrap(Flavor flavor) async {
  await runInBootstrapZone(() => _bootstrap(flavor));
}

Future<void> _bootstrap(Flavor flavor) async {
  final config = FlavorConfig.fromEnvironment(flavor);
  FlavorConfig.set(config);

  setupLogging(flavor, config);
  // Single install: wires `FlutterError.onError` (forwarding to logger +
  // CrashReporter, filtering known false positives) and replaces the
  // red-screen `ErrorWidget.builder` in release builds.
  // `PlatformDispatcher.instance.onError` is wired separately in
  // `initFirebase` after CrashReporter is ready.
  GlobalErrorHandler.install();
  setupDebugPrintRedirect();
  // How the device services behave: cache lifetimes, whether a dead
  // capability keeps being probed, which URL schemes may be launched,
  // and who the latency probe is allowed to talk to. It is a value
  // rather than a `ThemeExtension` because these are called from
  // bootstrap and from background work, where there is no
  // `BuildContext` — see `core/utils/device/CLAUDE.md`. Set BEFORE
  // anything reads a device value.
  DeviceServices.configure(const DevicePolicy());
  // Every handler above needs something to be THROWN. A hang throws
  // nothing, so a frozen UI thread is the one failure this app cannot
  // report about itself — the watchdog reports it from a second
  // isolate. Debug + profile only; not awaited, since nothing below
  // depends on it.
  unawaited(UiWatchdog.start());

  WidgetsFlutterBinding.ensureInitialized();
  // Debug only (assert-stripped): tell WidgetsApp NOT to mount its root
  // WidgetInspector — MyApp mounts a permanent one instead, so IDE
  // inspector toggles can't remount the Router subtree and wipe page
  // state. Must run before runApp; needs the binding above.
  PersistentWidgetInspector.install();
  // Switch the browser URL from `/#/foo` to clean paths (`/foo`). No-op
  // on mobile / desktop builds via conditional import.
  usePathUrlStrategyIfWeb();
  MediaKit.ensureInitialized();

  await initFirebase();
  await initSystemChrome();

  // The video module keeps the screen on while a film plays, but it
  // lives under `lib/shared/module` and must not reach the device
  // layer itself. This is the seam.
  VideoWakelock.setEnabled = (enable) =>
      SystemUiUtils.toggleWakelock(enable: enable);

  try {
    await initStorage();
    await initDi();

    // The Terracotta API requires a STABLE X-Device-Id on every
    // request. Seed it once here: guest carts, sessions and push all
    // key off it, and a guest who later registers is promoted in place
    // by matching it — so an id that changes between launches silently
    // orphans whatever the customer built as a guest.
    ApiService.seedDeviceId(await DeviceInfoUtils.getDeviceId());

    // Seed maintenance cubit with the latest Remote Config snapshot.
    // Runs AFTER initDi so the cubit is registered, but BEFORE
    // runApp so the gate has correct state on first frame.
    seedMaintenanceFromRemoteConfig();
    seedConnectivityFromRemoteConfig();
    unawaited(seedUpdateFromRemoteConfig());
    // Start the connectivity stack BEFORE the queue — the queue
    // subscribes to the cubit's recovery edge.
    getIt<ConnectivityCubit>().start();
    final offlineQueue = getIt<OfflineActionQueue>();
    // Replayer for queued feedback submissions — drains on reconnect.
    offlineQueue.registerReplayer('feedback.submit', (action) async {
      try {
        final endpoint = RemoteConfigService.feedbackEndpoint;
        final email = RemoteConfigService.feedbackSupportEmail;
        final submitter = endpoint.isEmpty
            ? MailtoFeedbackSubmitter(toEmail: email)
            : ApiFeedbackSubmitter(endpoint: endpoint);
        // Reconstruct just enough of FeedbackPayload to resubmit.
        // Attachments aren't persisted across cold start.
        final json = action.payload;
        final result = await submitter.submit(
          FeedbackPayload(
            type: FeedbackType.values.firstWhere(
              (t) => t.name == (json['type'] as String? ?? ''),
              orElse: () => FeedbackType.other,
            ),
            severity: (json['severity'] as String?) == null
                ? null
                : FeedbackSeverity.values.firstWhere(
                    (s) => s.name == json['severity'],
                    orElse: () => FeedbackSeverity.low,
                  ),
            description: (json['description'] as String?) ?? '',
            repro: json['repro'] as String?,
            email: json['email'] as String?,
            diagnostics:
                (json['diagnostics'] as Map?)?.cast<String, dynamic>() ??
                const {},
          ),
        );
        return result.kind == FeedbackResultKind.success
            ? ReplayResult.success
            : ReplayResult.retry;
      } catch (_) {
        return ReplayResult.retry;
      }
    });
    unawaited(offlineQueue.start());
    // Start the live RC watcher (mobile push / web poll / app
    // resume) and subscribe snapshot-style consumers to it.
    final rcWatcher = getIt<RemoteConfigWatcher>()..start();
    rcWatcher.updates.listen((_) {
      seedMaintenanceFromRemoteConfig();
      seedConnectivityFromRemoteConfig();
      unawaited(seedUpdateFromRemoteConfig());
    });

    unawaited(wireDeepLinks());

    // The STRINGS, before anything reads one.
    //
    // `S.current` is null until `S.load` has run, and the only thing
    // that normally runs it is `MaterialApp`'s delegate — which is
    // three steps below this, inside `runApp`. Android's notification
    // CHANNELS are named from `S` while they are created, so the very
    // first launch of a release build died here on
    // `Null check operator used on a null value`.
    //
    // Release-only by construction: `S.current` guards itself with an
    // `assert`, and asserts are stripped from a release build — so
    // debug got the readable message and release got the null check.
    //
    // The language is the one `PreferencesCubit` restored in `initDi`
    // above; `MaterialApp` loads it again for the widget tree, which is
    // idempotent.
    final channelLocale = getIt<PreferencesCubit>().state.language.locale;
    await S.load(Locale(channelLocale));
    Logger.m.i('[Bootstrap] strings loaded for $channelLocale');

    // Notifications — unified bootstrap (FCM + local + in-app + optional
    // history + analytics hooks). Register per-type route handlers via
    // the `routes:` param, matching `NotificationType` cases to paths.
    await NotificationsConfig.bootstrap(
      router: GoRouterConfig.router,
      enableHistory: true,
    );
    // AND SOMETHING TO LISTEN. `FCMService` parsed every tap, published
    // it and stashed a cold-start one — with nobody on the other end,
    // so a push opened the app wherever it was last left. The server
    // names the thing each notification is about; this is what takes
    // the reader to it. See [NotificationRouting].
    NotificationRouting.start();

    // Refresh the languages catalog. Sits HERE, not in `initDi`, because
    // it is the first network call of the run and the Terracotta API
    // 422s any request whose `X-Device-Id` or `X-FCM-Token` is empty —
    // the device id is seeded above, and the FCM token only exists once
    // `NotificationsConfig.bootstrap` has run. Still ahead of
    // `setupInitialState`, which reads the catalog to resolve the
    // startup locale. A failure leaves the bundled fallback intact.
    await getIt<LanguagesService>().init();

    await setupInitialState();

    // `GET /api/config`, then the BROADCAST TOPICS it names.
    //
    // A push addressed to one customer reaches their device token with
    // no topic at all, which is why notifications work without this. A
    // studio-wide ANNOUNCEMENT has no device list — it goes to a
    // topic, and a device that never subscribed never hears it.
    //
    // The names are the SERVER's (`fcm_topics`), never invented: see
    // [NotificationTopics]. Fired and not awaited — nothing on the
    // first screen depends on either call.
    unawaited(TopicSubscription.resync());

    // THE STUDIO'S GIFT OFFER — its face value and whether it is on at
    // all. Public, like the config, and read by three screens before
    // anybody taps anything: the tile beside the wallet on the shop
    // and workshops pages, and the row in the profile.
    //
    // Fired and not awaited. Unknown reads as ON and as a blank
    // amount, so a slow answer shows the offer a moment before it can
    // price it rather than hiding a live feature.
    unawaited(getIt<GiftPackageService>().load());

    // AND FOLLOW THE LANGUAGE from here on.
    //
    // A studio announcement is published per language, so switching to
    // Arabic has to move the device off `all_en` and onto `all_ar`.
    // That used to live in `LocaleService.changeLanguage()` — which
    // nothing in the app calls: every picker reaches for
    // `PreferencesCubit.setLanguage()` directly, so the subscription
    // never moved. A listener cannot be bypassed by the next call site
    // the way a helper method can.
    TopicSubscription.watchLanguage();

    // THE STUDIO'S OWN ARTWORK. One request; every dynamic asset falls
    // back to the bundled drawing until it answers, and a key the CMS
    // does not carry is seeded from the bundle so there is something
    // to edit. See [DynamicAssets].
    unawaited(getIt<DynamicAssets>().load());
    await initializeDateFormatting();

    // Register `timeago` messages for every language the app
    // supports — driven by LanguagesService. English is always
    // registered as the fallback.
    registerTimeagoLocales(
      getIt<LanguagesService>().languages.map((l) => l.locale),
    );

    if (config.useRemoteTranslations) {
      await getIt<RemoteTranslations>().init();
    }

    // Mark bootstrap-tail complete so the splash orchestrator can
    // stop blocking on `waitForBootstrap`. Anything past this point
    // is allowed to overlap the splash hold.
    SplashWarmer.instance.signalBootstrapDone();

    runApp(
      MultiBlocProvider(
        providers: [
          BlocProvider.value(value: getIt<AuthBloc>()),
          BlocProvider.value(value: getIt<PreferencesCubit>()),
          BlocProvider.value(value: getIt<MaintenanceCubit>()),
          BlocProvider.value(value: getIt<ConnectivityCubit>()),
          BlocProvider.value(value: getIt<LoadingCubit>()),
          BlocProvider.value(value: getIt<UpdateCubit>()),
        ],
        // WHO IS READING just changed — drop what belonged to the last
        // one. Sign-in, sign-out, an expired session and one account
        // replacing another all arrive here, so no call site has to
        // remember. See [AccountScope].
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (was, now) => _reader(was) != _reader(now),
          listener: (_, _) => AccountScope.changed(),
          child: ValueListenableBuilder<bool?>(
            valueListenable: DebugOverlayPrefs.devicePreviewOverride,
            builder: (_, override, _) {
              // Default behaviour: flavor decides. Override (set from
              // the debug overlay) wins. Wrapping unconditionally with
              // a ValueListenableBuilder lets the dev toggle without a
              // hot-restart — DevicePreview's `enabled` flag handles
              // the in/out-of-frame transition itself.
              final enabled =
                  override ?? (kDebugMode && flavor.useDevicePreview);
              return DevicePreview(
                enabled: enabled,
                builder: (_) => const MyApp(),
              );
            },
          ),
        ),
      ),
    );
  } catch (error, stack) {
    Logger.m.e('App initialization failed', error: error, stackTrace: stack);
    runApp(
      ErrorApp(
        errorMessage: 'App initialization failed',
        errorDetails: error.toString(),
        error: error,
        stack: stack,
      ),
    );
  }
}

/// The account behind a state, or null when there is none.
///
/// Compared by ID rather than by state type: signing out and back in
/// as the SAME person is not a change worth dropping five caches for,
/// and one account replacing another is — which a bare
/// `authenticated != authenticated` cannot tell apart.
String? _reader(AuthState state) =>
    state is AuthAuthenticated ? '${state.user.id}' : null;
