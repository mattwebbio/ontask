// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'charity_selection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CharitySelection {

 String? get charityId; String? get charityName;
/// Create a copy of CharitySelection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharitySelectionCopyWith<CharitySelection> get copyWith => _$CharitySelectionCopyWithImpl<CharitySelection>(this as CharitySelection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharitySelection&&(identical(other.charityId, charityId) || other.charityId == charityId)&&(identical(other.charityName, charityName) || other.charityName == charityName));
}


@override
int get hashCode => Object.hash(runtimeType,charityId,charityName);

@override
String toString() {
  return 'CharitySelection(charityId: $charityId, charityName: $charityName)';
}


}

/// @nodoc
abstract mixin class $CharitySelectionCopyWith<$Res>  {
  factory $CharitySelectionCopyWith(CharitySelection value, $Res Function(CharitySelection) _then) = _$CharitySelectionCopyWithImpl;
@useResult
$Res call({
 String? charityId, String? charityName
});




}
/// @nodoc
class _$CharitySelectionCopyWithImpl<$Res>
    implements $CharitySelectionCopyWith<$Res> {
  _$CharitySelectionCopyWithImpl(this._self, this._then);

  final CharitySelection _self;
  final $Res Function(CharitySelection) _then;

/// Create a copy of CharitySelection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? charityId = freezed,Object? charityName = freezed,}) {
  return _then(_self.copyWith(
charityId: freezed == charityId ? _self.charityId : charityId // ignore: cast_nullable_to_non_nullable
as String?,charityName: freezed == charityName ? _self.charityName : charityName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CharitySelection].
extension CharitySelectionPatterns on CharitySelection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharitySelection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharitySelection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharitySelection value)  $default,){
final _that = this;
switch (_that) {
case _CharitySelection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharitySelection value)?  $default,){
final _that = this;
switch (_that) {
case _CharitySelection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? charityId,  String? charityName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharitySelection() when $default != null:
return $default(_that.charityId,_that.charityName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? charityId,  String? charityName)  $default,) {final _that = this;
switch (_that) {
case _CharitySelection():
return $default(_that.charityId,_that.charityName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? charityId,  String? charityName)?  $default,) {final _that = this;
switch (_that) {
case _CharitySelection() when $default != null:
return $default(_that.charityId,_that.charityName);case _:
  return null;

}
}

}

/// @nodoc


class _CharitySelection implements CharitySelection {
  const _CharitySelection({this.charityId, this.charityName});
  

@override final  String? charityId;
@override final  String? charityName;

/// Create a copy of CharitySelection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharitySelectionCopyWith<_CharitySelection> get copyWith => __$CharitySelectionCopyWithImpl<_CharitySelection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharitySelection&&(identical(other.charityId, charityId) || other.charityId == charityId)&&(identical(other.charityName, charityName) || other.charityName == charityName));
}


@override
int get hashCode => Object.hash(runtimeType,charityId,charityName);

@override
String toString() {
  return 'CharitySelection(charityId: $charityId, charityName: $charityName)';
}


}

/// @nodoc
abstract mixin class _$CharitySelectionCopyWith<$Res> implements $CharitySelectionCopyWith<$Res> {
  factory _$CharitySelectionCopyWith(_CharitySelection value, $Res Function(_CharitySelection) _then) = __$CharitySelectionCopyWithImpl;
@override @useResult
$Res call({
 String? charityId, String? charityName
});




}
/// @nodoc
class __$CharitySelectionCopyWithImpl<$Res>
    implements _$CharitySelectionCopyWith<$Res> {
  __$CharitySelectionCopyWithImpl(this._self, this._then);

  final _CharitySelection _self;
  final $Res Function(_CharitySelection) _then;

/// Create a copy of CharitySelection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? charityId = freezed,Object? charityName = freezed,}) {
  return _then(_CharitySelection(
charityId: freezed == charityId ? _self.charityId : charityId // ignore: cast_nullable_to_non_nullable
as String?,charityName: freezed == charityName ? _self.charityName : charityName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
