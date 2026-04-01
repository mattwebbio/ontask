// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nudge_proposal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$NudgeProposal {

 String get taskId; DateTime get proposedStartTime; DateTime get proposedEndTime; String get interpretation; String get confidence;
/// Create a copy of NudgeProposal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NudgeProposalCopyWith<NudgeProposal> get copyWith => _$NudgeProposalCopyWithImpl<NudgeProposal>(this as NudgeProposal, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NudgeProposal&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.proposedStartTime, proposedStartTime) || other.proposedStartTime == proposedStartTime)&&(identical(other.proposedEndTime, proposedEndTime) || other.proposedEndTime == proposedEndTime)&&(identical(other.interpretation, interpretation) || other.interpretation == interpretation)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,taskId,proposedStartTime,proposedEndTime,interpretation,confidence);

@override
String toString() {
  return 'NudgeProposal(taskId: $taskId, proposedStartTime: $proposedStartTime, proposedEndTime: $proposedEndTime, interpretation: $interpretation, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class $NudgeProposalCopyWith<$Res>  {
  factory $NudgeProposalCopyWith(NudgeProposal value, $Res Function(NudgeProposal) _then) = _$NudgeProposalCopyWithImpl;
@useResult
$Res call({
 String taskId, DateTime proposedStartTime, DateTime proposedEndTime, String interpretation, String confidence
});




}
/// @nodoc
class _$NudgeProposalCopyWithImpl<$Res>
    implements $NudgeProposalCopyWith<$Res> {
  _$NudgeProposalCopyWithImpl(this._self, this._then);

  final NudgeProposal _self;
  final $Res Function(NudgeProposal) _then;

/// Create a copy of NudgeProposal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? taskId = null,Object? proposedStartTime = null,Object? proposedEndTime = null,Object? interpretation = null,Object? confidence = null,}) {
  return _then(_self.copyWith(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,proposedStartTime: null == proposedStartTime ? _self.proposedStartTime : proposedStartTime // ignore: cast_nullable_to_non_nullable
as DateTime,proposedEndTime: null == proposedEndTime ? _self.proposedEndTime : proposedEndTime // ignore: cast_nullable_to_non_nullable
as DateTime,interpretation: null == interpretation ? _self.interpretation : interpretation // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [NudgeProposal].
extension NudgeProposalPatterns on NudgeProposal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NudgeProposal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NudgeProposal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NudgeProposal value)  $default,){
final _that = this;
switch (_that) {
case _NudgeProposal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NudgeProposal value)?  $default,){
final _that = this;
switch (_that) {
case _NudgeProposal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String taskId,  DateTime proposedStartTime,  DateTime proposedEndTime,  String interpretation,  String confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NudgeProposal() when $default != null:
return $default(_that.taskId,_that.proposedStartTime,_that.proposedEndTime,_that.interpretation,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String taskId,  DateTime proposedStartTime,  DateTime proposedEndTime,  String interpretation,  String confidence)  $default,) {final _that = this;
switch (_that) {
case _NudgeProposal():
return $default(_that.taskId,_that.proposedStartTime,_that.proposedEndTime,_that.interpretation,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String taskId,  DateTime proposedStartTime,  DateTime proposedEndTime,  String interpretation,  String confidence)?  $default,) {final _that = this;
switch (_that) {
case _NudgeProposal() when $default != null:
return $default(_that.taskId,_that.proposedStartTime,_that.proposedEndTime,_that.interpretation,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc


class _NudgeProposal implements NudgeProposal {
  const _NudgeProposal({required this.taskId, required this.proposedStartTime, required this.proposedEndTime, required this.interpretation, required this.confidence});
  

@override final  String taskId;
@override final  DateTime proposedStartTime;
@override final  DateTime proposedEndTime;
@override final  String interpretation;
@override final  String confidence;

/// Create a copy of NudgeProposal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NudgeProposalCopyWith<_NudgeProposal> get copyWith => __$NudgeProposalCopyWithImpl<_NudgeProposal>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NudgeProposal&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.proposedStartTime, proposedStartTime) || other.proposedStartTime == proposedStartTime)&&(identical(other.proposedEndTime, proposedEndTime) || other.proposedEndTime == proposedEndTime)&&(identical(other.interpretation, interpretation) || other.interpretation == interpretation)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,taskId,proposedStartTime,proposedEndTime,interpretation,confidence);

@override
String toString() {
  return 'NudgeProposal(taskId: $taskId, proposedStartTime: $proposedStartTime, proposedEndTime: $proposedEndTime, interpretation: $interpretation, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$NudgeProposalCopyWith<$Res> implements $NudgeProposalCopyWith<$Res> {
  factory _$NudgeProposalCopyWith(_NudgeProposal value, $Res Function(_NudgeProposal) _then) = __$NudgeProposalCopyWithImpl;
@override @useResult
$Res call({
 String taskId, DateTime proposedStartTime, DateTime proposedEndTime, String interpretation, String confidence
});




}
/// @nodoc
class __$NudgeProposalCopyWithImpl<$Res>
    implements _$NudgeProposalCopyWith<$Res> {
  __$NudgeProposalCopyWithImpl(this._self, this._then);

  final _NudgeProposal _self;
  final $Res Function(_NudgeProposal) _then;

/// Create a copy of NudgeProposal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? taskId = null,Object? proposedStartTime = null,Object? proposedEndTime = null,Object? interpretation = null,Object? confidence = null,}) {
  return _then(_NudgeProposal(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,proposedStartTime: null == proposedStartTime ? _self.proposedStartTime : proposedStartTime // ignore: cast_nullable_to_non_nullable
as DateTime,proposedEndTime: null == proposedEndTime ? _self.proposedEndTime : proposedEndTime // ignore: cast_nullable_to_non_nullable
as DateTime,interpretation: null == interpretation ? _self.interpretation : interpretation // ignore: cast_nullable_to_non_nullable
as String,confidence: null == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
