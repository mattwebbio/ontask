// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_parse_result_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskParseResultDto {

 String get title; String get confidence; String? get dueDate; String? get scheduledTime; int? get estimatedDurationMinutes; String? get energyRequirement; String? get listId; Map<String, String> get fieldConfidences;
/// Create a copy of TaskParseResultDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskParseResultDtoCopyWith<TaskParseResultDto> get copyWith => _$TaskParseResultDtoCopyWithImpl<TaskParseResultDto>(this as TaskParseResultDto, _$identity);

  /// Serializes this TaskParseResultDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskParseResultDto&&(identical(other.title, title) || other.title == title)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.estimatedDurationMinutes, estimatedDurationMinutes) || other.estimatedDurationMinutes == estimatedDurationMinutes)&&(identical(other.energyRequirement, energyRequirement) || other.energyRequirement == energyRequirement)&&(identical(other.listId, listId) || other.listId == listId)&&const DeepCollectionEquality().equals(other.fieldConfidences, fieldConfidences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,confidence,dueDate,scheduledTime,estimatedDurationMinutes,energyRequirement,listId,const DeepCollectionEquality().hash(fieldConfidences));

@override
String toString() {
  return 'TaskParseResultDto(title: $title, confidence: $confidence, dueDate: $dueDate, scheduledTime: $scheduledTime, estimatedDurationMinutes: $estimatedDurationMinutes, energyRequirement: $energyRequirement, listId: $listId, fieldConfidences: $fieldConfidences)';
}


}

/// @nodoc
abstract mixin class $TaskParseResultDtoCopyWith<$Res>  {
  factory $TaskParseResultDtoCopyWith(TaskParseResultDto value, $Res Function(TaskParseResultDto) _then) = _$TaskParseResultDtoCopyWithImpl;
@useResult
$Res call({
 String title, String confidence, String? dueDate, String? scheduledTime, int? estimatedDurationMinutes, String? energyRequirement, String? listId, Map<String, String> fieldConfidences
});




}
/// @nodoc
class _$TaskParseResultDtoCopyWithImpl<$Res>
    implements $TaskParseResultDtoCopyWith<$Res> {
  _$TaskParseResultDtoCopyWithImpl(this._self, this._then);

  final TaskParseResultDto _self;
  final $Res Function(TaskParseResultDto) _then;

/// Create a copy of TaskParseResultDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = null,Object? confidence = null,Object? dueDate = freezed,Object? scheduledTime = freezed,Object? estimatedDurationMinutes = freezed,Object? energyRequirement = freezed,Object? listId = freezed,Object? fieldConfidences = null,}) {
  return _then(_self.copyWith(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as String,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,scheduledTime: freezed == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as String?,estimatedDurationMinutes: freezed == estimatedDurationMinutes ? _self.estimatedDurationMinutes : estimatedDurationMinutes // ignore: cast_nullable_to_non_nullable
as int?,energyRequirement: freezed == energyRequirement ? _self.energyRequirement : energyRequirement // ignore: cast_nullable_to_non_nullable
as String?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,fieldConfidences: null == fieldConfidences ? _self.fieldConfidences : fieldConfidences // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskParseResultDto].
extension TaskParseResultDtoPatterns on TaskParseResultDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskParseResultDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskParseResultDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskParseResultDto value)  $default,){
final _that = this;
switch (_that) {
case _TaskParseResultDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskParseResultDto value)?  $default,){
final _that = this;
switch (_that) {
case _TaskParseResultDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String title,  String confidence,  String? dueDate,  String? scheduledTime,  int? estimatedDurationMinutes,  String? energyRequirement,  String? listId,  Map<String, String> fieldConfidences)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskParseResultDto() when $default != null:
return $default(_that.title,_that.confidence,_that.dueDate,_that.scheduledTime,_that.estimatedDurationMinutes,_that.energyRequirement,_that.listId,_that.fieldConfidences);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String title,  String confidence,  String? dueDate,  String? scheduledTime,  int? estimatedDurationMinutes,  String? energyRequirement,  String? listId,  Map<String, String> fieldConfidences)  $default,) {final _that = this;
switch (_that) {
case _TaskParseResultDto():
return $default(_that.title,_that.confidence,_that.dueDate,_that.scheduledTime,_that.estimatedDurationMinutes,_that.energyRequirement,_that.listId,_that.fieldConfidences);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String title,  String confidence,  String? dueDate,  String? scheduledTime,  int? estimatedDurationMinutes,  String? energyRequirement,  String? listId,  Map<String, String> fieldConfidences)?  $default,) {final _that = this;
switch (_that) {
case _TaskParseResultDto() when $default != null:
return $default(_that.title,_that.confidence,_that.dueDate,_that.scheduledTime,_that.estimatedDurationMinutes,_that.energyRequirement,_that.listId,_that.fieldConfidences);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskParseResultDto extends TaskParseResultDto {
  const _TaskParseResultDto({required this.title, required this.confidence, this.dueDate, this.scheduledTime, this.estimatedDurationMinutes, this.energyRequirement, this.listId, final  Map<String, String> fieldConfidences = const <String, String>{}}): _fieldConfidences = fieldConfidences,super._();
  factory _TaskParseResultDto.fromJson(Map<String, dynamic> json) => _$TaskParseResultDtoFromJson(json);

@override final  String title;
@override final  String confidence;
@override final  String? dueDate;
@override final  String? scheduledTime;
@override final  int? estimatedDurationMinutes;
@override final  String? energyRequirement;
@override final  String? listId;
 final  Map<String, String> _fieldConfidences;
@override@JsonKey() Map<String, String> get fieldConfidences {
  if (_fieldConfidences is EqualUnmodifiableMapView) return _fieldConfidences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fieldConfidences);
}


/// Create a copy of TaskParseResultDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskParseResultDtoCopyWith<_TaskParseResultDto> get copyWith => __$TaskParseResultDtoCopyWithImpl<_TaskParseResultDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskParseResultDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskParseResultDto&&(identical(other.title, title) || other.title == title)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.estimatedDurationMinutes, estimatedDurationMinutes) || other.estimatedDurationMinutes == estimatedDurationMinutes)&&(identical(other.energyRequirement, energyRequirement) || other.energyRequirement == energyRequirement)&&(identical(other.listId, listId) || other.listId == listId)&&const DeepCollectionEquality().equals(other._fieldConfidences, _fieldConfidences));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,confidence,dueDate,scheduledTime,estimatedDurationMinutes,energyRequirement,listId,const DeepCollectionEquality().hash(_fieldConfidences));

@override
String toString() {
  return 'TaskParseResultDto(title: $title, confidence: $confidence, dueDate: $dueDate, scheduledTime: $scheduledTime, estimatedDurationMinutes: $estimatedDurationMinutes, energyRequirement: $energyRequirement, listId: $listId, fieldConfidences: $fieldConfidences)';
}


}

/// @nodoc
abstract mixin class _$TaskParseResultDtoCopyWith<$Res> implements $TaskParseResultDtoCopyWith<$Res> {
  factory _$TaskParseResultDtoCopyWith(_TaskParseResultDto value, $Res Function(_TaskParseResultDto) _then) = __$TaskParseResultDtoCopyWithImpl;
@override @useResult
$Res call({
 String title, String confidence, String? dueDate, String? scheduledTime, int? estimatedDurationMinutes, String? energyRequirement, String? listId, Map<String, String> fieldConfidences
});




}
/// @nodoc
class __$TaskParseResultDtoCopyWithImpl<$Res>
    implements _$TaskParseResultDtoCopyWith<$Res> {
  __$TaskParseResultDtoCopyWithImpl(this._self, this._then);

  final _TaskParseResultDto _self;
  final $Res Function(_TaskParseResultDto) _then;

/// Create a copy of TaskParseResultDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? confidence = null,Object? dueDate = freezed,Object? scheduledTime = freezed,Object? estimatedDurationMinutes = freezed,Object? energyRequirement = freezed,Object? listId = freezed,Object? fieldConfidences = null,}) {
  return _then(_TaskParseResultDto(
title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as String,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,scheduledTime: freezed == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as String?,estimatedDurationMinutes: freezed == estimatedDurationMinutes ? _self.estimatedDurationMinutes : estimatedDurationMinutes // ignore: cast_nullable_to_non_nullable
as int?,energyRequirement: freezed == energyRequirement ? _self.energyRequirement : energyRequirement // ignore: cast_nullable_to_non_nullable
as String?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,fieldConfidences: null == fieldConfidences ? _self._fieldConfidences : fieldConfidences // ignore: cast_nullable_to_non_nullable
as Map<String, String>,
  ));
}


}

// dart format on
