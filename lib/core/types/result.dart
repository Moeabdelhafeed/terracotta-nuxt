import 'dart:async';

import '../error/app_exception.dart';

/// Shorthand for the most common [Result] shape in this app — an async
/// operation that either produces a `T` or fails with an [AppException].
typedef AsyncResult<T> = Future<Result<T, AppException>>;

/// A discriminated union of a successful [value] ([Success]) or an
/// [error] ([Failure]).
///
/// ## Why
/// Every business-logic path either succeeds with a value or fails with
/// a typed error. Returning `null` conflates both, and throwing is
/// out-of-band control flow that hides the failure from the caller's
/// signature. [Result] makes the two outcomes first-class and visible
/// on the return type.
///
/// ## Construction
/// ```dart
/// Result<User, AppException> loadUser() {
///   try {
///     return Result.success(User('Ada'));
///   } on DioException catch (e) {
///     return Result.failure(NetworkException(e.message));
///   }
/// }
///
/// // Or wrap a throwing call:
/// final r = Result.runCatching(() => jsonDecode(input));
/// ```
///
/// ## Consumption
/// Dart 3 patterns for exhaustive matching:
/// ```dart
/// switch (result) {
///   Success(:final value) => show(value),
///   Failure(:final error) => report(error),
/// }
/// ```
/// Or the fluent form:
/// ```dart
/// final text = result.when(
///   success: (u) => 'Hello ${u.name}',
///   failure: (e) => 'Error: ${e.message}',
/// );
/// ```
///
/// ## Chaining
/// [map] transforms the success side, [flatMap] chains another
/// [Result]-returning operation, [mapError] transforms the error side.
/// All three short-circuit on failure:
/// ```dart
/// final result = fetchUser()
///     .map((u) => u.name)
///     .flatMap(validateName);
/// ```
sealed class Result<T, E> {
  const Result();

  /// Wrap a value as a successful [Result].
  const factory Result.success(T value) = Success<T, E>;

  /// Wrap an error as a failed [Result].
  const factory Result.failure(E error) = Failure<T, E>;

  /// Run [block] and capture its return value or thrown object.
  /// Useful for interoperating with throwing APIs.
  ///
  /// By default the thrown object is stored verbatim (requires
  /// `E == Object`). Pass [mapError] to convert it to your domain error.
  static Result<T, E> runCatching<T, E>(
    T Function() block, {
    E Function(Object error, StackTrace stack)? mapError,
  }) {
    try {
      return Result<T, E>.success(block());
    } catch (e, st) {
      if (mapError != null) return Result<T, E>.failure(mapError(e, st));
      return Result<T, E>.failure(e as E);
    }
  }

  /// Async variant of [runCatching].
  static Future<Result<T, E>> runCatchingAsync<T, E>(
    Future<T> Function() block, {
    E Function(Object error, StackTrace stack)? mapError,
  }) async {
    try {
      return Result<T, E>.success(await block());
    } catch (e, st) {
      if (mapError != null) return Result<T, E>.failure(mapError(e, st));
      return Result<T, E>.failure(e as E);
    }
  }

  /// True if this is a [Success].
  bool get isSuccess => this is Success<T, E>;

  /// True if this is a [Failure].
  bool get isFailure => this is Failure<T, E>;

  /// The value if [Success], otherwise `null`.
  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Failure() => null,
  };

  /// The error if [Failure], otherwise `null`.
  E? get errorOrNull => switch (this) {
    Success() => null,
    Failure(:final error) => error,
  };

  /// Pattern-match style consumer. Provide both branches; they must
  /// return the same type.
  R when<R>({
    required R Function(T value) success,
    required R Function(E error) failure,
  }) => switch (this) {
    Success(:final value) => success(value),
    Failure(:final error) => failure(error),
  };

  /// Like [when] but with positional arguments (error first, success
  /// second) — mirrors Kotlin / Rust `fold`.
  R fold<R>(
    R Function(E error) onFailure,
    R Function(T value) onSuccess,
  ) => switch (this) {
    Success(:final value) => onSuccess(value),
    Failure(:final error) => onFailure(error),
  };

  /// Transform the success value. Does nothing on failure.
  Result<R, E> map<R>(R Function(T value) transform) => switch (this) {
    Success(:final value) => Result<R, E>.success(transform(value)),
    Failure(:final error) => Result<R, E>.failure(error),
  };

  /// Chain another [Result]-returning operation. Short-circuits on failure.
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) transform) =>
      switch (this) {
        Success(:final value) => transform(value),
        Failure(:final error) => Result<R, E>.failure(error),
      };

  /// Transform the error. Does nothing on success.
  Result<T, F> mapError<F>(F Function(E error) transform) => switch (this) {
    Success(:final value) => Result<T, F>.success(value),
    Failure(:final error) => Result<T, F>.failure(transform(error)),
  };

  /// Unwrap the success value, or return [defaultValue] on failure.
  T getOrDefault(T defaultValue) => switch (this) {
    Success(:final value) => value,
    Failure() => defaultValue,
  };

  /// Unwrap the success value, or compute a replacement from the error.
  T getOrElse(T Function(E error) onError) => switch (this) {
    Success(:final value) => value,
    Failure(:final error) => onError(error),
  };

  /// Side-effect on the success value. Returns `this` unchanged.
  Result<T, E> onSuccess(void Function(T value) action) {
    if (this case Success(:final value)) action(value);
    return this;
  }

  /// Side-effect on the error. Returns `this` unchanged.
  Result<T, E> onFailure(void Function(E error) action) {
    if (this case Failure(:final error)) action(error);
    return this;
  }
}

/// Successful [Result] carrying a [value].
final class Success<T, E> extends Result<T, E> {
  const Success(this.value);
  final T value;

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      other is Success<T, E> && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Failed [Result] carrying an [error].
final class Failure<T, E> extends Result<T, E> {
  const Failure(this.error);
  final E error;

  @override
  String toString() => 'Failure($error)';

  @override
  bool operator ==(Object other) =>
      other is Failure<T, E> && other.error == error;

  @override
  int get hashCode => error.hashCode;
}

/// Async chaining helpers so `Future<Result<T, E>>` reads as nicely
/// as a synchronous [Result].
extension FutureResultX<T, E> on Future<Result<T, E>> {
  /// Transform the success value after awaiting.
  Future<Result<R, E>> mapAsync<R>(R Function(T value) transform) async =>
      (await this).map(transform);

  /// Chain another async [Result]-returning operation.
  Future<Result<R, E>> flatMapAsync<R>(
    Future<Result<R, E>> Function(T value) transform,
  ) async {
    final result = await this;
    return switch (result) {
      Success(:final value) => await transform(value),
      Failure(:final error) => Result<R, E>.failure(error),
    };
  }

  /// Transform the error after awaiting.
  Future<Result<T, F>> mapErrorAsync<F>(F Function(E error) transform) async =>
      (await this).mapError(transform);
}

/// Convert a raw `Stream<T>` into a `Stream<Result<T, AppException>>` —
/// emissions become [Success], errors from the source stream become
/// [Failure] emissions instead of terminating the subscription.
///
/// Use when a long-lived stream's transformations (`.map(...)`) can
/// throw and you want parse failures to surface at the listen site
/// without ending the whole subscription.
///
/// ```dart
/// final events = channel.on('order_updated')
///     .map((e) => Order.fromJson(e.data))   // throws on malformed JSON
///     .resultified();
///
/// events.listen((r) => r.when(
///   onSuccess: (order) => ui.update(order),
///   onFailure: (e) => log.warn('bad event: ${e.message}'),
/// ));
/// ```
///
/// For simple cases where parse failures should be silently dropped +
/// logged, prefer a `.map(...).handleError(...)` chain — this helper
/// is for when you want parse failures to be visible as emissions.
extension StreamResultX<T> on Stream<T> {
  Stream<Result<T, AppException>> resultified() {
    return transform(
      StreamTransformer<T, Result<T, AppException>>.fromHandlers(
        handleData: (data, sink) =>
            sink.add(Result<T, AppException>.success(data)),
        handleError: (error, stack, sink) {
          sink.add(
            Result<T, AppException>.failure(
              AppException.fromError(error, stack),
            ),
          );
        },
      ),
    );
  }
}
