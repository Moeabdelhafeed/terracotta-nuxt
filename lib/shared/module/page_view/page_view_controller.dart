import 'package:flutter/foundation.dart';

/// Drives a `GlobalPageView` in LOGICAL pages, from outside the tree.
///
/// A caller can already pass Flutter's own `PageController` — and with
/// `loop: true` that is a trap: the deck starts at
/// `items.length * 1000` so it can wrap in both directions, so
/// `jumpToPage(2)` lands a thousand laps away from where the caller
/// meant. This speaks the indices the caller's list actually has.
///
/// ```dart
/// final deck = GlobalPageViewController();
/// ...
/// GlobalPageView(pageViewController: deck, items: pages, ...);
/// ...
/// deck.next();               // wraps when the deck loops
/// deck.animateToPage(3);
/// deck.pauseAutoPlay();      // while a dialog is up
/// ```
///
/// A `ChangeNotifier`, so a caller can watch [page] to drive its own
/// chrome — a "next" button that disables on the last page, say.
class GlobalPageViewController extends ChangeNotifier {
  Object? _owner;
  Future<void> Function(int page)? _animate;
  void Function(int page)? _jump;
  void Function(int delta)? _step;
  int Function()? _page;
  int Function()? _count;
  void Function({required bool paused})? _setAutoPlayPaused;
  bool Function()? _autoPlayPaused;

  /// The logical page the deck is on, or 0 before it is attached.
  int get page => _page?.call() ?? 0;

  /// How many pages the deck has.
  int get count => _count?.call() ?? 0;

  /// Whether a widget is listening.
  bool get isAttached => _owner != null;

  /// Whether auto-play is being held. False when the deck does not
  /// auto-play at all.
  bool get isAutoPlayPaused => _autoPlayPaused?.call() ?? false;

  /// Animates to a logical page, taking the shortest way round when
  /// the deck loops.
  Future<void> animateToPage(int page) async => _animate?.call(page);

  /// Jumps without animating.
  void jumpToPage(int page) => _jump?.call(page);

  /// One page on, wrapping when the deck loops and stopping at the end
  /// when it does not.
  void next() => _step?.call(1);

  /// One page back, same rules.
  void previous() => _step?.call(-1);

  /// Holds auto-play — while a dialog is up, while a video in the page
  /// is playing, whatever the screen decides. The deck already pauses
  /// itself for a finger and for being scrolled off screen; this is
  /// for the reasons only the caller knows.
  void pauseAutoPlay() => _setAutoPlayPaused?.call(paused: true);

  /// Releases a [pauseAutoPlay].
  void resumeAutoPlay() => _setAutoPlayPaused?.call(paused: false);

  /// Wired by the widget's `initState` / `didUpdateWidget`.
  void attach({
    required Object owner,
    required Future<void> Function(int page) animateToPage,
    required void Function(int page) jumpToPage,
    required void Function(int delta) step,
    required int Function() page,
    required int Function() count,
    required void Function({required bool paused}) setAutoPlayPaused,
    required bool Function() autoPlayPaused,
  }) {
    _owner = owner;
    _animate = animateToPage;
    _jump = jumpToPage;
    _step = step;
    _page = page;
    _count = count;
    _setAutoPlayPaused = setAutoPlayPaused;
    _autoPlayPaused = autoPlayPaused;
  }

  /// Clears the wiring — but only when [owner] is still the current
  /// owner. A replaced State's deferred dispose must not tear down its
  /// successor's attachment.
  void detach({required Object owner}) {
    if (!identical(_owner, owner)) return;
    _owner = null;
    _animate = null;
    _jump = null;
    _step = null;
    _page = null;
    _count = null;
    _setAutoPlayPaused = null;
    _autoPlayPaused = null;
  }

  /// Called by the widget whenever the page it exposes changes.
  void notify() => notifyListeners();
}
