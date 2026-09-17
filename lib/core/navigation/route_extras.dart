import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/transitions/route_transition.dart';

// ---------------------------------------------------------------------------
// Safe extra parsing for GoRouter
// ---------------------------------------------------------------------------

/// Extensions on [GoRouterState] for type-safe, hot-restart-safe extra access.
///
/// Problem: `state.extra` is in-memory only. On hot restart, GoRouter
/// re-creates the route from the URL but `extra` is null → crash.
///
/// Solution: Use these helpers which return null instead of crashing,
/// so your page can show a loading/fallback state.
///
/// Usage:
/// ```dart
/// // In route definition:
/// pageBuilder: (context, state) {
///   final order = state.extraAs<Order>();
///   return MaterialPage(child: DealsPage(order: order)); // order may be null
/// }
///
/// // In page:
/// class DealsPage extends StatelessWidget {
///   final Order? order;
///   // Show loading/error if order is null (hot restart case)
/// }
///
/// // Passing extras:
/// context.push('/deals', extra: order);
/// context.push('/deals', extra: {'order': order.toJson()});
/// ```
extension GoRouterStateExtras on GoRouterState {
  /// Get [extra] cast to type [T], or null if it's missing/wrong type.
  /// Safe for hot restart — never throws.
  T? extraAs<T>() {
    try {
      if (extra == null) return null;
      if (extra is T) return extra as T;
      return null;
    } catch (e) {
      debugPrint('[RouteExtras] Failed to parse extra as $T: $e');
      return null;
    }
  }

  /// Get [extra] as a Map, then extract a key. Safe for hot restart.
  ///
  /// ```dart
  /// final orderId = state.extraMap<String>('orderId');
  /// ```
  T? extraMap<T>(String key) {
    try {
      if (extra is! Map<String, dynamic>) return null;
      final map = extra as Map<String, dynamic>;
      final value = map[key];
      if (value is T) return value;
      return null;
    } catch (e) {
      debugPrint('[RouteExtras] Failed to extract "$key" from extra map: $e');
      return null;
    }
  }

  /// Get [extra] cast to [T], or parse from JSON map using [fromJson].
  /// Handles both `context.push('/deals', extra: order)` and
  /// `context.push('/deals', extra: order.toJson())`.
  ///
  /// ```dart
  /// final order = state.extraOrParse<Order>(Order.fromJson);
  /// ```
  T? extraOrParse<T>(T Function(Map<String, dynamic>) fromJson) {
    try {
      if (extra == null) return null;
      if (extra is T) return extra as T;
      if (extra is Map<String, dynamic>) {
        return fromJson(extra as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[RouteExtras] Failed to parse extra: $e');
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Path parameter helpers
// ---------------------------------------------------------------------------

/// Extensions for safe path/query parameter access.
extension GoRouterStateParams on GoRouterState {
  /// Get a path parameter as String, or null.
  /// `/deals/:id` → `state.param('id')`
  String? param(String name) => pathParameters[name];

  /// Get a path parameter as int, or null.
  int? paramInt(String name) => int.tryParse(pathParameters[name] ?? '');

  /// Get a query parameter as String, or null.
  /// `/deals?page=2` → `state.query('page')`
  String? query(String name) => uri.queryParameters[name];

  /// Get a query parameter as int, or null.
  int? queryInt(String name) => int.tryParse(uri.queryParameters[name] ?? '');

  /// Get a query parameter as bool (accepts 'true', '1', 'yes').
  bool queryBool(String name) {
    final value = uri.queryParameters[name]?.toLowerCase();
    return value == 'true' || value == '1' || value == 'yes';
  }
}

// ---------------------------------------------------------------------------
// Push with transition override
// ---------------------------------------------------------------------------

/// Convenience extension for navigating with a custom transition.
///
/// ```dart
/// // Push with a specific transition:
/// context.pushWithTransition('/profile', TransitionType.slideFromBottom);
///
/// // With extra data + transition:
/// context.pushWithTransition('/deals/123', TransitionType.fade, extra: order);
/// ```
extension GoRouterTransitionPush on BuildContext {
  /// Push a route with a custom [TransitionType], overriding the route's default.
  void pushWithTransition(
    String location,
    TransitionType transition, {
    Object? extra,
  }) {
    final override = TransitionOverride(transition);

    Object? effectiveExtra;
    if (extra == null) {
      effectiveExtra = override;
    } else if (extra is Map<String, dynamic>) {
      effectiveExtra = {...extra, 'transition': override};
    } else {
      // Wrap both in a map
      effectiveExtra = {'data': extra, 'transition': override};
    }

    GoRouter.of(this).push(location, extra: effectiveExtra);
  }
}
