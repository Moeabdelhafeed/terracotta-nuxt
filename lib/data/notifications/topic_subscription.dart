import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/di/service_locator.dart';
import '../blocs/auth/auth_bloc.dart';
import '../models/common/language/language.dart';
import '../services/app_config_service.dart';
import '../services/preferences/locale_service.dart';
import 'fcm_service.dart';
import 'push_diagnostics.dart';

/// PUTTING THE DEVICE ON THE RIGHT BROADCAST TOPICS, from wherever the
/// thing that decides them just changed.
///
/// Three inputs, and all three move while the app is running:
///
///  * the topic NAMES, from `GET /api/config`;
///  * the LANGUAGE being read;
///  * whether there is an ACCOUNT — `users` against `guests`.
///
/// So this is called from startup, from a language change, and from
/// sign-in and sign-out. It is one line at each of those call sites
/// rather than three lookups, because the places that change one of
/// these inputs have no business knowing about the other two.
///
/// ## The config is retried, because one miss used to cost the run
///
/// `resync()` asked for the config exactly once and gave up: a single
/// failed call at boot — a cold radio, a captive portal, a server
/// blip — left `topics` empty, and every later trigger found it empty
/// and returned. The device then spent the whole session on no
/// broadcast topics with nothing on screen saying so.
///
/// [ensureConfig] is the fix: any call that needs the names will fetch
/// them if they are not there yet, so a language switch or a sign-in
/// is also a second chance. [_attempts] stops that becoming a retry
/// loop against a server that is genuinely down.
///
/// Silent and best-effort: a device that cannot reach Google's
/// subscription endpoint still receives everything addressed to it
/// personally, which is all of the app's own notifications. What is
/// NOT silent any more is why — see [PushDiagnostics].
class TopicSubscription {
  const TopicSubscription._();

  /// How many times one run will ask for the config before leaving it.
  static const _maxAttempts = 3;

  static int _attempts = 0;

  /// Fetch the config if it has not arrived, then subscribe.
  static Future<void> resync() async {
    await ensureConfig();
    await apply();
  }

  static StreamSubscription<Language>? _languageSub;

  /// Follow the LANGUAGE for as long as the app runs.
  ///
  /// **This is here because asking the call sites did not work.**
  /// `LocaleService.changeLanguage()` moved the subscription and was
  /// the documented way to switch language — and nothing in the app
  /// called it. Every picker reaches for
  /// `PreferencesCubit.setLanguage()` directly, so a reader who
  /// switched to Arabic stayed on `all_en` and went on being sent
  /// announcements they had just said they could not read.
  ///
  /// A listener cannot be bypassed by a new call site the way a helper
  /// method can. It is the same reason `AccountScope` hangs off an
  /// `AuthBloc` listener at the app root rather than trusting every
  /// sign-in path to remember.
  ///
  /// `onLanguageChanged` is already `distinct()`, so setting the same
  /// language twice does nothing.
  static void watchLanguage() {
    if (_languageSub != null) return;
    if (!getIt.isRegistered<LocaleService>()) return;

    _languageSub = getIt<LocaleService>().onLanguageChanged.listen((_) {
      unawaited(apply());
    });
  }

  /// For a test that wants the listener gone.
  @visibleForTesting
  static Future<void> stopWatching() async {
    await _languageSub?.cancel();
    _languageSub = null;
  }

  /// The topic names, fetched if this run has not got them yet.
  ///
  /// Once they are in hand this does nothing: they are a property of
  /// the BACKEND, not of the reader, so a language change does not
  /// need them again.
  static Future<void> ensureConfig() async {
    if (!getIt.isRegistered<AppConfigService>()) {
      PushDiagnostics.instance.recordConfig(
        'no AppConfigService — DI did not register it',
      );
      return;
    }

    final config = getIt<AppConfigService>();
    if (config.config != null) return;
    if (_attempts >= _maxAttempts) return;

    _attempts++;
    await config.load();
  }

  /// Subscribe using the config already in hand.
  ///
  /// For the callers that changed the READER rather than the server —
  /// a language switch, a sign-in. It still calls [ensureConfig]
  /// first, because "the reader changed" is also the app's next
  /// chance to recover from a boot that could not reach the server.
  static Future<void> apply() async {
    if (!getIt.isRegistered<FCMService>()) {
      PushDiagnostics.instance.recordConfig(
        'no FCMService — notifications did not bootstrap',
      );
      return;
    }

    await ensureConfig();
    if (!getIt.isRegistered<AppConfigService>()) return;

    final topics = getIt<AppConfigService>().topics;
    if (topics.isEmpty) {
      // Recorded rather than returned silently. An empty list is a
      // legitimate answer — a server that publishes no broadcasts —
      // and it is also what a failed call looks like. The two read the
      // same from here, so `configState` is what tells them apart.
      PushDiagnostics.instance.recordPublished(const []);
      return;
    }

    await getIt<FCMService>().syncTopics(
      published: topics,
      languageCode: getIt<LocaleService>().languageCode,
      signedIn: getIt.isRegistered<AuthBloc>()
          ? getIt<AuthBloc>().isAuthenticated
          : false,
    );
  }

  /// Ask again from scratch — the diagnostics screen's retry.
  ///
  /// Clears the attempt count, because a person pressing a button has
  /// information the app does not: they know the network is back.
  static Future<void> retry() async {
    _attempts = 0;
    if (getIt.isRegistered<AppConfigService>()) {
      getIt<AppConfigService>().forget();
    }
    await resync();
  }
}
