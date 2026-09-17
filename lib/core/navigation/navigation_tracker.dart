import 'dart:async';

import 'package:flutter/foundation.dart';

import '../utils/loggers/logger.dart';

// ---------------------------------------------------------------------------
// NavigationEvent — the 5 navigation cases
// ---------------------------------------------------------------------------

/// What happened to the page from its own perspective.
enum NavigationEvent {
  /// This page was just pushed onto the stack (entering for the first time).
  push,

  /// Another page was pushed on top of this page (this page is now covered).
  pushOther,

  /// This page is being popped (leaving the screen).
  pop,

  /// The page on top of this was popped (this page is being revealed).
  popOther,

  /// This page replaced another via pushReplacement.
  pushReplacement,
}

/// Kind of navigation that produced a [RouteHistoryEntry]. Drives the
/// debug overlay's route-history view filter + chip color.
enum RouteHistoryKind { push, pop, replace }

/// Single navigation event captured for the debug overlay.
class RouteHistoryEntry {
  const RouteHistoryEntry({
    required this.kind,
    required this.route,
    required this.previous,
    required this.at,
  });

  final RouteHistoryKind kind;
  final String route;
  final String? previous;
  final DateTime at;
}

// ---------------------------------------------------------------------------
// NavigationTracker — tracks route stack and notifies listeners
// ---------------------------------------------------------------------------

/// Global navigation tracker for coordinating widget-level animations
/// across pages. Singleton — accessed via `NavigationTracker()`.
///
/// Used by [NavigationAwareAnimation] to trigger per-widget animations
/// based on navigation events.
class NavigationTracker {
  static final NavigationTracker _instance = NavigationTracker._internal();
  factory NavigationTracker() => _instance;
  NavigationTracker._internal();

  final List<String> _navigationStack = [];
  final Map<String, List<void Function(NavigationEvent)>> _listeners = {};

  /// Ring buffer of recent navigation events. Powers the debug
  /// overlay's route-history view. Capped so memory doesn't grow
  /// unbounded over a long session.
  static const int _kHistoryCap = 50;
  final List<RouteHistoryEntry> _history = [];
  final StreamController<void> _historyChanges =
      StreamController<void>.broadcast();

  /// Snapshot of the history buffer, newest first. Returns an
  /// unmodifiable view so callers can't mutate internal state.
  List<RouteHistoryEntry> get historySnapshot =>
      List.unmodifiable(_history.reversed);

  /// Live route stack as tracked from push/pop/replace events, bottom
  /// first. Powers the debug overlay's current-stack readout.
  List<String> get stackSnapshot => List.unmodifiable(_navigationStack);

  /// Fires whenever a new entry lands.
  Stream<void> get historyChanges => _historyChanges.stream;

  /// Wipe the captured history. Doesn't touch live navigation state.
  void clearHistory() {
    if (_history.isEmpty) return;
    _history.clear();
    _historyChanges.add(null);
  }

  void _record(RouteHistoryEntry entry) {
    _history.add(entry);
    while (_history.length > _kHistoryCap) {
      _history.removeAt(0);
    }
    _historyChanges.add(null);
  }

  /// Register a listener for navigation events on [routePath].
  /// Multiple listeners per route are supported.
  /// Returns a callback to remove this specific listener.
  VoidCallback addListener(
    String routePath,
    void Function(NavigationEvent) callback,
  ) {
    _listeners.putIfAbsent(routePath, () => []).add(callback);
    return () => _listeners[routePath]?.remove(callback);
  }

  /// Called by [NavigationObserver] when a push happens.
  void onPush(String newRoute, String? previousRoute) {
    if (kDebugMode) {
      if (previousRoute == null) {
        Logger.m.i('[Nav] enter: $newRoute');
      } else {
        Logger.m.i('[Nav] push: $previousRoute → $newRoute');
      }
    }

    _record(
      RouteHistoryEntry(
        kind: RouteHistoryKind.push,
        route: newRoute,
        previous: previousRoute,
        at: DateTime.now(),
      ),
    );

    if (previousRoute == null) {
      // First route — treat as push
      _navigationStack.add(newRoute);
      _notify(newRoute, NavigationEvent.push);
      return;
    }

    _navigationStack.add(newRoute);
    _notify(previousRoute, NavigationEvent.pushOther);
    _notify(newRoute, NavigationEvent.push);
  }

  /// Called by [NavigationObserver] when a pop happens.
  void onPop(String poppedRoute, String? revealedRoute) {
    if (kDebugMode) {
      if (revealedRoute == null) {
        Logger.m.i('[Nav] exit: $poppedRoute');
      } else {
        Logger.m.i('[Nav] pop: $poppedRoute → $revealedRoute');
      }
    }

    _record(
      RouteHistoryEntry(
        kind: RouteHistoryKind.pop,
        route: poppedRoute,
        previous: revealedRoute,
        at: DateTime.now(),
      ),
    );

    if (_navigationStack.isNotEmpty && _navigationStack.last == poppedRoute) {
      _navigationStack.removeLast();
    }

    _notify(poppedRoute, NavigationEvent.pop);
    if (revealedRoute != null) {
      _notify(revealedRoute, NavigationEvent.popOther);
    }
  }

  /// Called by [NavigationObserver] when a pushReplacement happens.
  void onReplace(String newRoute, String? replacedRoute) {
    if (kDebugMode) {
      Logger.m.i('[Nav] replace: $replacedRoute → $newRoute');
    }

    _record(
      RouteHistoryEntry(
        kind: RouteHistoryKind.replace,
        route: newRoute,
        previous: replacedRoute,
        at: DateTime.now(),
      ),
    );

    if (_navigationStack.isNotEmpty && replacedRoute != null) {
      final idx = _navigationStack.lastIndexOf(replacedRoute);
      if (idx >= 0) {
        _navigationStack[idx] = newRoute;
      } else {
        _navigationStack.add(newRoute);
      }
    } else {
      _navigationStack.add(newRoute);
    }

    _notify(newRoute, NavigationEvent.pushReplacement);
  }

  void _notify(String routePath, NavigationEvent event) {
    final list = _listeners[routePath];
    if (list == null || list.isEmpty) return;
    // Iterate a copy in case a listener removes itself during callback
    for (final cb in List.of(list)) {
      cb(event);
    }
  }
}
