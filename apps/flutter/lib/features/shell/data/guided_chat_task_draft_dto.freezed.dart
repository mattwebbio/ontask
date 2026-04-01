// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guided_chat_task_draft_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GuidedChatTaskDraftDto {

 String? get title; String? get dueDate; String? get scheduledTime; int? get estimatedDurationMinutes; String? get energyRequirement; String? get listId;
/// Create a copy of GuidedChatTaskDraftDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidedChatTaskDraftDtoCopyWith<GuidedChatTaskDraftDto> get copyWith => _$GuidedChatTaskDraftDtoCopyWithImpl<GuidedChatTaskDraftDto>(this as GuidedChatTaskDraftDto, _$identity);

  /// Serializes this GuidedChatTaskDraftDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidedChatTaskDraftDto&&(identical(other.title, title) || other.title == title)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.estimatedDurationMinutes, estimatedDurationMinutes) || other.estimatedDurationMinutes == estimatedDurationMinutes)&&(identical(other.energyRequirement, energyRequirement) || other.energyRequirement == energyRequirement)&&(identical(other.listId, listId) || other.listId == listId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,dueDate,scheduledTime,estimatedDurationMinutes,energyRequirement,listId);

@override
String toString() {
  return 'GuidedChatTaskDraftDto(title: $title, dueDate: $dueDate, scheduledTime: $scheduledTime, estimatedDurationMinutes: $estimatedDurationMinutes, energyRequirement: $energyRequirement, listId: $listId)';
}


}

/// @nodoc
abstract mixin class $GuidedChatTaskDraftDtoCopyWith<$Res>  {
  factory $GuidedChatTaskDraftDtoCopyWith(GuidedChatTaskDraftDto value, $Res Function(GuidedChatTaskDraftDto) _then) = _$GuidedChatTaskDraftDtoCopyWithImpl;
@useResult
$Res call({
 String? title, String? dueDate, String? scheduledTime, int? estimatedDurationMinutes, String? energyRequirement, String? listId
});




}
/// @nodoc
class _$GuidedChatTaskDraftDtoCopyWithImpl<$Res>
    implements $GuidedChatTaskDraftDtoCopyWith<$Res> {
  _$GuidedChatTaskDraftDtoCopyWithImpl(this._self, this._then);

  final GuidedChatTaskDraftDto _self;
  final $Res Function(GuidedChatTaskDraftDto) _then;

/// Create a copy of GuidedChatTaskDraftDto
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


/// Adds pattern-matching-related methods to [GuidedChatTaskDraftDto].
extension GuidedChatTaskDraftDtoPatterns on GuidedChatTaskDraftDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuidedChatTaskDraftDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuidedChatTaskDraftDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuidedChatTaskDraftDto value)  $default,){
final _that = this;
switch (_that) {
case _GuidedChatTaskDraftDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuidedChatTaskDraftDto value)?  $default,){
final _that = this;
switch (_that) {
case _GuidedChatTaskDraftDto() when $default != null:
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
case _GuidedChatTaskDraftDto() when $default != null:
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
case _GuidedChatTaskDraftDto():
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
case _GuidedChatTaskDraftDto() when $default != null:
return $default(_that.title,_that.dueDate,_that.scheduledTime,_that.estimatedDurationMinutes,_that.energyRequirement,_that.listId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuidedChatTaskDraftDto extends GuidedChatTaskDraftDto {
  const _GuidedChatTaskDraftDto({this.title, this.dueDate, this.scheduledTime, this.estimatedDurationMinutes, this.energyRequirement, this.listId}): super._();
  factory _GuidedChatTaskDraftDto.fromJson(Map<String, dynamic> json) => _$GuidedChatTaskDraftDtoFromJson(json);

@override final  String? title;
@override final  String? dueDate;
@override final  String? scheduledTime;
@override final  int? estimatedDurationMinutes;
@override final  String? energyRequirement;
@override final  String? listId;

/// Create a copy of GuidedChatTaskDraftDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidedChatTaskDraftDtoCopyWith<_GuidedChatTaskDraftDto> get copyWith => __$GuidedChatTaskDraftDtoCopyWithImpl<_GuidedChatTaskDraftDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidedChatTaskDraftDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidedChatTaskDraftDto&&(identical(other.title, title) || other.title == title)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.scheduledTime, scheduledTime) || other.scheduledTime == scheduledTime)&&(identical(other.estimatedDurationMinutes, estimatedDurationMinutes) || other.estimatedDurationMinutes == estimatedDurationMinutes)&&(identical(other.energyRequirement, energyRequirement) || other.energyRequirement == energyRequirement)&&(identical(other.listId, listId) || other.listId == listId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,title,dueDate,scheduledTime,estimatedDurationMinutes,energyRequirement,listId);

@override
String toString() {
  return 'GuidedChatTaskDraftDto(title: $title, dueDate: $dueDate, scheduledTime: $scheduledTime, estimatedDurationMinutes: $estimatedDurationMinutes, energyRequirement: $energyRequirement, listId: $listId)';
}


}

/// @nodoc
abstract mixin class _$GuidedChatTaskDraftDtoCopyWith<$Res> implements $GuidedChatTaskDraftDtoCopyWith<$Res> {
  factory _$GuidedChatTaskDraftDtoCopyWith(_GuidedChatTaskDraftDto value, $Res Function(_GuidedChatTaskDraftDto) _then) = __$GuidedChatTaskDraftDtoCopyWithImpl;
@override @useResult
$Res call({
 String? title, String? dueDate, String? scheduledTime, int? estimatedDurationMinutes, String? energyRequirement, String? listId
});




}
/// @nodoc
class __$GuidedChatTaskDraftDtoCopyWithImpl<$Res>
    implements _$GuidedChatTaskDraftDtoCopyWith<$Res> {
  __$GuidedChatTaskDraftDtoCopyWithImpl(this._self, this._then);

  final _GuidedChatTaskDraftDto _self;
  final $Res Function(_GuidedChatTaskDraftDto) _then;

/// Create a copy of GuidedChatTaskDraftDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? title = freezed,Object? dueDate = freezed,Object? scheduledTime = freezed,Object? estimatedDurationMinutes = freezed,Object? energyRequirement = freezed,Object? listId = freezed,}) {
  return _then(_GuidedChatTaskDraftDto(
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
