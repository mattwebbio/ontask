// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_member.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListMember {

 String get userId; String get displayName; String get avatarInitials; String get role;// 'owner' | 'member'
 DateTime get joinedAt;
/// Create a copy of ListMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListMemberCopyWith<ListMember> get copyWith => _$ListMemberCopyWithImpl<ListMember>(this as ListMember, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarInitials, avatarInitials) || other.avatarInitials == avatarInitials)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}


@override
int get hashCode => Object.hash(runtimeType,userId,displayName,avatarInitials,role,joinedAt);

@override
String toString() {
  return 'ListMember(userId: $userId, displayName: $displayName, avatarInitials: $avatarInitials, role: $role, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class $ListMemberCopyWith<$Res>  {
  factory $ListMemberCopyWith(ListMember value, $Res Function(ListMember) _then) = _$ListMemberCopyWithImpl;
@useResult
$Res call({
 String userId, String displayName, String avatarInitials, String role, DateTime joinedAt
});




}
/// @nodoc
class _$ListMemberCopyWithImpl<$Res>
    implements $ListMemberCopyWith<$Res> {
  _$ListMemberCopyWithImpl(this._self, this._then);

  final ListMember _self;
  final $Res Function(ListMember) _then;

/// Create a copy of ListMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = null,Object? avatarInitials = null,Object? role = null,Object? joinedAt = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarInitials: null == avatarInitials ? _self.avatarInitials : avatarInitials // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ListMember].
extension ListMemberPatterns on ListMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListMember value)  $default,){
final _that = this;
switch (_that) {
case _ListMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListMember value)?  $default,){
final _that = this;
switch (_that) {
case _ListMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String displayName,  String avatarInitials,  String role,  DateTime joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListMember() when $default != null:
return $default(_that.userId,_that.displayName,_that.avatarInitials,_that.role,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String displayName,  String avatarInitials,  String role,  DateTime joinedAt)  $default,) {final _that = this;
switch (_that) {
case _ListMember():
return $default(_that.userId,_that.displayName,_that.avatarInitials,_that.role,_that.joinedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String displayName,  String avatarInitials,  String role,  DateTime joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _ListMember() when $default != null:
return $default(_that.userId,_that.displayName,_that.avatarInitials,_that.role,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ListMember implements ListMember {
  const _ListMember({required this.userId, required this.displayName, required this.avatarInitials, required this.role, required this.joinedAt});
  

@override final  String userId;
@override final  String displayName;
@override final  String avatarInitials;
@override final  String role;
// 'owner' | 'member'
@override final  DateTime joinedAt;

/// Create a copy of ListMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListMemberCopyWith<_ListMember> get copyWith => __$ListMemberCopyWithImpl<_ListMember>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarInitials, avatarInitials) || other.avatarInitials == avatarInitials)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}


@override
int get hashCode => Object.hash(runtimeType,userId,displayName,avatarInitials,role,joinedAt);

@override
String toString() {
  return 'ListMember(userId: $userId, displayName: $displayName, avatarInitials: $avatarInitials, role: $role, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$ListMemberCopyWith<$Res> implements $ListMemberCopyWith<$Res> {
  factory _$ListMemberCopyWith(_ListMember value, $Res Function(_ListMember) _then) = __$ListMemberCopyWithImpl;
@override @useResult
$Res call({
 String userId, String displayName, String avatarInitials, String role, DateTime joinedAt
});




}
/// @nodoc
class __$ListMemberCopyWithImpl<$Res>
    implements _$ListMemberCopyWith<$Res> {
  __$ListMemberCopyWithImpl(this._self, this._then);

  final _ListMember _self;
  final $Res Function(_ListMember) _then;

/// Create a copy of ListMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = null,Object? avatarInitials = null,Object? role = null,Object? joinedAt = null,}) {
  return _then(_ListMember(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarInitials: null == avatarInitials ? _self.avatarInitials : avatarInitials // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
