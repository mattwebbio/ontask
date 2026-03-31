// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Task {

 String get id; String get title; String? get notes; DateTime? get dueDate; String? get listId; String? get sectionId; String? get parentTaskId; int get position; TimeWindow? get timeWindow; String? get timeWindowStart; String? get timeWindowEnd; EnergyRequirement? get energyRequirement; TaskPriority? get priority; DateTime? get archivedAt; DateTime? get completedAt; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.parentTaskId, parentTaskId) || other.parentTaskId == parentTaskId)&&(identical(other.position, position) || other.position == position)&&(identical(other.timeWindow, timeWindow) || other.timeWindow == timeWindow)&&(identical(other.timeWindowStart, timeWindowStart) || other.timeWindowStart == timeWindowStart)&&(identical(other.timeWindowEnd, timeWindowEnd) || other.timeWindowEnd == timeWindowEnd)&&(identical(other.energyRequirement, energyRequirement) || other.energyRequirement == energyRequirement)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,notes,dueDate,listId,sectionId,parentTaskId,position,timeWindow,timeWindowStart,timeWindowEnd,energyRequirement,priority,archivedAt,completedAt,createdAt,updatedAt);

@override
String toString() {
  return 'Task(id: $id, title: $title, notes: $notes, dueDate: $dueDate, listId: $listId, sectionId: $sectionId, parentTaskId: $parentTaskId, position: $position, timeWindow: $timeWindow, timeWindowStart: $timeWindowStart, timeWindowEnd: $timeWindowEnd, energyRequirement: $energyRequirement, priority: $priority, archivedAt: $archivedAt, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? notes, DateTime? dueDate, String? listId, String? sectionId, String? parentTaskId, int position, TimeWindow? timeWindow, String? timeWindowStart, String? timeWindowEnd, EnergyRequirement? energyRequirement, TaskPriority? priority, DateTime? archivedAt, DateTime? completedAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$TaskCopyWithImpl<$Res>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._self, this._then);

  final Task _self;
  final $Res Function(Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? notes = freezed,Object? dueDate = freezed,Object? listId = freezed,Object? sectionId = freezed,Object? parentTaskId = freezed,Object? position = null,Object? timeWindow = freezed,Object? timeWindowStart = freezed,Object? timeWindowEnd = freezed,Object? energyRequirement = freezed,Object? priority = freezed,Object? archivedAt = freezed,Object? completedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,parentTaskId: freezed == parentTaskId ? _self.parentTaskId : parentTaskId // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,timeWindow: freezed == timeWindow ? _self.timeWindow : timeWindow // ignore: cast_nullable_to_non_nullable
as TimeWindow?,timeWindowStart: freezed == timeWindowStart ? _self.timeWindowStart : timeWindowStart // ignore: cast_nullable_to_non_nullable
as String?,timeWindowEnd: freezed == timeWindowEnd ? _self.timeWindowEnd : timeWindowEnd // ignore: cast_nullable_to_non_nullable
as String?,energyRequirement: freezed == energyRequirement ? _self.energyRequirement : energyRequirement // ignore: cast_nullable_to_non_nullable
as EnergyRequirement?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TaskPriority?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Task].
extension TaskPatterns on Task {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Task value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Task value)  $default,){
final _that = this;
switch (_that) {
case _Task():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Task value)?  $default,){
final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? notes,  DateTime? dueDate,  String? listId,  String? sectionId,  String? parentTaskId,  int position,  TimeWindow? timeWindow,  String? timeWindowStart,  String? timeWindowEnd,  EnergyRequirement? energyRequirement,  TaskPriority? priority,  DateTime? archivedAt,  DateTime? completedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? notes,  DateTime? dueDate,  String? listId,  String? sectionId,  String? parentTaskId,  int position,  TimeWindow? timeWindow,  String? timeWindowStart,  String? timeWindowEnd,  EnergyRequirement? energyRequirement,  TaskPriority? priority,  DateTime? archivedAt,  DateTime? completedAt,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Task():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? notes,  DateTime? dueDate,  String? listId,  String? sectionId,  String? parentTaskId,  int position,  TimeWindow? timeWindow,  String? timeWindowStart,  String? timeWindowEnd,  EnergyRequirement? energyRequirement,  TaskPriority? priority,  DateTime? archivedAt,  DateTime? completedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.title,_that.notes,_that.dueDate,_that.listId,_that.sectionId,_that.parentTaskId,_that.position,_that.timeWindow,_that.timeWindowStart,_that.timeWindowEnd,_that.energyRequirement,_that.priority,_that.archivedAt,_that.completedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Task implements Task {
  const _Task({required this.id, required this.title, this.notes, this.dueDate, this.listId, this.sectionId, this.parentTaskId, required this.position, this.timeWindow, this.timeWindowStart, this.timeWindowEnd, this.energyRequirement, this.priority = TaskPriority.normal, this.archivedAt, this.completedAt, required this.createdAt, required this.updatedAt});
  

@override final  String id;
@override final  String title;
@override final  String? notes;
@override final  DateTime? dueDate;
@override final  String? listId;
@override final  String? sectionId;
@override final  String? parentTaskId;
@override final  int position;
@override final  TimeWindow? timeWindow;
@override final  String? timeWindowStart;
@override final  String? timeWindowEnd;
@override final  EnergyRequirement? energyRequirement;
@override@JsonKey() final  TaskPriority? priority;
@override final  DateTime? archivedAt;
@override final  DateTime? completedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.parentTaskId, parentTaskId) || other.parentTaskId == parentTaskId)&&(identical(other.position, position) || other.position == position)&&(identical(other.timeWindow, timeWindow) || other.timeWindow == timeWindow)&&(identical(other.timeWindowStart, timeWindowStart) || other.timeWindowStart == timeWindowStart)&&(identical(other.timeWindowEnd, timeWindowEnd) || other.timeWindowEnd == timeWindowEnd)&&(identical(other.energyRequirement, energyRequirement) || other.energyRequirement == energyRequirement)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,notes,dueDate,listId,sectionId,parentTaskId,position,timeWindow,timeWindowStart,timeWindowEnd,energyRequirement,priority,archivedAt,completedAt,createdAt,updatedAt);

@override
String toString() {
  return 'Task(id: $id, title: $title, notes: $notes, dueDate: $dueDate, listId: $listId, sectionId: $sectionId, parentTaskId: $parentTaskId, position: $position, timeWindow: $timeWindow, timeWindowStart: $timeWindowStart, timeWindowEnd: $timeWindowEnd, energyRequirement: $energyRequirement, priority: $priority, archivedAt: $archivedAt, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? notes, DateTime? dueDate, String? listId, String? sectionId, String? parentTaskId, int position, TimeWindow? timeWindow, String? timeWindowStart, String? timeWindowEnd, EnergyRequirement? energyRequirement, TaskPriority? priority, DateTime? archivedAt, DateTime? completedAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$TaskCopyWithImpl<$Res>
    implements _$TaskCopyWith<$Res> {
  __$TaskCopyWithImpl(this._self, this._then);

  final _Task _self;
  final $Res Function(_Task) _then;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? notes = freezed,Object? dueDate = freezed,Object? listId = freezed,Object? sectionId = freezed,Object? parentTaskId = freezed,Object? position = null,Object? timeWindow = freezed,Object? timeWindowStart = freezed,Object? timeWindowEnd = freezed,Object? energyRequirement = freezed,Object? priority = freezed,Object? archivedAt = freezed,Object? completedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_Task(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,sectionId: freezed == sectionId ? _self.sectionId : sectionId // ignore: cast_nullable_to_non_nullable
as String?,parentTaskId: freezed == parentTaskId ? _self.parentTaskId : parentTaskId // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,timeWindow: freezed == timeWindow ? _self.timeWindow : timeWindow // ignore: cast_nullable_to_non_nullable
as TimeWindow?,timeWindowStart: freezed == timeWindowStart ? _self.timeWindowStart : timeWindowStart // ignore: cast_nullable_to_non_nullable
as String?,timeWindowEnd: freezed == timeWindowEnd ? _self.timeWindowEnd : timeWindowEnd // ignore: cast_nullable_to_non_nullable
as String?,energyRequirement: freezed == energyRequirement ? _self.energyRequirement : energyRequirement // ignore: cast_nullable_to_non_nullable
as EnergyRequirement?,priority: freezed == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as TaskPriority?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
