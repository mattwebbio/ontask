// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_parse_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskParseResult {

/// The parsed task title.
 String get title;/// Overall confidence in the parse result.
/// 'low' when the utterance was too ambiguous.
 String get confidence;/// Resolved due date as ISO 8601 string, if mentioned.
 String? get dueDate;/// Resolved scheduled time as ISO 8601 string, if mentioned.
 String? get scheduledTime;/// Estimated duration in minutes, if mentioned.
 int? get estimatedDurationMinutes;/// Energy requirement (high_focus / low_energy / flexible), if inferred.
 String? get energyRequirement;/// Matched list ID from the user's lists, if mentioned.
 String? get listId;/// Per-field confidence map (field name → 'high' | 'low').
/// Used by the UI to render dashed borders on uncertain fields.
 Map<String, String> get fieldConfidences;
/// Create a copy of TaskParseResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskParseResultCopyWith<TaskParseResult> get copyWith => _$TaskParseResultCopyWithImpl<TaskParseResult>(this as TaskParseResult, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskParseResult&&(identical(other.title, title) || other.title == title)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.estimatedDurationMinutes, estimatedDurationMinutes) || other.estimatedDurationMinutes == estimatedDurationMinutes)&&(identical(other.energyRequirement, energyRequirement) || other.energyRequirement == energyRequirement)&&(identical(other.listId, listId) || other.listId == listId)&&const DeepCollectionEquality().equals(other.fieldConfidences, fieldConfidences));
}


@override
int get hashCode => Object.hash(runtimeType,title,confidence,dueDate,scheduledTime,estimatedDurationMinutes,energyRequirement,listId,const DeepCollectionEquality().hash(fieldConfidences));

@override
String toString() {
  return 'TaskParseResult(title: $title, confidence: $confidence, dueDate: $dueDate, scheduledTime: $scheduledTime, estimatedDurationMinutes: $estimatedDurationMinutes, energyRequirement: $energyRequirement, listId: $listId, fieldConfidences: $fieldConfidences)';
}


}

/// @nodoc
abstract mixin class $TaskParseResultCopyWith<$Res>  {
  factory $TaskParseResultCopyWith(TaskParseResult value, $Res Function(TaskParseResult) _then) = _$TaskParseResultCopyWithImpl;
@useResult
$Res call({
 String title, String confidence, String? dueDate, String? scheduledTime, int? estimatedDurationMinutes, String? energyRequirement, String? listId, Map<String, String> fieldConfidences
});




}
/// @nodoc
class _$TaskParseResultCopyWithImpl<$Res>
    implements $TaskParseResultCopyWith<$Res> {
  _$TaskParseResultCopyWithImpl(this._self, this._then);

  final TaskParseResult _self;
  final $Res Function(TaskParseResult) _then;

/// Create a copy of TaskParseResult
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


/// Adds pattern-matching-related methods to [TaskParseResult].
extension TaskParseResultPatterns on TaskParseResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskParseResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskParseResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskParseResult value)  $default,){
final _that = this;
switch (_that) {
case _TaskParseResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskParseResult value)?  $default,){
final _that = this;
switch (_that) {
case _TaskParseResult() when $default != null:
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
case _TaskParseResult() when $default != null:
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
case _TaskParseResult():
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
case _TaskParseResult() when $default != null:
return $default(_that.title,_that.confidence,_that.dueDate,_that.scheduledTime,_that.estimatedDurationMinutes,_that.energyRequirement,_that.listId,_that.fieldConfidences);case _:
  return null;

}
}

}

/// @nodoc


class _TaskParseResult implements TaskParseResult {
  const _TaskParseResult({required this.title, required this.confidence, this.dueDate, this.scheduledTime, this.estimatedDurationMinutes, this.energyRequirement, this.listId, final  Map<String, String> fieldConfidences = const {}}): _fieldConfidences = fieldConfidences;
  

/// The parsed task title.
@override final  String title;
/// Overall confidence in the parse result.
/// 'low' when the utterance was too ambiguous.
@override final  String confidence;
/// Resolved due date as ISO 8601 string, if mentioned.
@override final  String? dueDate;
/// Resolved scheduled time as ISO 8601 string, if mentioned.
@override final  String? scheduledTime;
/// Estimated duration in minutes, if mentioned.
@override final  int? estimatedDurationMinutes;
/// Energy requirement (high_focus / low_energy / flexible), if inferred.
@override final  String? energyRequirement;
/// Matched list ID from the user's lists, if mentioned.
@override final  String? listId;
/// Per-field confidence map (field name → 'high' | 'low').
/// Used by the UI to render dashed borders on uncertain fields.
 final  Map<String, String> _fieldConfidences;
/// Per-field confidence map (field name → 'high' | 'low').
/// Used by the UI to render dashed borders on uncertain fields.
@override@JsonKey() Map<String, String> get fieldConfidences {
  if (_fieldConfidences is EqualUnmodifiableMapView) return _fieldConfidences;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fieldConfidences);
}


/// Create a copy of TaskParseResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskParseResultCopyWith<_TaskParseResult> get copyWith => __$TaskParseResultCopyWithImpl<_TaskParseResult>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskParseResult&&(identical(other.title, title) || other.title == title)&&(identical(other.confidence, confidence) || other.confidence == confidence)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.estimatedDurationMinutes, estimatedDurationMinutes) || other.estimatedDurationMinutes == estimatedDurationMinutes)&&(identical(other.energyRequirement, energyRequirement) || other.energyRequirement == energyRequirement)&&(identical(other.listId, listId) || other.listId == listId)&&const DeepCollectionEquality().equals(other._fieldConfidences, _fieldConfidences));
}


@override
int get hashCode => Object.hash(runtimeType,title,confidence,dueDate,scheduledTime,estimatedDurationMinutes,energyRequirement,listId,const DeepCollectionEquality().hash(_fieldConfidences));

@override
String toString() {
  return 'TaskParseResult(title: $title, confidence: $confidence, dueDate: $dueDate, scheduledTime: $scheduledTime, estimatedDurationMinutes: $estimatedDurationMinutes, energyRequirement: $energyRequirement, listId: $listId, fieldConfidences: $fieldConfidences)';
}


}

/// @nodoc
abstract mixin class _$TaskParseResultCopyWith<$Res> implements $TaskParseResultCopyWith<$Res> {
  factory _$TaskParseResultCopyWith(_TaskParseResult value, $Res Function(_TaskParseResult) _then) = __$TaskParseResultCopyWithImpl;
@override @useResult
$Res call({
 String title, String confidence, String? dueDate, String? scheduledTime, int? estimatedDurationMinutes, String? energyRequirement, String? listId, Map<String, String> fieldConfidences
});




}
/// @nodoc
class __$TaskParseResultCopyWithImpl<$Res>
    implements _$TaskParseResultCopyWith<$Res> {
  __$TaskParseResultCopyWithImpl(this._self, this._then);

  final _TaskParseResult _self;
  final $Res Function(_TaskParseResult) _then;

/// Create a copy of TaskParseResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = null,Object? confidence = null,Object? dueDate = freezed,Object? scheduledTime = freezed,Object? estimatedDurationMinutes = freezed,Object? energyRequirement = freezed,Object? listId = freezed,Object? fieldConfidences = null,}) {
  return _then(_TaskParseResult(
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
