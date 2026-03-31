// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_health_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DayHealthDto {

 String get date; String get status; int get taskCount; double get capacityPercent; List<String> get atRiskTaskIds;
/// Create a copy of DayHealthDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayHealthDtoCopyWith<DayHealthDto> get copyWith => _$DayHealthDtoCopyWithImpl<DayHealthDto>(this as DayHealthDto, _$identity);

  /// Serializes this DayHealthDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayHealthDto&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.taskCount, taskCount) || other.taskCount == taskCount)&&(identical(other.capacityPercent, capacityPercent) || other.capacityPercent == capacityPercent)&&const DeepCollectionEquality().equals(other.atRiskTaskIds, atRiskTaskIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,status,taskCount,capacityPercent,const DeepCollectionEquality().hash(atRiskTaskIds));

@override
String toString() {
  return 'DayHealthDto(date: $date, status: $status, taskCount: $taskCount, capacityPercent: $capacityPercent, atRiskTaskIds: $atRiskTaskIds)';
}


}

/// @nodoc
abstract mixin class $DayHealthDtoCopyWith<$Res>  {
  factory $DayHealthDtoCopyWith(DayHealthDto value, $Res Function(DayHealthDto) _then) = _$DayHealthDtoCopyWithImpl;
@useResult
$Res call({
 String date, String status, int taskCount, double capacityPercent, List<String> atRiskTaskIds
});




}
/// @nodoc
class _$DayHealthDtoCopyWithImpl<$Res>
    implements $DayHealthDtoCopyWith<$Res> {
  _$DayHealthDtoCopyWithImpl(this._self, this._then);

  final DayHealthDto _self;
  final $Res Function(DayHealthDto) _then;

/// Create a copy of DayHealthDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? status = null,Object? taskCount = null,Object? capacityPercent = null,Object? atRiskTaskIds = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,taskCount: null == taskCount ? _self.taskCount : taskCount // ignore: cast_nullable_to_non_nullable
as int,capacityPercent: null == capacityPercent ? _self.capacityPercent : capacityPercent // ignore: cast_nullable_to_non_nullable
as double,atRiskTaskIds: null == atRiskTaskIds ? _self.atRiskTaskIds : atRiskTaskIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [DayHealthDto].
extension DayHealthDtoPatterns on DayHealthDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DayHealthDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DayHealthDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DayHealthDto value)  $default,){
final _that = this;
switch (_that) {
case _DayHealthDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DayHealthDto value)?  $default,){
final _that = this;
switch (_that) {
case _DayHealthDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  String status,  int taskCount,  double capacityPercent,  List<String> atRiskTaskIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DayHealthDto() when $default != null:
return $default(_that.date,_that.status,_that.taskCount,_that.capacityPercent,_that.atRiskTaskIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  String status,  int taskCount,  double capacityPercent,  List<String> atRiskTaskIds)  $default,) {final _that = this;
switch (_that) {
case _DayHealthDto():
return $default(_that.date,_that.status,_that.taskCount,_that.capacityPercent,_that.atRiskTaskIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  String status,  int taskCount,  double capacityPercent,  List<String> atRiskTaskIds)?  $default,) {final _that = this;
switch (_that) {
case _DayHealthDto() when $default != null:
return $default(_that.date,_that.status,_that.taskCount,_that.capacityPercent,_that.atRiskTaskIds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DayHealthDto extends DayHealthDto {
  const _DayHealthDto({required this.date, required this.status, required this.taskCount, required this.capacityPercent, required final  List<String> atRiskTaskIds}): _atRiskTaskIds = atRiskTaskIds,super._();
  factory _DayHealthDto.fromJson(Map<String, dynamic> json) => _$DayHealthDtoFromJson(json);

@override final  String date;
@override final  String status;
@override final  int taskCount;
@override final  double capacityPercent;
 final  List<String> _atRiskTaskIds;
@override List<String> get atRiskTaskIds {
  if (_atRiskTaskIds is EqualUnmodifiableListView) return _atRiskTaskIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_atRiskTaskIds);
}


/// Create a copy of DayHealthDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayHealthDtoCopyWith<_DayHealthDto> get copyWith => __$DayHealthDtoCopyWithImpl<_DayHealthDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayHealthDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayHealthDto&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.taskCount, taskCount) || other.taskCount == taskCount)&&(identical(other.capacityPercent, capacityPercent) || other.capacityPercent == capacityPercent)&&const DeepCollectionEquality().equals(other._atRiskTaskIds, _atRiskTaskIds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,status,taskCount,capacityPercent,const DeepCollectionEquality().hash(_atRiskTaskIds));

@override
String toString() {
  return 'DayHealthDto(date: $date, status: $status, taskCount: $taskCount, capacityPercent: $capacityPercent, atRiskTaskIds: $atRiskTaskIds)';
}


}

/// @nodoc
abstract mixin class _$DayHealthDtoCopyWith<$Res> implements $DayHealthDtoCopyWith<$Res> {
  factory _$DayHealthDtoCopyWith(_DayHealthDto value, $Res Function(_DayHealthDto) _then) = __$DayHealthDtoCopyWithImpl;
@override @useResult
$Res call({
 String date, String status, int taskCount, double capacityPercent, List<String> atRiskTaskIds
});




}
/// @nodoc
class __$DayHealthDtoCopyWithImpl<$Res>
    implements _$DayHealthDtoCopyWith<$Res> {
  __$DayHealthDtoCopyWithImpl(this._self, this._then);

  final _DayHealthDto _self;
  final $Res Function(_DayHealthDto) _then;

/// Create a copy of DayHealthDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? status = null,Object? taskCount = null,Object? capacityPercent = null,Object? atRiskTaskIds = null,}) {
  return _then(_DayHealthDto(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,taskCount: null == taskCount ? _self.taskCount : taskCount // ignore: cast_nullable_to_non_nullable
as int,capacityPercent: null == capacityPercent ? _self.capacityPercent : capacityPercent // ignore: cast_nullable_to_non_nullable
as double,atRiskTaskIds: null == atRiskTaskIds ? _self._atRiskTaskIds : atRiskTaskIds // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
