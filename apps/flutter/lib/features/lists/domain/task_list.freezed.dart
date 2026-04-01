// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'task_list.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TaskList {

 String get id; String get title; DateTime? get defaultDueDate; int get position; DateTime? get archivedAt; DateTime get createdAt; DateTime get updatedAt; bool get isShared; int get memberCount; List<String> get memberAvatarInitials; String? get assignmentStrategy;// Proof requirement for all tasks in this list (FR20). Null = no requirement.
// Valid values: 'none' | 'photo' | 'watchMode' | 'healthKit' | null
 String? get proofRequirement;
/// Create a copy of TaskList
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TaskListCopyWith<TaskList> get copyWith => _$TaskListCopyWithImpl<TaskList>(this as TaskList, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TaskList&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.defaultDueDate, defaultDueDate) || other.defaultDueDate == defaultDueDate)&&(identical(other.position, position) || other.position == position)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isShared, isShared) || other.isShared == isShared)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&const DeepCollectionEquality().equals(other.memberAvatarInitials, memberAvatarInitials)&&(identical(other.assignmentStrategy, assignmentStrategy) || other.assignmentStrategy == assignmentStrategy)&&(identical(other.proofRequirement, proofRequirement) || other.proofRequirement == proofRequirement));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,defaultDueDate,position,archivedAt,createdAt,updatedAt,isShared,memberCount,const DeepCollectionEquality().hash(memberAvatarInitials),assignmentStrategy,proofRequirement);

@override
String toString() {
  return 'TaskList(id: $id, title: $title, defaultDueDate: $defaultDueDate, position: $position, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, isShared: $isShared, memberCount: $memberCount, memberAvatarInitials: $memberAvatarInitials, assignmentStrategy: $assignmentStrategy, proofRequirement: $proofRequirement)';
}


}

/// @nodoc
abstract mixin class $TaskListCopyWith<$Res>  {
  factory $TaskListCopyWith(TaskList value, $Res Function(TaskList) _then) = _$TaskListCopyWithImpl;
@useResult
$Res call({
 String id, String title, DateTime? defaultDueDate, int position, DateTime? archivedAt, DateTime createdAt, DateTime updatedAt, bool isShared, int memberCount, List<String> memberAvatarInitials, String? assignmentStrategy, String? proofRequirement
});




}
/// @nodoc
class _$TaskListCopyWithImpl<$Res>
    implements $TaskListCopyWith<$Res> {
  _$TaskListCopyWithImpl(this._self, this._then);

  final TaskList _self;
  final $Res Function(TaskList) _then;

/// Create a copy of TaskList
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? defaultDueDate = freezed,Object? position = null,Object? archivedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isShared = null,Object? memberCount = null,Object? memberAvatarInitials = null,Object? assignmentStrategy = freezed,Object? proofRequirement = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,defaultDueDate: freezed == defaultDueDate ? _self.defaultDueDate : defaultDueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isShared: null == isShared ? _self.isShared : isShared // ignore: cast_nullable_to_non_nullable
as bool,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,memberAvatarInitials: null == memberAvatarInitials ? _self.memberAvatarInitials : memberAvatarInitials // ignore: cast_nullable_to_non_nullable
as List<String>,assignmentStrategy: freezed == assignmentStrategy ? _self.assignmentStrategy : assignmentStrategy // ignore: cast_nullable_to_non_nullable
as String?,proofRequirement: freezed == proofRequirement ? _self.proofRequirement : proofRequirement // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TaskList].
extension TaskListPatterns on TaskList {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TaskList value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TaskList() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TaskList value)  $default,){
final _that = this;
switch (_that) {
case _TaskList():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TaskList value)?  $default,){
final _that = this;
switch (_that) {
case _TaskList() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  DateTime? defaultDueDate,  int position,  DateTime? archivedAt,  DateTime createdAt,  DateTime updatedAt,  bool isShared,  int memberCount,  List<String> memberAvatarInitials,  String? assignmentStrategy,  String? proofRequirement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TaskList() when $default != null:
return $default(_that.id,_that.title,_that.defaultDueDate,_that.position,_that.archivedAt,_that.createdAt,_that.updatedAt,_that.isShared,_that.memberCount,_that.memberAvatarInitials,_that.assignmentStrategy,_that.proofRequirement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  DateTime? defaultDueDate,  int position,  DateTime? archivedAt,  DateTime createdAt,  DateTime updatedAt,  bool isShared,  int memberCount,  List<String> memberAvatarInitials,  String? assignmentStrategy,  String? proofRequirement)  $default,) {final _that = this;
switch (_that) {
case _TaskList():
return $default(_that.id,_that.title,_that.defaultDueDate,_that.position,_that.archivedAt,_that.createdAt,_that.updatedAt,_that.isShared,_that.memberCount,_that.memberAvatarInitials,_that.assignmentStrategy,_that.proofRequirement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  DateTime? defaultDueDate,  int position,  DateTime? archivedAt,  DateTime createdAt,  DateTime updatedAt,  bool isShared,  int memberCount,  List<String> memberAvatarInitials,  String? assignmentStrategy,  String? proofRequirement)?  $default,) {final _that = this;
switch (_that) {
case _TaskList() when $default != null:
return $default(_that.id,_that.title,_that.defaultDueDate,_that.position,_that.archivedAt,_that.createdAt,_that.updatedAt,_that.isShared,_that.memberCount,_that.memberAvatarInitials,_that.assignmentStrategy,_that.proofRequirement);case _:
  return null;

}
}

}

/// @nodoc


class _TaskList implements TaskList {
  const _TaskList({required this.id, required this.title, this.defaultDueDate, required this.position, this.archivedAt, required this.createdAt, required this.updatedAt, this.isShared = false, this.memberCount = 1, final  List<String> memberAvatarInitials = const <String>[], this.assignmentStrategy, this.proofRequirement}): _memberAvatarInitials = memberAvatarInitials;
  

@override final  String id;
@override final  String title;
@override final  DateTime? defaultDueDate;
@override final  int position;
@override final  DateTime? archivedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;
@override@JsonKey() final  bool isShared;
@override@JsonKey() final  int memberCount;
 final  List<String> _memberAvatarInitials;
@override@JsonKey() List<String> get memberAvatarInitials {
  if (_memberAvatarInitials is EqualUnmodifiableListView) return _memberAvatarInitials;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberAvatarInitials);
}

@override final  String? assignmentStrategy;
// Proof requirement for all tasks in this list (FR20). Null = no requirement.
// Valid values: 'none' | 'photo' | 'watchMode' | 'healthKit' | null
@override final  String? proofRequirement;

/// Create a copy of TaskList
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TaskListCopyWith<_TaskList> get copyWith => __$TaskListCopyWithImpl<_TaskList>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TaskList&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.defaultDueDate, defaultDueDate) || other.defaultDueDate == defaultDueDate)&&(identical(other.position, position) || other.position == position)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isShared, isShared) || other.isShared == isShared)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&const DeepCollectionEquality().equals(other._memberAvatarInitials, _memberAvatarInitials)&&(identical(other.assignmentStrategy, assignmentStrategy) || other.assignmentStrategy == assignmentStrategy)&&(identical(other.proofRequirement, proofRequirement) || other.proofRequirement == proofRequirement));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,defaultDueDate,position,archivedAt,createdAt,updatedAt,isShared,memberCount,const DeepCollectionEquality().hash(_memberAvatarInitials),assignmentStrategy,proofRequirement);

@override
String toString() {
  return 'TaskList(id: $id, title: $title, defaultDueDate: $defaultDueDate, position: $position, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, isShared: $isShared, memberCount: $memberCount, memberAvatarInitials: $memberAvatarInitials, assignmentStrategy: $assignmentStrategy, proofRequirement: $proofRequirement)';
}


}

/// @nodoc
abstract mixin class _$TaskListCopyWith<$Res> implements $TaskListCopyWith<$Res> {
  factory _$TaskListCopyWith(_TaskList value, $Res Function(_TaskList) _then) = __$TaskListCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, DateTime? defaultDueDate, int position, DateTime? archivedAt, DateTime createdAt, DateTime updatedAt, bool isShared, int memberCount, List<String> memberAvatarInitials, String? assignmentStrategy, String? proofRequirement
});




}
/// @nodoc
class __$TaskListCopyWithImpl<$Res>
    implements _$TaskListCopyWith<$Res> {
  __$TaskListCopyWithImpl(this._self, this._then);

  final _TaskList _self;
  final $Res Function(_TaskList) _then;

/// Create a copy of TaskList
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? defaultDueDate = freezed,Object? position = null,Object? archivedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isShared = null,Object? memberCount = null,Object? memberAvatarInitials = null,Object? assignmentStrategy = freezed,Object? proofRequirement = freezed,}) {
  return _then(_TaskList(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,defaultDueDate: freezed == defaultDueDate ? _self.defaultDueDate : defaultDueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,isShared: null == isShared ? _self.isShared : isShared // ignore: cast_nullable_to_non_nullable
as bool,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,memberAvatarInitials: null == memberAvatarInitials ? _self._memberAvatarInitials : memberAvatarInitials // ignore: cast_nullable_to_non_nullable
as List<String>,assignmentStrategy: freezed == assignmentStrategy ? _self.assignmentStrategy : assignmentStrategy // ignore: cast_nullable_to_non_nullable
as String?,proofRequirement: freezed == proofRequirement ? _self.proofRequirement : proofRequirement // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
