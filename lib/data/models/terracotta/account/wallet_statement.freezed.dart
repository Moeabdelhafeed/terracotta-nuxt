// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_statement.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WalletStatement {

/// Decimal string, e.g. `"150.00"`.
 String? get balance;@JsonKey(fromJson: _readTransactions) List<WalletTransaction> get transactions;
/// Create a copy of WalletStatement
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletStatementCopyWith<WalletStatement> get copyWith => _$WalletStatementCopyWithImpl<WalletStatement>(this as WalletStatement, _$identity);

  /// Serializes this WalletStatement to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletStatement&&(identical(other.balance, balance) || other.balance == balance)&&const DeepCollectionEquality().equals(other.transactions, transactions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,balance,const DeepCollectionEquality().hash(transactions));

@override
String toString() {
  return 'WalletStatement(balance: $balance, transactions: $transactions)';
}


}

/// @nodoc
abstract mixin class $WalletStatementCopyWith<$Res>  {
  factory $WalletStatementCopyWith(WalletStatement value, $Res Function(WalletStatement) _then) = _$WalletStatementCopyWithImpl;
@useResult
$Res call({
 String? balance,@JsonKey(fromJson: _readTransactions) List<WalletTransaction> transactions
});




}
/// @nodoc
class _$WalletStatementCopyWithImpl<$Res>
    implements $WalletStatementCopyWith<$Res> {
  _$WalletStatementCopyWithImpl(this._self, this._then);

  final WalletStatement _self;
  final $Res Function(WalletStatement) _then;

/// Create a copy of WalletStatement
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? balance = freezed,Object? transactions = null,}) {
  return _then(_self.copyWith(
balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as String?,transactions: null == transactions ? _self.transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<WalletTransaction>,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletStatement].
extension WalletStatementPatterns on WalletStatement {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletStatement value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletStatement() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletStatement value)  $default,){
final _that = this;
switch (_that) {
case _WalletStatement():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletStatement value)?  $default,){
final _that = this;
switch (_that) {
case _WalletStatement() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? balance, @JsonKey(fromJson: _readTransactions)  List<WalletTransaction> transactions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletStatement() when $default != null:
return $default(_that.balance,_that.transactions);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? balance, @JsonKey(fromJson: _readTransactions)  List<WalletTransaction> transactions)  $default,) {final _that = this;
switch (_that) {
case _WalletStatement():
return $default(_that.balance,_that.transactions);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? balance, @JsonKey(fromJson: _readTransactions)  List<WalletTransaction> transactions)?  $default,) {final _that = this;
switch (_that) {
case _WalletStatement() when $default != null:
return $default(_that.balance,_that.transactions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WalletStatement extends WalletStatement {
  const _WalletStatement({this.balance, @JsonKey(fromJson: _readTransactions) final  List<WalletTransaction> transactions = const <WalletTransaction>[]}): _transactions = transactions,super._();
  factory _WalletStatement.fromJson(Map<String, dynamic> json) => _$WalletStatementFromJson(json);

/// Decimal string, e.g. `"150.00"`.
@override final  String? balance;
 final  List<WalletTransaction> _transactions;
@override@JsonKey(fromJson: _readTransactions) List<WalletTransaction> get transactions {
  if (_transactions is EqualUnmodifiableListView) return _transactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transactions);
}


/// Create a copy of WalletStatement
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletStatementCopyWith<_WalletStatement> get copyWith => __$WalletStatementCopyWithImpl<_WalletStatement>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WalletStatementToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletStatement&&(identical(other.balance, balance) || other.balance == balance)&&const DeepCollectionEquality().equals(other._transactions, _transactions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,balance,const DeepCollectionEquality().hash(_transactions));

@override
String toString() {
  return 'WalletStatement(balance: $balance, transactions: $transactions)';
}


}

/// @nodoc
abstract mixin class _$WalletStatementCopyWith<$Res> implements $WalletStatementCopyWith<$Res> {
  factory _$WalletStatementCopyWith(_WalletStatement value, $Res Function(_WalletStatement) _then) = __$WalletStatementCopyWithImpl;
@override @useResult
$Res call({
 String? balance,@JsonKey(fromJson: _readTransactions) List<WalletTransaction> transactions
});




}
/// @nodoc
class __$WalletStatementCopyWithImpl<$Res>
    implements _$WalletStatementCopyWith<$Res> {
  __$WalletStatementCopyWithImpl(this._self, this._then);

  final _WalletStatement _self;
  final $Res Function(_WalletStatement) _then;

/// Create a copy of WalletStatement
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? balance = freezed,Object? transactions = null,}) {
  return _then(_WalletStatement(
balance: freezed == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as String?,transactions: null == transactions ? _self._transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<WalletTransaction>,
  ));
}


}

// dart format on
