// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_dependency_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TaskDependencyDto {

 String get id; String get dependentTaskId; String get dependsOnTaskId; String get createdAt;
/// Create a copy of TaskDependencyDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskDependencyDtoCopyWith<TaskDependencyDto> get copyWith => _$TaskDependencyDtoCopyWithImpl<TaskDependencyDto>(this as TaskDependencyDto, _$identity);

  /// Serializes this TaskDependencyDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskDependencyDto&&(identical(other.id, id) || other.id == id)&&(identical(other.dependentTaskId, dependentTaskId) || other.dependentTaskId == dependentTaskId)&&(identical(other.dependsOnTaskId, dependsOnTaskId) || other.dependsOnTaskId == dependsOnTaskId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,dependentTaskId,dependsOnTaskId,createdAt);

@override
String toString() {
  return 'TaskDependencyDto(id: $id, dependentTaskId: $dependentTaskId, dependsOnTaskId: $dependsOnTaskId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $TaskDependencyDtoCopyWith<$Res>  {
  factory $TaskDependencyDtoCopyWith(TaskDependencyDto value, $Res Function(TaskDependencyDto) _then) = _$TaskDependencyDtoCopyWithImpl;
@useResult
$Res call({
 String id, String dependentTaskId, String dependsOnTaskId, String createdAt
});




}
/// @nodoc
class _$TaskDependencyDtoCopyWithImpl<$Res>
    implements $TaskDependencyDtoCopyWith<$Res> {
  _$TaskDependencyDtoCopyWithImpl(this._self, this._then);

  final TaskDependencyDto _self;
  final $Res Function(TaskDependencyDto) _then;

/// Create a copy of TaskDependencyDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? dependentTaskId = null,Object? dependsOnTaskId = null,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dependentTaskId: null == dependentTaskId ? _self.dependentTaskId : dependentTaskId // ignore: cast_nullable_to_non_nullable
as String,dependsOnTaskId: null == dependsOnTaskId ? _self.dependsOnTaskId : dependsOnTaskId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskDependencyDto].
extension TaskDependencyDtoPatterns on TaskDependencyDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskDependencyDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskDependencyDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskDependencyDto value)  $default,){
final _that = this;
switch (_that) {
case _TaskDependencyDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskDependencyDto value)?  $default,){
final _that = this;
switch (_that) {
case _TaskDependencyDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String dependentTaskId,  String dependsOnTaskId,  String createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskDependencyDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String dependentTaskId,  String dependsOnTaskId,  String createdAt)  $default,) {final _that = this;
switch (_that) {
case _TaskDependencyDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String dependentTaskId,  String dependsOnTaskId,  String createdAt)?  $default,) {final _that = this;
switch (_that) {
case _TaskDependencyDto() when $default != null:
return $default(_that.id,_that.dependentTaskId,_that.dependsOnTaskId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TaskDependencyDto extends TaskDependencyDto {
  const _TaskDependencyDto({required this.id, required this.dependentTaskId, required this.dependsOnTaskId, required this.createdAt}): super._();
  factory _TaskDependencyDto.fromJson(Map<String, dynamic> json) => _$TaskDependencyDtoFromJson(json);

@override final  String id;
@override final  String dependentTaskId;
@override final  String dependsOnTaskId;
@override final  String createdAt;

/// Create a copy of TaskDependencyDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskDependencyDtoCopyWith<_TaskDependencyDto> get copyWith => __$TaskDependencyDtoCopyWithImpl<_TaskDependencyDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TaskDependencyDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskDependencyDto&&(identical(other.id, id) || other.id == id)&&(identical(other.dependentTaskId, dependentTaskId) || other.dependentTaskId == dependentTaskId)&&(identical(other.dependsOnTaskId, dependsOnTaskId) || other.dependsOnTaskId == dependsOnTaskId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,dependentTaskId,dependsOnTaskId,createdAt);

@override
String toString() {
  return 'TaskDependencyDto(id: $id, dependentTaskId: $dependentTaskId, dependsOnTaskId: $dependsOnTaskId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$TaskDependencyDtoCopyWith<$Res> implements $TaskDependencyDtoCopyWith<$Res> {
  factory _$TaskDependencyDtoCopyWith(_TaskDependencyDto value, $Res Function(_TaskDependencyDto) _then) = __$TaskDependencyDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String dependentTaskId, String dependsOnTaskId, String createdAt
});




}
/// @nodoc
class __$TaskDependencyDtoCopyWithImpl<$Res>
    implements _$TaskDependencyDtoCopyWith<$Res> {
  __$TaskDependencyDtoCopyWithImpl(this._self, this._then);

  final _TaskDependencyDto _self;
  final $Res Function(_TaskDependencyDto) _then;

/// Create a copy of TaskDependencyDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? dependentTaskId = null,Object? dependsOnTaskId = null,Object? createdAt = null,}) {
  return _then(_TaskDependencyDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,dependentTaskId: null == dependentTaskId ? _self.dependentTaskId : dependentTaskId // ignore: cast_nullable_to_non_nullable
as String,dependsOnTaskId: null == dependsOnTaskId ? _self.dependsOnTaskId : dependsOnTaskId // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
