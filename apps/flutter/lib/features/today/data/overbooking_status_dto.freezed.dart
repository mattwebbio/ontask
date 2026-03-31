// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'overbooking_status_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OverbookedTaskDto {

 String get taskId; String get taskTitle; bool get hasStake; int get durationMinutes;
/// Create a copy of OverbookedTaskDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverbookedTaskDtoCopyWith<OverbookedTaskDto> get copyWith => _$OverbookedTaskDtoCopyWithImpl<OverbookedTaskDto>(this as OverbookedTaskDto, _$identity);

  /// Serializes this OverbookedTaskDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverbookedTaskDto&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.taskTitle, taskTitle) || other.taskTitle == taskTitle)&&(identical(other.hasStake, hasStake) || other.hasStake == hasStake)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,taskId,taskTitle,hasStake,durationMinutes);

@override
String toString() {
  return 'OverbookedTaskDto(taskId: $taskId, taskTitle: $taskTitle, hasStake: $hasStake, durationMinutes: $durationMinutes)';
}


}

/// @nodoc
abstract mixin class $OverbookedTaskDtoCopyWith<$Res>  {
  factory $OverbookedTaskDtoCopyWith(OverbookedTaskDto value, $Res Function(OverbookedTaskDto) _then) = _$OverbookedTaskDtoCopyWithImpl;
@useResult
$Res call({
 String taskId, String taskTitle, bool hasStake, int durationMinutes
});




}
/// @nodoc
class _$OverbookedTaskDtoCopyWithImpl<$Res>
    implements $OverbookedTaskDtoCopyWith<$Res> {
  _$OverbookedTaskDtoCopyWithImpl(this._self, this._then);

  final OverbookedTaskDto _self;
  final $Res Function(OverbookedTaskDto) _then;

/// Create a copy of OverbookedTaskDto
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


/// Adds pattern-matching-related methods to [OverbookedTaskDto].
extension OverbookedTaskDtoPatterns on OverbookedTaskDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OverbookedTaskDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OverbookedTaskDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OverbookedTaskDto value)  $default,){
final _that = this;
switch (_that) {
case _OverbookedTaskDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OverbookedTaskDto value)?  $default,){
final _that = this;
switch (_that) {
case _OverbookedTaskDto() when $default != null:
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
case _OverbookedTaskDto() when $default != null:
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
case _OverbookedTaskDto():
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
case _OverbookedTaskDto() when $default != null:
return $default(_that.taskId,_that.taskTitle,_that.hasStake,_that.durationMinutes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OverbookedTaskDto extends OverbookedTaskDto {
  const _OverbookedTaskDto({required this.taskId, required this.taskTitle, required this.hasStake, required this.durationMinutes}): super._();
  factory _OverbookedTaskDto.fromJson(Map<String, dynamic> json) => _$OverbookedTaskDtoFromJson(json);

@override final  String taskId;
@override final  String taskTitle;
@override final  bool hasStake;
@override final  int durationMinutes;

/// Create a copy of OverbookedTaskDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverbookedTaskDtoCopyWith<_OverbookedTaskDto> get copyWith => __$OverbookedTaskDtoCopyWithImpl<_OverbookedTaskDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OverbookedTaskDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OverbookedTaskDto&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.taskTitle, taskTitle) || other.taskTitle == taskTitle)&&(identical(other.hasStake, hasStake) || other.hasStake == hasStake)&&(identical(other.durationMinutes, durationMinutes) || other.durationMinutes == durationMinutes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,taskId,taskTitle,hasStake,durationMinutes);

@override
String toString() {
  return 'OverbookedTaskDto(taskId: $taskId, taskTitle: $taskTitle, hasStake: $hasStake, durationMinutes: $durationMinutes)';
}


}

/// @nodoc
abstract mixin class _$OverbookedTaskDtoCopyWith<$Res> implements $OverbookedTaskDtoCopyWith<$Res> {
  factory _$OverbookedTaskDtoCopyWith(_OverbookedTaskDto value, $Res Function(_OverbookedTaskDto) _then) = __$OverbookedTaskDtoCopyWithImpl;
@override @useResult
$Res call({
 String taskId, String taskTitle, bool hasStake, int durationMinutes
});




}
/// @nodoc
class __$OverbookedTaskDtoCopyWithImpl<$Res>
    implements _$OverbookedTaskDtoCopyWith<$Res> {
  __$OverbookedTaskDtoCopyWithImpl(this._self, this._then);

  final _OverbookedTaskDto _self;
  final $Res Function(_OverbookedTaskDto) _then;

/// Create a copy of OverbookedTaskDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? taskId = null,Object? taskTitle = null,Object? hasStake = null,Object? durationMinutes = null,}) {
  return _then(_OverbookedTaskDto(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,taskTitle: null == taskTitle ? _self.taskTitle : taskTitle // ignore: cast_nullable_to_non_nullable
as String,hasStake: null == hasStake ? _self.hasStake : hasStake // ignore: cast_nullable_to_non_nullable
as bool,durationMinutes: null == durationMinutes ? _self.durationMinutes : durationMinutes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$OverbookingStatusDto {

 bool get isOverbooked; String get severity; double get capacityPercent; List<OverbookedTaskDto> get overbookedTasks;
/// Create a copy of OverbookingStatusDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OverbookingStatusDtoCopyWith<OverbookingStatusDto> get copyWith => _$OverbookingStatusDtoCopyWithImpl<OverbookingStatusDto>(this as OverbookingStatusDto, _$identity);

  /// Serializes this OverbookingStatusDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OverbookingStatusDto&&(identical(other.isOverbooked, isOverbooked) || other.isOverbooked == isOverbooked)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.capacityPercent, capacityPercent) || other.capacityPercent == capacityPercent)&&const DeepCollectionEquality().equals(other.overbookedTasks, overbookedTasks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isOverbooked,severity,capacityPercent,const DeepCollectionEquality().hash(overbookedTasks));

@override
String toString() {
  return 'OverbookingStatusDto(isOverbooked: $isOverbooked, severity: $severity, capacityPercent: $capacityPercent, overbookedTasks: $overbookedTasks)';
}


}

/// @nodoc
abstract mixin class $OverbookingStatusDtoCopyWith<$Res>  {
  factory $OverbookingStatusDtoCopyWith(OverbookingStatusDto value, $Res Function(OverbookingStatusDto) _then) = _$OverbookingStatusDtoCopyWithImpl;
@useResult
$Res call({
 bool isOverbooked, String severity, double capacityPercent, List<OverbookedTaskDto> overbookedTasks
});




}
/// @nodoc
class _$OverbookingStatusDtoCopyWithImpl<$Res>
    implements $OverbookingStatusDtoCopyWith<$Res> {
  _$OverbookingStatusDtoCopyWithImpl(this._self, this._then);

  final OverbookingStatusDto _self;
  final $Res Function(OverbookingStatusDto) _then;

/// Create a copy of OverbookingStatusDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isOverbooked = null,Object? severity = null,Object? capacityPercent = null,Object? overbookedTasks = null,}) {
  return _then(_self.copyWith(
isOverbooked: null == isOverbooked ? _self.isOverbooked : isOverbooked // ignore: cast_nullable_to_non_nullable
as bool,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,capacityPercent: null == capacityPercent ? _self.capacityPercent : capacityPercent // ignore: cast_nullable_to_non_nullable
as double,overbookedTasks: null == overbookedTasks ? _self.overbookedTasks : overbookedTasks // ignore: cast_nullable_to_non_nullable
as List<OverbookedTaskDto>,
  ));
}

}


/// Adds pattern-matching-related methods to [OverbookingStatusDto].
extension OverbookingStatusDtoPatterns on OverbookingStatusDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OverbookingStatusDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OverbookingStatusDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OverbookingStatusDto value)  $default,){
final _that = this;
switch (_that) {
case _OverbookingStatusDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OverbookingStatusDto value)?  $default,){
final _that = this;
switch (_that) {
case _OverbookingStatusDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isOverbooked,  String severity,  double capacityPercent,  List<OverbookedTaskDto> overbookedTasks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OverbookingStatusDto() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isOverbooked,  String severity,  double capacityPercent,  List<OverbookedTaskDto> overbookedTasks)  $default,) {final _that = this;
switch (_that) {
case _OverbookingStatusDto():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isOverbooked,  String severity,  double capacityPercent,  List<OverbookedTaskDto> overbookedTasks)?  $default,) {final _that = this;
switch (_that) {
case _OverbookingStatusDto() when $default != null:
return $default(_that.isOverbooked,_that.severity,_that.capacityPercent,_that.overbookedTasks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OverbookingStatusDto extends OverbookingStatusDto {
  const _OverbookingStatusDto({required this.isOverbooked, required this.severity, required this.capacityPercent, required final  List<OverbookedTaskDto> overbookedTasks}): _overbookedTasks = overbookedTasks,super._();
  factory _OverbookingStatusDto.fromJson(Map<String, dynamic> json) => _$OverbookingStatusDtoFromJson(json);

@override final  bool isOverbooked;
@override final  String severity;
@override final  double capacityPercent;
 final  List<OverbookedTaskDto> _overbookedTasks;
@override List<OverbookedTaskDto> get overbookedTasks {
  if (_overbookedTasks is EqualUnmodifiableListView) return _overbookedTasks;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_overbookedTasks);
}


/// Create a copy of OverbookingStatusDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OverbookingStatusDtoCopyWith<_OverbookingStatusDto> get copyWith => __$OverbookingStatusDtoCopyWithImpl<_OverbookingStatusDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OverbookingStatusDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OverbookingStatusDto&&(identical(other.isOverbooked, isOverbooked) || other.isOverbooked == isOverbooked)&&(identical(other.severity, severity) || other.severity == severity)&&(identical(other.capacityPercent, capacityPercent) || other.capacityPercent == capacityPercent)&&const DeepCollectionEquality().equals(other._overbookedTasks, _overbookedTasks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isOverbooked,severity,capacityPercent,const DeepCollectionEquality().hash(_overbookedTasks));

@override
String toString() {
  return 'OverbookingStatusDto(isOverbooked: $isOverbooked, severity: $severity, capacityPercent: $capacityPercent, overbookedTasks: $overbookedTasks)';
}


}

/// @nodoc
abstract mixin class _$OverbookingStatusDtoCopyWith<$Res> implements $OverbookingStatusDtoCopyWith<$Res> {
  factory _$OverbookingStatusDtoCopyWith(_OverbookingStatusDto value, $Res Function(_OverbookingStatusDto) _then) = __$OverbookingStatusDtoCopyWithImpl;
@override @useResult
$Res call({
 bool isOverbooked, String severity, double capacityPercent, List<OverbookedTaskDto> overbookedTasks
});




}
/// @nodoc
class __$OverbookingStatusDtoCopyWithImpl<$Res>
    implements _$OverbookingStatusDtoCopyWith<$Res> {
  __$OverbookingStatusDtoCopyWithImpl(this._self, this._then);

  final _OverbookingStatusDto _self;
  final $Res Function(_OverbookingStatusDto) _then;

/// Create a copy of OverbookingStatusDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isOverbooked = null,Object? severity = null,Object? capacityPercent = null,Object? overbookedTasks = null,}) {
  return _then(_OverbookingStatusDto(
isOverbooked: null == isOverbooked ? _self.isOverbooked : isOverbooked // ignore: cast_nullable_to_non_nullable
as bool,severity: null == severity ? _self.severity : severity // ignore: cast_nullable_to_non_nullable
as String,capacityPercent: null == capacityPercent ? _self.capacityPercent : capacityPercent // ignore: cast_nullable_to_non_nullable
as double,overbookedTasks: null == overbookedTasks ? _self._overbookedTasks : overbookedTasks // ignore: cast_nullable_to_non_nullable
as List<OverbookedTaskDto>,
  ));
}


}

// dart format on
