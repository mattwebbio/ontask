// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'impact_milestone.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ImpactMilestone {

 String get id; String get title; String get body; DateTime get earnedAt; String get shareText;
/// Create a copy of ImpactMilestone
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImpactMilestoneCopyWith<ImpactMilestone> get copyWith => _$ImpactMilestoneCopyWithImpl<ImpactMilestone>(this as ImpactMilestone, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImpactMilestone&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.earnedAt, earnedAt) || other.earnedAt == earnedAt)&&(identical(other.shareText, shareText) || other.shareText == shareText));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,body,earnedAt,shareText);

@override
String toString() {
  return 'ImpactMilestone(id: $id, title: $title, body: $body, earnedAt: $earnedAt, shareText: $shareText)';
}


}

/// @nodoc
abstract mixin class $ImpactMilestoneCopyWith<$Res>  {
  factory $ImpactMilestoneCopyWith(ImpactMilestone value, $Res Function(ImpactMilestone) _then) = _$ImpactMilestoneCopyWithImpl;
@useResult
$Res call({
 String id, String title, String body, DateTime earnedAt, String shareText
});




}
/// @nodoc
class _$ImpactMilestoneCopyWithImpl<$Res>
    implements $ImpactMilestoneCopyWith<$Res> {
  _$ImpactMilestoneCopyWithImpl(this._self, this._then);

  final ImpactMilestone _self;
  final $Res Function(ImpactMilestone) _then;

/// Create a copy of ImpactMilestone
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? body = null,Object? earnedAt = null,Object? shareText = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,earnedAt: null == earnedAt ? _self.earnedAt : earnedAt // ignore: cast_nullable_to_non_nullable
as DateTime,shareText: null == shareText ? _self.shareText : shareText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ImpactMilestone].
extension ImpactMilestonePatterns on ImpactMilestone {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImpactMilestone value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImpactMilestone() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImpactMilestone value)  $default,){
final _that = this;
switch (_that) {
case _ImpactMilestone():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImpactMilestone value)?  $default,){
final _that = this;
switch (_that) {
case _ImpactMilestone() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String body,  DateTime earnedAt,  String shareText)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImpactMilestone() when $default != null:
return $default(_that.id,_that.title,_that.body,_that.earnedAt,_that.shareText);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String body,  DateTime earnedAt,  String shareText)  $default,) {final _that = this;
switch (_that) {
case _ImpactMilestone():
return $default(_that.id,_that.title,_that.body,_that.earnedAt,_that.shareText);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String body,  DateTime earnedAt,  String shareText)?  $default,) {final _that = this;
switch (_that) {
case _ImpactMilestone() when $default != null:
return $default(_that.id,_that.title,_that.body,_that.earnedAt,_that.shareText);case _:
  return null;

}
}

}

/// @nodoc


class _ImpactMilestone implements ImpactMilestone {
  const _ImpactMilestone({required this.id, required this.title, required this.body, required this.earnedAt, required this.shareText});
  

@override final  String id;
@override final  String title;
@override final  String body;
@override final  DateTime earnedAt;
@override final  String shareText;

/// Create a copy of ImpactMilestone
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImpactMilestoneCopyWith<_ImpactMilestone> get copyWith => __$ImpactMilestoneCopyWithImpl<_ImpactMilestone>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImpactMilestone&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.body, body) || other.body == body)&&(identical(other.earnedAt, earnedAt) || other.earnedAt == earnedAt)&&(identical(other.shareText, shareText) || other.shareText == shareText));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,body,earnedAt,shareText);

@override
String toString() {
  return 'ImpactMilestone(id: $id, title: $title, body: $body, earnedAt: $earnedAt, shareText: $shareText)';
}


}

/// @nodoc
abstract mixin class _$ImpactMilestoneCopyWith<$Res> implements $ImpactMilestoneCopyWith<$Res> {
  factory _$ImpactMilestoneCopyWith(_ImpactMilestone value, $Res Function(_ImpactMilestone) _then) = __$ImpactMilestoneCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String body, DateTime earnedAt, String shareText
});




}
/// @nodoc
class __$ImpactMilestoneCopyWithImpl<$Res>
    implements _$ImpactMilestoneCopyWith<$Res> {
  __$ImpactMilestoneCopyWithImpl(this._self, this._then);

  final _ImpactMilestone _self;
  final $Res Function(_ImpactMilestone) _then;

/// Create a copy of ImpactMilestone
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? body = null,Object? earnedAt = null,Object? shareText = null,}) {
  return _then(_ImpactMilestone(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,body: null == body ? _self.body : body // ignore: cast_nullable_to_non_nullable
as String,earnedAt: null == earnedAt ? _self.earnedAt : earnedAt // ignore: cast_nullable_to_non_nullable
as DateTime,shareText: null == shareText ? _self.shareText : shareText // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
