import 'package:flutter/foundation.dart';

import '../../core/types/result.dart';
import '../../core/utils/loggers/logger.dart';
import '../api/calls/auth_apis.dart';
import '../models/terracotta/account/app_config.dart';
import '../notifications/push_diagnostics.dart';

/// `GET /api/config` — what this backend can do, held for the run.
///
/// ## Why it exists now
///
/// `AuthApis.getAuthConfig` was written and then never called by
/// anything: the auth screens assume phone + password, which is what
/// the live server reports, so nothing broke and nothing asked. The
/// call then grew `fcm_topics`, which is the only place the broadcast
/// topic names are published — and the app had been inventing them.
///
/// ## What it does NOT do yet
///
/// It does not drive the auth screens. `identifiers`, `auth_mode` and
/// the `has_*_field` flags are all here and all still ignored: the
/// screens are built for phone + password, and an `auth_mode: otp`
/// server would need `verifyLogin` wired into sign-in before reading
/// this could change anything. Reading it and acting on it are two
/// jobs; this is the first.
///
/// Public — no session — so it is fetched once at startup and kept.
/// A failure leaves [config] null and every caller falls back to what
/// it assumed before.
class AppConfigService {
  AppConfigService({AppConfigFetch? fetch})
    : _fetch = fetch ?? AuthApis.getAuthConfig;

  final AppConfigFetch _fetch;

  AppConfig? _config;

  /// The server's answer, or null when it has not arrived.
  AppConfig? get config => _config;

  /// The broadcast topics, or empty when there are none to have.
  List<FcmTopic> get topics => _config?.fcmTopics ?? const [];

  /// Whether the studio is selling gift credit.
  ///
  /// TRUE while the config has not arrived, and true while the key is
  /// absent — see `AppConfig.allowGift`. The whole gift surface is
  /// gated on this: the tile beside the wallet on two pages, the row
  /// in the profile, and the sheet all three open.
  bool get allowsGift => _config?.allowsGift ?? true;

  /// Ask once. Never throws — the app ran without this for months.
  ///
  /// The outcome is recorded in [PushDiagnostics] as well as logged,
  /// because the log is compiled out of a release build and this call
  /// failing is invisible everywhere else: the only symptom is a
  /// device silently on no broadcast topics.
  Future<void> load() async {
    PushDiagnostics.instance.recordConfig('asking…');
    switch (await _fetch()) {
      case Success(:final value):
        _config = value;
        Logger.m.i(
          '[Config] loaded — ${value.fcmTopics.length} topics, '
          'auth ${value.authMode}',
        );
        PushDiagnostics.instance.recordConfig(
          'ok — ${value.fcmTopics.length} topics',
        );
      case Failure(:final error):
        Logger.m.w('[Config] failed, using the app\'s assumptions: $error');
        PushDiagnostics.instance.recordConfig('FAILED — $error');
    }
  }

  @visibleForTesting
  void setConfig(AppConfig? value) => _config = value;

  /// Forget what was loaded, so the next [load] really asks.
  ///
  /// Only the diagnostics screen's retry uses this: the config is a
  /// property of the backend and does not change while the app runs,
  /// so nothing else has a reason to drop it.
  void forget() => _config = null;
}

/// The call, injectable so a test answers without a server.
typedef AppConfigFetch = AsyncResult<AppConfig> Function();
