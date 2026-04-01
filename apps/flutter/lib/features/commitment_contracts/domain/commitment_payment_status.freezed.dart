// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'commitment_payment_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CommitmentPaymentStatus {

 bool get hasPaymentMethod; String? get last4; String? get brand; bool get hasActiveStakes;
/// Create a copy of CommitmentPaymentStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CommitmentPaymentStatusCopyWith<CommitmentPaymentStatus> get copyWith => _$CommitmentPaymentStatusCopyWithImpl<CommitmentPaymentStatus>(this as CommitmentPaymentStatus, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CommitmentPaymentStatus&&(identical(other.hasPaymentMethod, hasPaymentMethod) || other.hasPaymentMethod == hasPaymentMethod)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.hasActiveStakes, hasActiveStakes) || other.hasActiveStakes == hasActiveStakes));
}


@override
int get hashCode => Object.hash(runtimeType,hasPaymentMethod,last4,brand,hasActiveStakes);

@override
String toString() {
  return 'CommitmentPaymentStatus(hasPaymentMethod: $hasPaymentMethod, last4: $last4, brand: $brand, hasActiveStakes: $hasActiveStakes)';
}


}

/// @nodoc
abstract mixin class $CommitmentPaymentStatusCopyWith<$Res>  {
  factory $CommitmentPaymentStatusCopyWith(CommitmentPaymentStatus value, $Res Function(CommitmentPaymentStatus) _then) = _$CommitmentPaymentStatusCopyWithImpl;
@useResult
$Res call({
 bool hasPaymentMethod, String? last4, String? brand, bool hasActiveStakes
});




}
/// @nodoc
class _$CommitmentPaymentStatusCopyWithImpl<$Res>
    implements $CommitmentPaymentStatusCopyWith<$Res> {
  _$CommitmentPaymentStatusCopyWithImpl(this._self, this._then);

  final CommitmentPaymentStatus _self;
  final $Res Function(CommitmentPaymentStatus) _then;

/// Create a copy of CommitmentPaymentStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hasPaymentMethod = null,Object? last4 = freezed,Object? brand = freezed,Object? hasActiveStakes = null,}) {
  return _then(_self.copyWith(
hasPaymentMethod: null == hasPaymentMethod ? _self.hasPaymentMethod : hasPaymentMethod // ignore: cast_nullable_to_non_nullable
as bool,last4: freezed == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String?,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,hasActiveStakes: null == hasActiveStakes ? _self.hasActiveStakes : hasActiveStakes // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [CommitmentPaymentStatus].
extension CommitmentPaymentStatusPatterns on CommitmentPaymentStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CommitmentPaymentStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CommitmentPaymentStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CommitmentPaymentStatus value)  $default,){
final _that = this;
switch (_that) {
case _CommitmentPaymentStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CommitmentPaymentStatus value)?  $default,){
final _that = this;
switch (_that) {
case _CommitmentPaymentStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool hasPaymentMethod,  String? last4,  String? brand,  bool hasActiveStakes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CommitmentPaymentStatus() when $default != null:
return $default(_that.hasPaymentMethod,_that.last4,_that.brand,_that.hasActiveStakes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool hasPaymentMethod,  String? last4,  String? brand,  bool hasActiveStakes)  $default,) {final _that = this;
switch (_that) {
case _CommitmentPaymentStatus():
return $default(_that.hasPaymentMethod,_that.last4,_that.brand,_that.hasActiveStakes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool hasPaymentMethod,  String? last4,  String? brand,  bool hasActiveStakes)?  $default,) {final _that = this;
switch (_that) {
case _CommitmentPaymentStatus() when $default != null:
return $default(_that.hasPaymentMethod,_that.last4,_that.brand,_that.hasActiveStakes);case _:
  return null;

}
}

}

/// @nodoc


class _CommitmentPaymentStatus implements CommitmentPaymentStatus {
  const _CommitmentPaymentStatus({required this.hasPaymentMethod, this.last4, this.brand, required this.hasActiveStakes});
  

@override final  bool hasPaymentMethod;
@override final  String? last4;
@override final  String? brand;
@override final  bool hasActiveStakes;

/// Create a copy of CommitmentPaymentStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CommitmentPaymentStatusCopyWith<_CommitmentPaymentStatus> get copyWith => __$CommitmentPaymentStatusCopyWithImpl<_CommitmentPaymentStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CommitmentPaymentStatus&&(identical(other.hasPaymentMethod, hasPaymentMethod) || other.hasPaymentMethod == hasPaymentMethod)&&(identical(other.last4, last4) || other.last4 == last4)&&(identical(other.brand, brand) || other.brand == brand)&&(identical(other.hasActiveStakes, hasActiveStakes) || other.hasActiveStakes == hasActiveStakes));
}


@override
int get hashCode => Object.hash(runtimeType,hasPaymentMethod,last4,brand,hasActiveStakes);

@override
String toString() {
  return 'CommitmentPaymentStatus(hasPaymentMethod: $hasPaymentMethod, last4: $last4, brand: $brand, hasActiveStakes: $hasActiveStakes)';
}


}

/// @nodoc
abstract mixin class _$CommitmentPaymentStatusCopyWith<$Res> implements $CommitmentPaymentStatusCopyWith<$Res> {
  factory _$CommitmentPaymentStatusCopyWith(_CommitmentPaymentStatus value, $Res Function(_CommitmentPaymentStatus) _then) = __$CommitmentPaymentStatusCopyWithImpl;
@override @useResult
$Res call({
 bool hasPaymentMethod, String? last4, String? brand, bool hasActiveStakes
});




}
/// @nodoc
class __$CommitmentPaymentStatusCopyWithImpl<$Res>
    implements _$CommitmentPaymentStatusCopyWith<$Res> {
  __$CommitmentPaymentStatusCopyWithImpl(this._self, this._then);

  final _CommitmentPaymentStatus _self;
  final $Res Function(_CommitmentPaymentStatus) _then;

/// Create a copy of CommitmentPaymentStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hasPaymentMethod = null,Object? last4 = freezed,Object? brand = freezed,Object? hasActiveStakes = null,}) {
  return _then(_CommitmentPaymentStatus(
hasPaymentMethod: null == hasPaymentMethod ? _self.hasPaymentMethod : hasPaymentMethod // ignore: cast_nullable_to_non_nullable
as bool,last4: freezed == last4 ? _self.last4 : last4 // ignore: cast_nullable_to_non_nullable
as String?,brand: freezed == brand ? _self.brand : brand // ignore: cast_nullable_to_non_nullable
as String?,hasActiveStakes: null == hasActiveStakes ? _self.hasActiveStakes : hasActiveStakes // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
