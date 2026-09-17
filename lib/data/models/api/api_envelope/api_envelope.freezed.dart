// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'api_envelope.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ApiEnvelope<T> {

/// Whether the server considered the call a success.
///
/// Read from `success` OR `status`: the documented envelope names it
/// `status`, and this backend actually sends `success`. Looking for
/// `status` alone meant a failure body fell through to the DEFAULT
/// of true — a 422 was handled as a success with no `data`, and the
/// customer got "Expected `data` on a successful response" instead
/// of "User not found."
@JsonKey(readValue: readStatusFlag) bool get status; int? get statusCode; String? get message; T? get data;/// The envelope's OWN side-band, beside `data` rather than inside
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
 Map<String, dynamic>? get meta;/// A flat list of messages, when the server sends one.
@JsonKey(fromJson: flatErrors) List<String>? get errors;/// Validation messages keyed by the input that failed — the shape
/// this backend uses for a 422. Reads the SAME `errors` key.
@JsonKey(name: 'errors', fromJson: keyedErrors, includeToJson: false) Map<String, List<String>>? get fieldErrors;
/// Create a copy of ApiEnvelope
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ApiEnvelopeCopyWith<T, ApiEnvelope<T>> get copyWith => _$ApiEnvelopeCopyWithImpl<T, ApiEnvelope<T>>(this as ApiEnvelope<T>, _$identity);

  /// Serializes this ApiEnvelope to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT);


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ApiEnvelope<T>&&(identical(other.status, status) || other.status == status)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data)&&const DeepCollectionEquality().equals(other.meta, meta)&&const DeepCollectionEquality().equals(other.errors, errors)&&const DeepCollectionEquality().equals(other.fieldErrors, fieldErrors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,statusCode,message,const DeepCollectionEquality().hash(data),const DeepCollectionEquality().hash(meta),const DeepCollectionEquality().hash(errors),const DeepCollectionEquality().hash(fieldErrors));

@override
String toString() {
  return 'ApiEnvelope<$T>(status: $status, statusCode: $statusCode, message: $message, data: $data, meta: $meta, errors: $errors, fieldErrors: $fieldErrors)';
}


}

/// @nodoc
abstract mixin class $ApiEnvelopeCopyWith<T,$Res>  {
  factory $ApiEnvelopeCopyWith(ApiEnvelope<T> value, $Res Function(ApiEnvelope<T>) _then) = _$ApiEnvelopeCopyWithImpl;
@useResult
$Res call({
@JsonKey(readValue: readStatusFlag) bool status, int? statusCode, String? message, T? data, Map<String, dynamic>? meta,@JsonKey(fromJson: flatErrors) List<String>? errors,@JsonKey(name: 'errors', fromJson: keyedErrors, includeToJson: false) Map<String, List<String>>? fieldErrors
});




}
/// @nodoc
class _$ApiEnvelopeCopyWithImpl<T,$Res>
    implements $ApiEnvelopeCopyWith<T, $Res> {
  _$ApiEnvelopeCopyWithImpl(this._self, this._then);

  final ApiEnvelope<T> _self;
  final $Res Function(ApiEnvelope<T>) _then;

/// Create a copy of ApiEnvelope
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? statusCode = freezed,Object? message = freezed,Object? data = freezed,Object? meta = freezed,Object? errors = freezed,Object? fieldErrors = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as bool,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T?,meta: freezed == meta ? _self.meta : meta // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,errors: freezed == errors ? _self.errors : errors // ignore: cast_nullable_to_non_nullable
as List<String>?,fieldErrors: freezed == fieldErrors ? _self.fieldErrors : fieldErrors // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ApiEnvelope].
extension ApiEnvelopePatterns<T> on ApiEnvelope<T> {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ApiEnvelope<T> value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ApiEnvelope() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ApiEnvelope<T> value)  $default,){
final _that = this;
switch (_that) {
case _ApiEnvelope():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ApiEnvelope<T> value)?  $default,){
final _that = this;
switch (_that) {
case _ApiEnvelope() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(readValue: readStatusFlag)  bool status,  int? statusCode,  String? message,  T? data,  Map<String, dynamic>? meta, @JsonKey(fromJson: flatErrors)  List<String>? errors, @JsonKey(name: 'errors', fromJson: keyedErrors, includeToJson: false)  Map<String, List<String>>? fieldErrors)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ApiEnvelope() when $default != null:
return $default(_that.status,_that.statusCode,_that.message,_that.data,_that.meta,_that.errors,_that.fieldErrors);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(readValue: readStatusFlag)  bool status,  int? statusCode,  String? message,  T? data,  Map<String, dynamic>? meta, @JsonKey(fromJson: flatErrors)  List<String>? errors, @JsonKey(name: 'errors', fromJson: keyedErrors, includeToJson: false)  Map<String, List<String>>? fieldErrors)  $default,) {final _that = this;
switch (_that) {
case _ApiEnvelope():
return $default(_that.status,_that.statusCode,_that.message,_that.data,_that.meta,_that.errors,_that.fieldErrors);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(readValue: readStatusFlag)  bool status,  int? statusCode,  String? message,  T? data,  Map<String, dynamic>? meta, @JsonKey(fromJson: flatErrors)  List<String>? errors, @JsonKey(name: 'errors', fromJson: keyedErrors, includeToJson: false)  Map<String, List<String>>? fieldErrors)?  $default,) {final _that = this;
switch (_that) {
case _ApiEnvelope() when $default != null:
return $default(_that.status,_that.statusCode,_that.message,_that.data,_that.meta,_that.errors,_that.fieldErrors);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class _ApiEnvelope<T> implements ApiEnvelope<T> {
  const _ApiEnvelope({@JsonKey(readValue: readStatusFlag) this.status = true, this.statusCode, this.message, this.data, final  Map<String, dynamic>? meta, @JsonKey(fromJson: flatErrors) final  List<String>? errors, @JsonKey(name: 'errors', fromJson: keyedErrors, includeToJson: false) final  Map<String, List<String>>? fieldErrors}): _meta = meta,_errors = errors,_fieldErrors = fieldErrors;
  factory _ApiEnvelope.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$ApiEnvelopeFromJson(json,fromJsonT);

/// Whether the server considered the call a success.
///
/// Read from `success` OR `status`: the documented envelope names it
/// `status`, and this backend actually sends `success`. Looking for
/// `status` alone meant a failure body fell through to the DEFAULT
/// of true — a 422 was handled as a success with no `data`, and the
/// customer got "Expected `data` on a successful response" instead
/// of "User not found."
@override@JsonKey(readValue: readStatusFlag) final  bool status;
@override final  int? statusCode;
@override final  String? message;
@override final  T? data;
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
 final  Map<String, dynamic>? _meta;
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
@override Map<String, dynamic>? get meta {
  final value = _meta;
  if (value == null) return null;
  if (_meta is EqualUnmodifiableMapView) return _meta;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

/// A flat list of messages, when the server sends one.
 final  List<String>? _errors;
/// A flat list of messages, when the server sends one.
@override@JsonKey(fromJson: flatErrors) List<String>? get errors {
  final value = _errors;
  if (value == null) return null;
  if (_errors is EqualUnmodifiableListView) return _errors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

/// Validation messages keyed by the input that failed — the shape
/// this backend uses for a 422. Reads the SAME `errors` key.
 final  Map<String, List<String>>? _fieldErrors;
/// Validation messages keyed by the input that failed — the shape
/// this backend uses for a 422. Reads the SAME `errors` key.
@override@JsonKey(name: 'errors', fromJson: keyedErrors, includeToJson: false) Map<String, List<String>>? get fieldErrors {
  final value = _fieldErrors;
  if (value == null) return null;
  if (_fieldErrors is EqualUnmodifiableMapView) return _fieldErrors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of ApiEnvelope
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ApiEnvelopeCopyWith<T, _ApiEnvelope<T>> get copyWith => __$ApiEnvelopeCopyWithImpl<T, _ApiEnvelope<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$ApiEnvelopeToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ApiEnvelope<T>&&(identical(other.status, status) || other.status == status)&&(identical(other.statusCode, statusCode) || other.statusCode == statusCode)&&(identical(other.message, message) || other.message == message)&&const DeepCollectionEquality().equals(other.data, data)&&const DeepCollectionEquality().equals(other._meta, _meta)&&const DeepCollectionEquality().equals(other._errors, _errors)&&const DeepCollectionEquality().equals(other._fieldErrors, _fieldErrors));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,statusCode,message,const DeepCollectionEquality().hash(data),const DeepCollectionEquality().hash(_meta),const DeepCollectionEquality().hash(_errors),const DeepCollectionEquality().hash(_fieldErrors));

@override
String toString() {
  return 'ApiEnvelope<$T>(status: $status, statusCode: $statusCode, message: $message, data: $data, meta: $meta, errors: $errors, fieldErrors: $fieldErrors)';
}


}

/// @nodoc
abstract mixin class _$ApiEnvelopeCopyWith<T,$Res> implements $ApiEnvelopeCopyWith<T, $Res> {
  factory _$ApiEnvelopeCopyWith(_ApiEnvelope<T> value, $Res Function(_ApiEnvelope<T>) _then) = __$ApiEnvelopeCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(readValue: readStatusFlag) bool status, int? statusCode, String? message, T? data, Map<String, dynamic>? meta,@JsonKey(fromJson: flatErrors) List<String>? errors,@JsonKey(name: 'errors', fromJson: keyedErrors, includeToJson: false) Map<String, List<String>>? fieldErrors
});




}
/// @nodoc
class __$ApiEnvelopeCopyWithImpl<T,$Res>
    implements _$ApiEnvelopeCopyWith<T, $Res> {
  __$ApiEnvelopeCopyWithImpl(this._self, this._then);

  final _ApiEnvelope<T> _self;
  final $Res Function(_ApiEnvelope<T>) _then;

/// Create a copy of ApiEnvelope
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? statusCode = freezed,Object? message = freezed,Object? data = freezed,Object? meta = freezed,Object? errors = freezed,Object? fieldErrors = freezed,}) {
  return _then(_ApiEnvelope<T>(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as bool,statusCode: freezed == statusCode ? _self.statusCode : statusCode // ignore: cast_nullable_to_non_nullable
as int?,message: freezed == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String?,data: freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T?,meta: freezed == meta ? _self._meta : meta // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,errors: freezed == errors ? _self._errors : errors // ignore: cast_nullable_to_non_nullable
as List<String>?,fieldErrors: freezed == fieldErrors ? _self._fieldErrors : fieldErrors // ignore: cast_nullable_to_non_nullable
as Map<String, List<String>>?,
  ));
}


}

// dart format on
