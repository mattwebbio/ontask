// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_explanation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScheduleExplanation {

 List<String> get reasons;
/// Create a copy of ScheduleExplanation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleExplanationCopyWith<ScheduleExplanation> get copyWith => _$ScheduleExplanationCopyWithImpl<ScheduleExplanation>(this as ScheduleExplanation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduleExplanation&&const DeepCollectionEquality().equals(other.reasons, reasons));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(reasons));

@override
String toString() {
  return 'ScheduleExplanation(reasons: $reasons)';
}


}

/// @nodoc
abstract mixin class $ScheduleExplanationCopyWith<$Res>  {
  factory $ScheduleExplanationCopyWith(ScheduleExplanation value, $Res Function(ScheduleExplanation) _then) = _$ScheduleExplanationCopyWithImpl;
@useResult
$Res call({
 List<String> reasons
});




}
/// @nodoc
class _$ScheduleExplanationCopyWithImpl<$Res>
    implements $ScheduleExplanationCopyWith<$Res> {
  _$ScheduleExplanationCopyWithImpl(this._self, this._then);

  final ScheduleExplanation _self;
  final $Res Function(ScheduleExplanation) _then;

/// Create a copy of ScheduleExplanation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reasons = null,}) {
  return _then(_self.copyWith(
reasons: null == reasons ? _self.reasons : reasons // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduleExplanation].
extension ScheduleExplanationPatterns on ScheduleExplanation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduleExplanation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduleExplanation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduleExplanation value)  $default,){
final _that = this;
switch (_that) {
case _ScheduleExplanation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduleExplanation value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduleExplanation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> reasons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduleExplanation() when $default != null:
return $default(_that.reasons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> reasons)  $default,) {final _that = this;
switch (_that) {
case _ScheduleExplanation():
return $default(_that.reasons);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> reasons)?  $default,) {final _that = this;
switch (_that) {
case _ScheduleExplanation() when $default != null:
return $default(_that.reasons);case _:
  return null;

}
}

}

/// @nodoc


class _ScheduleExplanation implements ScheduleExplanation {
  const _ScheduleExplanation({required final  List<String> reasons}): _reasons = reasons;
  

 final  List<String> _reasons;
@override List<String> get reasons {
  if (_reasons is EqualUnmodifiableListView) return _reasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reasons);
}


/// Create a copy of ScheduleExplanation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduleExplanationCopyWith<_ScheduleExplanation> get copyWith => __$ScheduleExplanationCopyWithImpl<_ScheduleExplanation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduleExplanation&&const DeepCollectionEquality().equals(other._reasons, _reasons));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_reasons));

@override
String toString() {
  return 'ScheduleExplanation(reasons: $reasons)';
}


}

/// @nodoc
abstract mixin class _$ScheduleExplanationCopyWith<$Res> implements $ScheduleExplanationCopyWith<$Res> {
  factory _$ScheduleExplanationCopyWith(_ScheduleExplanation value, $Res Function(_ScheduleExplanation) _then) = __$ScheduleExplanationCopyWithImpl;
@override @useResult
$Res call({
 List<String> reasons
});




}
/// @nodoc
class __$ScheduleExplanationCopyWithImpl<$Res>
    implements _$ScheduleExplanationCopyWith<$Res> {
  __$ScheduleExplanationCopyWithImpl(this._self, this._then);

  final _ScheduleExplanation _self;
  final $Res Function(_ScheduleExplanation) _then;

/// Create a copy of ScheduleExplanation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reasons = null,}) {
  return _then(_ScheduleExplanation(
reasons: null == reasons ? _self._reasons : reasons // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
