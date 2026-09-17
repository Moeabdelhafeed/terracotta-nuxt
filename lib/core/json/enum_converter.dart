import 'package:freezed_annotation/freezed_annotation.dart';

/// Generic enum converter — serializes by `name`, deserializes by name
/// with a [fallback] value when the string doesn't match any case.
///
/// ```dart
/// @JsonSerializable()
/// class Post {
///   @EnumConverter(PostStatus.values, PostStatus.unknown)
///   final PostStatus status;
/// }
/// ```
///
/// For nullable enums, see [NullableEnumConverter].
class EnumConverter<T extends Enum> extends JsonConverter<T, String> {
  const EnumConverter(this.values, this.fallback);

  /// All enum cases, usually `MyEnum.values`.
  final List<T> values;

  /// Returned when the JSON string doesn't match any case.
  final T fallback;

  @override
  T fromJson(String json) {
    for (final v in values) {
      if (v.name == json) return v;
    }
    return fallback;
  }

  @override
  String toJson(T object) => object.name;
}

/// Nullable variant of [EnumConverter]. Returns `null` for `null` input
/// (rather than the fallback).
class NullableEnumConverter<T extends Enum> extends JsonConverter<T?, String?> {
  const NullableEnumConverter(this.values, {this.fallback});

  final List<T> values;
  final T? fallback;

  @override
  T? fromJson(String? json) {
    if (json == null) return null;
    for (final v in values) {
      if (v.name == json) return v;
    }
    return fallback;
  }

  @override
  String? toJson(T? object) => object?.name;
}

/// Functional helpers for `@JsonKey(fromJson:, toJson:)` usage — useful
/// when a class-level annotation isn't convenient.
///
/// ```dart
/// @JsonKey(
///   fromJson: _statusFromJson,
///   toJson: _statusToJson,
/// )
/// final PostStatus status;
///
/// static PostStatus _statusFromJson(dynamic j) =>
///     enumFromJson(PostStatus.values, j, fallback: PostStatus.unknown);
/// static String _statusToJson(PostStatus s) => enumToJson(s);
/// ```
T enumFromJson<T extends Enum>(
  List<T> values,
  Object? json, {
  required T fallback,
}) {
  if (json is! String) return fallback;
  for (final v in values) {
    if (v.name == json) return v;
  }
  return fallback;
}

String enumToJson<T extends Enum>(T value) => value.name;
