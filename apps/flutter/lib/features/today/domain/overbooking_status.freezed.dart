// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'overbooking_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OverbookedTask {

 String get taskId; String get taskTitle; bool get hasStake; int get durationMinutes;
/// Create a copy of OverbookedTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverbookedTaskCopyWith<OverbookedTask> get copyWith => _$OverbookedTaskCopyWithImpl<OverbookedTask>(this as OverbookedTask, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverbookedTask&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.taskTitle, taskTitle) || other.taskTitle == taskTitle)&&(identical(other.hasStake, hasStake) || other.hasStake == hasStake)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes));
}


@override
int get hashCode => Object.hash(runtimeType,taskId,taskTitle,hasStake,durationMinutes);

@override
String toString() {
  return 'OverbookedTask(taskId: $taskId, taskTitle: $taskTitle, hasStake: $hasStake, durationMinutes: $durationMinutes)';
}


}

/// @nodoc
abstract mixin class $OverbookedTaskCopyWith<$Res>  {
  factory $OverbookedTaskCopyWith(OverbookedTask value, $Res Function(OverbookedTask) _then) = _$OverbookedTaskCopyWithImpl;
@useResult
$Res call({
 String taskId, String taskTitle, bool hasStake, int durationMinutes
});




}
/// @nodoc
class _$OverbookedTaskCopyWithImpl<$Res>
    implements $OverbookedTaskCopyWith<$Res> {
  _$OverbookedTaskCopyWithImpl(this._self, this._then);

  final OverbookedTask _self;
  final $Res Function(OverbookedTask) _then;

/// Create a copy of OverbookedTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? taskId = null,Object? taskTitle = null,Object? hasStake = null,Object? durationMinutes = null,}) {
  return _then(_self.copyWith(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,taskTitle: null == taskTitle ? _self.taskTitle : taskTitle // ignore: cast_nullable_to_non_nullable
as String,hasStake: null == hasStake ? _self.hasStake : hasStake // ignore: cast_nullable_to_non_nullable
as bool,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [OverbookedTask].
extension OverbookedTaskPatterns on OverbookedTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OverbookedTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OverbookedTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OverbookedTask value)  $default,){
final _that = this;
switch (_that) {
case _OverbookedTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OverbookedTask value)?  $default,){
final _that = this;
switch (_that) {
case _OverbookedTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String taskId,  String taskTitle,  bool hasStake,  int durationMinutes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OverbookedTask() when $default != null:
return $default(_that.taskId,_that.taskTitle,_that.hasStake,_that.durationMinutes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String taskId,  String taskTitle,  bool hasStake,  int durationMinutes)  $default,) {final _that = this;
switch (_that) {
case _OverbookedTask():
return $default(_that.taskId,_that.taskTitle,_that.hasStake,_that.durationMinutes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String taskId,  String taskTitle,  bool hasStake,  int durationMinutes)?  $default,) {final _that = this;
switch (_that) {
case _OverbookedTask() when $default != null:
return $default(_that.taskId,_that.taskTitle,_that.hasStake,_that.durationMinutes);case _:
  return null;

}
}

}

/// @nodoc


class _OverbookedTask implements OverbookedTask {
  const _OverbookedTask({required this.taskId, required this.taskTitle, required this.hasStake, required this.durationMinutes});
  

@override final  String taskId;
@override final  String taskTitle;
@override final  bool hasStake;
@override final  int durationMinutes;

/// Create a copy of OverbookedTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverbookedTaskCopyWith<_OverbookedTask> get copyWith => __$OverbookedTaskCopyWithImpl<_OverbookedTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OverbookedTask&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.taskTitle, taskTitle) || other.taskTitle == taskTitle)&&(identical(other.hasStake, hasStake) || other.hasStake == hasStake)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes));
}


@override
int get hashCode => Object.hash(runtimeType,taskId,taskTitle,hasStake,durationMinutes);

@override
String toString() {
  return 'OverbookedTask(taskId: $taskId, taskTitle: $taskTitle, hasStake: $hasStake, durationMinutes: $durationMinutes)';
}


}

/// @nodoc
abstract mixin class _$OverbookedTaskCopyWith<$Res> implements $OverbookedTaskCopyWith<$Res> {
  factory _$OverbookedTaskCopyWith(_OverbookedTask value, $Res Function(_OverbookedTask) _then) = __$OverbookedTaskCopyWithImpl;
@override @useResult
$Res call({
 String taskId, String taskTitle, bool hasStake, int durationMinutes
});




}
/// @nodoc
class __$OverbookedTaskCopyWithImpl<$Res>
    implements _$OverbookedTaskCopyWith<$Res> {
  __$OverbookedTaskCopyWithImpl(this._self, this._then);

  final _OverbookedTask _self;
  final $Res Function(_OverbookedTask) _then;

/// Create a copy of OverbookedTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? taskId = null,Object? taskTitle = null,Object? hasStake = null,Object? durationMinutes = null,}) {
  return _then(_OverbookedTask(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,taskTitle: null == taskTitle ? _self.taskTitle : taskTitle // ignore: cast_nullable_to_non_nullable
as String,hasStake: null == hasStake ? _self.hasStake : hasStake // ignore: cast_nullable_to_non_nullable
as bool,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$OverbookingStatus {

 bool get isOverbooked; OverbookingSeverity get severity; double get capacityPercent; List<OverbookedTask> get overbookedTasks;
/// Create a copy of OverbookingStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverbookingStatusCopyWith<OverbookingStatus> get copyWith => _$OverbookingStatusCopyWithImpl<OverbookingStatus>(this as OverbookingStatus, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverbookingStatus&&(identical(other.isOverbooked, isOverbooked) || other.isOverbooked == isOverbooked)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.capacityPercent, capacityPercent) || other.capacityPercent == capacityPercent)&&const DeepCollectionEquality().equals(other.overbookedTasks, overbookedTasks));
}


@override
int get hashCode => Object.hash(runtimeType,isOverbooked,severity,capacityPercent,const DeepCollectionEquality().hash(overbookedTasks));

@override
String toString() {
  return 'OverbookingStatus(isOverbooked: $isOverbooked, severity: $severity, capacityPercent: $capacityPercent, overbookedTasks: $overbookedTasks)';
}


}

/// @nodoc
abstract mixin class $OverbookingStatusCopyWith<$Res>  {
  factory $OverbookingStatusCopyWith(OverbookingStatus value, $Res Function(OverbookingStatus) _then) = _$OverbookingStatusCopyWithImpl;
@useResult
$Res call({
 bool isOverbooked, OverbookingSeverity severity, double capacityPercent, List<OverbookedTask> overbookedTasks
});




}
/// @nodoc
class _$OverbookingStatusCopyWithImpl<$Res>
    implements $OverbookingStatusCopyWith<$Res> {
  _$OverbookingStatusCopyWithImpl(this._self, this._then);

  final OverbookingStatus _self;
  final $Res Function(OverbookingStatus) _then;

/// Create a copy of OverbookingStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isOverbooked = null,Object? severity = null,Object? capacityPercent = null,Object? overbookedTasks = null,}) {
  return _then(_self.copyWith(
isOverbooked: null == isOverbooked ? _self.isOverbooked : isOverbooked // ignore: cast_nullable_to_non_nullable
as bool,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as OverbookingSeverity,capacityPercent: null == capacityPercent ? _self.capacityPercent : capacityPercent // ignore: cast_nullable_to_non_nullable
as double,overbookedTasks: null == overbookedTasks ? _self.overbookedTasks : overbookedTasks // ignore: cast_nullable_to_non_nullable
as List<OverbookedTask>,
  ));
}

}


/// Adds pattern-matching-related methods to [OverbookingStatus].
extension OverbookingStatusPatterns on OverbookingStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OverbookingStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OverbookingStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OverbookingStatus value)  $default,){
final _that = this;
switch (_that) {
case _OverbookingStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OverbookingStatus value)?  $default,){
final _that = this;
switch (_that) {
case _OverbookingStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isOverbooked,  OverbookingSeverity severity,  double capacityPercent,  List<OverbookedTask> overbookedTasks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OverbookingStatus() when $default != null:
return $default(_that.isOverbooked,_that.severity,_that.capacityPercent,_that.overbookedTasks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isOverbooked,  OverbookingSeverity severity,  double capacityPercent,  List<OverbookedTask> overbookedTasks)  $default,) {final _that = this;
switch (_that) {
case _OverbookingStatus():
return $default(_that.isOverbooked,_that.severity,_that.capacityPercent,_that.overbookedTasks);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isOverbooked,  OverbookingSeverity severity,  double capacityPercent,  List<OverbookedTask> overbookedTasks)?  $default,) {final _that = this;
switch (_that) {
case _OverbookingStatus() when $default != null:
return $default(_that.isOverbooked,_that.severity,_that.capacityPercent,_that.overbookedTasks);case _:
  return null;

}
}

}

/// @nodoc


class _OverbookingStatus implements OverbookingStatus {
  const _OverbookingStatus({required this.isOverbooked, required this.severity, required this.capacityPercent, required final  List<OverbookedTask> overbookedTasks}): _overbookedTasks = overbookedTasks;
  

@override final  bool isOverbooked;
@override final  OverbookingSeverity severity;
@override final  double capacityPercent;
 final  List<OverbookedTask> _overbookedTasks;
@override List<OverbookedTask> get overbookedTasks {
  if (_overbookedTasks is EqualUnmodifiableListView) return _overbookedTasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_overbookedTasks);
}


/// Create a copy of OverbookingStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverbookingStatusCopyWith<_OverbookingStatus> get copyWith => __$OverbookingStatusCopyWithImpl<_OverbookingStatus>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OverbookingStatus&&(identical(other.isOverbooked, isOverbooked) || other.isOverbooked == isOverbooked)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.capacityPercent, capacityPercent) || other.capacityPercent == capacityPercent)&&const DeepCollectionEquality().equals(other._overbookedTasks, _overbookedTasks));
}


@override
int get hashCode => Object.hash(runtimeType,isOverbooked,severity,capacityPercent,const DeepCollectionEquality().hash(_overbookedTasks));

@override
String toString() {
  return 'OverbookingStatus(isOverbooked: $isOverbooked, severity: $severity, capacityPercent: $capacityPercent, overbookedTasks: $overbookedTasks)';
}


}

/// @nodoc
abstract mixin class _$OverbookingStatusCopyWith<$Res> implements $OverbookingStatusCopyWith<$Res> {
  factory _$OverbookingStatusCopyWith(_OverbookingStatus value, $Res Function(_OverbookingStatus) _then) = __$OverbookingStatusCopyWithImpl;
@override @useResult
$Res call({
 bool isOverbooked, OverbookingSeverity severity, double capacityPercent, List<OverbookedTask> overbookedTasks
});




}
/// @nodoc
class __$OverbookingStatusCopyWithImpl<$Res>
    implements _$OverbookingStatusCopyWith<$Res> {
  __$OverbookingStatusCopyWithImpl(this._self, this._then);

  final _OverbookingStatus _self;
  final $Res Function(_OverbookingStatus) _then;

/// Create a copy of OverbookingStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isOverbooked = null,Object? severity = null,Object? capacityPercent = null,Object? overbookedTasks = null,}) {
  return _then(_OverbookingStatus(
isOverbooked: null == isOverbooked ? _self.isOverbooked : isOverbooked // ignore: cast_nullable_to_non_nullable
as bool,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as OverbookingSeverity,capacityPercent: null == capacityPercent ? _self.capacityPercent : capacityPercent // ignore: cast_nullable_to_non_nullable
as double,overbookedTasks: null == overbookedTasks ? _self._overbookedTasks : overbookedTasks // ignore: cast_nullable_to_non_nullable
as List<OverbookedTask>,
  ));
}


}

// dart format on
