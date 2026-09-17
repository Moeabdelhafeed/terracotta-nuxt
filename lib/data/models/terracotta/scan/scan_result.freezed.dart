// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScanResult {

 int get id;@JsonKey(name: 'user_name') String? get userName;@JsonKey(name: 'workshop_id') int? get workshopId;@JsonKey(name: 'workshop_slot_id') int? get workshopSlotId;@JsonKey(name: 'workshop_title') String? get workshopTitle;@JsonKey(name: 'people_count') int get peopleCount;@JsonKey(name: 'checked_in_count') int? get checkedInCount;/// They were already in. Scanning twice is not an error — a desk
/// scans the same code twice all the time.
@JsonKey(name: 'already_checked_in') bool get alreadyCheckedIn;/// The server wrote NOTHING and wants a headcount. See the class
/// note.
@JsonKey(name: 'needs_count') bool get needsCount;
/// Create a copy of ScanResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanResultCopyWith<ScanResult> get copyWith => _$ScanResultCopyWithImpl<ScanResult>(this as ScanResult, _$identity);

  /// Serializes this ScanResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanResult&&(identical(other.id, id) || other.id == id)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.workshopId, workshopId) || other.workshopId == workshopId)&&(identical(other.workshopSlotId, workshopSlotId) || other.workshopSlotId == workshopSlotId)&&(identical(other.workshopTitle, workshopTitle) || other.workshopTitle == workshopTitle)&&(identical(other.peopleCount, peopleCount) || other.peopleCount == peopleCount)&&(identical(other.checkedInCount, checkedInCount) || other.checkedInCount == checkedInCount)&&(identical(other.alreadyCheckedIn, alreadyCheckedIn) || other.alreadyCheckedIn == alreadyCheckedIn)&&(identical(other.needsCount, needsCount) || other.needsCount == needsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userName,workshopId,workshopSlotId,workshopTitle,peopleCount,checkedInCount,alreadyCheckedIn,needsCount);

@override
String toString() {
  return 'ScanResult(id: $id, userName: $userName, workshopId: $workshopId, workshopSlotId: $workshopSlotId, workshopTitle: $workshopTitle, peopleCount: $peopleCount, checkedInCount: $checkedInCount, alreadyCheckedIn: $alreadyCheckedIn, needsCount: $needsCount)';
}


}

/// @nodoc
abstract mixin class $ScanResultCopyWith<$Res>  {
  factory $ScanResultCopyWith(ScanResult value, $Res Function(ScanResult) _then) = _$ScanResultCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'user_name') String? userName,@JsonKey(name: 'workshop_id') int? workshopId,@JsonKey(name: 'workshop_slot_id') int? workshopSlotId,@JsonKey(name: 'workshop_title') String? workshopTitle,@JsonKey(name: 'people_count') int peopleCount,@JsonKey(name: 'checked_in_count') int? checkedInCount,@JsonKey(name: 'already_checked_in') bool alreadyCheckedIn,@JsonKey(name: 'needs_count') bool needsCount
});




}
/// @nodoc
class _$ScanResultCopyWithImpl<$Res>
    implements $ScanResultCopyWith<$Res> {
  _$ScanResultCopyWithImpl(this._self, this._then);

  final ScanResult _self;
  final $Res Function(ScanResult) _then;

/// Create a copy of ScanResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userName = freezed,Object? workshopId = freezed,Object? workshopSlotId = freezed,Object? workshopTitle = freezed,Object? peopleCount = null,Object? checkedInCount = freezed,Object? alreadyCheckedIn = null,Object? needsCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,workshopId: freezed == workshopId ? _self.workshopId : workshopId // ignore: cast_nullable_to_non_nullable
as int?,workshopSlotId: freezed == workshopSlotId ? _self.workshopSlotId : workshopSlotId // ignore: cast_nullable_to_non_nullable
as int?,workshopTitle: freezed == workshopTitle ? _self.workshopTitle : workshopTitle // ignore: cast_nullable_to_non_nullable
as String?,peopleCount: null == peopleCount ? _self.peopleCount : peopleCount // ignore: cast_nullable_to_non_nullable
as int,checkedInCount: freezed == checkedInCount ? _self.checkedInCount : checkedInCount // ignore: cast_nullable_to_non_nullable
as int?,alreadyCheckedIn: null == alreadyCheckedIn ? _self.alreadyCheckedIn : alreadyCheckedIn // ignore: cast_nullable_to_non_nullable
as bool,needsCount: null == needsCount ? _self.needsCount : needsCount // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanResult].
extension ScanResultPatterns on ScanResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanResult value)  $default,){
final _that = this;
switch (_that) {
case _ScanResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanResult value)?  $default,){
final _that = this;
switch (_that) {
case _ScanResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'user_name')  String? userName, @JsonKey(name: 'workshop_id')  int? workshopId, @JsonKey(name: 'workshop_slot_id')  int? workshopSlotId, @JsonKey(name: 'workshop_title')  String? workshopTitle, @JsonKey(name: 'people_count')  int peopleCount, @JsonKey(name: 'checked_in_count')  int? checkedInCount, @JsonKey(name: 'already_checked_in')  bool alreadyCheckedIn, @JsonKey(name: 'needs_count')  bool needsCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanResult() when $default != null:
return $default(_that.id,_that.userName,_that.workshopId,_that.workshopSlotId,_that.workshopTitle,_that.peopleCount,_that.checkedInCount,_that.alreadyCheckedIn,_that.needsCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'user_name')  String? userName, @JsonKey(name: 'workshop_id')  int? workshopId, @JsonKey(name: 'workshop_slot_id')  int? workshopSlotId, @JsonKey(name: 'workshop_title')  String? workshopTitle, @JsonKey(name: 'people_count')  int peopleCount, @JsonKey(name: 'checked_in_count')  int? checkedInCount, @JsonKey(name: 'already_checked_in')  bool alreadyCheckedIn, @JsonKey(name: 'needs_count')  bool needsCount)  $default,) {final _that = this;
switch (_that) {
case _ScanResult():
return $default(_that.id,_that.userName,_that.workshopId,_that.workshopSlotId,_that.workshopTitle,_that.peopleCount,_that.checkedInCount,_that.alreadyCheckedIn,_that.needsCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'user_name')  String? userName, @JsonKey(name: 'workshop_id')  int? workshopId, @JsonKey(name: 'workshop_slot_id')  int? workshopSlotId, @JsonKey(name: 'workshop_title')  String? workshopTitle, @JsonKey(name: 'people_count')  int peopleCount, @JsonKey(name: 'checked_in_count')  int? checkedInCount, @JsonKey(name: 'already_checked_in')  bool alreadyCheckedIn, @JsonKey(name: 'needs_count')  bool needsCount)?  $default,) {final _that = this;
switch (_that) {
case _ScanResult() when $default != null:
return $default(_that.id,_that.userName,_that.workshopId,_that.workshopSlotId,_that.workshopTitle,_that.peopleCount,_that.checkedInCount,_that.alreadyCheckedIn,_that.needsCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScanResult implements ScanResult {
  const _ScanResult({required this.id, @JsonKey(name: 'user_name') this.userName, @JsonKey(name: 'workshop_id') this.workshopId, @JsonKey(name: 'workshop_slot_id') this.workshopSlotId, @JsonKey(name: 'workshop_title') this.workshopTitle, @JsonKey(name: 'people_count') this.peopleCount = 1, @JsonKey(name: 'checked_in_count') this.checkedInCount, @JsonKey(name: 'already_checked_in') this.alreadyCheckedIn = false, @JsonKey(name: 'needs_count') this.needsCount = false});
  factory _ScanResult.fromJson(Map<String, dynamic> json) => _$ScanResultFromJson(json);

@override final  int id;
@override@JsonKey(name: 'user_name') final  String? userName;
@override@JsonKey(name: 'workshop_id') final  int? workshopId;
@override@JsonKey(name: 'workshop_slot_id') final  int? workshopSlotId;
@override@JsonKey(name: 'workshop_title') final  String? workshopTitle;
@override@JsonKey(name: 'people_count') final  int peopleCount;
@override@JsonKey(name: 'checked_in_count') final  int? checkedInCount;
/// They were already in. Scanning twice is not an error — a desk
/// scans the same code twice all the time.
@override@JsonKey(name: 'already_checked_in') final  bool alreadyCheckedIn;
/// The server wrote NOTHING and wants a headcount. See the class
/// note.
@override@JsonKey(name: 'needs_count') final  bool needsCount;

/// Create a copy of ScanResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanResultCopyWith<_ScanResult> get copyWith => __$ScanResultCopyWithImpl<_ScanResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScanResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanResult&&(identical(other.id, id) || other.id == id)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.workshopId, workshopId) || other.workshopId == workshopId)&&(identical(other.workshopSlotId, workshopSlotId) || other.workshopSlotId == workshopSlotId)&&(identical(other.workshopTitle, workshopTitle) || other.workshopTitle == workshopTitle)&&(identical(other.peopleCount, peopleCount) || other.peopleCount == peopleCount)&&(identical(other.checkedInCount, checkedInCount) || other.checkedInCount == checkedInCount)&&(identical(other.alreadyCheckedIn, alreadyCheckedIn) || other.alreadyCheckedIn == alreadyCheckedIn)&&(identical(other.needsCount, needsCount) || other.needsCount == needsCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userName,workshopId,workshopSlotId,workshopTitle,peopleCount,checkedInCount,alreadyCheckedIn,needsCount);

@override
String toString() {
  return 'ScanResult(id: $id, userName: $userName, workshopId: $workshopId, workshopSlotId: $workshopSlotId, workshopTitle: $workshopTitle, peopleCount: $peopleCount, checkedInCount: $checkedInCount, alreadyCheckedIn: $alreadyCheckedIn, needsCount: $needsCount)';
}


}

/// @nodoc
abstract mixin class _$ScanResultCopyWith<$Res> implements $ScanResultCopyWith<$Res> {
  factory _$ScanResultCopyWith(_ScanResult value, $Res Function(_ScanResult) _then) = __$ScanResultCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'user_name') String? userName,@JsonKey(name: 'workshop_id') int? workshopId,@JsonKey(name: 'workshop_slot_id') int? workshopSlotId,@JsonKey(name: 'workshop_title') String? workshopTitle,@JsonKey(name: 'people_count') int peopleCount,@JsonKey(name: 'checked_in_count') int? checkedInCount,@JsonKey(name: 'already_checked_in') bool alreadyCheckedIn,@JsonKey(name: 'needs_count') bool needsCount
});




}
/// @nodoc
class __$ScanResultCopyWithImpl<$Res>
    implements _$ScanResultCopyWith<$Res> {
  __$ScanResultCopyWithImpl(this._self, this._then);

  final _ScanResult _self;
  final $Res Function(_ScanResult) _then;

/// Create a copy of ScanResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userName = freezed,Object? workshopId = freezed,Object? workshopSlotId = freezed,Object? workshopTitle = freezed,Object? peopleCount = null,Object? checkedInCount = freezed,Object? alreadyCheckedIn = null,Object? needsCount = null,}) {
  return _then(_ScanResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,workshopId: freezed == workshopId ? _self.workshopId : workshopId // ignore: cast_nullable_to_non_nullable
as int?,workshopSlotId: freezed == workshopSlotId ? _self.workshopSlotId : workshopSlotId // ignore: cast_nullable_to_non_nullable
as int?,workshopTitle: freezed == workshopTitle ? _self.workshopTitle : workshopTitle // ignore: cast_nullable_to_non_nullable
as String?,peopleCount: null == peopleCount ? _self.peopleCount : peopleCount // ignore: cast_nullable_to_non_nullable
as int,checkedInCount: freezed == checkedInCount ? _self.checkedInCount : checkedInCount // ignore: cast_nullable_to_non_nullable
as int?,alreadyCheckedIn: null == alreadyCheckedIn ? _self.alreadyCheckedIn : alreadyCheckedIn // ignore: cast_nullable_to_non_nullable
as bool,needsCount: null == needsCount ? _self.needsCount : needsCount // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
