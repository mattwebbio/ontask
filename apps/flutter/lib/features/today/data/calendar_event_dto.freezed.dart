// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'calendar_event_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CalendarEventDto {

 String get id; String get startTime; String get endTime; bool get isAllDay; String? get summary;
/// Create a copy of CalendarEventDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CalendarEventDtoCopyWith<CalendarEventDto> get copyWith => _$CalendarEventDtoCopyWithImpl<CalendarEventDto>(this as CalendarEventDto, _$identity);

  /// Serializes this CalendarEventDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CalendarEventDto&&(identical(other.id, id) || other.id == id)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.isAllDay, isAllDay) || other.isAllDay == isAllDay)&&(identical(other.summary, summary) || other.summary == summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,startTime,endTime,isAllDay,summary);

@override
String toString() {
  return 'CalendarEventDto(id: $id, startTime: $startTime, endTime: $endTime, isAllDay: $isAllDay, summary: $summary)';
}


}

/// @nodoc
abstract mixin class $CalendarEventDtoCopyWith<$Res>  {
  factory $CalendarEventDtoCopyWith(CalendarEventDto value, $Res Function(CalendarEventDto) _then) = _$CalendarEventDtoCopyWithImpl;
@useResult
$Res call({
 String id, String startTime, String endTime, bool isAllDay, String? summary
});




}
/// @nodoc
class _$CalendarEventDtoCopyWithImpl<$Res>
    implements $CalendarEventDtoCopyWith<$Res> {
  _$CalendarEventDtoCopyWithImpl(this._self, this._then);

  final CalendarEventDto _self;
  final $Res Function(CalendarEventDto) _then;

/// Create a copy of CalendarEventDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startTime = null,Object? endTime = null,Object? isAllDay = null,Object? summary = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,isAllDay: null == isAllDay ? _self.isAllDay : isAllDay // ignore: cast_nullable_to_non_nullable
as bool,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CalendarEventDto].
extension CalendarEventDtoPatterns on CalendarEventDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CalendarEventDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CalendarEventDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CalendarEventDto value)  $default,){
final _that = this;
switch (_that) {
case _CalendarEventDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CalendarEventDto value)?  $default,){
final _that = this;
switch (_that) {
case _CalendarEventDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String startTime,  String endTime,  bool isAllDay,  String? summary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CalendarEventDto() when $default != null:
return $default(_that.id,_that.startTime,_that.endTime,_that.isAllDay,_that.summary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String startTime,  String endTime,  bool isAllDay,  String? summary)  $default,) {final _that = this;
switch (_that) {
case _CalendarEventDto():
return $default(_that.id,_that.startTime,_that.endTime,_that.isAllDay,_that.summary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String startTime,  String endTime,  bool isAllDay,  String? summary)?  $default,) {final _that = this;
switch (_that) {
case _CalendarEventDto() when $default != null:
return $default(_that.id,_that.startTime,_that.endTime,_that.isAllDay,_that.summary);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CalendarEventDto extends CalendarEventDto {
  const _CalendarEventDto({required this.id, required this.startTime, required this.endTime, required this.isAllDay, this.summary}): super._();
  factory _CalendarEventDto.fromJson(Map<String, dynamic> json) => _$CalendarEventDtoFromJson(json);

@override final  String id;
@override final  String startTime;
@override final  String endTime;
@override final  bool isAllDay;
@override final  String? summary;

/// Create a copy of CalendarEventDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CalendarEventDtoCopyWith<_CalendarEventDto> get copyWith => __$CalendarEventDtoCopyWithImpl<_CalendarEventDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CalendarEventDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CalendarEventDto&&(identical(other.id, id) || other.id == id)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.isAllDay, isAllDay) || other.isAllDay == isAllDay)&&(identical(other.summary, summary) || other.summary == summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,startTime,endTime,isAllDay,summary);

@override
String toString() {
  return 'CalendarEventDto(id: $id, startTime: $startTime, endTime: $endTime, isAllDay: $isAllDay, summary: $summary)';
}


}

/// @nodoc
abstract mixin class _$CalendarEventDtoCopyWith<$Res> implements $CalendarEventDtoCopyWith<$Res> {
  factory _$CalendarEventDtoCopyWith(_CalendarEventDto value, $Res Function(_CalendarEventDto) _then) = __$CalendarEventDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String startTime, String endTime, bool isAllDay, String? summary
});




}
/// @nodoc
class __$CalendarEventDtoCopyWithImpl<$Res>
    implements _$CalendarEventDtoCopyWith<$Res> {
  __$CalendarEventDtoCopyWithImpl(this._self, this._then);

  final _CalendarEventDto _self;
  final $Res Function(_CalendarEventDto) _then;

/// Create a copy of CalendarEventDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startTime = null,Object? endTime = null,Object? isAllDay = null,Object? summary = freezed,}) {
  return _then(_CalendarEventDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startTime: null == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as String,endTime: null == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as String,isAllDay: null == isAllDay ? _self.isAllDay : isAllDay // ignore: cast_nullable_to_non_nullable
as bool,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
