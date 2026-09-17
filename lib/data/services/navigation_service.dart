// Flutter imports:
import 'package:flutter/material.dart' hide Banner;
import 'package:go_router/go_router.dart';

import '../../core/di/service_locator.dart';

/// GoRouter-backed navigation service. Plain Dart singleton — register
/// in `service_locator.dart` once the `GoRouter` instance is ready.
/// UI code reads via `context.navigationService` or `getIt<NavigationService>()`.
class NavigationService {
  NavigationService({
    required this.router,
    required this.navigatorKey,
  });

  final GoRouter router;
  final GlobalKey<NavigatorState> navigatorKey;

  final List<String> _smartNavigationHistory = [];
  bool _lastWasSmartNavigation = false;

  void refresh() => router.refresh();

  void goTo(String location) {
    clearSmartHistory();
    router.go(location);
  }

  void push(String location, {Object? extra}) =>
      router.push(location, extra: extra);
  void pushReplacement(String location) => router.pushReplacement(location);
  void replace(String location) => router.replace(location);

  void goBack() {
    if (router.canPop()) router.pop();
  }

  String getCurrentLocation() =>
      router.routeInformationProvider.value.uri.toString();
  bool canGoBack() => router.canPop();

  /// SMART NAVIGATION: push without duplicating the same page; history
  /// is tracked so [smartPop] can restore prior state.
  ///
  /// Workaround for two specific patterns:
  /// 1. **Auth flow loops** (login ↔ signup ↔ login link) where naive
  ///    `push` accumulates duplicate stack entries. Prefer
  ///    [pushReplacement] for new auth flows — it never duplicates and
  ///    needs no parallel history.
  /// 2. **`StatefulShellRoute` sibling state errors** where reactive UI
  ///    in one branch breaks when another branch updates external state.
  ///    Root cause is usually missing branch isolation; prefer fixing
  ///    the shell wiring (per-branch `Navigator` keys, proper
  ///    `KeyedSubtree`s) over routing around the issue here.
  ///
  /// New code should reach for [pushReplacement] or [GoRouter.go]
  /// before adopting smart history.
  void pushSmart(String location) {
    final currentLocation = getCurrentLocation();
    final currentPath = Uri.parse(currentLocation).path;
    final newPath = Uri.parse(location).path;

    if (currentPath == newPath) {
      _lastWasSmartNavigation = false;
      return;
    }

    _smartNavigationHistory.add(currentLocation);
    _lastWasSmartNavigation = true;
    router.go(location);
  }

  /// Undo the last [pushSmart] — returns true if a stored state was
  /// restored (or a regular pop succeeded), false otherwise.
  bool smartPop() {
    if (_smartNavigationHistory.isEmpty) {
      if (canGoBack()) {
        goBack();
        return true;
      }
      return false;
    }

    final previousLocation = _smartNavigationHistory.removeLast();
    _lastWasSmartNavigation = false;
    router.go(previousLocation);
    return true;
  }

  void clearSmartHistory() {
    _smartNavigationHistory.clear();
    _lastWasSmartNavigation = false;
  }

  bool get lastWasSmartNavigation => _lastWasSmartNavigation;
  int get smartHistoryLength => _smartNavigationHistory.length;
}

extension NavigationServiceExtension on BuildContext {
  NavigationService get navigationService => getIt<NavigationService>();
}
