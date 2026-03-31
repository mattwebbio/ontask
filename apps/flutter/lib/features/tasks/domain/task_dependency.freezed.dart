// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_dependency.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskDependency {

 String get id; String get dependentTaskId; String get dependsOnTaskId; DateTime get createdAt;
/// Create a copy of TaskDependency
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskDependencyCopyWith<TaskDependency> get copyWith => _$TaskDependencyCopyWithImpl<TaskDependency>(this as TaskDependency, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDependency&&(identical(other.id, id) || other.id == id)&&(identical(other.dependentTaskId, dependentTaskId) || other.dependentTaskId == dependentTaskId)&&(identical(other.dependsOnTaskId, dependsOnTaskId) || other.dependsOnTaskId == dependsOnTaskId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,dependentTaskId,dependsOnTaskId,createdAt);

@override
String toString() {
  return 'TaskDependency(id: $id, dependentTaskId: $dependentTaskId, dependsOnTaskId: $dependsOnTaskId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TaskDependencyCopyWith<$Res>  {
  factory $TaskDependencyCopyWith(TaskDependency value, $Res Function(TaskDependency) _then) = _$TaskDependencyCopyWithImpl;
@useResult
$Res call({
 String id, String dependentTaskId, String dependsOnTaskId, DateTime createdAt
});




}
/// @nodoc
class _$TaskDependencyCopyWithImpl<$Res>
    implements $TaskDependencyCopyWith<$Res> {
  _$TaskDependencyCopyWithImpl(this._self, this._then);

  final TaskDependency _self;
  final $Res Function(TaskDependency) _then;

/// Create a copy of TaskDependency
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? dependentTaskId = null,Object? dependsOnTaskId = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dependentTaskId: null == dependentTaskId ? _self.dependentTaskId : dependentTaskId // ignore: cast_nullable_to_non_nullable
as String,dependsOnTaskId: null == dependsOnTaskId ? _self.dependsOnTaskId : dependsOnTaskId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskDependency].
extension TaskDependencyPatterns on TaskDependency {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskDependency value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskDependency() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskDependency value)  $default,){
final _that = this;
switch (_that) {
case _TaskDependency():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskDependency value)?  $default,){
final _that = this;
switch (_that) {
case _TaskDependency() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String dependentTaskId,  String dependsOnTaskId,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskDependency() when $default != null:
return $default(_that.id,_that.dependentTaskId,_that.dependsOnTaskId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String dependentTaskId,  String dependsOnTaskId,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _TaskDependency():
return $default(_that.id,_that.dependentTaskId,_that.dependsOnTaskId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String dependentTaskId,  String dependsOnTaskId,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TaskDependency() when $default != null:
return $default(_that.id,_that.dependentTaskId,_that.dependsOnTaskId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _TaskDependency implements TaskDependency {
  const _TaskDependency({required this.id, required this.dependentTaskId, required this.dependsOnTaskId, required this.createdAt});
  

@override final  String id;
@override final  String dependentTaskId;
@override final  String dependsOnTaskId;
@override final  DateTime createdAt;

/// Create a copy of TaskDependency
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDependencyCopyWith<_TaskDependency> get copyWith => __$TaskDependencyCopyWithImpl<_TaskDependency>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDependency&&(identical(other.id, id) || other.id == id)&&(identical(other.dependentTaskId, dependentTaskId) || other.dependentTaskId == dependentTaskId)&&(identical(other.dependsOnTaskId, dependsOnTaskId) || other.dependsOnTaskId == dependsOnTaskId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,dependentTaskId,dependsOnTaskId,createdAt);

@override
String toString() {
  return 'TaskDependency(id: $id, dependentTaskId: $dependentTaskId, dependsOnTaskId: $dependsOnTaskId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TaskDependencyCopyWith<$Res> implements $TaskDependencyCopyWith<$Res> {
  factory _$TaskDependencyCopyWith(_TaskDependency value, $Res Function(_TaskDependency) _then) = __$TaskDependencyCopyWithImpl;
@override @useResult
$Res call({
 String id, String dependentTaskId, String dependsOnTaskId, DateTime createdAt
});




}
/// @nodoc
class __$TaskDependencyCopyWithImpl<$Res>
    implements _$TaskDependencyCopyWith<$Res> {
  __$TaskDependencyCopyWithImpl(this._self, this._then);

  final _TaskDependency _self;
  final $Res Function(_TaskDependency) _then;

/// Create a copy of TaskDependency
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? dependentTaskId = null,Object? dependsOnTaskId = null,Object? createdAt = null,}) {
  return _then(_TaskDependency(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dependentTaskId: null == dependentTaskId ? _self.dependentTaskId : dependentTaskId // ignore: cast_nullable_to_non_nullable
as String,dependsOnTaskId: null == dependsOnTaskId ? _self.dependsOnTaskId : dependsOnTaskId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
