// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'scan_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScanBooking {

 int get id;@JsonKey(name: 'user_name') String? get userName;@JsonKey(name: 'people_count') int get peopleCount; String get status;/// When the desk checked them in. Null until they arrive.
@JsonKey(name: 'checked_in_at') DateTime? get checkedInAt;/// How many of the party actually turned up — null until asked,
/// and never more than [peopleCount].
@JsonKey(name: 'checked_in_count') int? get checkedInCount;@JsonKey(name: 'has_celebration') bool get hasCelebration;/// How many pieces this booking has PHOTOGRAPHED so far.
@JsonKey(name: 'pieces_count') int get piecesCount;/// How many it is expected to end up with — one per person who
/// actually checked in for `make_your_piece`, and the quantity of
/// products bought for `paint_your_piece` / `make_your_candle`.
///
/// A GUIDE on the wheel and a CEILING in the other two: one person
/// can freely make three things, but a key past the number of
/// objects paid for answers 422.
@JsonKey(name: 'expected_piece_count') int? get expectedPieceCount;
/// Create a copy of ScanBooking
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanBookingCopyWith<ScanBooking> get copyWith => _$ScanBookingCopyWithImpl<ScanBooking>(this as ScanBooking, _$identity);

  /// Serializes this ScanBooking to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanBooking&&(identical(other.id, id) || other.id == id)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.peopleCount, peopleCount) || other.peopleCount == peopleCount)&&(identical(other.status, status) || other.status == status)&&(identical(other.checkedInAt, checkedInAt) || other.checkedInAt == checkedInAt)&&(identical(other.checkedInCount, checkedInCount) || other.checkedInCount == checkedInCount)&&(identical(other.hasCelebration, hasCelebration) || other.hasCelebration == hasCelebration)&&(identical(other.piecesCount, piecesCount) || other.piecesCount == piecesCount)&&(identical(other.expectedPieceCount, expectedPieceCount) || other.expectedPieceCount == expectedPieceCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userName,peopleCount,status,checkedInAt,checkedInCount,hasCelebration,piecesCount,expectedPieceCount);

@override
String toString() {
  return 'ScanBooking(id: $id, userName: $userName, peopleCount: $peopleCount, status: $status, checkedInAt: $checkedInAt, checkedInCount: $checkedInCount, hasCelebration: $hasCelebration, piecesCount: $piecesCount, expectedPieceCount: $expectedPieceCount)';
}


}

/// @nodoc
abstract mixin class $ScanBookingCopyWith<$Res>  {
  factory $ScanBookingCopyWith(ScanBooking value, $Res Function(ScanBooking) _then) = _$ScanBookingCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'user_name') String? userName,@JsonKey(name: 'people_count') int peopleCount, String status,@JsonKey(name: 'checked_in_at') DateTime? checkedInAt,@JsonKey(name: 'checked_in_count') int? checkedInCount,@JsonKey(name: 'has_celebration') bool hasCelebration,@JsonKey(name: 'pieces_count') int piecesCount,@JsonKey(name: 'expected_piece_count') int? expectedPieceCount
});




}
/// @nodoc
class _$ScanBookingCopyWithImpl<$Res>
    implements $ScanBookingCopyWith<$Res> {
  _$ScanBookingCopyWithImpl(this._self, this._then);

  final ScanBooking _self;
  final $Res Function(ScanBooking) _then;

/// Create a copy of ScanBooking
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userName = freezed,Object? peopleCount = null,Object? status = null,Object? checkedInAt = freezed,Object? checkedInCount = freezed,Object? hasCelebration = null,Object? piecesCount = null,Object? expectedPieceCount = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,peopleCount: null == peopleCount ? _self.peopleCount : peopleCount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,checkedInAt: freezed == checkedInAt ? _self.checkedInAt : checkedInAt // ignore: cast_nullable_to_non_nullable
as DateTime?,checkedInCount: freezed == checkedInCount ? _self.checkedInCount : checkedInCount // ignore: cast_nullable_to_non_nullable
as int?,hasCelebration: null == hasCelebration ? _self.hasCelebration : hasCelebration // ignore: cast_nullable_to_non_nullable
as bool,piecesCount: null == piecesCount ? _self.piecesCount : piecesCount // ignore: cast_nullable_to_non_nullable
as int,expectedPieceCount: freezed == expectedPieceCount ? _self.expectedPieceCount : expectedPieceCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanBooking].
extension ScanBookingPatterns on ScanBooking {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanBooking value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanBooking() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanBooking value)  $default,){
final _that = this;
switch (_that) {
case _ScanBooking():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanBooking value)?  $default,){
final _that = this;
switch (_that) {
case _ScanBooking() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'user_name')  String? userName, @JsonKey(name: 'people_count')  int peopleCount,  String status, @JsonKey(name: 'checked_in_at')  DateTime? checkedInAt, @JsonKey(name: 'checked_in_count')  int? checkedInCount, @JsonKey(name: 'has_celebration')  bool hasCelebration, @JsonKey(name: 'pieces_count')  int piecesCount, @JsonKey(name: 'expected_piece_count')  int? expectedPieceCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanBooking() when $default != null:
return $default(_that.id,_that.userName,_that.peopleCount,_that.status,_that.checkedInAt,_that.checkedInCount,_that.hasCelebration,_that.piecesCount,_that.expectedPieceCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'user_name')  String? userName, @JsonKey(name: 'people_count')  int peopleCount,  String status, @JsonKey(name: 'checked_in_at')  DateTime? checkedInAt, @JsonKey(name: 'checked_in_count')  int? checkedInCount, @JsonKey(name: 'has_celebration')  bool hasCelebration, @JsonKey(name: 'pieces_count')  int piecesCount, @JsonKey(name: 'expected_piece_count')  int? expectedPieceCount)  $default,) {final _that = this;
switch (_that) {
case _ScanBooking():
return $default(_that.id,_that.userName,_that.peopleCount,_that.status,_that.checkedInAt,_that.checkedInCount,_that.hasCelebration,_that.piecesCount,_that.expectedPieceCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'user_name')  String? userName, @JsonKey(name: 'people_count')  int peopleCount,  String status, @JsonKey(name: 'checked_in_at')  DateTime? checkedInAt, @JsonKey(name: 'checked_in_count')  int? checkedInCount, @JsonKey(name: 'has_celebration')  bool hasCelebration, @JsonKey(name: 'pieces_count')  int piecesCount, @JsonKey(name: 'expected_piece_count')  int? expectedPieceCount)?  $default,) {final _that = this;
switch (_that) {
case _ScanBooking() when $default != null:
return $default(_that.id,_that.userName,_that.peopleCount,_that.status,_that.checkedInAt,_that.checkedInCount,_that.hasCelebration,_that.piecesCount,_that.expectedPieceCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScanBooking extends ScanBooking {
  const _ScanBooking({required this.id, @JsonKey(name: 'user_name') this.userName, @JsonKey(name: 'people_count') this.peopleCount = 1, this.status = 'confirmed', @JsonKey(name: 'checked_in_at') this.checkedInAt, @JsonKey(name: 'checked_in_count') this.checkedInCount, @JsonKey(name: 'has_celebration') this.hasCelebration = false, @JsonKey(name: 'pieces_count') this.piecesCount = 0, @JsonKey(name: 'expected_piece_count') this.expectedPieceCount}): super._();
  factory _ScanBooking.fromJson(Map<String, dynamic> json) => _$ScanBookingFromJson(json);

@override final  int id;
@override@JsonKey(name: 'user_name') final  String? userName;
@override@JsonKey(name: 'people_count') final  int peopleCount;
@override@JsonKey() final  String status;
/// When the desk checked them in. Null until they arrive.
@override@JsonKey(name: 'checked_in_at') final  DateTime? checkedInAt;
/// How many of the party actually turned up — null until asked,
/// and never more than [peopleCount].
@override@JsonKey(name: 'checked_in_count') final  int? checkedInCount;
@override@JsonKey(name: 'has_celebration') final  bool hasCelebration;
/// How many pieces this booking has PHOTOGRAPHED so far.
@override@JsonKey(name: 'pieces_count') final  int piecesCount;
/// How many it is expected to end up with — one per person who
/// actually checked in for `make_your_piece`, and the quantity of
/// products bought for `paint_your_piece` / `make_your_candle`.
///
/// A GUIDE on the wheel and a CEILING in the other two: one person
/// can freely make three things, but a key past the number of
/// objects paid for answers 422.
@override@JsonKey(name: 'expected_piece_count') final  int? expectedPieceCount;

/// Create a copy of ScanBooking
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanBookingCopyWith<_ScanBooking> get copyWith => __$ScanBookingCopyWithImpl<_ScanBooking>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScanBookingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanBooking&&(identical(other.id, id) || other.id == id)&&(identical(other.userName, userName) || other.userName == userName)&&(identical(other.peopleCount, peopleCount) || other.peopleCount == peopleCount)&&(identical(other.status, status) || other.status == status)&&(identical(other.checkedInAt, checkedInAt) || other.checkedInAt == checkedInAt)&&(identical(other.checkedInCount, checkedInCount) || other.checkedInCount == checkedInCount)&&(identical(other.hasCelebration, hasCelebration) || other.hasCelebration == hasCelebration)&&(identical(other.piecesCount, piecesCount) || other.piecesCount == piecesCount)&&(identical(other.expectedPieceCount, expectedPieceCount) || other.expectedPieceCount == expectedPieceCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userName,peopleCount,status,checkedInAt,checkedInCount,hasCelebration,piecesCount,expectedPieceCount);

@override
String toString() {
  return 'ScanBooking(id: $id, userName: $userName, peopleCount: $peopleCount, status: $status, checkedInAt: $checkedInAt, checkedInCount: $checkedInCount, hasCelebration: $hasCelebration, piecesCount: $piecesCount, expectedPieceCount: $expectedPieceCount)';
}


}

/// @nodoc
abstract mixin class _$ScanBookingCopyWith<$Res> implements $ScanBookingCopyWith<$Res> {
  factory _$ScanBookingCopyWith(_ScanBooking value, $Res Function(_ScanBooking) _then) = __$ScanBookingCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'user_name') String? userName,@JsonKey(name: 'people_count') int peopleCount, String status,@JsonKey(name: 'checked_in_at') DateTime? checkedInAt,@JsonKey(name: 'checked_in_count') int? checkedInCount,@JsonKey(name: 'has_celebration') bool hasCelebration,@JsonKey(name: 'pieces_count') int piecesCount,@JsonKey(name: 'expected_piece_count') int? expectedPieceCount
});




}
/// @nodoc
class __$ScanBookingCopyWithImpl<$Res>
    implements _$ScanBookingCopyWith<$Res> {
  __$ScanBookingCopyWithImpl(this._self, this._then);

  final _ScanBooking _self;
  final $Res Function(_ScanBooking) _then;

/// Create a copy of ScanBooking
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userName = freezed,Object? peopleCount = null,Object? status = null,Object? checkedInAt = freezed,Object? checkedInCount = freezed,Object? hasCelebration = null,Object? piecesCount = null,Object? expectedPieceCount = freezed,}) {
  return _then(_ScanBooking(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userName: freezed == userName ? _self.userName : userName // ignore: cast_nullable_to_non_nullable
as String?,peopleCount: null == peopleCount ? _self.peopleCount : peopleCount // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,checkedInAt: freezed == checkedInAt ? _self.checkedInAt : checkedInAt // ignore: cast_nullable_to_non_nullable
as DateTime?,checkedInCount: freezed == checkedInCount ? _self.checkedInCount : checkedInCount // ignore: cast_nullable_to_non_nullable
as int?,hasCelebration: null == hasCelebration ? _self.hasCelebration : hasCelebration // ignore: cast_nullable_to_non_nullable
as bool,piecesCount: null == piecesCount ? _self.piecesCount : piecesCount // ignore: cast_nullable_to_non_nullable
as int,expectedPieceCount: freezed == expectedPieceCount ? _self.expectedPieceCount : expectedPieceCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ScanSession {

@JsonKey(name: 'workshop_id') int get workshopId;@JsonKey(name: 'workshop_slot_id') int get workshopSlotId;@JsonKey(name: 'workshop_title') String? get workshopTitle;/// Asia/Riyadh, printed as received — the studio's clock is the one
/// the session runs on.
@JsonKey(name: 'start_time') String? get startTime;@JsonKey(name: 'end_time') String? get endTime; int? get capacity;/// Heads booked onto it, which is not the same as bookings.
@JsonKey(name: 'total_people') int get totalPeople;/// **BOOKINGS checked in, not people.** The scanner API counts rows
/// here where the CMS counts heads — the two numbers differ the
/// moment a party of three arrives as two.
@JsonKey(name: 'checked_in_count') int get checkedInCount;/// Whether anyone is still holding a seat — `Start` finalises
/// attendance and marks everyone unscanned as absent.
@JsonKey(name: 'can_start') bool get canStart;/// Whether anyone is attending, so the session can be finished.
@JsonKey(name: 'can_finish') bool get canFinish;/// **False once the session has been finished.** Every check-in
/// against it then answers 422 — it makes no difference that the
/// customer is standing at the desk.
///
/// Defaults TRUE so a server that has not grown the field yet
/// behaves as it always did, rather than locking a working desk
/// out of its own scanner.
@JsonKey(name: 'can_check_in') bool get canCheckIn;/// When Finish ran. Null while the session is still open.
@JsonKey(name: 'session_finished_at') DateTime? get sessionFinishedAt; List<ScanBooking> get bookings;
/// Create a copy of ScanSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanSessionCopyWith<ScanSession> get copyWith => _$ScanSessionCopyWithImpl<ScanSession>(this as ScanSession, _$identity);

  /// Serializes this ScanSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanSession&&(identical(other.workshopId, workshopId) || other.workshopId == workshopId)&&(identical(other.workshopSlotId, workshopSlotId) || other.workshopSlotId == workshopSlotId)&&(identical(other.workshopTitle, workshopTitle) || other.workshopTitle == workshopTitle)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.totalPeople, totalPeople) || other.totalPeople == totalPeople)&&(identical(other.checkedInCount, checkedInCount) || other.checkedInCount == checkedInCount)&&(identical(other.canStart, canStart) || other.canStart == canStart)&&(identical(other.canFinish, canFinish) || other.canFinish == canFinish)&&(identical(other.canCheckIn, canCheckIn) || other.canCheckIn == canCheckIn)&&(identical(other.sessionFinishedAt, sessionFinishedAt) || other.sessionFinishedAt == sessionFinishedAt)&&const DeepCollectionEquality().equals(other.bookings, bookings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workshopId,workshopSlotId,workshopTitle,startTime,endTime,capacity,totalPeople,checkedInCount,canStart,canFinish,canCheckIn,sessionFinishedAt,const DeepCollectionEquality().hash(bookings));

@override
String toString() {
  return 'ScanSession(workshopId: $workshopId, workshopSlotId: $workshopSlotId, workshopTitle: $workshopTitle, startTime: $startTime, endTime: $endTime, capacity: $capacity, totalPeople: $totalPeople, checkedInCount: $checkedInCount, canStart: $canStart, canFinish: $canFinish, canCheckIn: $canCheckIn, sessionFinishedAt: $sessionFinishedAt, bookings: $bookings)';
}


}

/// @nodoc
abstract mixin class $ScanSessionCopyWith<$Res>  {
  factory $ScanSessionCopyWith(ScanSession value, $Res Function(ScanSession) _then) = _$ScanSessionCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'workshop_id') int workshopId,@JsonKey(name: 'workshop_slot_id') int workshopSlotId,@JsonKey(name: 'workshop_title') String? workshopTitle,@JsonKey(name: 'start_time') String? startTime,@JsonKey(name: 'end_time') String? endTime, int? capacity,@JsonKey(name: 'total_people') int totalPeople,@JsonKey(name: 'checked_in_count') int checkedInCount,@JsonKey(name: 'can_start') bool canStart,@JsonKey(name: 'can_finish') bool canFinish,@JsonKey(name: 'can_check_in') bool canCheckIn,@JsonKey(name: 'session_finished_at') DateTime? sessionFinishedAt, List<ScanBooking> bookings
});




}
/// @nodoc
class _$ScanSessionCopyWithImpl<$Res>
    implements $ScanSessionCopyWith<$Res> {
  _$ScanSessionCopyWithImpl(this._self, this._then);

  final ScanSession _self;
  final $Res Function(ScanSession) _then;

/// Create a copy of ScanSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? workshopId = null,Object? workshopSlotId = null,Object? workshopTitle = freezed,Object? startTime = freezed,Object? endTime = freezed,Object? capacity = freezed,Object? totalPeople = null,Object? checkedInCount = null,Object? canStart = null,Object? canFinish = null,Object? canCheckIn = null,Object? sessionFinishedAt = freezed,Object? bookings = null,}) {
  return _then(_self.copyWith(
workshopId: null == workshopId ? _self.workshopId : workshopId // ignore: cast_nullable_to_non_nullable
as int,workshopSlotId: null == workshopSlotId ? _self.workshopSlotId : workshopSlotId // ignore: cast_nullable_to_non_nullable
as int,workshopTitle: freezed == workshopTitle ? _self.workshopTitle : workshopTitle // ignore: cast_nullable_to_non_nullable
as String?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,totalPeople: null == totalPeople ? _self.totalPeople : totalPeople // ignore: cast_nullable_to_non_nullable
as int,checkedInCount: null == checkedInCount ? _self.checkedInCount : checkedInCount // ignore: cast_nullable_to_non_nullable
as int,canStart: null == canStart ? _self.canStart : canStart // ignore: cast_nullable_to_non_nullable
as bool,canFinish: null == canFinish ? _self.canFinish : canFinish // ignore: cast_nullable_to_non_nullable
as bool,canCheckIn: null == canCheckIn ? _self.canCheckIn : canCheckIn // ignore: cast_nullable_to_non_nullable
as bool,sessionFinishedAt: freezed == sessionFinishedAt ? _self.sessionFinishedAt : sessionFinishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,bookings: null == bookings ? _self.bookings : bookings // ignore: cast_nullable_to_non_nullable
as List<ScanBooking>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanSession].
extension ScanSessionPatterns on ScanSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanSession value)  $default,){
final _that = this;
switch (_that) {
case _ScanSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanSession value)?  $default,){
final _that = this;
switch (_that) {
case _ScanSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'workshop_id')  int workshopId, @JsonKey(name: 'workshop_slot_id')  int workshopSlotId, @JsonKey(name: 'workshop_title')  String? workshopTitle, @JsonKey(name: 'start_time')  String? startTime, @JsonKey(name: 'end_time')  String? endTime,  int? capacity, @JsonKey(name: 'total_people')  int totalPeople, @JsonKey(name: 'checked_in_count')  int checkedInCount, @JsonKey(name: 'can_start')  bool canStart, @JsonKey(name: 'can_finish')  bool canFinish, @JsonKey(name: 'can_check_in')  bool canCheckIn, @JsonKey(name: 'session_finished_at')  DateTime? sessionFinishedAt,  List<ScanBooking> bookings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanSession() when $default != null:
return $default(_that.workshopId,_that.workshopSlotId,_that.workshopTitle,_that.startTime,_that.endTime,_that.capacity,_that.totalPeople,_that.checkedInCount,_that.canStart,_that.canFinish,_that.canCheckIn,_that.sessionFinishedAt,_that.bookings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'workshop_id')  int workshopId, @JsonKey(name: 'workshop_slot_id')  int workshopSlotId, @JsonKey(name: 'workshop_title')  String? workshopTitle, @JsonKey(name: 'start_time')  String? startTime, @JsonKey(name: 'end_time')  String? endTime,  int? capacity, @JsonKey(name: 'total_people')  int totalPeople, @JsonKey(name: 'checked_in_count')  int checkedInCount, @JsonKey(name: 'can_start')  bool canStart, @JsonKey(name: 'can_finish')  bool canFinish, @JsonKey(name: 'can_check_in')  bool canCheckIn, @JsonKey(name: 'session_finished_at')  DateTime? sessionFinishedAt,  List<ScanBooking> bookings)  $default,) {final _that = this;
switch (_that) {
case _ScanSession():
return $default(_that.workshopId,_that.workshopSlotId,_that.workshopTitle,_that.startTime,_that.endTime,_that.capacity,_that.totalPeople,_that.checkedInCount,_that.canStart,_that.canFinish,_that.canCheckIn,_that.sessionFinishedAt,_that.bookings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'workshop_id')  int workshopId, @JsonKey(name: 'workshop_slot_id')  int workshopSlotId, @JsonKey(name: 'workshop_title')  String? workshopTitle, @JsonKey(name: 'start_time')  String? startTime, @JsonKey(name: 'end_time')  String? endTime,  int? capacity, @JsonKey(name: 'total_people')  int totalPeople, @JsonKey(name: 'checked_in_count')  int checkedInCount, @JsonKey(name: 'can_start')  bool canStart, @JsonKey(name: 'can_finish')  bool canFinish, @JsonKey(name: 'can_check_in')  bool canCheckIn, @JsonKey(name: 'session_finished_at')  DateTime? sessionFinishedAt,  List<ScanBooking> bookings)?  $default,) {final _that = this;
switch (_that) {
case _ScanSession() when $default != null:
return $default(_that.workshopId,_that.workshopSlotId,_that.workshopTitle,_that.startTime,_that.endTime,_that.capacity,_that.totalPeople,_that.checkedInCount,_that.canStart,_that.canFinish,_that.canCheckIn,_that.sessionFinishedAt,_that.bookings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScanSession extends ScanSession {
  const _ScanSession({@JsonKey(name: 'workshop_id') required this.workshopId, @JsonKey(name: 'workshop_slot_id') required this.workshopSlotId, @JsonKey(name: 'workshop_title') this.workshopTitle, @JsonKey(name: 'start_time') this.startTime, @JsonKey(name: 'end_time') this.endTime, this.capacity, @JsonKey(name: 'total_people') this.totalPeople = 0, @JsonKey(name: 'checked_in_count') this.checkedInCount = 0, @JsonKey(name: 'can_start') this.canStart = false, @JsonKey(name: 'can_finish') this.canFinish = false, @JsonKey(name: 'can_check_in') this.canCheckIn = true, @JsonKey(name: 'session_finished_at') this.sessionFinishedAt, final  List<ScanBooking> bookings = const <ScanBooking>[]}): _bookings = bookings,super._();
  factory _ScanSession.fromJson(Map<String, dynamic> json) => _$ScanSessionFromJson(json);

@override@JsonKey(name: 'workshop_id') final  int workshopId;
@override@JsonKey(name: 'workshop_slot_id') final  int workshopSlotId;
@override@JsonKey(name: 'workshop_title') final  String? workshopTitle;
/// Asia/Riyadh, printed as received — the studio's clock is the one
/// the session runs on.
@override@JsonKey(name: 'start_time') final  String? startTime;
@override@JsonKey(name: 'end_time') final  String? endTime;
@override final  int? capacity;
/// Heads booked onto it, which is not the same as bookings.
@override@JsonKey(name: 'total_people') final  int totalPeople;
/// **BOOKINGS checked in, not people.** The scanner API counts rows
/// here where the CMS counts heads — the two numbers differ the
/// moment a party of three arrives as two.
@override@JsonKey(name: 'checked_in_count') final  int checkedInCount;
/// Whether anyone is still holding a seat — `Start` finalises
/// attendance and marks everyone unscanned as absent.
@override@JsonKey(name: 'can_start') final  bool canStart;
/// Whether anyone is attending, so the session can be finished.
@override@JsonKey(name: 'can_finish') final  bool canFinish;
/// **False once the session has been finished.** Every check-in
/// against it then answers 422 — it makes no difference that the
/// customer is standing at the desk.
///
/// Defaults TRUE so a server that has not grown the field yet
/// behaves as it always did, rather than locking a working desk
/// out of its own scanner.
@override@JsonKey(name: 'can_check_in') final  bool canCheckIn;
/// When Finish ran. Null while the session is still open.
@override@JsonKey(name: 'session_finished_at') final  DateTime? sessionFinishedAt;
 final  List<ScanBooking> _bookings;
@override@JsonKey() List<ScanBooking> get bookings {
  if (_bookings is EqualUnmodifiableListView) return _bookings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bookings);
}


/// Create a copy of ScanSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanSessionCopyWith<_ScanSession> get copyWith => __$ScanSessionCopyWithImpl<_ScanSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScanSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanSession&&(identical(other.workshopId, workshopId) || other.workshopId == workshopId)&&(identical(other.workshopSlotId, workshopSlotId) || other.workshopSlotId == workshopSlotId)&&(identical(other.workshopTitle, workshopTitle) || other.workshopTitle == workshopTitle)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.capacity, capacity) || other.capacity == capacity)&&(identical(other.totalPeople, totalPeople) || other.totalPeople == totalPeople)&&(identical(other.checkedInCount, checkedInCount) || other.checkedInCount == checkedInCount)&&(identical(other.canStart, canStart) || other.canStart == canStart)&&(identical(other.canFinish, canFinish) || other.canFinish == canFinish)&&(identical(other.canCheckIn, canCheckIn) || other.canCheckIn == canCheckIn)&&(identical(other.sessionFinishedAt, sessionFinishedAt) || other.sessionFinishedAt == sessionFinishedAt)&&const DeepCollectionEquality().equals(other._bookings, _bookings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,workshopId,workshopSlotId,workshopTitle,startTime,endTime,capacity,totalPeople,checkedInCount,canStart,canFinish,canCheckIn,sessionFinishedAt,const DeepCollectionEquality().hash(_bookings));

@override
String toString() {
  return 'ScanSession(workshopId: $workshopId, workshopSlotId: $workshopSlotId, workshopTitle: $workshopTitle, startTime: $startTime, endTime: $endTime, capacity: $capacity, totalPeople: $totalPeople, checkedInCount: $checkedInCount, canStart: $canStart, canFinish: $canFinish, canCheckIn: $canCheckIn, sessionFinishedAt: $sessionFinishedAt, bookings: $bookings)';
}


}

/// @nodoc
abstract mixin class _$ScanSessionCopyWith<$Res> implements $ScanSessionCopyWith<$Res> {
  factory _$ScanSessionCopyWith(_ScanSession value, $Res Function(_ScanSession) _then) = __$ScanSessionCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'workshop_id') int workshopId,@JsonKey(name: 'workshop_slot_id') int workshopSlotId,@JsonKey(name: 'workshop_title') String? workshopTitle,@JsonKey(name: 'start_time') String? startTime,@JsonKey(name: 'end_time') String? endTime, int? capacity,@JsonKey(name: 'total_people') int totalPeople,@JsonKey(name: 'checked_in_count') int checkedInCount,@JsonKey(name: 'can_start') bool canStart,@JsonKey(name: 'can_finish') bool canFinish,@JsonKey(name: 'can_check_in') bool canCheckIn,@JsonKey(name: 'session_finished_at') DateTime? sessionFinishedAt, List<ScanBooking> bookings
});




}
/// @nodoc
class __$ScanSessionCopyWithImpl<$Res>
    implements _$ScanSessionCopyWith<$Res> {
  __$ScanSessionCopyWithImpl(this._self, this._then);

  final _ScanSession _self;
  final $Res Function(_ScanSession) _then;

/// Create a copy of ScanSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? workshopId = null,Object? workshopSlotId = null,Object? workshopTitle = freezed,Object? startTime = freezed,Object? endTime = freezed,Object? capacity = freezed,Object? totalPeople = null,Object? checkedInCount = null,Object? canStart = null,Object? canFinish = null,Object? canCheckIn = null,Object? sessionFinishedAt = freezed,Object? bookings = null,}) {
  return _then(_ScanSession(
workshopId: null == workshopId ? _self.workshopId : workshopId // ignore: cast_nullable_to_non_nullable
as int,workshopSlotId: null == workshopSlotId ? _self.workshopSlotId : workshopSlotId // ignore: cast_nullable_to_non_nullable
as int,workshopTitle: freezed == workshopTitle ? _self.workshopTitle : workshopTitle // ignore: cast_nullable_to_non_nullable
as String?,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String?,capacity: freezed == capacity ? _self.capacity : capacity // ignore: cast_nullable_to_non_nullable
as int?,totalPeople: null == totalPeople ? _self.totalPeople : totalPeople // ignore: cast_nullable_to_non_nullable
as int,checkedInCount: null == checkedInCount ? _self.checkedInCount : checkedInCount // ignore: cast_nullable_to_non_nullable
as int,canStart: null == canStart ? _self.canStart : canStart // ignore: cast_nullable_to_non_nullable
as bool,canFinish: null == canFinish ? _self.canFinish : canFinish // ignore: cast_nullable_to_non_nullable
as bool,canCheckIn: null == canCheckIn ? _self.canCheckIn : canCheckIn // ignore: cast_nullable_to_non_nullable
as bool,sessionFinishedAt: freezed == sessionFinishedAt ? _self.sessionFinishedAt : sessionFinishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,bookings: null == bookings ? _self._bookings : bookings // ignore: cast_nullable_to_non_nullable
as List<ScanBooking>,
  ));
}


}


/// @nodoc
mixin _$ScanDay {

/// `Y-m-d`, the day these sessions belong to.
 String? get date; List<ScanSession> get sessions;
/// Create a copy of ScanDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScanDayCopyWith<ScanDay> get copyWith => _$ScanDayCopyWithImpl<ScanDay>(this as ScanDay, _$identity);

  /// Serializes this ScanDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScanDay&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other.sessions, sessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(sessions));

@override
String toString() {
  return 'ScanDay(date: $date, sessions: $sessions)';
}


}

/// @nodoc
abstract mixin class $ScanDayCopyWith<$Res>  {
  factory $ScanDayCopyWith(ScanDay value, $Res Function(ScanDay) _then) = _$ScanDayCopyWithImpl;
@useResult
$Res call({
 String? date, List<ScanSession> sessions
});




}
/// @nodoc
class _$ScanDayCopyWithImpl<$Res>
    implements $ScanDayCopyWith<$Res> {
  _$ScanDayCopyWithImpl(this._self, this._then);

  final ScanDay _self;
  final $Res Function(ScanDay) _then;

/// Create a copy of ScanDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = freezed,Object? sessions = null,}) {
  return _then(_self.copyWith(
date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,sessions: null == sessions ? _self.sessions : sessions // ignore: cast_nullable_to_non_nullable
as List<ScanSession>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScanDay].
extension ScanDayPatterns on ScanDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScanDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScanDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScanDay value)  $default,){
final _that = this;
switch (_that) {
case _ScanDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScanDay value)?  $default,){
final _that = this;
switch (_that) {
case _ScanDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? date,  List<ScanSession> sessions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScanDay() when $default != null:
return $default(_that.date,_that.sessions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? date,  List<ScanSession> sessions)  $default,) {final _that = this;
switch (_that) {
case _ScanDay():
return $default(_that.date,_that.sessions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? date,  List<ScanSession> sessions)?  $default,) {final _that = this;
switch (_that) {
case _ScanDay() when $default != null:
return $default(_that.date,_that.sessions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScanDay implements ScanDay {
  const _ScanDay({this.date, final  List<ScanSession> sessions = const <ScanSession>[]}): _sessions = sessions;
  factory _ScanDay.fromJson(Map<String, dynamic> json) => _$ScanDayFromJson(json);

/// `Y-m-d`, the day these sessions belong to.
@override final  String? date;
 final  List<ScanSession> _sessions;
@override@JsonKey() List<ScanSession> get sessions {
  if (_sessions is EqualUnmodifiableListView) return _sessions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sessions);
}


/// Create a copy of ScanDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScanDayCopyWith<_ScanDay> get copyWith => __$ScanDayCopyWithImpl<_ScanDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScanDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScanDay&&(identical(other.date, date) || other.date == date)&&const DeepCollectionEquality().equals(other._sessions, _sessions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,const DeepCollectionEquality().hash(_sessions));

@override
String toString() {
  return 'ScanDay(date: $date, sessions: $sessions)';
}


}

/// @nodoc
abstract mixin class _$ScanDayCopyWith<$Res> implements $ScanDayCopyWith<$Res> {
  factory _$ScanDayCopyWith(_ScanDay value, $Res Function(_ScanDay) _then) = __$ScanDayCopyWithImpl;
@override @useResult
$Res call({
 String? date, List<ScanSession> sessions
});




}
/// @nodoc
class __$ScanDayCopyWithImpl<$Res>
    implements _$ScanDayCopyWith<$Res> {
  __$ScanDayCopyWithImpl(this._self, this._then);

  final _ScanDay _self;
  final $Res Function(_ScanDay) _then;

/// Create a copy of ScanDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = freezed,Object? sessions = null,}) {
  return _then(_ScanDay(
date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,sessions: null == sessions ? _self._sessions : sessions // ignore: cast_nullable_to_non_nullable
as List<ScanSession>,
  ));
}


}

// dart format on
