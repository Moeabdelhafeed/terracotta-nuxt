import 'package:flutter/foundation.dart';

/// Once per LAUNCH, per tab.
///
/// A pushed page can animate its arrival every time, because arriving
/// is what it just did. A tab cannot: every tab is a top-level route
/// and `TerracottaNavBar` switches with `context.go`, which tears the
/// previous page's `State` down — so an entrance left on plays again on
/// every switch, and switching tabs is the most frequent thing anyone
/// does in this app. The nav bar itself learned this first and carries
/// its own latch for exactly the same reason: chrome that animates in
/// on every route change is chrome that is LATE on every route change.
///
/// So the rule is the first sight of a tab in a session, and nothing
/// after it. Held in memory on purpose — a new launch is a new first
/// sight, and persisting it would mean the app only ever animated once,
/// on the day it was installed.
///
/// **Claim it when the CONTENT exists, not when the page mounts.** A
/// bound tab mounts on a spinner; claiming there spends the one
/// entrance on a screen that had nothing to show, and a reader who
/// switched away before the response landed would never see it at all.
/// The page holds the answer in its `State` so rebuilds are stable:
///
/// ```dart
/// bool? _entrance;
/// bool get entrance => _entrance ??= TabEntrance.claim('profile');
/// ```
abstract final class TabEntrance {
  static final _spent = <String>{};

  /// True the FIRST time this key is asked for, false ever after.
  static bool claim(String key) => _spent.add(key);

  /// Whether [key] has been used, without using it.
  static bool spent(String key) => _spent.contains(key);

  /// A fresh launch, for a test that needs one.
  @visibleForTesting
  static void reset() => _spent.clear();
}

/// The keys, in one place — a typo in a string literal is a tab that
/// silently shares another's latch and never animates.
abstract final class TabEntranceKey {
  static const home = 'tab-home';
  static const shop = 'tab-shop';
  static const workshops = 'tab-workshops';
  static const gallery = 'tab-gallery';
  static const profile = 'tab-profile';

  // ─── the same page, in two phases ─────────────────────────
  //
  // A bound tab draws its SKELETON first, and the skeleton is not a
  // grey rectangle where the page will be: it holds the page's real
  // shape, with the real section headings in it, because shimmering
  // «تصفح الفئات» pretends to be waiting for four words that are
  // already here.
  //
  // So the headings are drawn twice, by two different widgets, and a
  // single latch gave each of them an arrival: the heading animated as
  // the page opened and then again as the content landed — the
  // reported "it does it twice". They are separate keys because they
  // are separate questions:
  //
  //   * the HEADINGS arrive with the page. Whichever phase draws them
  //     first — the skeleton on a cold load, the loaded page on a warm
  //     one — owns that arrival, and the other gets nothing.
  //   * the CONTENT arrives when the server answers, which is a second
  //     moment and deserves its own.

  static const homeHeadings = 'tab-home-headings';
  static const homeContent = 'tab-home-content';
  static const shopHeadings = 'tab-shop-headings';
  static const shopContent = 'tab-shop-content';
}
