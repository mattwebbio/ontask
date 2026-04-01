// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'guided_chat_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GuidedChatResponse {

/// The LLM's next conversational message to display to the user.
 String get reply;/// True when the LLM has collected enough information to create the task.
 bool get isComplete;/// The partially or fully resolved task draft. Populated when [isComplete]
/// is true.
 GuidedChatTaskDraft? get extractedTask;
/// Create a copy of GuidedChatResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GuidedChatResponseCopyWith<GuidedChatResponse> get copyWith => _$GuidedChatResponseCopyWithImpl<GuidedChatResponse>(this as GuidedChatResponse, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GuidedChatResponse&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.extractedTask, extractedTask) || other.extractedTask == extractedTask));
}


@override
int get hashCode => Object.hash(runtimeType,reply,isComplete,extractedTask);

@override
String toString() {
  return 'GuidedChatResponse(reply: $reply, isComplete: $isComplete, extractedTask: $extractedTask)';
}


}

/// @nodoc
abstract mixin class $GuidedChatResponseCopyWith<$Res>  {
  factory $GuidedChatResponseCopyWith(GuidedChatResponse value, $Res Function(GuidedChatResponse) _then) = _$GuidedChatResponseCopyWithImpl;
@useResult
$Res call({
 String reply, bool isComplete, GuidedChatTaskDraft? extractedTask
});


$GuidedChatTaskDraftCopyWith<$Res>? get extractedTask;

}
/// @nodoc
class _$GuidedChatResponseCopyWithImpl<$Res>
    implements $GuidedChatResponseCopyWith<$Res> {
  _$GuidedChatResponseCopyWithImpl(this._self, this._then);

  final GuidedChatResponse _self;
  final $Res Function(GuidedChatResponse) _then;

/// Create a copy of GuidedChatResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? reply = null,Object? isComplete = null,Object? extractedTask = freezed,}) {
  return _then(_self.copyWith(
reply: null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,extractedTask: freezed == extractedTask ? _self.extractedTask : extractedTask // ignore: cast_nullable_to_non_nullable
as GuidedChatTaskDraft?,
  ));
}
/// Create a copy of GuidedChatResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuidedChatTaskDraftCopyWith<$Res>? get extractedTask {
    if (_self.extractedTask == null) {
    return null;
  }

  return $GuidedChatTaskDraftCopyWith<$Res>(_self.extractedTask!, (value) {
    return _then(_self.copyWith(extractedTask: value));
  });
}
}


/// Adds pattern-matching-related methods to [GuidedChatResponse].
extension GuidedChatResponsePatterns on GuidedChatResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GuidedChatResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GuidedChatResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GuidedChatResponse value)  $default,){
final _that = this;
switch (_that) {
case _GuidedChatResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GuidedChatResponse value)?  $default,){
final _that = this;
switch (_that) {
case _GuidedChatResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String reply,  bool isComplete,  GuidedChatTaskDraft? extractedTask)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GuidedChatResponse() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String reply,  bool isComplete,  GuidedChatTaskDraft? extractedTask)  $default,) {final _that = this;
switch (_that) {
case _GuidedChatResponse():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String reply,  bool isComplete,  GuidedChatTaskDraft? extractedTask)?  $default,) {final _that = this;
switch (_that) {
case _GuidedChatResponse() when $default != null:
return $default(_that.reply,_that.isComplete,_that.extractedTask);case _:
  return null;

}
}

}

/// @nodoc


class _GuidedChatResponse implements GuidedChatResponse {
  const _GuidedChatResponse({required this.reply, required this.isComplete, this.extractedTask});
  

/// The LLM's next conversational message to display to the user.
@override final  String reply;
/// True when the LLM has collected enough information to create the task.
@override final  bool isComplete;
/// The partially or fully resolved task draft. Populated when [isComplete]
/// is true.
@override final  GuidedChatTaskDraft? extractedTask;

/// Create a copy of GuidedChatResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GuidedChatResponseCopyWith<_GuidedChatResponse> get copyWith => __$GuidedChatResponseCopyWithImpl<_GuidedChatResponse>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GuidedChatResponse&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete)&&(identical(other.extractedTask, extractedTask) || other.extractedTask == extractedTask));
}


@override
int get hashCode => Object.hash(runtimeType,reply,isComplete,extractedTask);

@override
String toString() {
  return 'GuidedChatResponse(reply: $reply, isComplete: $isComplete, extractedTask: $extractedTask)';
}


}

/// @nodoc
abstract mixin class _$GuidedChatResponseCopyWith<$Res> implements $GuidedChatResponseCopyWith<$Res> {
  factory _$GuidedChatResponseCopyWith(_GuidedChatResponse value, $Res Function(_GuidedChatResponse) _then) = __$GuidedChatResponseCopyWithImpl;
@override @useResult
$Res call({
 String reply, bool isComplete, GuidedChatTaskDraft? extractedTask
});


@override $GuidedChatTaskDraftCopyWith<$Res>? get extractedTask;

}
/// @nodoc
class __$GuidedChatResponseCopyWithImpl<$Res>
    implements _$GuidedChatResponseCopyWith<$Res> {
  __$GuidedChatResponseCopyWithImpl(this._self, this._then);

  final _GuidedChatResponse _self;
  final $Res Function(_GuidedChatResponse) _then;

/// Create a copy of GuidedChatResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? reply = null,Object? isComplete = null,Object? extractedTask = freezed,}) {
  return _then(_GuidedChatResponse(
reply: null == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,extractedTask: freezed == extractedTask ? _self.extractedTask : extractedTask // ignore: cast_nullable_to_non_nullable
as GuidedChatTaskDraft?,
  ));
}

/// Create a copy of GuidedChatResponse
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GuidedChatTaskDraftCopyWith<$Res>? get extractedTask {
    if (_self.extractedTask == null) {
    return null;
  }

  return $GuidedChatTaskDraftCopyWith<$Res>(_self.extractedTask!, (value) {
    return _then(_self.copyWith(extractedTask: value));
  });
}
}

// dart format on
