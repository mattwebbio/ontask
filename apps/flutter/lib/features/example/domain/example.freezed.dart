// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'example.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Example {

 String get id; String get title; bool get isCompleted;
/// Create a copy of Example
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExampleCopyWith<Example> get copyWith => _$ExampleCopyWithImpl<Example>(this as Example, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Example&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,isCompleted);

@override
String toString() {
  return 'Example(id: $id, title: $title, isCompleted: $isCompleted)';
}


}

/// @nodoc
abstract mixin class $ExampleCopyWith<$Res>  {
  factory $ExampleCopyWith(Example value, $Res Function(Example) _then) = _$ExampleCopyWithImpl;
@useResult
$Res call({
 String id, String title, bool isCompleted
});




}
/// @nodoc
class _$ExampleCopyWithImpl<$Res>
    implements $ExampleCopyWith<$Res> {
  _$ExampleCopyWithImpl(this._self, this._then);

  final Example _self;
  final $Res Function(Example) _then;

/// Create a copy of Example
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? isCompleted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Example].
extension ExamplePatterns on Example {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Example value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Example() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Example value)  $default,){
final _that = this;
switch (_that) {
case _Example():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Example value)?  $default,){
final _that = this;
switch (_that) {
case _Example() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  bool isCompleted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Example() when $default != null:
return $default(_that.id,_that.title,_that.isCompleted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  bool isCompleted)  $default,) {final _that = this;
switch (_that) {
case _Example():
return $default(_that.id,_that.title,_that.isCompleted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  bool isCompleted)?  $default,) {final _that = this;
switch (_that) {
case _Example() when $default != null:
return $default(_that.id,_that.title,_that.isCompleted);case _:
  return null;

}
}

}

/// @nodoc


class _Example implements Example {
  const _Example({required this.id, required this.title, this.isCompleted = false});
  

@override final  String id;
@override final  String title;
@override@JsonKey() final  bool isCompleted;

/// Create a copy of Example
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExampleCopyWith<_Example> get copyWith => __$ExampleCopyWithImpl<_Example>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Example&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,isCompleted);

@override
String toString() {
  return 'Example(id: $id, title: $title, isCompleted: $isCompleted)';
}


}

/// @nodoc
abstract mixin class _$ExampleCopyWith<$Res> implements $ExampleCopyWith<$Res> {
  factory _$ExampleCopyWith(_Example value, $Res Function(_Example) _then) = __$ExampleCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, bool isCompleted
});




}
/// @nodoc
class __$ExampleCopyWithImpl<$Res>
    implements _$ExampleCopyWith<$Res> {
  __$ExampleCopyWithImpl(this._self, this._then);

  final _Example _self;
  final $Res Function(_Example) _then;

/// Create a copy of Example
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? isCompleted = null,}) {
  return _then(_Example(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
