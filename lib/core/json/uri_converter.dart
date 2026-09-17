import 'package:freezed_annotation/freezed_annotation.dart';

/// Converts between [Uri] and a string.
///
/// ```dart
/// @JsonSerializable()
/// class Profile {
///   @UriConverter()
///   final Uri avatar;
/// }
/// ```
class UriConverter extends JsonConverter<Uri, String> {
  const UriConverter();

  @override
  Uri fromJson(String json) => Uri.parse(json);

  @override
  String toJson(Uri object) => object.toString();
}

/// Nullable variant of [UriConverter]. Returns `null` for a `null` or
/// unparseable input instead of throwing.
class NullableUriConverter extends JsonConverter<Uri?, String?> {
  const NullableUriConverter();

  @override
  Uri? fromJson(String? json) {
    if (json == null || json.isEmpty) return null;
    return Uri.tryParse(json);
  }

  @override
  String? toJson(Uri? object) => object?.toString();
}
