// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guided_chat_task_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GuidedChatTaskDraft {

/// The resolved task title, if collected.
 String? get title;/// Resolved due date as ISO 8601 string, if mentioned.
 String? get dueDate;/// Resolved scheduled time as ISO 8601 string, if mentioned.
 String? get scheduledTime;/// Estimated duration in minutes, if mentioned.
 int? get estimatedDurationMinutes;/// Energy requirement (high_focus / low_energy / flexible), if inferred.
 String? get energyRequirement;/// Matched list ID from the user's lists, if mentioned.
 String? get listId;
/// Create a copy of GuidedChatTaskDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidedChatTaskDraftCopyWith<GuidedChatTaskDraft> get copyWith => _$GuidedChatTaskDraftCopyWithImpl<GuidedChatTaskDraft>(this as GuidedChatTaskDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidedChatTaskDraft&&(identical(other.title, title) || other.title == title)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.estimatedDurationMinutes, estimatedDurationMinutes) || other.estimatedDurationMinutes == estimatedDurationMinutes)&&(identical(other.energyRequirement, energyRequirement) || other.energyRequirement == energyRequirement)&&(identical(other.listId, listId) || other.listId == listId));
}


@override
int get hashCode => Object.hash(runtimeType,title,dueDate,scheduledTime,estimatedDurationMinutes,energyRequirement,listId);

@override
String toString() {
  return 'GuidedChatTaskDraft(title: $title, dueDate: $dueDate, scheduledTime: $scheduledTime, estimatedDurationMinutes: $estimatedDurationMinutes, energyRequirement: $energyRequirement, listId: $listId)';
}


}

/// @nodoc
abstract mixin class $GuidedChatTaskDraftCopyWith<$Res>  {
  factory $GuidedChatTaskDraftCopyWith(GuidedChatTaskDraft value, $Res Function(GuidedChatTaskDraft) _then) = _$GuidedChatTaskDraftCopyWithImpl;
@useResult
$Res call({
 String? title, String? dueDate, String? scheduledTime, int? estimatedDurationMinutes, String? energyRequirement, String? listId
});




}
/// @nodoc
class _$GuidedChatTaskDraftCopyWithImpl<$Res>
    implements $GuidedChatTaskDraftCopyWith<$Res> {
  _$GuidedChatTaskDraftCopyWithImpl(this._self, this._then);

  final GuidedChatTaskDraft _self;
  final $Res Function(GuidedChatTaskDraft) _then;

/// Create a copy of GuidedChatTaskDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? title = freezed,Object? dueDate = freezed,Object? scheduledTime = freezed,Object? estimatedDurationMinutes = freezed,Object? energyRequirement = freezed,Object? listId = freezed,}) {
  return _then(_self.copyWith(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,scheduledTime: freezed == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as String?,estimatedDurationMinutes: freezed == estimatedDurationMinutes ? _self.estimatedDurationMinutes : estimatedDurationMinutes // ignore: cast_nullable_to_non_nullable
as int?,energyRequirement: freezed == energyRequirement ? _self.energyRequirement : energyRequirement // ignore: cast_nullable_to_non_nullable
as String?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GuidedChatTaskDraft].
extension GuidedChatTaskDraftPatterns on GuidedChatTaskDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuidedChatTaskDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuidedChatTaskDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuidedChatTaskDraft value)  $default,){
final _that = this;
switch (_that) {
case _GuidedChatTaskDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuidedChatTaskDraft value)?  $default,){
final _that = this;
switch (_that) {
case _GuidedChatTaskDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? title,  String? dueDate,  String? scheduledTime,  int? estimatedDurationMinutes,  String? energyRequirement,  String? listId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuidedChatTaskDraft() when $default != null:
return $default(_that.title,_that.dueDate,_that.scheduledTime,_that.estimatedDurationMinutes,_that.energyRequirement,_that.listId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? title,  String? dueDate,  String? scheduledTime,  int? estimatedDurationMinutes,  String? energyRequirement,  String? listId)  $default,) {final _that = this;
switch (_that) {
case _GuidedChatTaskDraft():
return $default(_that.title,_that.dueDate,_that.scheduledTime,_that.estimatedDurationMinutes,_that.energyRequirement,_that.listId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? title,  String? dueDate,  String? scheduledTime,  int? estimatedDurationMinutes,  String? energyRequirement,  String? listId)?  $default,) {final _that = this;
switch (_that) {
case _GuidedChatTaskDraft() when $default != null:
return $default(_that.title,_that.dueDate,_that.scheduledTime,_that.estimatedDurationMinutes,_that.energyRequirement,_that.listId);case _:
  return null;

}
}

}

/// @nodoc


class _GuidedChatTaskDraft implements GuidedChatTaskDraft {
  const _GuidedChatTaskDraft({this.title, this.dueDate, this.scheduledTime, this.estimatedDurationMinutes, this.energyRequirement, this.listId});
  

/// The resolved task title, if collected.
@override final  String? title;
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

/// Create a copy of GuidedChatTaskDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidedChatTaskDraftCopyWith<_GuidedChatTaskDraft> get copyWith => __$GuidedChatTaskDraftCopyWithImpl<_GuidedChatTaskDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidedChatTaskDraft&&(identical(other.title, title) || other.title == title)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.estimatedDurationMinutes, estimatedDurationMinutes) || other.estimatedDurationMinutes == estimatedDurationMinutes)&&(identical(other.energyRequirement, energyRequirement) || other.energyRequirement == energyRequirement)&&(identical(other.listId, listId) || other.listId == listId));
}


@override
int get hashCode => Object.hash(runtimeType,title,dueDate,scheduledTime,estimatedDurationMinutes,energyRequirement,listId);

@override
String toString() {
  return 'GuidedChatTaskDraft(title: $title, dueDate: $dueDate, scheduledTime: $scheduledTime, estimatedDurationMinutes: $estimatedDurationMinutes, energyRequirement: $energyRequirement, listId: $listId)';
}


}

/// @nodoc
abstract mixin class _$GuidedChatTaskDraftCopyWith<$Res> implements $GuidedChatTaskDraftCopyWith<$Res> {
  factory _$GuidedChatTaskDraftCopyWith(_GuidedChatTaskDraft value, $Res Function(_GuidedChatTaskDraft) _then) = __$GuidedChatTaskDraftCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? dueDate, String? scheduledTime, int? estimatedDurationMinutes, String? energyRequirement, String? listId
});




}
/// @nodoc
class __$GuidedChatTaskDraftCopyWithImpl<$Res>
    implements _$GuidedChatTaskDraftCopyWith<$Res> {
  __$GuidedChatTaskDraftCopyWithImpl(this._self, this._then);

  final _GuidedChatTaskDraft _self;
  final $Res Function(_GuidedChatTaskDraft) _then;

/// Create a copy of GuidedChatTaskDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? dueDate = freezed,Object? scheduledTime = freezed,Object? estimatedDurationMinutes = freezed,Object? energyRequirement = freezed,Object? listId = freezed,}) {
  return _then(_GuidedChatTaskDraft(
title: freezed == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,scheduledTime: freezed == scheduledTime ? _self.scheduledTime : scheduledTime // ignore: cast_nullable_to_non_nullable
as String?,estimatedDurationMinutes: freezed == estimatedDurationMinutes ? _self.estimatedDurationMinutes : estimatedDurationMinutes // ignore: cast_nullable_to_non_nullable
as int?,energyRequirement: freezed == energyRequirement ? _self.energyRequirement : energyRequirement // ignore: cast_nullable_to_non_nullable
as String?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
