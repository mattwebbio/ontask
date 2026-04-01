// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_explanation_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScheduleExplanationDto {

 List<String> get reasons;
/// Create a copy of ScheduleExplanationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleExplanationDtoCopyWith<ScheduleExplanationDto> get copyWith => _$ScheduleExplanationDtoCopyWithImpl<ScheduleExplanationDto>(this as ScheduleExplanationDto, _$identity);

  /// Serializes this ScheduleExplanationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduleExplanationDto&&const DeepCollectionEquality().equals(other.reasons, reasons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(reasons));

@override
String toString() {
  return 'ScheduleExplanationDto(reasons: $reasons)';
}


}

/// @nodoc
abstract mixin class $ScheduleExplanationDtoCopyWith<$Res>  {
  factory $ScheduleExplanationDtoCopyWith(ScheduleExplanationDto value, $Res Function(ScheduleExplanationDto) _then) = _$ScheduleExplanationDtoCopyWithImpl;
@useResult
$Res call({
 List<String> reasons
});




}
/// @nodoc
class _$ScheduleExplanationDtoCopyWithImpl<$Res>
    implements $ScheduleExplanationDtoCopyWith<$Res> {
  _$ScheduleExplanationDtoCopyWithImpl(this._self, this._then);

  final ScheduleExplanationDto _self;
  final $Res Function(ScheduleExplanationDto) _then;

/// Create a copy of ScheduleExplanationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reasons = null,}) {
  return _then(_self.copyWith(
reasons: null == reasons ? _self.reasons : reasons // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduleExplanationDto].
extension ScheduleExplanationDtoPatterns on ScheduleExplanationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduleExplanationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduleExplanationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduleExplanationDto value)  $default,){
final _that = this;
switch (_that) {
case _ScheduleExplanationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduleExplanationDto value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduleExplanationDto() when $default != null:
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
case _ScheduleExplanationDto() when $default != null:
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
case _ScheduleExplanationDto():
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
case _ScheduleExplanationDto() when $default != null:
return $default(_that.reasons);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScheduleExplanationDto extends ScheduleExplanationDto {
  const _ScheduleExplanationDto({required final  List<String> reasons}): _reasons = reasons,super._();
  factory _ScheduleExplanationDto.fromJson(Map<String, dynamic> json) => _$ScheduleExplanationDtoFromJson(json);

 final  List<String> _reasons;
@override List<String> get reasons {
  if (_reasons is EqualUnmodifiableListView) return _reasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_reasons);
}


/// Create a copy of ScheduleExplanationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduleExplanationDtoCopyWith<_ScheduleExplanationDto> get copyWith => __$ScheduleExplanationDtoCopyWithImpl<_ScheduleExplanationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduleExplanationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduleExplanationDto&&const DeepCollectionEquality().equals(other._reasons, _reasons));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_reasons));

@override
String toString() {
  return 'ScheduleExplanationDto(reasons: $reasons)';
}


}

/// @nodoc
abstract mixin class _$ScheduleExplanationDtoCopyWith<$Res> implements $ScheduleExplanationDtoCopyWith<$Res> {
  factory _$ScheduleExplanationDtoCopyWith(_ScheduleExplanationDto value, $Res Function(_ScheduleExplanationDto) _then) = __$ScheduleExplanationDtoCopyWithImpl;
@override @useResult
$Res call({
 List<String> reasons
});




}
/// @nodoc
class __$ScheduleExplanationDtoCopyWithImpl<$Res>
    implements _$ScheduleExplanationDtoCopyWith<$Res> {
  __$ScheduleExplanationDtoCopyWithImpl(this._self, this._then);

  final _ScheduleExplanationDto _self;
  final $Res Function(_ScheduleExplanationDto) _then;

/// Create a copy of ScheduleExplanationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reasons = null,}) {
  return _then(_ScheduleExplanationDto(
reasons: null == reasons ? _self._reasons : reasons // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
