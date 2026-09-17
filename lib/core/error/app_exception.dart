import 'dart:io';

import 'package:dio/dio.dart';

/// Base of the app's exception hierarchy. All domain errors extend one of
/// the concrete subtypes below so UI code can pattern-match on failures
/// without grepping strings.
///
/// Pair with [Result] (`core/types/result.dart`) for typed error flows:
/// ```dart
/// Future<Result<User, AppException>> loadUser() =>
///   Result.runCatchingAsync(
///     () => _dio.get('/users/me'),
///     mapError: AppException.fromError,
///   );
/// ```
sealed class AppException implements Exception {
  const AppException({
    required this.message,
    this.code,
    this.cause,
    this.stackTrace,
  });

  /// Human-readable description suitable for logs. Localize at the UI layer
  /// using [AppException.key] or a dedicated i18n map — not here.
  final String message;

  /// Optional machine-readable code (HTTP status, business code, …).
  final String? code;

  /// The underlying error if this exception wraps another (e.g. a
  /// [DioException] or a parser [FormatException]).
  final Object? cause;

  final StackTrace? stackTrace;

  /// Classify an arbitrary [error] into a concrete [AppException]. Dispatches
  /// on [DioException] first, then on common Dart/IO exceptions, falling
  /// back to [UnknownException]. Safe for use with
  /// [Result.runCatchingAsync].
  static AppException fromError(Object error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;
    if (error is DioException) return _fromDioException(error, stackTrace);
    if (error is SocketException) {
      return NetworkException(
        message: error.message,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (error is HttpException) {
      return NetworkException(
        message: error.message,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    if (error is FormatException) {
      return ValidationException(
        message: error.message,
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return UnknownException(
      message: error.toString(),
      cause: error,
      stackTrace: stackTrace,
    );
  }

  static AppException _fromDioException(
    DioException e, [
    StackTrace? stackTrace,
  ]) {
    final status = e.response?.statusCode;
    final st = stackTrace ?? e.stackTrace;

    // Transport-level failures — network/timeout/cancellation/cert.
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return NetworkException(
          message: e.message ?? 'Request timed out',
          code: 'timeout',
          cause: e,
          stackTrace: st,
        );
      case DioExceptionType.connectionError:
        return NetworkException(
          message: e.message ?? 'Connection failed',
          code: 'connection_error',
          cause: e,
          stackTrace: st,
        );
      case DioExceptionType.cancel:
        return NetworkException(
          message: 'Request cancelled',
          code: 'cancelled',
          cause: e,
          stackTrace: st,
        );
      case DioExceptionType.badCertificate:
        return NetworkException(
          message: 'Bad certificate',
          code: 'bad_certificate',
          cause: e,
          stackTrace: st,
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        break; // fall through to status-based classification below
    }

    // Response received but status indicates an error.
    if (status == 401 || status == 403) {
      return AuthException(
        message: e.message ?? 'Authentication failed',
        code: status.toString(),
        cause: e,
        stackTrace: st,
      );
    }
    if (status == 404) {
      return NotFoundException(
        message: e.message ?? 'Not found',
        code: '404',
        cause: e,
        stackTrace: st,
      );
    }
    if (status != null && status >= 400 && status < 500) {
      return ValidationException(
        message: e.message ?? 'Bad request',
        code: status.toString(),
        cause: e,
        stackTrace: st,
      );
    }
    if (status != null && status >= 500) {
      return ServerException(
        message: e.message ?? 'Server error',
        code: status.toString(),
        cause: e,
        stackTrace: st,
      );
    }

    return UnknownException(
      message: e.message ?? e.toString(),
      cause: e,
      stackTrace: st,
    );
  }

  @override
  String toString() {
    final buf = StringBuffer('$runtimeType: $message');
    if (code != null) buf.write(' [$code]');
    return buf.toString();
  }
}

/// Connection timeout, DNS failure, no network, cert issues. Retry is
/// often appropriate.
final class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// HTTP 5xx — server-side error. Usually retryable.
final class ServerException extends AppException {
  const ServerException({
    required super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// HTTP 401 / 403 — token expired, bad credentials, insufficient perms.
/// UI typically responds by triggering a refresh or redirecting to login.
final class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// HTTP 404 — the requested resource doesn't exist. UI typically responds
/// with an empty state rather than an error banner.
final class NotFoundException extends AppException {
  const NotFoundException({
    required super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// HTTP 400/422 or client-side validation failures. Surface the message
/// next to the offending field rather than in a global error banner.
///
/// [errors] carries the optional list of field-level or detail errors
/// (e.g. `["email: must be valid", "name: required"]`) returned by the
/// server. Safe to display inline in a form.
///
/// [fieldErrors] is the same information KEYED BY INPUT, which is the
/// shape this backend actually sends: a wrong password comes back under
/// `password`, an unknown account under `identifier`, a bad code under
/// `otp`. Use [forField] to put each message where it belongs instead of
/// dropping the lot into one banner.
final class ValidationException extends AppException {
  const ValidationException({
    required super.message,
    super.code,
    super.cause,
    super.stackTrace,
    this.errors,
    this.fieldErrors,
  });

  final List<String>? errors;

  /// Validation messages keyed by the input that failed.
  final Map<String, List<String>>? fieldErrors;

  /// The first message the server sent for [field], if any.
  String? forField(String field) {
    final messages = fieldErrors?[field];
    return (messages == null || messages.isEmpty) ? null : messages.first;
  }
}

/// Reading a server-side validation failure off any [AppException].
///
/// Saves every call site a type test it would otherwise get slightly
/// wrong — a failure that is NOT a validation error simply has no field
/// messages, which is the same answer as a validation error that did not
/// mention that field.
extension AppExceptionFields on AppException {
  /// The server's message for [field], or null.
  String? fieldError(String field) => this is ValidationException
      ? (this as ValidationException).forField(field)
      : null;

  /// True when the server blamed at least one named input, so the caller
  /// knows the failure has already been shown next to a field and does
  /// not also need a banner.
  bool get hasFieldErrors =>
      this is ValidationException &&
      ((this as ValidationException).fieldErrors?.isNotEmpty ?? false);

  /// The first thing the server actually SAID, whichever input it
  /// blamed.
  ///
  /// A 422's envelope message is boilerplate — "The given data was
  /// invalid." — while the sentence worth showing sits under a field
  /// key. On a screen with no box to put it under (a payment bar, a
  /// confirm sheet) this is what the customer is told instead.
  String? get anyFieldError {
    if (this is! ValidationException) return null;
    for (final said
        in ((this as ValidationException).fieldErrors ?? {}).values) {
      if (said.isNotEmpty) return said.first;
    }
    return null;
  }

  /// The best sentence available for a screen that can only show ONE:
  /// what the server said about an input, else the envelope's message.
  String get spokenMessage => anyFieldError ?? message;
}

/// Local cache miss, read/write failure, or corruption.
final class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// Denied platform permission — location, camera, storage, notifications…
final class PermissionException extends AppException {
  const PermissionException({
    required super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}

/// Catch-all for errors that don't fit any of the above. Keep usage to a
/// minimum; prefer a concrete subtype whenever possible so the UI layer
/// can pattern-match exhaustively.
final class UnknownException extends AppException {
  const UnknownException({
    required super.message,
    super.code,
    super.cause,
    super.stackTrace,
  });
}
