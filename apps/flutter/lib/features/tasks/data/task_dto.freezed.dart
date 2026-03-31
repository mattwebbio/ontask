// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskDto {

 String get id; String get title; String? get notes; String? get dueDate; String? get listId; String? get sectionId; String? get parentTaskId; int get position; String? get timeWindow; String? get timeWindowStart; String? get timeWindowEnd; String? get energyRequirement; String? get priority; String? get archivedAt; String? get completedAt; String get createdAt; String get updatedAt;
/// Create a copy of TaskDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskDtoCopyWith<TaskDto> get copyWith => _$TaskDtoCopyWithImpl<TaskDto>(this as TaskDto, _$identity);

  /// Serializes this TaskDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.parentTaskId, parentTaskId) || other.parentTaskId == parentTaskId)&&(identical(other.position, position) || other.position == position)&&(identical(other.timeWindow, timeWindow) || other.timeWindow == timeWindow)&&(identical(other.timeWindowStart, timeWindowStart) || other.timeWindowStart == timeWindowStart)&&(identical(other.timeWindowEnd, timeWindowEnd) || other.timeWindowEnd == timeWindowEnd)&&(identical(other.energyRequirement, energyRequirement) || other.energyRequirement == energyRequirement)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,notes,dueDate,listId,sectionId,parentTaskId,position,timeWindow,timeWindowStart,timeWindowEnd,energyRequirement,priority,archivedAt,completedAt,createdAt,updatedAt);

@override
String toString() {
  return 'TaskDto(id: $id, title: $title, notes: $notes, dueDate: $dueDate, listId: $listId, sectionId: $sectionId, parentTaskId: $parentTaskId, position: $position, timeWindow: $timeWindow, timeWindowStart: $timeWindowStart, timeWindowEnd: $timeWindowEnd, energyRequirement: $energyRequirement, priority: $priority, archivedAt: $archivedAt, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TaskDtoCopyWith<$Res>  {
  factory $TaskDtoCopyWith(TaskDto value, $Res Function(TaskDto) _then) = _$TaskDtoCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? notes, String? dueDate, String? listId, String? sectionId, String? parentTaskId, int position, String? timeWindow, String? timeWindowStart, String? timeWindowEnd, String? energyRequirement, String? priority, String? archivedAt, String? completedAt, String createdAt, String updatedAt
});




}
/// @nodoc
class _$TaskDtoCopyWithImpl<$Res>
    implements $TaskDtoCopyWith<$Res> {
  _$TaskDtoCopyWithImpl(this._self, this._then);

  final TaskDto _self;
  final $Res Function(TaskDto) _then;

/// Create a copy of TaskDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? notes = freezed,Object? dueDate = freezed,Object? listId = freezed,Object? sectionId = freezed,Object? parentTaskId = freezed,Object? position = null,Object? timeWindow = freezed,Object? timeWindowStart = freezed,Object? timeWindowEnd = freezed,Object? energyRequirement = freezed,Object? priority = freezed,Object? archivedAt = freezed,Object? completedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,parentTaskId: freezed == parentTaskId ? _self.parentTaskId : parentTaskId // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,timeWindow: freezed == timeWindow ? _self.timeWindow : timeWindow // ignore: cast_nullable_to_non_nullable
as String?,timeWindowStart: freezed == timeWindowStart ? _self.timeWindowStart : timeWindowStart // ignore: cast_nullable_to_non_nullable
as String?,timeWindowEnd: freezed == timeWindowEnd ? _self.timeWindowEnd : timeWindowEnd // ignore: cast_nullable_to_non_nullable
as String?,energyRequirement: freezed == energyRequirement ? _self.energyRequirement : energyRequirement // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskDto].
extension TaskDtoPatterns on TaskDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskDto value)  $default,){
final _that = this;
switch (_that) {
case _TaskDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskDto value)?  $default,){
final _that = this;
switch (_that) {
case _TaskDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? notes,  String? dueDate,  String? listId,  String? sectionId,  String? parentTaskId,  int position,  String? timeWindow,  String? timeWindowStart,  String? timeWindowEnd,  String? energyRequirement,  String? priority,  String? archivedAt,  String? completedAt,  String createdAt,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskDto() when $default != null:
return $default(_that.id,_that.title,_that.notes,_that.dueDate,_that.listId,_that.sectionId,_that.parentTaskId,_that.position,_that.timeWindow,_that.timeWindowStart,_that.timeWindowEnd,_that.energyRequirement,_that.priority,_that.archivedAt,_that.completedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? notes,  String? dueDate,  String? listId,  String? sectionId,  String? parentTaskId,  int position,  String? timeWindow,  String? timeWindowStart,  String? timeWindowEnd,  String? energyRequirement,  String? priority,  String? archivedAt,  String? completedAt,  String createdAt,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TaskDto():
return $default(_that.id,_that.title,_that.notes,_that.dueDate,_that.listId,_that.sectionId,_that.parentTaskId,_that.position,_that.timeWindow,_that.timeWindowStart,_that.timeWindowEnd,_that.energyRequirement,_that.priority,_that.archivedAt,_that.completedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? notes,  String? dueDate,  String? listId,  String? sectionId,  String? parentTaskId,  int position,  String? timeWindow,  String? timeWindowStart,  String? timeWindowEnd,  String? energyRequirement,  String? priority,  String? archivedAt,  String? completedAt,  String createdAt,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TaskDto() when $default != null:
return $default(_that.id,_that.title,_that.notes,_that.dueDate,_that.listId,_that.sectionId,_that.parentTaskId,_that.position,_that.timeWindow,_that.timeWindowStart,_that.timeWindowEnd,_that.energyRequirement,_that.priority,_that.archivedAt,_that.completedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskDto extends TaskDto {
  const _TaskDto({required this.id, required this.title, this.notes, this.dueDate, this.listId, this.sectionId, this.parentTaskId, required this.position, this.timeWindow, this.timeWindowStart, this.timeWindowEnd, this.energyRequirement, this.priority, this.archivedAt, this.completedAt, required this.createdAt, required this.updatedAt}): super._();
  factory _TaskDto.fromJson(Map<String, dynamic> json) => _$TaskDtoFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? notes;
@override final  String? dueDate;
@override final  String? listId;
@override final  String? sectionId;
@override final  String? parentTaskId;
@override final  int position;
@override final  String? timeWindow;
@override final  String? timeWindowStart;
@override final  String? timeWindowEnd;
@override final  String? energyRequirement;
@override final  String? priority;
@override final  String? archivedAt;
@override final  String? completedAt;
@override final  String createdAt;
@override final  String updatedAt;

/// Create a copy of TaskDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDtoCopyWith<_TaskDto> get copyWith => __$TaskDtoCopyWithImpl<_TaskDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.parentTaskId, parentTaskId) || other.parentTaskId == parentTaskId)&&(identical(other.position, position) || other.position == position)&&(identical(other.timeWindow, timeWindow) || other.timeWindow == timeWindow)&&(identical(other.timeWindowStart, timeWindowStart) || other.timeWindowStart == timeWindowStart)&&(identical(other.timeWindowEnd, timeWindowEnd) || other.timeWindowEnd == timeWindowEnd)&&(identical(other.energyRequirement, energyRequirement) || other.energyRequirement == energyRequirement)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,notes,dueDate,listId,sectionId,parentTaskId,position,timeWindow,timeWindowStart,timeWindowEnd,energyRequirement,priority,archivedAt,completedAt,createdAt,updatedAt);

@override
String toString() {
  return 'TaskDto(id: $id, title: $title, notes: $notes, dueDate: $dueDate, listId: $listId, sectionId: $sectionId, parentTaskId: $parentTaskId, position: $position, timeWindow: $timeWindow, timeWindowStart: $timeWindowStart, timeWindowEnd: $timeWindowEnd, energyRequirement: $energyRequirement, priority: $priority, archivedAt: $archivedAt, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TaskDtoCopyWith<$Res> implements $TaskDtoCopyWith<$Res> {
  factory _$TaskDtoCopyWith(_TaskDto value, $Res Function(_TaskDto) _then) = __$TaskDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? notes, String? dueDate, String? listId, String? sectionId, String? parentTaskId, int position, String? timeWindow, String? timeWindowStart, String? timeWindowEnd, String? energyRequirement, String? priority, String? archivedAt, String? completedAt, String createdAt, String updatedAt
});




}
/// @nodoc
class __$TaskDtoCopyWithImpl<$Res>
    implements _$TaskDtoCopyWith<$Res> {
  __$TaskDtoCopyWithImpl(this._self, this._then);

  final _TaskDto _self;
  final $Res Function(_TaskDto) _then;

/// Create a copy of TaskDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? notes = freezed,Object? dueDate = freezed,Object? listId = freezed,Object? sectionId = freezed,Object? parentTaskId = freezed,Object? position = null,Object? timeWindow = freezed,Object? timeWindowStart = freezed,Object? timeWindowEnd = freezed,Object? energyRequirement = freezed,Object? priority = freezed,Object? archivedAt = freezed,Object? completedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_TaskDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,parentTaskId: freezed == parentTaskId ? _self.parentTaskId : parentTaskId // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,timeWindow: freezed == timeWindow ? _self.timeWindow : timeWindow // ignore: cast_nullable_to_non_nullable
as String?,timeWindowStart: freezed == timeWindowStart ? _self.timeWindowStart : timeWindowStart // ignore: cast_nullable_to_non_nullable
as String?,timeWindowEnd: freezed == timeWindowEnd ? _self.timeWindowEnd : timeWindowEnd // ignore: cast_nullable_to_non_nullable
as String?,energyRequirement: freezed == energyRequirement ? _self.energyRequirement : energyRequirement // ignore: cast_nullable_to_non_nullable
as String?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as String?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
