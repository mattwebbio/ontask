// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'now_task.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NowTask {

 String get id; String get title; String? get notes; DateTime? get dueDate; String? get listId; String? get listName; String? get assignorName; int? get stakeAmountCents; ProofMode get proofMode; DateTime? get completedAt; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of NowTask
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NowTaskCopyWith<NowTask> get copyWith => _$NowTaskCopyWithImpl<NowTask>(this as NowTask, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NowTask&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.listName, listName) || other.listName == listName)&&(identical(other.assignorName, assignorName) || other.assignorName == assignorName)&&(identical(other.stakeAmountCents, stakeAmountCents) || other.stakeAmountCents == stakeAmountCents)&&(identical(other.proofMode, proofMode) || other.proofMode == proofMode)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,notes,dueDate,listId,listName,assignorName,stakeAmountCents,proofMode,completedAt,createdAt,updatedAt);

@override
String toString() {
  return 'NowTask(id: $id, title: $title, notes: $notes, dueDate: $dueDate, listId: $listId, listName: $listName, assignorName: $assignorName, stakeAmountCents: $stakeAmountCents, proofMode: $proofMode, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $NowTaskCopyWith<$Res>  {
  factory $NowTaskCopyWith(NowTask value, $Res Function(NowTask) _then) = _$NowTaskCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? notes, DateTime? dueDate, String? listId, String? listName, String? assignorName, int? stakeAmountCents, ProofMode proofMode, DateTime? completedAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$NowTaskCopyWithImpl<$Res>
    implements $NowTaskCopyWith<$Res> {
  _$NowTaskCopyWithImpl(this._self, this._then);

  final NowTask _self;
  final $Res Function(NowTask) _then;

/// Create a copy of NowTask
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? notes = freezed,Object? dueDate = freezed,Object? listId = freezed,Object? listName = freezed,Object? assignorName = freezed,Object? stakeAmountCents = freezed,Object? proofMode = null,Object? completedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,listName: freezed == listName ? _self.listName : listName // ignore: cast_nullable_to_non_nullable
as String?,assignorName: freezed == assignorName ? _self.assignorName : assignorName // ignore: cast_nullable_to_non_nullable
as String?,stakeAmountCents: freezed == stakeAmountCents ? _self.stakeAmountCents : stakeAmountCents // ignore: cast_nullable_to_non_nullable
as int?,proofMode: null == proofMode ? _self.proofMode : proofMode // ignore: cast_nullable_to_non_nullable
as ProofMode,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [NowTask].
extension NowTaskPatterns on NowTask {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NowTask value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NowTask() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NowTask value)  $default,){
final _that = this;
switch (_that) {
case _NowTask():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NowTask value)?  $default,){
final _that = this;
switch (_that) {
case _NowTask() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? notes,  DateTime? dueDate,  String? listId,  String? listName,  String? assignorName,  int? stakeAmountCents,  ProofMode proofMode,  DateTime? completedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NowTask() when $default != null:
return $default(_that.id,_that.title,_that.notes,_that.dueDate,_that.listId,_that.listName,_that.assignorName,_that.stakeAmountCents,_that.proofMode,_that.completedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? notes,  DateTime? dueDate,  String? listId,  String? listName,  String? assignorName,  int? stakeAmountCents,  ProofMode proofMode,  DateTime? completedAt,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _NowTask():
return $default(_that.id,_that.title,_that.notes,_that.dueDate,_that.listId,_that.listName,_that.assignorName,_that.stakeAmountCents,_that.proofMode,_that.completedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? notes,  DateTime? dueDate,  String? listId,  String? listName,  String? assignorName,  int? stakeAmountCents,  ProofMode proofMode,  DateTime? completedAt,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _NowTask() when $default != null:
return $default(_that.id,_that.title,_that.notes,_that.dueDate,_that.listId,_that.listName,_that.assignorName,_that.stakeAmountCents,_that.proofMode,_that.completedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _NowTask implements NowTask {
  const _NowTask({required this.id, required this.title, this.notes, this.dueDate, this.listId, this.listName, this.assignorName, this.stakeAmountCents, this.proofMode = ProofMode.standard, this.completedAt, required this.createdAt, required this.updatedAt});
  

@override final  String id;
@override final  String title;
@override final  String? notes;
@override final  DateTime? dueDate;
@override final  String? listId;
@override final  String? listName;
@override final  String? assignorName;
@override final  int? stakeAmountCents;
@override@JsonKey() final  ProofMode proofMode;
@override final  DateTime? completedAt;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of NowTask
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NowTaskCopyWith<_NowTask> get copyWith => __$NowTaskCopyWithImpl<_NowTask>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NowTask&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.listName, listName) || other.listName == listName)&&(identical(other.assignorName, assignorName) || other.assignorName == assignorName)&&(identical(other.stakeAmountCents, stakeAmountCents) || other.stakeAmountCents == stakeAmountCents)&&(identical(other.proofMode, proofMode) || other.proofMode == proofMode)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,notes,dueDate,listId,listName,assignorName,stakeAmountCents,proofMode,completedAt,createdAt,updatedAt);

@override
String toString() {
  return 'NowTask(id: $id, title: $title, notes: $notes, dueDate: $dueDate, listId: $listId, listName: $listName, assignorName: $assignorName, stakeAmountCents: $stakeAmountCents, proofMode: $proofMode, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$NowTaskCopyWith<$Res> implements $NowTaskCopyWith<$Res> {
  factory _$NowTaskCopyWith(_NowTask value, $Res Function(_NowTask) _then) = __$NowTaskCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? notes, DateTime? dueDate, String? listId, String? listName, String? assignorName, int? stakeAmountCents, ProofMode proofMode, DateTime? completedAt, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$NowTaskCopyWithImpl<$Res>
    implements _$NowTaskCopyWith<$Res> {
  __$NowTaskCopyWithImpl(this._self, this._then);

  final _NowTask _self;
  final $Res Function(_NowTask) _then;

/// Create a copy of NowTask
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? notes = freezed,Object? dueDate = freezed,Object? listId = freezed,Object? listName = freezed,Object? assignorName = freezed,Object? stakeAmountCents = freezed,Object? proofMode = null,Object? completedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_NowTask(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,listName: freezed == listName ? _self.listName : listName // ignore: cast_nullable_to_non_nullable
as String?,assignorName: freezed == assignorName ? _self.assignorName : assignorName // ignore: cast_nullable_to_non_nullable
as String?,stakeAmountCents: freezed == stakeAmountCents ? _self.stakeAmountCents : stakeAmountCents // ignore: cast_nullable_to_non_nullable
as int?,proofMode: null == proofMode ? _self.proofMode : proofMode // ignore: cast_nullable_to_non_nullable
as ProofMode,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
