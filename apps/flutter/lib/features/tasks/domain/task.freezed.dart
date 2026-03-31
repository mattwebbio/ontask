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

 String get id; String get title; String? get notes; DateTime? get dueDate; String? get listId; String? get sectionId; String? get parentTaskId; int get position; TimeWindow? get timeWindow; String? get timeWindowStart; String? get timeWindowEnd; EnergyRequirement? get energyRequirement; TaskPriority? get priority; RecurrenceRule? get recurrenceRule; int? get recurrenceInterval; List<int>? get recurrenceDaysOfWeek; String? get recurrenceParentId; DateTime? get startedAt; int? get elapsedSeconds; DateTime? get archivedAt; DateTime? get completedAt; DateTime get createdAt; DateTime get updatedAt; int? get durationMinutes; DateTime? get scheduledStartTime;
/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskCopyWith<Task> get copyWith => _$TaskCopyWithImpl<Task>(this as Task, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Task&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.parentTaskId, parentTaskId) || other.parentTaskId == parentTaskId)&&(identical(other.position, position) || other.position == position)&&(identical(other.timeWindow, timeWindow) || other.timeWindow == timeWindow)&&(identical(other.timeWindowStart, timeWindowStart) || other.timeWindowStart == timeWindowStart)&&(identical(other.timeWindowEnd, timeWindowEnd) || other.timeWindowEnd == timeWindowEnd)&&(identical(other.energyRequirement, energyRequirement) || other.energyRequirement == energyRequirement)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.recurrenceRule, recurrenceRule) || other.recurrenceRule == recurrenceRule)&&(identical(other.recurrenceInterval, recurrenceInterval) || other.recurrenceInterval == recurrenceInterval)&&const DeepCollectionEquality().equals(other.recurrenceDaysOfWeek, recurrenceDaysOfWeek)&&(identical(other.recurrenceParentId, recurrenceParentId) || other.recurrenceParentId == recurrenceParentId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.scheduledStartTime, scheduledStartTime) || other.scheduledStartTime == scheduledStartTime));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,title,notes,dueDate,listId,sectionId,parentTaskId,position,timeWindow,timeWindowStart,timeWindowEnd,energyRequirement,priority,recurrenceRule,recurrenceInterval,const DeepCollectionEquality().hash(recurrenceDaysOfWeek),recurrenceParentId,startedAt,elapsedSeconds,archivedAt,completedAt,createdAt,updatedAt,durationMinutes,scheduledStartTime]);

@override
String toString() {
  return 'Task(id: $id, title: $title, notes: $notes, dueDate: $dueDate, listId: $listId, sectionId: $sectionId, parentTaskId: $parentTaskId, position: $position, timeWindow: $timeWindow, timeWindowStart: $timeWindowStart, timeWindowEnd: $timeWindowEnd, energyRequirement: $energyRequirement, priority: $priority, recurrenceRule: $recurrenceRule, recurrenceInterval: $recurrenceInterval, recurrenceDaysOfWeek: $recurrenceDaysOfWeek, recurrenceParentId: $recurrenceParentId, startedAt: $startedAt, elapsedSeconds: $elapsedSeconds, archivedAt: $archivedAt, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt, durationMinutes: $durationMinutes, scheduledStartTime: $scheduledStartTime)';
}


}

/// @nodoc
abstract mixin class $TaskCopyWith<$Res>  {
  factory $TaskCopyWith(Task value, $Res Function(Task) _then) = _$TaskCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? notes, DateTime? dueDate, String? listId, String? sectionId, String? parentTaskId, int position, TimeWindow? timeWindow, String? timeWindowStart, String? timeWindowEnd, EnergyRequirement? energyRequirement, TaskPriority? priority, RecurrenceRule? recurrenceRule, int? recurrenceInterval, List<int>? recurrenceDaysOfWeek, String? recurrenceParentId, DateTime? startedAt, int? elapsedSeconds, DateTime? archivedAt, DateTime? completedAt, DateTime createdAt, DateTime updatedAt, int? durationMinutes, DateTime? scheduledStartTime
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? notes = freezed,Object? dueDate = freezed,Object? listId = freezed,Object? sectionId = freezed,Object? parentTaskId = freezed,Object? position = null,Object? timeWindow = freezed,Object? timeWindowStart = freezed,Object? timeWindowEnd = freezed,Object? energyRequirement = freezed,Object? priority = freezed,Object? recurrenceRule = freezed,Object? recurrenceInterval = freezed,Object? recurrenceDaysOfWeek = freezed,Object? recurrenceParentId = freezed,Object? startedAt = freezed,Object? elapsedSeconds = freezed,Object? archivedAt = freezed,Object? completedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? durationMinutes = freezed,Object? scheduledStartTime = freezed,}) {
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
as TaskPriority?,recurrenceRule: freezed == recurrenceRule ? _self.recurrenceRule : recurrenceRule // ignore: cast_nullable_to_non_nullable
as RecurrenceRule?,recurrenceInterval: freezed == recurrenceInterval ? _self.recurrenceInterval : recurrenceInterval // ignore: cast_nullable_to_non_nullable
as int?,recurrenceDaysOfWeek: freezed == recurrenceDaysOfWeek ? _self.recurrenceDaysOfWeek : recurrenceDaysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>?,recurrenceParentId: freezed == recurrenceParentId ? _self.recurrenceParentId : recurrenceParentId // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,elapsedSeconds: freezed == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,durationMinutes: freezed == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int?,scheduledStartTime: freezed == scheduledStartTime ? _self.scheduledStartTime : scheduledStartTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? notes,  DateTime? dueDate,  String? listId,  String? sectionId,  String? parentTaskId,  int position,  TimeWindow? timeWindow,  String? timeWindowStart,  String? timeWindowEnd,  EnergyRequirement? energyRequirement,  TaskPriority? priority,  RecurrenceRule? recurrenceRule,  int? recurrenceInterval,  List<int>? recurrenceDaysOfWeek,  String? recurrenceParentId,  DateTime? startedAt,  int? elapsedSeconds,  DateTime? archivedAt,  DateTime? completedAt,  DateTime createdAt,  DateTime updatedAt,  int? durationMinutes,  DateTime? scheduledStartTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.title,_that.notes,_that.dueDate,_that.listId,_that.sectionId,_that.parentTaskId,_that.position,_that.timeWindow,_that.timeWindowStart,_that.timeWindowEnd,_that.energyRequirement,_that.priority,_that.recurrenceRule,_that.recurrenceInterval,_that.recurrenceDaysOfWeek,_that.recurrenceParentId,_that.startedAt,_that.elapsedSeconds,_that.archivedAt,_that.completedAt,_that.createdAt,_that.updatedAt,_that.durationMinutes,_that.scheduledStartTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? notes,  DateTime? dueDate,  String? listId,  String? sectionId,  String? parentTaskId,  int position,  TimeWindow? timeWindow,  String? timeWindowStart,  String? timeWindowEnd,  EnergyRequirement? energyRequirement,  TaskPriority? priority,  RecurrenceRule? recurrenceRule,  int? recurrenceInterval,  List<int>? recurrenceDaysOfWeek,  String? recurrenceParentId,  DateTime? startedAt,  int? elapsedSeconds,  DateTime? archivedAt,  DateTime? completedAt,  DateTime createdAt,  DateTime updatedAt,  int? durationMinutes,  DateTime? scheduledStartTime)  $default,) {final _that = this;
switch (_that) {
case _Task():
return $default(_that.id,_that.title,_that.notes,_that.dueDate,_that.listId,_that.sectionId,_that.parentTaskId,_that.position,_that.timeWindow,_that.timeWindowStart,_that.timeWindowEnd,_that.energyRequirement,_that.priority,_that.recurrenceRule,_that.recurrenceInterval,_that.recurrenceDaysOfWeek,_that.recurrenceParentId,_that.startedAt,_that.elapsedSeconds,_that.archivedAt,_that.completedAt,_that.createdAt,_that.updatedAt,_that.durationMinutes,_that.scheduledStartTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? notes,  DateTime? dueDate,  String? listId,  String? sectionId,  String? parentTaskId,  int position,  TimeWindow? timeWindow,  String? timeWindowStart,  String? timeWindowEnd,  EnergyRequirement? energyRequirement,  TaskPriority? priority,  RecurrenceRule? recurrenceRule,  int? recurrenceInterval,  List<int>? recurrenceDaysOfWeek,  String? recurrenceParentId,  DateTime? startedAt,  int? elapsedSeconds,  DateTime? archivedAt,  DateTime? completedAt,  DateTime createdAt,  DateTime updatedAt,  int? durationMinutes,  DateTime? scheduledStartTime)?  $default,) {final _that = this;
switch (_that) {
case _Task() when $default != null:
return $default(_that.id,_that.title,_that.notes,_that.dueDate,_that.listId,_that.sectionId,_that.parentTaskId,_that.position,_that.timeWindow,_that.timeWindowStart,_that.timeWindowEnd,_that.energyRequirement,_that.priority,_that.recurrenceRule,_that.recurrenceInterval,_that.recurrenceDaysOfWeek,_that.recurrenceParentId,_that.startedAt,_that.elapsedSeconds,_that.archivedAt,_that.completedAt,_that.createdAt,_that.updatedAt,_that.durationMinutes,_that.scheduledStartTime);case _:
  return null;

}
}

}

/// @nodoc


class _Task implements Task {
  const _Task({required this.id, required this.title, this.notes, this.dueDate, this.listId, this.sectionId, this.parentTaskId, required this.position, this.timeWindow, this.timeWindowStart, this.timeWindowEnd, this.energyRequirement, this.priority = TaskPriority.normal, this.recurrenceRule, this.recurrenceInterval, final  List<int>? recurrenceDaysOfWeek, this.recurrenceParentId, this.startedAt, this.elapsedSeconds, this.archivedAt, this.completedAt, required this.createdAt, required this.updatedAt, this.durationMinutes, this.scheduledStartTime}): _recurrenceDaysOfWeek = recurrenceDaysOfWeek;
  

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
@override final  RecurrenceRule? recurrenceRule;
@override final  int? recurrenceInterval;
 final  List<int>? _recurrenceDaysOfWeek;
@override List<int>? get recurrenceDaysOfWeek {
  final value = _recurrenceDaysOfWeek;
  if (value == null) return null;
  if (_recurrenceDaysOfWeek is EqualUnmodifiableListView) return _recurrenceDaysOfWeek;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? recurrenceParentId;
@override final  DateTime? startedAt;
@override final  int? elapsedSeconds;
@override final  DateTime? archivedAt;
@override final  DateTime? completedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override final  int? durationMinutes;
@override final  DateTime? scheduledStartTime;

/// Create a copy of Task
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskCopyWith<_Task> get copyWith => __$TaskCopyWithImpl<_Task>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Task&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.sectionId, sectionId) || other.sectionId == sectionId)&&(identical(other.parentTaskId, parentTaskId) || other.parentTaskId == parentTaskId)&&(identical(other.position, position) || other.position == position)&&(identical(other.timeWindow, timeWindow) || other.timeWindow == timeWindow)&&(identical(other.timeWindowStart, timeWindowStart) || other.timeWindowStart == timeWindowStart)&&(identical(other.timeWindowEnd, timeWindowEnd) || other.timeWindowEnd == timeWindowEnd)&&(identical(other.energyRequirement, energyRequirement) || other.energyRequirement == energyRequirement)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.recurrenceRule, recurrenceRule) || other.recurrenceRule == recurrenceRule)&&(identical(other.recurrenceInterval, recurrenceInterval) || other.recurrenceInterval == recurrenceInterval)&&const DeepCollectionEquality().equals(other._recurrenceDaysOfWeek, _recurrenceDaysOfWeek)&&(identical(other.recurrenceParentId, recurrenceParentId) || other.recurrenceParentId == recurrenceParentId)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes)&&(identical(other.scheduledStartTime, scheduledStartTime) || other.scheduledStartTime == scheduledStartTime));
}


@override
int get hashCode => Object.hashAll([runtimeType,id,title,notes,dueDate,listId,sectionId,parentTaskId,position,timeWindow,timeWindowStart,timeWindowEnd,energyRequirement,priority,recurrenceRule,recurrenceInterval,const DeepCollectionEquality().hash(_recurrenceDaysOfWeek),recurrenceParentId,startedAt,elapsedSeconds,archivedAt,completedAt,createdAt,updatedAt,durationMinutes,scheduledStartTime]);

@override
String toString() {
  return 'Task(id: $id, title: $title, notes: $notes, dueDate: $dueDate, listId: $listId, sectionId: $sectionId, parentTaskId: $parentTaskId, position: $position, timeWindow: $timeWindow, timeWindowStart: $timeWindowStart, timeWindowEnd: $timeWindowEnd, energyRequirement: $energyRequirement, priority: $priority, recurrenceRule: $recurrenceRule, recurrenceInterval: $recurrenceInterval, recurrenceDaysOfWeek: $recurrenceDaysOfWeek, recurrenceParentId: $recurrenceParentId, startedAt: $startedAt, elapsedSeconds: $elapsedSeconds, archivedAt: $archivedAt, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt, durationMinutes: $durationMinutes, scheduledStartTime: $scheduledStartTime)';
}


}

/// @nodoc
abstract mixin class _$TaskCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$TaskCopyWith(_Task value, $Res Function(_Task) _then) = __$TaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? notes, DateTime? dueDate, String? listId, String? sectionId, String? parentTaskId, int position, TimeWindow? timeWindow, String? timeWindowStart, String? timeWindowEnd, EnergyRequirement? energyRequirement, TaskPriority? priority, RecurrenceRule? recurrenceRule, int? recurrenceInterval, List<int>? recurrenceDaysOfWeek, String? recurrenceParentId, DateTime? startedAt, int? elapsedSeconds, DateTime? archivedAt, DateTime? completedAt, DateTime createdAt, DateTime updatedAt, int? durationMinutes, DateTime? scheduledStartTime
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? notes = freezed,Object? dueDate = freezed,Object? listId = freezed,Object? sectionId = freezed,Object? parentTaskId = freezed,Object? position = null,Object? timeWindow = freezed,Object? timeWindowStart = freezed,Object? timeWindowEnd = freezed,Object? energyRequirement = freezed,Object? priority = freezed,Object? recurrenceRule = freezed,Object? recurrenceInterval = freezed,Object? recurrenceDaysOfWeek = freezed,Object? recurrenceParentId = freezed,Object? startedAt = freezed,Object? elapsedSeconds = freezed,Object? archivedAt = freezed,Object? completedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? durationMinutes = freezed,Object? scheduledStartTime = freezed,}) {
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
as TaskPriority?,recurrenceRule: freezed == recurrenceRule ? _self.recurrenceRule : recurrenceRule // ignore: cast_nullable_to_non_nullable
as RecurrenceRule?,recurrenceInterval: freezed == recurrenceInterval ? _self.recurrenceInterval : recurrenceInterval // ignore: cast_nullable_to_non_nullable
as int?,recurrenceDaysOfWeek: freezed == recurrenceDaysOfWeek ? _self._recurrenceDaysOfWeek : recurrenceDaysOfWeek // ignore: cast_nullable_to_non_nullable
as List<int>?,recurrenceParentId: freezed == recurrenceParentId ? _self.recurrenceParentId : recurrenceParentId // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,elapsedSeconds: freezed == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int?,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,durationMinutes: freezed == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int?,scheduledStartTime: freezed == scheduledStartTime ? _self.scheduledStartTime : scheduledStartTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
