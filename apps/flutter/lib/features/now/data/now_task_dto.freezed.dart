// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'now_task_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NowTaskDto {

 String get id; String get title; String? get notes; String? get dueDate; String? get listId; String? get listName; String? get assignorName; int? get stakeAmountCents; String? get proofMode; String? get startedAt; int? get elapsedSeconds; String? get completedAt; String get createdAt; String get updatedAt;
/// Create a copy of NowTaskDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NowTaskDtoCopyWith<NowTaskDto> get copyWith => _$NowTaskDtoCopyWithImpl<NowTaskDto>(this as NowTaskDto, _$identity);

  /// Serializes this NowTaskDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NowTaskDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.listName, listName) || other.listName == listName)&&(identical(other.assignorName, assignorName) || other.assignorName == assignorName)&&(identical(other.stakeAmountCents, stakeAmountCents) || other.stakeAmountCents == stakeAmountCents)&&(identical(other.proofMode, proofMode) || other.proofMode == proofMode)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,notes,dueDate,listId,listName,assignorName,stakeAmountCents,proofMode,startedAt,elapsedSeconds,completedAt,createdAt,updatedAt);

@override
String toString() {
  return 'NowTaskDto(id: $id, title: $title, notes: $notes, dueDate: $dueDate, listId: $listId, listName: $listName, assignorName: $assignorName, stakeAmountCents: $stakeAmountCents, proofMode: $proofMode, startedAt: $startedAt, elapsedSeconds: $elapsedSeconds, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $NowTaskDtoCopyWith<$Res>  {
  factory $NowTaskDtoCopyWith(NowTaskDto value, $Res Function(NowTaskDto) _then) = _$NowTaskDtoCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? notes, String? dueDate, String? listId, String? listName, String? assignorName, int? stakeAmountCents, String? proofMode, String? startedAt, int? elapsedSeconds, String? completedAt, String createdAt, String updatedAt
});




}
/// @nodoc
class _$NowTaskDtoCopyWithImpl<$Res>
    implements $NowTaskDtoCopyWith<$Res> {
  _$NowTaskDtoCopyWithImpl(this._self, this._then);

  final NowTaskDto _self;
  final $Res Function(NowTaskDto) _then;

/// Create a copy of NowTaskDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? notes = freezed,Object? dueDate = freezed,Object? listId = freezed,Object? listName = freezed,Object? assignorName = freezed,Object? stakeAmountCents = freezed,Object? proofMode = freezed,Object? startedAt = freezed,Object? elapsedSeconds = freezed,Object? completedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,listName: freezed == listName ? _self.listName : listName // ignore: cast_nullable_to_non_nullable
as String?,assignorName: freezed == assignorName ? _self.assignorName : assignorName // ignore: cast_nullable_to_non_nullable
as String?,stakeAmountCents: freezed == stakeAmountCents ? _self.stakeAmountCents : stakeAmountCents // ignore: cast_nullable_to_non_nullable
as int?,proofMode: freezed == proofMode ? _self.proofMode : proofMode // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,elapsedSeconds: freezed == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NowTaskDto].
extension NowTaskDtoPatterns on NowTaskDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NowTaskDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NowTaskDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NowTaskDto value)  $default,){
final _that = this;
switch (_that) {
case _NowTaskDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NowTaskDto value)?  $default,){
final _that = this;
switch (_that) {
case _NowTaskDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? notes,  String? dueDate,  String? listId,  String? listName,  String? assignorName,  int? stakeAmountCents,  String? proofMode,  String? startedAt,  int? elapsedSeconds,  String? completedAt,  String createdAt,  String updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NowTaskDto() when $default != null:
return $default(_that.id,_that.title,_that.notes,_that.dueDate,_that.listId,_that.listName,_that.assignorName,_that.stakeAmountCents,_that.proofMode,_that.startedAt,_that.elapsedSeconds,_that.completedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? notes,  String? dueDate,  String? listId,  String? listName,  String? assignorName,  int? stakeAmountCents,  String? proofMode,  String? startedAt,  int? elapsedSeconds,  String? completedAt,  String createdAt,  String updatedAt)  $default,) {final _that = this;
switch (_that) {
case _NowTaskDto():
return $default(_that.id,_that.title,_that.notes,_that.dueDate,_that.listId,_that.listName,_that.assignorName,_that.stakeAmountCents,_that.proofMode,_that.startedAt,_that.elapsedSeconds,_that.completedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? notes,  String? dueDate,  String? listId,  String? listName,  String? assignorName,  int? stakeAmountCents,  String? proofMode,  String? startedAt,  int? elapsedSeconds,  String? completedAt,  String createdAt,  String updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _NowTaskDto() when $default != null:
return $default(_that.id,_that.title,_that.notes,_that.dueDate,_that.listId,_that.listName,_that.assignorName,_that.stakeAmountCents,_that.proofMode,_that.startedAt,_that.elapsedSeconds,_that.completedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NowTaskDto extends NowTaskDto {
  const _NowTaskDto({required this.id, required this.title, this.notes, this.dueDate, this.listId, this.listName, this.assignorName, this.stakeAmountCents, this.proofMode, this.startedAt, this.elapsedSeconds, this.completedAt, required this.createdAt, required this.updatedAt}): super._();
  factory _NowTaskDto.fromJson(Map<String, dynamic> json) => _$NowTaskDtoFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? notes;
@override final  String? dueDate;
@override final  String? listId;
@override final  String? listName;
@override final  String? assignorName;
@override final  int? stakeAmountCents;
@override final  String? proofMode;
@override final  String? startedAt;
@override final  int? elapsedSeconds;
@override final  String? completedAt;
@override final  String createdAt;
@override final  String updatedAt;

/// Create a copy of NowTaskDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NowTaskDtoCopyWith<_NowTaskDto> get copyWith => __$NowTaskDtoCopyWithImpl<_NowTaskDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NowTaskDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NowTaskDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.listName, listName) || other.listName == listName)&&(identical(other.assignorName, assignorName) || other.assignorName == assignorName)&&(identical(other.stakeAmountCents, stakeAmountCents) || other.stakeAmountCents == stakeAmountCents)&&(identical(other.proofMode, proofMode) || other.proofMode == proofMode)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,notes,dueDate,listId,listName,assignorName,stakeAmountCents,proofMode,startedAt,elapsedSeconds,completedAt,createdAt,updatedAt);

@override
String toString() {
  return 'NowTaskDto(id: $id, title: $title, notes: $notes, dueDate: $dueDate, listId: $listId, listName: $listName, assignorName: $assignorName, stakeAmountCents: $stakeAmountCents, proofMode: $proofMode, startedAt: $startedAt, elapsedSeconds: $elapsedSeconds, completedAt: $completedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$NowTaskDtoCopyWith<$Res> implements $NowTaskDtoCopyWith<$Res> {
  factory _$NowTaskDtoCopyWith(_NowTaskDto value, $Res Function(_NowTaskDto) _then) = __$NowTaskDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? notes, String? dueDate, String? listId, String? listName, String? assignorName, int? stakeAmountCents, String? proofMode, String? startedAt, int? elapsedSeconds, String? completedAt, String createdAt, String updatedAt
});




}
/// @nodoc
class __$NowTaskDtoCopyWithImpl<$Res>
    implements _$NowTaskDtoCopyWith<$Res> {
  __$NowTaskDtoCopyWithImpl(this._self, this._then);

  final _NowTaskDto _self;
  final $Res Function(_NowTaskDto) _then;

/// Create a copy of NowTaskDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? notes = freezed,Object? dueDate = freezed,Object? listId = freezed,Object? listName = freezed,Object? assignorName = freezed,Object? stakeAmountCents = freezed,Object? proofMode = freezed,Object? startedAt = freezed,Object? elapsedSeconds = freezed,Object? completedAt = freezed,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_NowTaskDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as String?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,listName: freezed == listName ? _self.listName : listName // ignore: cast_nullable_to_non_nullable
as String?,assignorName: freezed == assignorName ? _self.assignorName : assignorName // ignore: cast_nullable_to_non_nullable
as String?,stakeAmountCents: freezed == stakeAmountCents ? _self.stakeAmountCents : stakeAmountCents // ignore: cast_nullable_to_non_nullable
as int?,proofMode: freezed == proofMode ? _self.proofMode : proofMode // ignore: cast_nullable_to_non_nullable
as String?,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as String?,elapsedSeconds: freezed == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int?,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
