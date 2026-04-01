// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_stake.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskStake {

 String get taskId; int? get stakeAmountCents;// null = no stake
 DateTime? get stakeModificationDeadline;// null when no stake or not yet computed
 bool get canModify;
/// Create a copy of TaskStake
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskStakeCopyWith<TaskStake> get copyWith => _$TaskStakeCopyWithImpl<TaskStake>(this as TaskStake, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskStake&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.stakeAmountCents, stakeAmountCents) || other.stakeAmountCents == stakeAmountCents)&&(identical(other.stakeModificationDeadline, stakeModificationDeadline) || other.stakeModificationDeadline == stakeModificationDeadline)&&(identical(other.canModify, canModify) || other.canModify == canModify));
}


@override
int get hashCode => Object.hash(runtimeType,taskId,stakeAmountCents,stakeModificationDeadline,canModify);

@override
String toString() {
  return 'TaskStake(taskId: $taskId, stakeAmountCents: $stakeAmountCents, stakeModificationDeadline: $stakeModificationDeadline, canModify: $canModify)';
}


}

/// @nodoc
abstract mixin class $TaskStakeCopyWith<$Res>  {
  factory $TaskStakeCopyWith(TaskStake value, $Res Function(TaskStake) _then) = _$TaskStakeCopyWithImpl;
@useResult
$Res call({
 String taskId, int? stakeAmountCents, DateTime? stakeModificationDeadline, bool canModify
});




}
/// @nodoc
class _$TaskStakeCopyWithImpl<$Res>
    implements $TaskStakeCopyWith<$Res> {
  _$TaskStakeCopyWithImpl(this._self, this._then);

  final TaskStake _self;
  final $Res Function(TaskStake) _then;

/// Create a copy of TaskStake
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? taskId = null,Object? stakeAmountCents = freezed,Object? stakeModificationDeadline = freezed,Object? canModify = null,}) {
  return _then(_self.copyWith(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,stakeAmountCents: freezed == stakeAmountCents ? _self.stakeAmountCents : stakeAmountCents // ignore: cast_nullable_to_non_nullable
as int?,stakeModificationDeadline: freezed == stakeModificationDeadline ? _self.stakeModificationDeadline : stakeModificationDeadline // ignore: cast_nullable_to_non_nullable
as DateTime?,canModify: null == canModify ? _self.canModify : canModify // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskStake].
extension TaskStakePatterns on TaskStake {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskStake value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskStake() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskStake value)  $default,){
final _that = this;
switch (_that) {
case _TaskStake():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskStake value)?  $default,){
final _that = this;
switch (_that) {
case _TaskStake() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String taskId,  int? stakeAmountCents,  DateTime? stakeModificationDeadline,  bool canModify)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskStake() when $default != null:
return $default(_that.taskId,_that.stakeAmountCents,_that.stakeModificationDeadline,_that.canModify);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String taskId,  int? stakeAmountCents,  DateTime? stakeModificationDeadline,  bool canModify)  $default,) {final _that = this;
switch (_that) {
case _TaskStake():
return $default(_that.taskId,_that.stakeAmountCents,_that.stakeModificationDeadline,_that.canModify);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String taskId,  int? stakeAmountCents,  DateTime? stakeModificationDeadline,  bool canModify)?  $default,) {final _that = this;
switch (_that) {
case _TaskStake() when $default != null:
return $default(_that.taskId,_that.stakeAmountCents,_that.stakeModificationDeadline,_that.canModify);case _:
  return null;

}
}

}

/// @nodoc


class _TaskStake implements TaskStake {
  const _TaskStake({required this.taskId, this.stakeAmountCents, this.stakeModificationDeadline, this.canModify = false});
  

@override final  String taskId;
@override final  int? stakeAmountCents;
// null = no stake
@override final  DateTime? stakeModificationDeadline;
// null when no stake or not yet computed
@override@JsonKey() final  bool canModify;

/// Create a copy of TaskStake
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskStakeCopyWith<_TaskStake> get copyWith => __$TaskStakeCopyWithImpl<_TaskStake>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskStake&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.stakeAmountCents, stakeAmountCents) || other.stakeAmountCents == stakeAmountCents)&&(identical(other.stakeModificationDeadline, stakeModificationDeadline) || other.stakeModificationDeadline == stakeModificationDeadline)&&(identical(other.canModify, canModify) || other.canModify == canModify));
}


@override
int get hashCode => Object.hash(runtimeType,taskId,stakeAmountCents,stakeModificationDeadline,canModify);

@override
String toString() {
  return 'TaskStake(taskId: $taskId, stakeAmountCents: $stakeAmountCents, stakeModificationDeadline: $stakeModificationDeadline, canModify: $canModify)';
}


}

/// @nodoc
abstract mixin class _$TaskStakeCopyWith<$Res> implements $TaskStakeCopyWith<$Res> {
  factory _$TaskStakeCopyWith(_TaskStake value, $Res Function(_TaskStake) _then) = __$TaskStakeCopyWithImpl;
@override @useResult
$Res call({
 String taskId, int? stakeAmountCents, DateTime? stakeModificationDeadline, bool canModify
});




}
/// @nodoc
class __$TaskStakeCopyWithImpl<$Res>
    implements _$TaskStakeCopyWith<$Res> {
  __$TaskStakeCopyWithImpl(this._self, this._then);

  final _TaskStake _self;
  final $Res Function(_TaskStake) _then;

/// Create a copy of TaskStake
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? taskId = null,Object? stakeAmountCents = freezed,Object? stakeModificationDeadline = freezed,Object? canModify = null,}) {
  return _then(_TaskStake(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,stakeAmountCents: freezed == stakeAmountCents ? _self.stakeAmountCents : stakeAmountCents // ignore: cast_nullable_to_non_nullable
as int?,stakeModificationDeadline: freezed == stakeModificationDeadline ? _self.stakeModificationDeadline : stakeModificationDeadline // ignore: cast_nullable_to_non_nullable
as DateTime?,canModify: null == canModify ? _self.canModify : canModify // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
