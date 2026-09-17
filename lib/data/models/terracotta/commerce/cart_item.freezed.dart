// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CartItem {

/// Cart LINE id — the `{item}` of `/api/shop/cart/{item}`.
 int get id;/// Catalogue snapshot of what is on this line.
 LineProduct get product;/// Chosen colour as a hex string (`"#c96f4a"`), null when the
/// customer picked none.
 String? get color;/// How many. The cart's own endpoints clamp this to stock.
 int get quantity;/// Price of ONE unit, frozen when the line was created. Decimal
/// string (`"35.00"`).
 String get unitPrice;/// [unitPrice] × [quantity] as computed by the server. Decimal
/// string — do not recompute it in Dart floats.
 String get lineTotal;/// Whether the PIECE is still sellable, as of this read. A cart
/// outlives the stock it was filled from.
 bool get inStock;/// How many are left for this line right now, or null when the
/// piece tracks no stock. `quantity > availableStock` is a line the
/// customer cannot check out with — the whole reason the server
/// sends it back on every cart read.
 int? get availableStock;
/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartItemCopyWith<CartItem> get copyWith => _$CartItemCopyWithImpl<CartItem>(this as CartItem, _$identity);

  /// Serializes this CartItem to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartItem&&(identical(other.id, id) || other.id == id)&&(identical(other.product, product) || other.product == product)&&(identical(other.color, color) || other.color == color)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.inStock, inStock) || other.inStock == inStock)&&(identical(other.availableStock, availableStock) || other.availableStock == availableStock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,product,color,quantity,unitPrice,lineTotal,inStock,availableStock);

@override
String toString() {
  return 'CartItem(id: $id, product: $product, color: $color, quantity: $quantity, unitPrice: $unitPrice, lineTotal: $lineTotal, inStock: $inStock, availableStock: $availableStock)';
}


}

/// @nodoc
abstract mixin class $CartItemCopyWith<$Res>  {
  factory $CartItemCopyWith(CartItem value, $Res Function(CartItem) _then) = _$CartItemCopyWithImpl;
@useResult
$Res call({
 int id, LineProduct product, String? color, int quantity, String unitPrice, String lineTotal, bool inStock, int? availableStock
});


$LineProductCopyWith<$Res> get product;

}
/// @nodoc
class _$CartItemCopyWithImpl<$Res>
    implements $CartItemCopyWith<$Res> {
  _$CartItemCopyWithImpl(this._self, this._then);

  final CartItem _self;
  final $Res Function(CartItem) _then;

/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? product = null,Object? color = freezed,Object? quantity = null,Object? unitPrice = null,Object? lineTotal = null,Object? inStock = null,Object? availableStock = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,product: null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as LineProduct,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as String,inStock: null == inStock ? _self.inStock : inStock // ignore: cast_nullable_to_non_nullable
as bool,availableStock: freezed == availableStock ? _self.availableStock : availableStock // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}
/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LineProductCopyWith<$Res> get product {
  
  return $LineProductCopyWith<$Res>(_self.product, (value) {
    return _then(_self.copyWith(product: value));
  });
}
}


/// Adds pattern-matching-related methods to [CartItem].
extension CartItemPatterns on CartItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartItem value)  $default,){
final _that = this;
switch (_that) {
case _CartItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartItem value)?  $default,){
final _that = this;
switch (_that) {
case _CartItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  LineProduct product,  String? color,  int quantity,  String unitPrice,  String lineTotal,  bool inStock,  int? availableStock)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartItem() when $default != null:
return $default(_that.id,_that.product,_that.color,_that.quantity,_that.unitPrice,_that.lineTotal,_that.inStock,_that.availableStock);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  LineProduct product,  String? color,  int quantity,  String unitPrice,  String lineTotal,  bool inStock,  int? availableStock)  $default,) {final _that = this;
switch (_that) {
case _CartItem():
return $default(_that.id,_that.product,_that.color,_that.quantity,_that.unitPrice,_that.lineTotal,_that.inStock,_that.availableStock);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  LineProduct product,  String? color,  int quantity,  String unitPrice,  String lineTotal,  bool inStock,  int? availableStock)?  $default,) {final _that = this;
switch (_that) {
case _CartItem() when $default != null:
return $default(_that.id,_that.product,_that.color,_that.quantity,_that.unitPrice,_that.lineTotal,_that.inStock,_that.availableStock);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CartItem implements CartItem {
  const _CartItem({required this.id, required this.product, this.color, required this.quantity, required this.unitPrice, required this.lineTotal, this.inStock = true, this.availableStock});
  factory _CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);

/// Cart LINE id — the `{item}` of `/api/shop/cart/{item}`.
@override final  int id;
/// Catalogue snapshot of what is on this line.
@override final  LineProduct product;
/// Chosen colour as a hex string (`"#c96f4a"`), null when the
/// customer picked none.
@override final  String? color;
/// How many. The cart's own endpoints clamp this to stock.
@override final  int quantity;
/// Price of ONE unit, frozen when the line was created. Decimal
/// string (`"35.00"`).
@override final  String unitPrice;
/// [unitPrice] × [quantity] as computed by the server. Decimal
/// string — do not recompute it in Dart floats.
@override final  String lineTotal;
/// Whether the PIECE is still sellable, as of this read. A cart
/// outlives the stock it was filled from.
@override@JsonKey() final  bool inStock;
/// How many are left for this line right now, or null when the
/// piece tracks no stock. `quantity > availableStock` is a line the
/// customer cannot check out with — the whole reason the server
/// sends it back on every cart read.
@override final  int? availableStock;

/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartItemCopyWith<_CartItem> get copyWith => __$CartItemCopyWithImpl<_CartItem>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CartItemToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartItem&&(identical(other.id, id) || other.id == id)&&(identical(other.product, product) || other.product == product)&&(identical(other.color, color) || other.color == color)&&(identical(other.quantity, quantity) || other.quantity == quantity)&&(identical(other.unitPrice, unitPrice) || other.unitPrice == unitPrice)&&(identical(other.lineTotal, lineTotal) || other.lineTotal == lineTotal)&&(identical(other.inStock, inStock) || other.inStock == inStock)&&(identical(other.availableStock, availableStock) || other.availableStock == availableStock));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,product,color,quantity,unitPrice,lineTotal,inStock,availableStock);

@override
String toString() {
  return 'CartItem(id: $id, product: $product, color: $color, quantity: $quantity, unitPrice: $unitPrice, lineTotal: $lineTotal, inStock: $inStock, availableStock: $availableStock)';
}


}

/// @nodoc
abstract mixin class _$CartItemCopyWith<$Res> implements $CartItemCopyWith<$Res> {
  factory _$CartItemCopyWith(_CartItem value, $Res Function(_CartItem) _then) = __$CartItemCopyWithImpl;
@override @useResult
$Res call({
 int id, LineProduct product, String? color, int quantity, String unitPrice, String lineTotal, bool inStock, int? availableStock
});


@override $LineProductCopyWith<$Res> get product;

}
/// @nodoc
class __$CartItemCopyWithImpl<$Res>
    implements _$CartItemCopyWith<$Res> {
  __$CartItemCopyWithImpl(this._self, this._then);

  final _CartItem _self;
  final $Res Function(_CartItem) _then;

/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? product = null,Object? color = freezed,Object? quantity = null,Object? unitPrice = null,Object? lineTotal = null,Object? inStock = null,Object? availableStock = freezed,}) {
  return _then(_CartItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,product: null == product ? _self.product : product // ignore: cast_nullable_to_non_nullable
as LineProduct,color: freezed == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,unitPrice: null == unitPrice ? _self.unitPrice : unitPrice // ignore: cast_nullable_to_non_nullable
as String,lineTotal: null == lineTotal ? _self.lineTotal : lineTotal // ignore: cast_nullable_to_non_nullable
as String,inStock: null == inStock ? _self.inStock : inStock // ignore: cast_nullable_to_non_nullable
as bool,availableStock: freezed == availableStock ? _self.availableStock : availableStock // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

/// Create a copy of CartItem
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LineProductCopyWith<$Res> get product {
  
  return $LineProductCopyWith<$Res>(_self.product, (value) {
    return _then(_self.copyWith(product: value));
  });
}
}

// dart format on
