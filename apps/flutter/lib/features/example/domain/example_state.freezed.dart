// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'example_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExampleState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExampleState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExampleState()';
}


}

/// @nodoc
class $ExampleStateCopyWith<$Res>  {
$ExampleStateCopyWith(ExampleState _, $Res Function(ExampleState) __);
}


/// Adds pattern-matching-related methods to [ExampleState].
extension ExampleStatePatterns on ExampleState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ExampleStateInitial value)?  initial,TResult Function( ExampleStateLoaded value)?  loaded,TResult Function( ExampleStateError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ExampleStateInitial() when initial != null:
return initial(_that);case ExampleStateLoaded() when loaded != null:
return loaded(_that);case ExampleStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ExampleStateInitial value)  initial,required TResult Function( ExampleStateLoaded value)  loaded,required TResult Function( ExampleStateError value)  error,}){
final _that = this;
switch (_that) {
case ExampleStateInitial():
return initial(_that);case ExampleStateLoaded():
return loaded(_that);case ExampleStateError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ExampleStateInitial value)?  initial,TResult? Function( ExampleStateLoaded value)?  loaded,TResult? Function( ExampleStateError value)?  error,}){
final _that = this;
switch (_that) {
case ExampleStateInitial() when initial != null:
return initial(_that);case ExampleStateLoaded() when loaded != null:
return loaded(_that);case ExampleStateError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  initial,TResult Function( List<Example> examples)?  loaded,TResult Function( String message)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ExampleStateInitial() when initial != null:
return initial();case ExampleStateLoaded() when loaded != null:
return loaded(_that.examples);case ExampleStateError() when error != null:
return error(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  initial,required TResult Function( List<Example> examples)  loaded,required TResult Function( String message)  error,}) {final _that = this;
switch (_that) {
case ExampleStateInitial():
return initial();case ExampleStateLoaded():
return loaded(_that.examples);case ExampleStateError():
return error(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  initial,TResult? Function( List<Example> examples)?  loaded,TResult? Function( String message)?  error,}) {final _that = this;
switch (_that) {
case ExampleStateInitial() when initial != null:
return initial();case ExampleStateLoaded() when loaded != null:
return loaded(_that.examples);case ExampleStateError() when error != null:
return error(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class ExampleStateInitial implements ExampleState {
  const ExampleStateInitial();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExampleStateInitial);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ExampleState.initial()';
}


}




/// @nodoc


class ExampleStateLoaded implements ExampleState {
  const ExampleStateLoaded({required final  List<Example> examples}): _examples = examples;
  

 final  List<Example> _examples;
 List<Example> get examples {
  if (_examples is EqualUnmodifiableListView) return _examples;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_examples);
}


/// Create a copy of ExampleState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExampleStateLoadedCopyWith<ExampleStateLoaded> get copyWith => _$ExampleStateLoadedCopyWithImpl<ExampleStateLoaded>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExampleStateLoaded&&const DeepCollectionEquality().equals(other._examples, _examples));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_examples));

@override
String toString() {
  return 'ExampleState.loaded(examples: $examples)';
}


}

/// @nodoc
abstract mixin class $ExampleStateLoadedCopyWith<$Res> implements $ExampleStateCopyWith<$Res> {
  factory $ExampleStateLoadedCopyWith(ExampleStateLoaded value, $Res Function(ExampleStateLoaded) _then) = _$ExampleStateLoadedCopyWithImpl;
@useResult
$Res call({
 List<Example> examples
});




}
/// @nodoc
class _$ExampleStateLoadedCopyWithImpl<$Res>
    implements $ExampleStateLoadedCopyWith<$Res> {
  _$ExampleStateLoadedCopyWithImpl(this._self, this._then);

  final ExampleStateLoaded _self;
  final $Res Function(ExampleStateLoaded) _then;

/// Create a copy of ExampleState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? examples = null,}) {
  return _then(ExampleStateLoaded(
examples: null == examples ? _self._examples : examples // ignore: cast_nullable_to_non_nullable
as List<Example>,
  ));
}


}

/// @nodoc


class ExampleStateError implements ExampleState {
  const ExampleStateError({required this.message});
  

 final  String message;

/// Create a copy of ExampleState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExampleStateErrorCopyWith<ExampleStateError> get copyWith => _$ExampleStateErrorCopyWithImpl<ExampleStateError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExampleStateError&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'ExampleState.error(message: $message)';
}


}

/// @nodoc
abstract mixin class $ExampleStateErrorCopyWith<$Res> implements $ExampleStateCopyWith<$Res> {
  factory $ExampleStateErrorCopyWith(ExampleStateError value, $Res Function(ExampleStateError) _then) = _$ExampleStateErrorCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$ExampleStateErrorCopyWithImpl<$Res>
    implements $ExampleStateErrorCopyWith<$Res> {
  _$ExampleStateErrorCopyWithImpl(this._self, this._then);

  final ExampleStateError _self;
  final $Res Function(ExampleStateError) _then;

/// Create a copy of ExampleState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(ExampleStateError(
message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
