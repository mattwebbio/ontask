// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'completion_prediction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CompletionPrediction {

 String get entityId; DateTime? get predictedDate; PredictionStatus get status; int get tasksRemaining; int get estimatedMinutesRemaining; int get availableWindowsCount; String get reasoning;
/// Create a copy of CompletionPrediction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CompletionPredictionCopyWith<CompletionPrediction> get copyWith => _$CompletionPredictionCopyWithImpl<CompletionPrediction>(this as CompletionPrediction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CompletionPrediction&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.predictedDate, predictedDate) || other.predictedDate == predictedDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.tasksRemaining, tasksRemaining) || other.tasksRemaining == tasksRemaining)&&(identical(other.estimatedMinutesRemaining, estimatedMinutesRemaining) || other.estimatedMinutesRemaining == estimatedMinutesRemaining)&&(identical(other.availableWindowsCount, availableWindowsCount) || other.availableWindowsCount == availableWindowsCount)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning));
}


@override
int get hashCode => Object.hash(runtimeType,entityId,predictedDate,status,tasksRemaining,estimatedMinutesRemaining,availableWindowsCount,reasoning);

@override
String toString() {
  return 'CompletionPrediction(entityId: $entityId, predictedDate: $predictedDate, status: $status, tasksRemaining: $tasksRemaining, estimatedMinutesRemaining: $estimatedMinutesRemaining, availableWindowsCount: $availableWindowsCount, reasoning: $reasoning)';
}


}

/// @nodoc
abstract mixin class $CompletionPredictionCopyWith<$Res>  {
  factory $CompletionPredictionCopyWith(CompletionPrediction value, $Res Function(CompletionPrediction) _then) = _$CompletionPredictionCopyWithImpl;
@useResult
$Res call({
 String entityId, DateTime? predictedDate, PredictionStatus status, int tasksRemaining, int estimatedMinutesRemaining, int availableWindowsCount, String reasoning
});




}
/// @nodoc
class _$CompletionPredictionCopyWithImpl<$Res>
    implements $CompletionPredictionCopyWith<$Res> {
  _$CompletionPredictionCopyWithImpl(this._self, this._then);

  final CompletionPrediction _self;
  final $Res Function(CompletionPrediction) _then;

/// Create a copy of CompletionPrediction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? entityId = null,Object? predictedDate = freezed,Object? status = null,Object? tasksRemaining = null,Object? estimatedMinutesRemaining = null,Object? availableWindowsCount = null,Object? reasoning = null,}) {
  return _then(_self.copyWith(
entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,predictedDate: freezed == predictedDate ? _self.predictedDate : predictedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PredictionStatus,tasksRemaining: null == tasksRemaining ? _self.tasksRemaining : tasksRemaining // ignore: cast_nullable_to_non_nullable
as int,estimatedMinutesRemaining: null == estimatedMinutesRemaining ? _self.estimatedMinutesRemaining : estimatedMinutesRemaining // ignore: cast_nullable_to_non_nullable
as int,availableWindowsCount: null == availableWindowsCount ? _self.availableWindowsCount : availableWindowsCount // ignore: cast_nullable_to_non_nullable
as int,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CompletionPrediction].
extension CompletionPredictionPatterns on CompletionPrediction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CompletionPrediction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CompletionPrediction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CompletionPrediction value)  $default,){
final _that = this;
switch (_that) {
case _CompletionPrediction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CompletionPrediction value)?  $default,){
final _that = this;
switch (_that) {
case _CompletionPrediction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String entityId,  DateTime? predictedDate,  PredictionStatus status,  int tasksRemaining,  int estimatedMinutesRemaining,  int availableWindowsCount,  String reasoning)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CompletionPrediction() when $default != null:
return $default(_that.entityId,_that.predictedDate,_that.status,_that.tasksRemaining,_that.estimatedMinutesRemaining,_that.availableWindowsCount,_that.reasoning);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String entityId,  DateTime? predictedDate,  PredictionStatus status,  int tasksRemaining,  int estimatedMinutesRemaining,  int availableWindowsCount,  String reasoning)  $default,) {final _that = this;
switch (_that) {
case _CompletionPrediction():
return $default(_that.entityId,_that.predictedDate,_that.status,_that.tasksRemaining,_that.estimatedMinutesRemaining,_that.availableWindowsCount,_that.reasoning);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String entityId,  DateTime? predictedDate,  PredictionStatus status,  int tasksRemaining,  int estimatedMinutesRemaining,  int availableWindowsCount,  String reasoning)?  $default,) {final _that = this;
switch (_that) {
case _CompletionPrediction() when $default != null:
return $default(_that.entityId,_that.predictedDate,_that.status,_that.tasksRemaining,_that.estimatedMinutesRemaining,_that.availableWindowsCount,_that.reasoning);case _:
  return null;

}
}

}

/// @nodoc


class _CompletionPrediction implements CompletionPrediction {
  const _CompletionPrediction({required this.entityId, required this.predictedDate, required this.status, required this.tasksRemaining, required this.estimatedMinutesRemaining, required this.availableWindowsCount, required this.reasoning});
  

@override final  String entityId;
@override final  DateTime? predictedDate;
@override final  PredictionStatus status;
@override final  int tasksRemaining;
@override final  int estimatedMinutesRemaining;
@override final  int availableWindowsCount;
@override final  String reasoning;

/// Create a copy of CompletionPrediction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CompletionPredictionCopyWith<_CompletionPrediction> get copyWith => __$CompletionPredictionCopyWithImpl<_CompletionPrediction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CompletionPrediction&&(identical(other.entityId, entityId) || other.entityId == entityId)&&(identical(other.predictedDate, predictedDate) || other.predictedDate == predictedDate)&&(identical(other.status, status) || other.status == status)&&(identical(other.tasksRemaining, tasksRemaining) || other.tasksRemaining == tasksRemaining)&&(identical(other.estimatedMinutesRemaining, estimatedMinutesRemaining) || other.estimatedMinutesRemaining == estimatedMinutesRemaining)&&(identical(other.availableWindowsCount, availableWindowsCount) || other.availableWindowsCount == availableWindowsCount)&&(identical(other.reasoning, reasoning) || other.reasoning == reasoning));
}


@override
int get hashCode => Object.hash(runtimeType,entityId,predictedDate,status,tasksRemaining,estimatedMinutesRemaining,availableWindowsCount,reasoning);

@override
String toString() {
  return 'CompletionPrediction(entityId: $entityId, predictedDate: $predictedDate, status: $status, tasksRemaining: $tasksRemaining, estimatedMinutesRemaining: $estimatedMinutesRemaining, availableWindowsCount: $availableWindowsCount, reasoning: $reasoning)';
}


}

/// @nodoc
abstract mixin class _$CompletionPredictionCopyWith<$Res> implements $CompletionPredictionCopyWith<$Res> {
  factory _$CompletionPredictionCopyWith(_CompletionPrediction value, $Res Function(_CompletionPrediction) _then) = __$CompletionPredictionCopyWithImpl;
@override @useResult
$Res call({
 String entityId, DateTime? predictedDate, PredictionStatus status, int tasksRemaining, int estimatedMinutesRemaining, int availableWindowsCount, String reasoning
});




}
/// @nodoc
class __$CompletionPredictionCopyWithImpl<$Res>
    implements _$CompletionPredictionCopyWith<$Res> {
  __$CompletionPredictionCopyWithImpl(this._self, this._then);

  final _CompletionPrediction _self;
  final $Res Function(_CompletionPrediction) _then;

/// Create a copy of CompletionPrediction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? entityId = null,Object? predictedDate = freezed,Object? status = null,Object? tasksRemaining = null,Object? estimatedMinutesRemaining = null,Object? availableWindowsCount = null,Object? reasoning = null,}) {
  return _then(_CompletionPrediction(
entityId: null == entityId ? _self.entityId : entityId // ignore: cast_nullable_to_non_nullable
as String,predictedDate: freezed == predictedDate ? _self.predictedDate : predictedDate // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PredictionStatus,tasksRemaining: null == tasksRemaining ? _self.tasksRemaining : tasksRemaining // ignore: cast_nullable_to_non_nullable
as int,estimatedMinutesRemaining: null == estimatedMinutesRemaining ? _self.estimatedMinutesRemaining : estimatedMinutesRemaining // ignore: cast_nullable_to_non_nullable
as int,availableWindowsCount: null == availableWindowsCount ? _self.availableWindowsCount : availableWindowsCount // ignore: cast_nullable_to_non_nullable
as int,reasoning: null == reasoning ? _self.reasoning : reasoning // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
