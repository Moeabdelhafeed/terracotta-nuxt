// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gift_history.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GiftTotals {

/// Every gift bought, INCLUDING unpaid and abandoned ones.
@JsonKey(name: 'sent_count') int get sentCount;/// Sum of `total_price` over PAID purchases only — a hold that
/// lapsed is not money anybody spent. A decimal STRING.
@JsonKey(name: 'sent_total_paid') String get sentTotalPaid;@JsonKey(name: 'received_count') int get receivedCount;/// Sum of the `amount` credited. A decimal STRING.
@JsonKey(name: 'received_total') String get receivedTotal;
/// Create a copy of GiftTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GiftTotalsCopyWith<GiftTotals> get copyWith => _$GiftTotalsCopyWithImpl<GiftTotals>(this as GiftTotals, _$identity);

  /// Serializes this GiftTotals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GiftTotals&&(identical(other.sentCount, sentCount) || other.sentCount == sentCount)&&(identical(other.sentTotalPaid, sentTotalPaid) || other.sentTotalPaid == sentTotalPaid)&&(identical(other.receivedCount, receivedCount) || other.receivedCount == receivedCount)&&(identical(other.receivedTotal, receivedTotal) || other.receivedTotal == receivedTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sentCount,sentTotalPaid,receivedCount,receivedTotal);

@override
String toString() {
  return 'GiftTotals(sentCount: $sentCount, sentTotalPaid: $sentTotalPaid, receivedCount: $receivedCount, receivedTotal: $receivedTotal)';
}


}

/// @nodoc
abstract mixin class $GiftTotalsCopyWith<$Res>  {
  factory $GiftTotalsCopyWith(GiftTotals value, $Res Function(GiftTotals) _then) = _$GiftTotalsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'sent_count') int sentCount,@JsonKey(name: 'sent_total_paid') String sentTotalPaid,@JsonKey(name: 'received_count') int receivedCount,@JsonKey(name: 'received_total') String receivedTotal
});




}
/// @nodoc
class _$GiftTotalsCopyWithImpl<$Res>
    implements $GiftTotalsCopyWith<$Res> {
  _$GiftTotalsCopyWithImpl(this._self, this._then);

  final GiftTotals _self;
  final $Res Function(GiftTotals) _then;

/// Create a copy of GiftTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? sentCount = null,Object? sentTotalPaid = null,Object? receivedCount = null,Object? receivedTotal = null,}) {
  return _then(_self.copyWith(
sentCount: null == sentCount ? _self.sentCount : sentCount // ignore: cast_nullable_to_non_nullable
as int,sentTotalPaid: null == sentTotalPaid ? _self.sentTotalPaid : sentTotalPaid // ignore: cast_nullable_to_non_nullable
as String,receivedCount: null == receivedCount ? _self.receivedCount : receivedCount // ignore: cast_nullable_to_non_nullable
as int,receivedTotal: null == receivedTotal ? _self.receivedTotal : receivedTotal // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [GiftTotals].
extension GiftTotalsPatterns on GiftTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GiftTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GiftTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GiftTotals value)  $default,){
final _that = this;
switch (_that) {
case _GiftTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GiftTotals value)?  $default,){
final _that = this;
switch (_that) {
case _GiftTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'sent_count')  int sentCount, @JsonKey(name: 'sent_total_paid')  String sentTotalPaid, @JsonKey(name: 'received_count')  int receivedCount, @JsonKey(name: 'received_total')  String receivedTotal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GiftTotals() when $default != null:
return $default(_that.sentCount,_that.sentTotalPaid,_that.receivedCount,_that.receivedTotal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'sent_count')  int sentCount, @JsonKey(name: 'sent_total_paid')  String sentTotalPaid, @JsonKey(name: 'received_count')  int receivedCount, @JsonKey(name: 'received_total')  String receivedTotal)  $default,) {final _that = this;
switch (_that) {
case _GiftTotals():
return $default(_that.sentCount,_that.sentTotalPaid,_that.receivedCount,_that.receivedTotal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'sent_count')  int sentCount, @JsonKey(name: 'sent_total_paid')  String sentTotalPaid, @JsonKey(name: 'received_count')  int receivedCount, @JsonKey(name: 'received_total')  String receivedTotal)?  $default,) {final _that = this;
switch (_that) {
case _GiftTotals() when $default != null:
return $default(_that.sentCount,_that.sentTotalPaid,_that.receivedCount,_that.receivedTotal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GiftTotals implements GiftTotals {
  const _GiftTotals({@JsonKey(name: 'sent_count') this.sentCount = 0, @JsonKey(name: 'sent_total_paid') this.sentTotalPaid = '0.00', @JsonKey(name: 'received_count') this.receivedCount = 0, @JsonKey(name: 'received_total') this.receivedTotal = '0.00'});
  factory _GiftTotals.fromJson(Map<String, dynamic> json) => _$GiftTotalsFromJson(json);

/// Every gift bought, INCLUDING unpaid and abandoned ones.
@override@JsonKey(name: 'sent_count') final  int sentCount;
/// Sum of `total_price` over PAID purchases only — a hold that
/// lapsed is not money anybody spent. A decimal STRING.
@override@JsonKey(name: 'sent_total_paid') final  String sentTotalPaid;
@override@JsonKey(name: 'received_count') final  int receivedCount;
/// Sum of the `amount` credited. A decimal STRING.
@override@JsonKey(name: 'received_total') final  String receivedTotal;

/// Create a copy of GiftTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GiftTotalsCopyWith<_GiftTotals> get copyWith => __$GiftTotalsCopyWithImpl<_GiftTotals>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GiftTotalsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GiftTotals&&(identical(other.sentCount, sentCount) || other.sentCount == sentCount)&&(identical(other.sentTotalPaid, sentTotalPaid) || other.sentTotalPaid == sentTotalPaid)&&(identical(other.receivedCount, receivedCount) || other.receivedCount == receivedCount)&&(identical(other.receivedTotal, receivedTotal) || other.receivedTotal == receivedTotal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,sentCount,sentTotalPaid,receivedCount,receivedTotal);

@override
String toString() {
  return 'GiftTotals(sentCount: $sentCount, sentTotalPaid: $sentTotalPaid, receivedCount: $receivedCount, receivedTotal: $receivedTotal)';
}


}

/// @nodoc
abstract mixin class _$GiftTotalsCopyWith<$Res> implements $GiftTotalsCopyWith<$Res> {
  factory _$GiftTotalsCopyWith(_GiftTotals value, $Res Function(_GiftTotals) _then) = __$GiftTotalsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'sent_count') int sentCount,@JsonKey(name: 'sent_total_paid') String sentTotalPaid,@JsonKey(name: 'received_count') int receivedCount,@JsonKey(name: 'received_total') String receivedTotal
});




}
/// @nodoc
class __$GiftTotalsCopyWithImpl<$Res>
    implements _$GiftTotalsCopyWith<$Res> {
  __$GiftTotalsCopyWithImpl(this._self, this._then);

  final _GiftTotals _self;
  final $Res Function(_GiftTotals) _then;

/// Create a copy of GiftTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? sentCount = null,Object? sentTotalPaid = null,Object? receivedCount = null,Object? receivedTotal = null,}) {
  return _then(_GiftTotals(
sentCount: null == sentCount ? _self.sentCount : sentCount // ignore: cast_nullable_to_non_nullable
as int,sentTotalPaid: null == sentTotalPaid ? _self.sentTotalPaid : sentTotalPaid // ignore: cast_nullable_to_non_nullable
as String,receivedCount: null == receivedCount ? _self.receivedCount : receivedCount // ignore: cast_nullable_to_non_nullable
as int,receivedTotal: null == receivedTotal ? _self.receivedTotal : receivedTotal // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
