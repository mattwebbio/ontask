// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guided_chat_response_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GuidedChatResponseDto {

 String get reply; bool get isComplete; GuidedChatTaskDraftDto? get extractedTask;
/// Create a copy of GuidedChatResponseDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidedChatResponseDtoCopyWith<GuidedChatResponseDto> get copyWith => _$GuidedChatResponseDtoCopyWithImpl<GuidedChatResponseDto>(this as GuidedChatResponseDto, _$identity);

  /// Serializes this GuidedChatResponseDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidedChatResponseDto&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.extractedTask, extractedTask) || other.extractedTask == extractedTask));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reply,isComplete,extractedTask);

@override
String toString() {
  return 'GuidedChatResponseDto(reply: $reply, isComplete: $isComplete, extractedTask: $extractedTask)';
}


}

/// @nodoc
abstract mixin class $GuidedChatResponseDtoCopyWith<$Res>  {
  factory $GuidedChatResponseDtoCopyWith(GuidedChatResponseDto value, $Res Function(GuidedChatResponseDto) _then) = _$GuidedChatResponseDtoCopyWithImpl;
@useResult
$Res call({
 String reply, bool isComplete, GuidedChatTaskDraftDto? extractedTask
});


$GuidedChatTaskDraftDtoCopyWith<$Res>? get extractedTask;

}
/// @nodoc
class _$GuidedChatResponseDtoCopyWithImpl<$Res>
    implements $GuidedChatResponseDtoCopyWith<$Res> {
  _$GuidedChatResponseDtoCopyWithImpl(this._self, this._then);

  final GuidedChatResponseDto _self;
  final $Res Function(GuidedChatResponseDto) _then;

/// Create a copy of GuidedChatResponseDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reply = null,Object? isComplete = null,Object? extractedTask = freezed,}) {
  return _then(_self.copyWith(
reply: null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,extractedTask: freezed == extractedTask ? _self.extractedTask : extractedTask // ignore: cast_nullable_to_non_nullable
as GuidedChatTaskDraftDto?,
  ));
}
/// Create a copy of GuidedChatResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuidedChatTaskDraftDtoCopyWith<$Res>? get extractedTask {
    if (_self.extractedTask == null) {
    return null;
  }

  return $GuidedChatTaskDraftDtoCopyWith<$Res>(_self.extractedTask!, (value) {
    return _then(_self.copyWith(extractedTask: value));
  });
}
}


/// Adds pattern-matching-related methods to [GuidedChatResponseDto].
extension GuidedChatResponseDtoPatterns on GuidedChatResponseDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuidedChatResponseDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuidedChatResponseDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuidedChatResponseDto value)  $default,){
final _that = this;
switch (_that) {
case _GuidedChatResponseDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuidedChatResponseDto value)?  $default,){
final _that = this;
switch (_that) {
case _GuidedChatResponseDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reply,  bool isComplete,  GuidedChatTaskDraftDto? extractedTask)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuidedChatResponseDto() when $default != null:
return $default(_that.reply,_that.isComplete,_that.extractedTask);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reply,  bool isComplete,  GuidedChatTaskDraftDto? extractedTask)  $default,) {final _that = this;
switch (_that) {
case _GuidedChatResponseDto():
return $default(_that.reply,_that.isComplete,_that.extractedTask);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reply,  bool isComplete,  GuidedChatTaskDraftDto? extractedTask)?  $default,) {final _that = this;
switch (_that) {
case _GuidedChatResponseDto() when $default != null:
return $default(_that.reply,_that.isComplete,_that.extractedTask);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GuidedChatResponseDto extends GuidedChatResponseDto {
  const _GuidedChatResponseDto({required this.reply, required this.isComplete, this.extractedTask}): super._();
  factory _GuidedChatResponseDto.fromJson(Map<String, dynamic> json) => _$GuidedChatResponseDtoFromJson(json);

@override final  String reply;
@override final  bool isComplete;
@override final  GuidedChatTaskDraftDto? extractedTask;

/// Create a copy of GuidedChatResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidedChatResponseDtoCopyWith<_GuidedChatResponseDto> get copyWith => __$GuidedChatResponseDtoCopyWithImpl<_GuidedChatResponseDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GuidedChatResponseDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidedChatResponseDto&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.extractedTask, extractedTask) || other.extractedTask == extractedTask));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,reply,isComplete,extractedTask);

@override
String toString() {
  return 'GuidedChatResponseDto(reply: $reply, isComplete: $isComplete, extractedTask: $extractedTask)';
}


}

/// @nodoc
abstract mixin class _$GuidedChatResponseDtoCopyWith<$Res> implements $GuidedChatResponseDtoCopyWith<$Res> {
  factory _$GuidedChatResponseDtoCopyWith(_GuidedChatResponseDto value, $Res Function(_GuidedChatResponseDto) _then) = __$GuidedChatResponseDtoCopyWithImpl;
@override @useResult
$Res call({
 String reply, bool isComplete, GuidedChatTaskDraftDto? extractedTask
});


@override $GuidedChatTaskDraftDtoCopyWith<$Res>? get extractedTask;

}
/// @nodoc
class __$GuidedChatResponseDtoCopyWithImpl<$Res>
    implements _$GuidedChatResponseDtoCopyWith<$Res> {
  __$GuidedChatResponseDtoCopyWithImpl(this._self, this._then);

  final _GuidedChatResponseDto _self;
  final $Res Function(_GuidedChatResponseDto) _then;

/// Create a copy of GuidedChatResponseDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reply = null,Object? isComplete = null,Object? extractedTask = freezed,}) {
  return _then(_GuidedChatResponseDto(
reply: null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,extractedTask: freezed == extractedTask ? _self.extractedTask : extractedTask // ignore: cast_nullable_to_non_nullable
as GuidedChatTaskDraftDto?,
  ));
}

/// Create a copy of GuidedChatResponseDto
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuidedChatTaskDraftDtoCopyWith<$Res>? get extractedTask {
    if (_self.extractedTask == null) {
    return null;
  }

  return $GuidedChatTaskDraftDtoCopyWith<$Res>(_self.extractedTask!, (value) {
    return _then(_self.copyWith(extractedTask: value));
  });
}
}

// dart format on
