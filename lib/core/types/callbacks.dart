import '../error/app_exception.dart';
import 'json.dart';
import 'result.dart';

/// Common callback typedefs used across the app. Keep them here so call
/// sites don't spell `Future<void> Function()` in every API.

// ─── Async callbacks ──────────────────────────────────────────

/// Fire-and-return callback with no args.
typedef AsyncCallback = Future<void> Function();

/// Async setter for a single value (the async cousin of `ValueChanged<T>`).
typedef AsyncValueChanged<T> = Future<void> Function(T value);

// ─── Parsers ──────────────────────────────────────────────────

/// `fromJson` signature used throughout the API layer.
typedef JsonParser<T> = T Function(Json json);

/// `fromJson` signature for list-shaped responses.
typedef JsonListParser<T> = T Function(JsonList list);

/// Generic mapper from `S` to `T`.
typedef Mapper<S, T> = T Function(S source);

// ─── Predicates & comparators ────────────────────────────────

/// `bool` predicate on a single value — filter, find, validate.
typedef Predicate<T> = bool Function(T value);

/// Comparator — returns negative / zero / positive.
typedef Compare<T> = int Function(T a, T b);

// ─── Result-aware callbacks ──────────────────────────────────

/// Callback that receives a [Result].
typedef ResultCallback<T> = void Function(Result<T, AppException> result);

/// Callback for the success side of a [Result].
typedef SuccessCallback<T> = void Function(T value);

/// Callback for the failure side of a [Result].
typedef FailureCallback = void Function(AppException error);
