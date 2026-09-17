import 'package:flutter/foundation.dart';

import '../../../core/utils/loggers/logger.dart';

/// A gift token waiting to be opened.
///
/// ## The two places a gift link gets dropped
///
/// **Cold start.** `wireDeepLinks` runs inside `bootstrap` and calls
/// `router.go('/gift/{token}')` — but the router intercepts the FIRST
/// redirect of every session and bounces to the splash, deliberately,
/// so state restoration cannot skip the splash gate. The gift link is
/// state restoration as far as that check is concerned, so the token
/// went in the bin and the recipient landed on the shop with no idea
/// why they had opened the app. [remember] parks it and
/// `defaultSplashNext` reads it, so the splash still runs and the link
/// is still honoured.
///
/// **Signing in.** Claiming needs an account and most recipients have
/// none — that is the whole shape of a gift. The sign-in screen ends
/// with `context.goNamed('home')`, which is right for everybody else
/// and wrong for someone who arrived holding a link. The token parked
/// here is what sends them back to the gift instead.
///
/// ## Why memory and not storage
///
/// The link IS the launch: the process is alive from the tap until the
/// gift screen opens, and it stays alive across the sign-in that
/// happens on top of it. A token that outlived the process would be a
/// gift screen appearing days later, on a launch that had nothing to
/// do with it — which is worse than losing it.
///
/// [take] reads and CLEARS, so one link opens one screen. Peeking
/// without clearing is [token].
class PendingGift {
  const PendingGift._();

  static String? _token;

  /// The token waiting, without consuming it.
  static String? get token => _token;

  /// Whether a gift is waiting to be opened.
  static bool get isWaiting => _token != null;

  /// Park a token from an incoming link.
  static void remember(String token) {
    if (token.isEmpty) return;
    _token = token;
    Logger.m.i('[Gift] link parked, waiting for a screen to take it');
  }

  /// Read it and clear it — one link, one screen.
  static String? take() {
    final held = _token;
    _token = null;
    return held;
  }

  /// Forget it. The recipient closed the gift, or claimed it.
  static void clear() => _token = null;

  /// The token in `/gift/{token}`, or null when the path is not one.
  ///
  /// Matches the resolved IN-APP path, which is what both link forms
  /// become — `terracotta://gift/x` and `https://…/gift/x` both arrive
  /// here as `/gift/x`. See `DeepLinkHandler.normalize`.
  static String? tokenIn(String path) {
    final match = _giftPath.firstMatch(path);
    return match?.group(1);
  }

  /// One path segment after `/gift/`, and nothing after it. A query is
  /// allowed and ignored — a link shared through a mailer often picks
  /// up tracking parameters on the way.
  static final RegExp _giftPath = RegExp(r'^/gift/([^/?#]+)');

  @visibleForTesting
  static void reset() => _token = null;
}
