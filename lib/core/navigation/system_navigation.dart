import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../system_pages/error_payload.dart';
import 'go_router_config.dart';

/// Single funnel for navigating to the system pages
/// (`/not-found`, `/coming-soon`, `/error`).
///
/// Encapsulates path + extras so callers don't hand-roll URLs.
/// Each method works with or without a [BuildContext]: callers in
/// flows that don't have a context (global error hooks, async
/// callbacks) can pass `null` and the helper falls back to the
/// router's [GoRouterConfig.navigatorKey].
class SystemNavigation {
  const SystemNavigation._();

  /// Push the error page on top of the stack — preserves the back
  /// stack so users can recover. Use [SystemNavigation.replaceWithError]
  /// for unrecoverable states where the prior route should be gone.
  static void toError(
    BuildContext? context, {
    Object? error,
    StackTrace? stack,
    String? title,
    String? message,
    String? code,
    VoidCallback? onRetry,
  }) {
    final payload = ErrorPayload(
      error: error,
      stack: stack,
      title: title,
      message: message,
      code: code,
      onRetry: onRetry,
    );
    final router = _router(context);
    router?.push('/error', extra: payload);
  }

  /// Hard navigate — replaces the current location entirely. Use for
  /// catastrophic failures where you don't want users hitting back
  /// into a broken screen.
  static void replaceWithError(
    BuildContext? context, {
    Object? error,
    StackTrace? stack,
    String? title,
    String? message,
    String? code,
    VoidCallback? onRetry,
  }) {
    final payload = ErrorPayload(
      error: error,
      stack: stack,
      title: title,
      message: message,
      code: code,
      onRetry: onRetry,
    );
    final router = _router(context);
    router?.go('/error', extra: payload);
  }

  static void toComingSoon(
    BuildContext? context, {
    required String feature,
    String? eta,
    bool showNotifyForm = true,
  }) {
    final query = <String, String>{
      'feature': feature,
      if (eta != null && eta.isNotEmpty) 'eta': eta,
      if (!showNotifyForm) 'notify': 'false',
    };
    final qs = Uri(queryParameters: query).query;
    final loc = qs.isEmpty ? '/coming-soon' : '/coming-soon?$qs';
    _router(context)?.push(loc);
  }

  static void toNotFound(BuildContext? context, {String? path}) {
    final query = (path ?? '').isEmpty
        ? ''
        : '?${Uri(queryParameters: {'path': path!}).query}';
    _router(context)?.push('/not-found$query');
  }

  // ─── Internals ──────────────────────────────────────────

  static GoRouter? _router(BuildContext? context) {
    if (context != null) {
      try {
        return GoRouter.of(context);
      } catch (_) {
        // Fall through to the static handle.
      }
    }
    final ctx = GoRouterConfig.navigatorKey.currentContext;
    if (ctx == null) return null;
    try {
      return GoRouter.of(ctx);
    } catch (_) {
      return null;
    }
  }
}
