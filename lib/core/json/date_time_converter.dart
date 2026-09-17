import 'package:freezed_annotation/freezed_annotation.dart';

/// Converts between [DateTime] and ISO 8601 string.
///
/// Serializes via [DateTime.toIso8601String]; deserializes via
/// [DateTime.parse] which accepts both UTC (`...Z`) and local
/// (`...+HH:MM`) offsets.
///
/// ```dart
/// @JsonSerializable()
/// class Post {
///   @DateTimeConverter()
///   final DateTime createdAt;
/// }
/// ```
class DateTimeConverter extends JsonConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json);

  @override
  String toJson(DateTime object) => object.toIso8601String();
}

/// Nullable variant of [DateTimeConverter]. Returns `null` for a `null`
/// or unparseable input instead of throwing.
class NullableDateTimeConverter extends JsonConverter<DateTime?, String?> {
  const NullableDateTimeConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null || json.isEmpty) return null;
    return DateTime.tryParse(json);
  }

  @override
  String? toJson(DateTime? object) => object?.toIso8601String();
}
