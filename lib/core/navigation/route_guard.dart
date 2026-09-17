import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

// ---------------------------------------------------------------------------
// RouteGuard — abstract base for all middleware guards
// ---------------------------------------------------------------------------

/// A middleware that runs before a route is displayed.
///
/// Implement [canActivate] to check conditions and optionally redirect.
/// Specify [appliesTo] to control which routes this guard protects.
///
/// Example:
/// ```dart
/// class AuthGuard extends RouteGuard {
///   @override
///   List<String>? get appliesTo => ['/profile', '/settings'];
///
///   @override
///   String? canActivate(GoRouterState state) {
///     if (!isLoggedIn) return '/login';
///     return null; // allow
///   }
/// }
/// ```
abstract class RouteGuard {
  const RouteGuard();

  /// Routes this guard applies to. Null = applies to ALL routes.
  /// Supports exact paths and prefix matching with `*`:
  /// - `'/profile'` → exact match
  /// - `'/admin/*'` → matches `/admin/users`, `/admin/settings`, etc.
  List<String>? get appliesTo => null;

  /// Routes this guard should NOT apply to, even if [appliesTo] matches.
  List<String> get excludeFrom => const [];

  /// Check if the route can be activated.
  /// Return null to allow, or a redirect path to block.
  String? canActivate(GoRouterState state);

  /// Whether this guard applies to the given path.
  bool matchesRoute(String path) {
    // Check exclusions first
    for (final exclude in excludeFrom) {
      if (_matchesPattern(path, exclude)) return false;
    }

    // Null appliesTo = applies to all
    if (appliesTo == null) return true;

    // Check inclusions
    for (final pattern in appliesTo!) {
      if (_matchesPattern(path, pattern)) return true;
    }
    return false;
  }

  bool _matchesPattern(String path, String pattern) {
    if (pattern.endsWith('/*')) {
      final prefix = pattern.substring(0, pattern.length - 2);
      return path == prefix || path.startsWith('$prefix/');
    }
    return path == pattern;
  }
}

// ---------------------------------------------------------------------------
// GuardRunner — executes guards in order on GoRouter redirect
// ---------------------------------------------------------------------------

/// Manages a list of [RouteGuard]s and runs them on each navigation.
///
/// Usage in GoRouter:
/// ```dart
/// GoRouter(
///   redirect: guardRunner.redirect,
///   ...
/// )
/// ```
class GuardRunner {
  GuardRunner(this._guards);

  final List<RouteGuard> _guards;

  /// Add a guard at runtime (e.g. after login).
  void add(RouteGuard guard) => _guards.add(guard);

  /// Remove a guard at runtime.
  void remove<T extends RouteGuard>() => _guards.removeWhere((g) => g is T);

  /// Clear all guards.
  void clear() => _guards.clear();

  /// The redirect function to pass to GoRouter.
  /// Returns null to allow navigation, or a path to redirect.
  String? redirect(GoRouterState state) {
    final path = state.matchedLocation;

    for (final guard in _guards) {
      if (!guard.matchesRoute(path)) continue;

      final redirectPath = guard.canActivate(state);
      if (redirectPath != null) {
        debugPrint(
          '[GuardRunner] ${guard.runtimeType} blocked $path → $redirectPath',
        );
        return redirectPath;
      }
    }

    return null;
  }
}
