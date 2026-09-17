import '../../core/types/result.dart';
import '../../core/utils/loggers/logger.dart';
import '../api/calls/gift_apis.dart';
import '../models/terracotta/commerce/gift_package.dart';

typedef GiftPackageFetch = AsyncResult<GiftPackage> Function();

/// The studio's gift offer — `GET /api/gifts/package`.
///
/// Two facts, and the app needs both before it can draw anything:
///
///   * **`amount`** — the face value of one gift, set in the CMS. It is
///     NOT the customer's to choose, so the sheet STATES it. Nothing
///     fetched it, which is why the card read «اهدِ رصيداً» with a
///     blank where «٢٠٠ ريال» belongs.
///   * **`is_active`** — whether gifting is on offer at all. This is
///     the switch, and it lives HERE rather than on `/api/config`
///     (probed 2026-09-16: the config carries no gift flag of any
///     kind). Live it is currently **false**.
///
/// Public — no session — so it is fetched at startup like the config.
/// A failure leaves both unknown, and unknown means the gift surface
/// stays as it was: a feature must not vanish because one request
/// failed.
///
/// ## It is RETRIED, for the reason every early call is
///
/// This app's API **422s any request whose `X-FCM-Token` header is
/// empty**, and on a cold radio that token arrives after boot. The
/// first call therefore fails with
/// «X-FCM-Token header is required on iOS and Android» and the amount
/// stays blank for the whole session — which is exactly what happened,
/// and exactly what `GET /api/config` used to do before
/// `TopicSubscription.ensureConfig` was written.
///
/// So: [ensureLoaded] asks again for anything that needs the answer,
/// and `FCMService._onTokenRefresh` asks the moment the token lands.
/// [_maxAttempts] stops that becoming a loop against a server that is
/// genuinely down.
class GiftPackageService {
  GiftPackageService({GiftPackageFetch? fetch})
    : _fetch = fetch ?? GiftApis.getGiftPackage;

  final GiftPackageFetch _fetch;

  GiftPackage? _package;

  /// How many times one run will ask before leaving it.
  static const _maxAttempts = 3;

  int _attempts = 0;

  /// The server's answer, or null when it has not arrived.
  GiftPackage? get package => _package;

  /// The face value as a decimal STRING, or empty when unknown. Never
  /// parsed on the way past — money is decimal on this API.
  String get amount => _package?.amount ?? '';

  /// Whether to offer gifting. TRUE while the answer is unknown, for
  /// the same reason `AppConfig.allowsGift` is: a missing answer must
  /// not take a live feature off three screens.
  bool get isActive => _package?.isActive ?? true;

  /// Ask, unless the answer is already in hand or this run has asked
  /// enough times. What every caller that NEEDS the answer should use.
  Future<void> ensureLoaded() {
    if (_package != null || _attempts >= _maxAttempts) return Future.value();
    return load();
  }

  /// Ask. Never throws — the app ran without this for months.
  Future<void> load() async {
    _attempts++;
    switch (await _fetch()) {
      case Success(:final value):
        _package = value;
        Logger.m.i(
          '[Gift] package — ${value.amount}, '
          'active ${value.isActive}',
        );
      case Failure(:final error):
        Logger.m.w('[Gift] package unavailable: ${error.message}');
    }
  }

  /// Forget what was loaded, so the next [load] really asks.
  void reset() {
    _package = null;
    _attempts = 0;
  }
}
