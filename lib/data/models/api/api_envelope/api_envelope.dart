// Package imports:
import 'package:freezed_annotation/freezed_annotation.dart';

part 'api_envelope.freezed.dart';
part 'api_envelope.g.dart';

/// Generic wire-level response envelope — every successful API
/// response conforms to this shape:
///
/// ```json
/// {
///   "status": true,
///   "status_code": 200,
///   "message": "Ok",
///   "data": {…}        // object, list, or paginated sub-envelope
///   "errors": ["…"]    // optional, usually only on failure
/// }
/// ```
///
/// ## `errors` arrives in TWO shapes
///
/// Laravel keys a validation failure by the INPUT it belongs to —
/// `{"errors": {"password": ["The provided password is incorrect."]}}`
/// — while other failures send a flat list. Declared as a list alone,
/// the map threw a cast error inside `fromJson`, which the handler then
/// reported as an unknown parse failure: every field-keyed 422 from the
/// backend lost both its message and the field it belonged to, so
/// "wrong password" could never be shown under the password box.
///
/// Both shapes are read now, into [errors] and [fieldErrors]
/// respectively, and whichever does not match is simply null.
///
/// This is distinct from `Result<T, AppException>` in `core/types/`:
///
/// - **`ApiEnvelope<T>`** is the *wire* shape — how the backend
///   structures responses before the app unwraps them.
/// - **`Result<T, AppException>`** is the *app* shape — how errors
///   and values flow through feature code.
///
/// The `api_response_handler.dart` helpers take a raw [Response],
/// parse it through this envelope, and emit a `Result` — so feature
/// code sees only `Result`, never the envelope.
///
/// ## Generic limitation
/// Dart's `json_serializable` can't round-trip `T` without a
/// `fromJsonT` callback, so this model deserializes [data] as a raw
/// `Map<String, dynamic>` / `List<dynamic>` — callers handle the
/// type-specific conversion downstream (exactly what the handlers
/// do today).
@Freezed(genericArgumentFactories: true)
abstract class ApiEnvelope<T> with _$ApiEnvelope<T> {
  const factory ApiEnvelope({
    /// Whether the server considered the call a success.
    ///
    /// Read from `success` OR `status`: the documented envelope names it
    /// `status`, and this backend actually sends `success`. Looking for
    /// `status` alone meant a failure body fell through to the DEFAULT
    /// of true — a 422 was handled as a success with no `data`, and the
    /// customer got "Expected `data` on a successful response" instead
    /// of "User not found."
    @JsonKey(readValue: readStatusFlag) @Default(true) bool status,
    int? statusCode,
    String? message,
    T? data,

    /// The envelope's OWN side-band, beside `data` rather than inside
    /// it.
    ///
    /// `GET /api/workshops/bookings` answers with
    /// `meta.status_counts` — a tally of the customer's whole history
    /// that does not move when `?status=` filters the rows. It is a
    /// sibling of `data`, so a parser handed only `data` cannot see
    /// it, which is why it is read here and carried out through
    /// [handleListWithMetaResponse].
    ///
    /// Raw on purpose: this key holds a different shape per endpoint,
    /// and one model per shape would be a class each time the backend
    /// adds a tally.
    Map<String, dynamic>? meta,

    /// A flat list of messages, when the server sends one.
    @JsonKey(fromJson: flatErrors) List<String>? errors,

    /// Validation messages keyed by the input that failed — the shape
    /// this backend uses for a 422. Reads the SAME `errors` key.
    @JsonKey(name: 'errors', fromJson: keyedErrors, includeToJson: false)
    Map<String, List<String>>? fieldErrors,
  }) = _ApiEnvelope<T>;

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) => _$ApiEnvelopeFromJson<T>(json, fromJsonT);
}

/// The success flag under either of the two names it arrives under.
Object? readStatusFlag(Map<dynamic, dynamic> json, String key) =>
    json['success'] ?? json['status'];

/// `errors` when it is a flat list; null when it is anything else.
///
/// Deliberately total: a body that fails to parse is a body whose
/// MESSAGE is lost too, and a validation failure the customer cannot
/// read is worse than one shown without its field.
List<String>? flatErrors(Object? value) {
  if (value is! List) return null;
  return value.map((e) => e.toString()).toList();
}

/// `errors` when it is keyed by input name; null when it is anything
/// else. A single string under a key is accepted as a list of one,
/// which is a shape Laravel produces for some rules.
Map<String, List<String>>? keyedErrors(Object? value) {
  if (value is! Map) return null;
  final out = <String, List<String>>{};
  for (final entry in value.entries) {
    final key = entry.key.toString();
    final v = entry.value;
    out[key] = v is List
        ? v.map((e) => e.toString()).toList()
        : <String>[v.toString()];
  }
  return out.isEmpty ? null : out;
}
