// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_change_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ScheduleChangeItemDto {

 String get taskId; String get taskTitle; String get changeType; String? get oldTime; String? get newTime;
/// Create a copy of ScheduleChangeItemDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleChangeItemDtoCopyWith<ScheduleChangeItemDto> get copyWith => _$ScheduleChangeItemDtoCopyWithImpl<ScheduleChangeItemDto>(this as ScheduleChangeItemDto, _$identity);

  /// Serializes this ScheduleChangeItemDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduleChangeItemDto&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.taskTitle, taskTitle) || other.taskTitle == taskTitle)&&(identical(other.changeType, changeType) || other.changeType == changeType)&&(identical(other.oldTime, oldTime) || other.oldTime == oldTime)&&(identical(other.newTime, newTime) || other.newTime == newTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,taskId,taskTitle,changeType,oldTime,newTime);

@override
String toString() {
  return 'ScheduleChangeItemDto(taskId: $taskId, taskTitle: $taskTitle, changeType: $changeType, oldTime: $oldTime, newTime: $newTime)';
}


}

/// @nodoc
abstract mixin class $ScheduleChangeItemDtoCopyWith<$Res>  {
  factory $ScheduleChangeItemDtoCopyWith(ScheduleChangeItemDto value, $Res Function(ScheduleChangeItemDto) _then) = _$ScheduleChangeItemDtoCopyWithImpl;
@useResult
$Res call({
 String taskId, String taskTitle, String changeType, String? oldTime, String? newTime
});




}
/// @nodoc
class _$ScheduleChangeItemDtoCopyWithImpl<$Res>
    implements $ScheduleChangeItemDtoCopyWith<$Res> {
  _$ScheduleChangeItemDtoCopyWithImpl(this._self, this._then);

  final ScheduleChangeItemDto _self;
  final $Res Function(ScheduleChangeItemDto) _then;

/// Create a copy of ScheduleChangeItemDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? taskId = null,Object? taskTitle = null,Object? changeType = null,Object? oldTime = freezed,Object? newTime = freezed,}) {
  return _then(_self.copyWith(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,taskTitle: null == taskTitle ? _self.taskTitle : taskTitle // ignore: cast_nullable_to_non_nullable
as String,changeType: null == changeType ? _self.changeType : changeType // ignore: cast_nullable_to_non_nullable
as String,oldTime: freezed == oldTime ? _self.oldTime : oldTime // ignore: cast_nullable_to_non_nullable
as String?,newTime: freezed == newTime ? _self.newTime : newTime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduleChangeItemDto].
extension ScheduleChangeItemDtoPatterns on ScheduleChangeItemDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduleChangeItemDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduleChangeItemDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduleChangeItemDto value)  $default,){
final _that = this;
switch (_that) {
case _ScheduleChangeItemDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduleChangeItemDto value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduleChangeItemDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String taskId,  String taskTitle,  String changeType,  String? oldTime,  String? newTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduleChangeItemDto() when $default != null:
return $default(_that.taskId,_that.taskTitle,_that.changeType,_that.oldTime,_that.newTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String taskId,  String taskTitle,  String changeType,  String? oldTime,  String? newTime)  $default,) {final _that = this;
switch (_that) {
case _ScheduleChangeItemDto():
return $default(_that.taskId,_that.taskTitle,_that.changeType,_that.oldTime,_that.newTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String taskId,  String taskTitle,  String changeType,  String? oldTime,  String? newTime)?  $default,) {final _that = this;
switch (_that) {
case _ScheduleChangeItemDto() when $default != null:
return $default(_that.taskId,_that.taskTitle,_that.changeType,_that.oldTime,_that.newTime);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScheduleChangeItemDto extends ScheduleChangeItemDto {
  const _ScheduleChangeItemDto({required this.taskId, required this.taskTitle, required this.changeType, required this.oldTime, required this.newTime}): super._();
  factory _ScheduleChangeItemDto.fromJson(Map<String, dynamic> json) => _$ScheduleChangeItemDtoFromJson(json);

@override final  String taskId;
@override final  String taskTitle;
@override final  String changeType;
@override final  String? oldTime;
@override final  String? newTime;

/// Create a copy of ScheduleChangeItemDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduleChangeItemDtoCopyWith<_ScheduleChangeItemDto> get copyWith => __$ScheduleChangeItemDtoCopyWithImpl<_ScheduleChangeItemDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduleChangeItemDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduleChangeItemDto&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.taskTitle, taskTitle) || other.taskTitle == taskTitle)&&(identical(other.changeType, changeType) || other.changeType == changeType)&&(identical(other.oldTime, oldTime) || other.oldTime == oldTime)&&(identical(other.newTime, newTime) || other.newTime == newTime));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,taskId,taskTitle,changeType,oldTime,newTime);

@override
String toString() {
  return 'ScheduleChangeItemDto(taskId: $taskId, taskTitle: $taskTitle, changeType: $changeType, oldTime: $oldTime, newTime: $newTime)';
}


}

/// @nodoc
abstract mixin class _$ScheduleChangeItemDtoCopyWith<$Res> implements $ScheduleChangeItemDtoCopyWith<$Res> {
  factory _$ScheduleChangeItemDtoCopyWith(_ScheduleChangeItemDto value, $Res Function(_ScheduleChangeItemDto) _then) = __$ScheduleChangeItemDtoCopyWithImpl;
@override @useResult
$Res call({
 String taskId, String taskTitle, String changeType, String? oldTime, String? newTime
});




}
/// @nodoc
class __$ScheduleChangeItemDtoCopyWithImpl<$Res>
    implements _$ScheduleChangeItemDtoCopyWith<$Res> {
  __$ScheduleChangeItemDtoCopyWithImpl(this._self, this._then);

  final _ScheduleChangeItemDto _self;
  final $Res Function(_ScheduleChangeItemDto) _then;

/// Create a copy of ScheduleChangeItemDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? taskId = null,Object? taskTitle = null,Object? changeType = null,Object? oldTime = freezed,Object? newTime = freezed,}) {
  return _then(_ScheduleChangeItemDto(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,taskTitle: null == taskTitle ? _self.taskTitle : taskTitle // ignore: cast_nullable_to_non_nullable
as String,changeType: null == changeType ? _self.changeType : changeType // ignore: cast_nullable_to_non_nullable
as String,oldTime: freezed == oldTime ? _self.oldTime : oldTime // ignore: cast_nullable_to_non_nullable
as String?,newTime: freezed == newTime ? _self.newTime : newTime // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$ScheduleChangesDto {

 bool get hasMeaningfulChanges; int get changeCount; List<ScheduleChangeItemDto> get changes;
/// Create a copy of ScheduleChangesDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleChangesDtoCopyWith<ScheduleChangesDto> get copyWith => _$ScheduleChangesDtoCopyWithImpl<ScheduleChangesDto>(this as ScheduleChangesDto, _$identity);

  /// Serializes this ScheduleChangesDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduleChangesDto&&(identical(other.hasMeaningfulChanges, hasMeaningfulChanges) || other.hasMeaningfulChanges == hasMeaningfulChanges)&&(identical(other.changeCount, changeCount) || other.changeCount == changeCount)&&const DeepCollectionEquality().equals(other.changes, changes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hasMeaningfulChanges,changeCount,const DeepCollectionEquality().hash(changes));

@override
String toString() {
  return 'ScheduleChangesDto(hasMeaningfulChanges: $hasMeaningfulChanges, changeCount: $changeCount, changes: $changes)';
}


}

/// @nodoc
abstract mixin class $ScheduleChangesDtoCopyWith<$Res>  {
  factory $ScheduleChangesDtoCopyWith(ScheduleChangesDto value, $Res Function(ScheduleChangesDto) _then) = _$ScheduleChangesDtoCopyWithImpl;
@useResult
$Res call({
 bool hasMeaningfulChanges, int changeCount, List<ScheduleChangeItemDto> changes
});




}
/// @nodoc
class _$ScheduleChangesDtoCopyWithImpl<$Res>
    implements $ScheduleChangesDtoCopyWith<$Res> {
  _$ScheduleChangesDtoCopyWithImpl(this._self, this._then);

  final ScheduleChangesDto _self;
  final $Res Function(ScheduleChangesDto) _then;

/// Create a copy of ScheduleChangesDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hasMeaningfulChanges = null,Object? changeCount = null,Object? changes = null,}) {
  return _then(_self.copyWith(
hasMeaningfulChanges: null == hasMeaningfulChanges ? _self.hasMeaningfulChanges : hasMeaningfulChanges // ignore: cast_nullable_to_non_nullable
as bool,changeCount: null == changeCount ? _self.changeCount : changeCount // ignore: cast_nullable_to_non_nullable
as int,changes: null == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as List<ScheduleChangeItemDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduleChangesDto].
extension ScheduleChangesDtoPatterns on ScheduleChangesDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduleChangesDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduleChangesDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduleChangesDto value)  $default,){
final _that = this;
switch (_that) {
case _ScheduleChangesDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduleChangesDto value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduleChangesDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool hasMeaningfulChanges,  int changeCount,  List<ScheduleChangeItemDto> changes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduleChangesDto() when $default != null:
return $default(_that.hasMeaningfulChanges,_that.changeCount,_that.changes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool hasMeaningfulChanges,  int changeCount,  List<ScheduleChangeItemDto> changes)  $default,) {final _that = this;
switch (_that) {
case _ScheduleChangesDto():
return $default(_that.hasMeaningfulChanges,_that.changeCount,_that.changes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool hasMeaningfulChanges,  int changeCount,  List<ScheduleChangeItemDto> changes)?  $default,) {final _that = this;
switch (_that) {
case _ScheduleChangesDto() when $default != null:
return $default(_that.hasMeaningfulChanges,_that.changeCount,_that.changes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ScheduleChangesDto extends ScheduleChangesDto {
  const _ScheduleChangesDto({required this.hasMeaningfulChanges, required this.changeCount, required final  List<ScheduleChangeItemDto> changes}): _changes = changes,super._();
  factory _ScheduleChangesDto.fromJson(Map<String, dynamic> json) => _$ScheduleChangesDtoFromJson(json);

@override final  bool hasMeaningfulChanges;
@override final  int changeCount;
 final  List<ScheduleChangeItemDto> _changes;
@override List<ScheduleChangeItemDto> get changes {
  if (_changes is EqualUnmodifiableListView) return _changes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_changes);
}


/// Create a copy of ScheduleChangesDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduleChangesDtoCopyWith<_ScheduleChangesDto> get copyWith => __$ScheduleChangesDtoCopyWithImpl<_ScheduleChangesDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ScheduleChangesDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduleChangesDto&&(identical(other.hasMeaningfulChanges, hasMeaningfulChanges) || other.hasMeaningfulChanges == hasMeaningfulChanges)&&(identical(other.changeCount, changeCount) || other.changeCount == changeCount)&&const DeepCollectionEquality().equals(other._changes, _changes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hasMeaningfulChanges,changeCount,const DeepCollectionEquality().hash(_changes));

@override
String toString() {
  return 'ScheduleChangesDto(hasMeaningfulChanges: $hasMeaningfulChanges, changeCount: $changeCount, changes: $changes)';
}


}

/// @nodoc
abstract mixin class _$ScheduleChangesDtoCopyWith<$Res> implements $ScheduleChangesDtoCopyWith<$Res> {
  factory _$ScheduleChangesDtoCopyWith(_ScheduleChangesDto value, $Res Function(_ScheduleChangesDto) _then) = __$ScheduleChangesDtoCopyWithImpl;
@override @useResult
$Res call({
 bool hasMeaningfulChanges, int changeCount, List<ScheduleChangeItemDto> changes
});




}
/// @nodoc
class __$ScheduleChangesDtoCopyWithImpl<$Res>
    implements _$ScheduleChangesDtoCopyWith<$Res> {
  __$ScheduleChangesDtoCopyWithImpl(this._self, this._then);

  final _ScheduleChangesDto _self;
  final $Res Function(_ScheduleChangesDto) _then;

/// Create a copy of ScheduleChangesDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hasMeaningfulChanges = null,Object? changeCount = null,Object? changes = null,}) {
  return _then(_ScheduleChangesDto(
hasMeaningfulChanges: null == hasMeaningfulChanges ? _self.hasMeaningfulChanges : hasMeaningfulChanges // ignore: cast_nullable_to_non_nullable
as bool,changeCount: null == changeCount ? _self.changeCount : changeCount // ignore: cast_nullable_to_non_nullable
as int,changes: null == changes ? _self._changes : changes // ignore: cast_nullable_to_non_nullable
as List<ScheduleChangeItemDto>,
  ));
}


}

// dart format on
