import 'package:flutter/foundation.dart';

/// Payload passed via GoRouter `extra` to `/error`. Holds enough
/// context for [ErrorPage] to render diagnostics, retry, and report
/// without losing state across hot restarts.
@immutable
class ErrorPayload {
  const ErrorPayload({
    this.title,
    this.message,
    this.error,
    this.stack,
    this.code,
    this.onRetry,
  });

  final String? title;
  final String? message;
  final Object? error;
  final StackTrace? stack;

  /// Optional short code surfaced to support (e.g. `BOOT_DI_FAIL`).
  final String? code;

  /// Optional callback invoked by the "Try again" button. When null
  /// the button defaults to `context.go('/')`.
  final VoidCallback? onRetry;
}
