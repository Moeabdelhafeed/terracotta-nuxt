import 'package:freezed_annotation/freezed_annotation.dart';

/// Converts between [Duration] and `int` milliseconds.
///
/// ```dart
/// @JsonSerializable()
/// class Config {
///   @DurationConverter()
///   final Duration timeout;
/// }
/// ```
class DurationConverter extends JsonConverter<Duration, int> {
  const DurationConverter();

  @override
  Duration fromJson(int json) => Duration(milliseconds: json);

  @override
  int toJson(Duration object) => object.inMilliseconds;
}

/// Nullable variant of [DurationConverter].
class NullableDurationConverter extends JsonConverter<Duration?, int?> {
  const NullableDurationConverter();

  @override
  Duration? fromJson(int? json) =>
      json == null ? null : Duration(milliseconds: json);

  @override
  int? toJson(Duration? object) => object?.inMilliseconds;
}

/// Converts between [Duration] and `int` **seconds** — use when the
/// backend stores durations in seconds rather than milliseconds.
class DurationSecondsConverter extends JsonConverter<Duration, int> {
  const DurationSecondsConverter();

  @override
  Duration fromJson(int json) => Duration(seconds: json);

  @override
  int toJson(Duration object) => object.inSeconds;
}
