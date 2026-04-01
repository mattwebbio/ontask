// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_member_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ListMemberDto {

 String get userId; String get displayName; String get avatarInitials; String get role; String get joinedAt;@JsonKey(defaultValue: 0) int get roundRobinIndex;
/// Create a copy of ListMemberDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListMemberDtoCopyWith<ListMemberDto> get copyWith => _$ListMemberDtoCopyWithImpl<ListMemberDto>(this as ListMemberDto, _$identity);

  /// Serializes this ListMemberDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListMemberDto&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarInitials, avatarInitials) || other.avatarInitials == avatarInitials)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.roundRobinIndex, roundRobinIndex) || other.roundRobinIndex == roundRobinIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,avatarInitials,role,joinedAt,roundRobinIndex);

@override
String toString() {
  return 'ListMemberDto(userId: $userId, displayName: $displayName, avatarInitials: $avatarInitials, role: $role, joinedAt: $joinedAt, roundRobinIndex: $roundRobinIndex)';
}


}

/// @nodoc
abstract mixin class $ListMemberDtoCopyWith<$Res>  {
  factory $ListMemberDtoCopyWith(ListMemberDto value, $Res Function(ListMemberDto) _then) = _$ListMemberDtoCopyWithImpl;
@useResult
$Res call({
 String userId, String displayName, String avatarInitials, String role, String joinedAt,@JsonKey(defaultValue: 0) int roundRobinIndex
});




}
/// @nodoc
class _$ListMemberDtoCopyWithImpl<$Res>
    implements $ListMemberDtoCopyWith<$Res> {
  _$ListMemberDtoCopyWithImpl(this._self, this._then);

  final ListMemberDto _self;
  final $Res Function(ListMemberDto) _then;

/// Create a copy of ListMemberDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? displayName = null,Object? avatarInitials = null,Object? role = null,Object? joinedAt = null,Object? roundRobinIndex = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarInitials: null == avatarInitials ? _self.avatarInitials : avatarInitials // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as String,roundRobinIndex: null == roundRobinIndex ? _self.roundRobinIndex : roundRobinIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ListMemberDto].
extension ListMemberDtoPatterns on ListMemberDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListMemberDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListMemberDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListMemberDto value)  $default,){
final _that = this;
switch (_that) {
case _ListMemberDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListMemberDto value)?  $default,){
final _that = this;
switch (_that) {
case _ListMemberDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  String displayName,  String avatarInitials,  String role,  String joinedAt, @JsonKey(defaultValue: 0)  int roundRobinIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListMemberDto() when $default != null:
return $default(_that.userId,_that.displayName,_that.avatarInitials,_that.role,_that.joinedAt,_that.roundRobinIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  String displayName,  String avatarInitials,  String role,  String joinedAt, @JsonKey(defaultValue: 0)  int roundRobinIndex)  $default,) {final _that = this;
switch (_that) {
case _ListMemberDto():
return $default(_that.userId,_that.displayName,_that.avatarInitials,_that.role,_that.joinedAt,_that.roundRobinIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  String displayName,  String avatarInitials,  String role,  String joinedAt, @JsonKey(defaultValue: 0)  int roundRobinIndex)?  $default,) {final _that = this;
switch (_that) {
case _ListMemberDto() when $default != null:
return $default(_that.userId,_that.displayName,_that.avatarInitials,_that.role,_that.joinedAt,_that.roundRobinIndex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListMemberDto extends ListMemberDto {
  const _ListMemberDto({required this.userId, required this.displayName, required this.avatarInitials, required this.role, required this.joinedAt, @JsonKey(defaultValue: 0) this.roundRobinIndex = 0}): super._();
  factory _ListMemberDto.fromJson(Map<String, dynamic> json) => _$ListMemberDtoFromJson(json);

@override final  String userId;
@override final  String displayName;
@override final  String avatarInitials;
@override final  String role;
@override final  String joinedAt;
@override@JsonKey(defaultValue: 0) final  int roundRobinIndex;

/// Create a copy of ListMemberDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListMemberDtoCopyWith<_ListMemberDto> get copyWith => __$ListMemberDtoCopyWithImpl<_ListMemberDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListMemberDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListMemberDto&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.avatarInitials, avatarInitials) || other.avatarInitials == avatarInitials)&&(identical(other.role, role) || other.role == role)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt)&&(identical(other.roundRobinIndex, roundRobinIndex) || other.roundRobinIndex == roundRobinIndex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,userId,displayName,avatarInitials,role,joinedAt,roundRobinIndex);

@override
String toString() {
  return 'ListMemberDto(userId: $userId, displayName: $displayName, avatarInitials: $avatarInitials, role: $role, joinedAt: $joinedAt, roundRobinIndex: $roundRobinIndex)';
}


}

/// @nodoc
abstract mixin class _$ListMemberDtoCopyWith<$Res> implements $ListMemberDtoCopyWith<$Res> {
  factory _$ListMemberDtoCopyWith(_ListMemberDto value, $Res Function(_ListMemberDto) _then) = __$ListMemberDtoCopyWithImpl;
@override @useResult
$Res call({
 String userId, String displayName, String avatarInitials, String role, String joinedAt,@JsonKey(defaultValue: 0) int roundRobinIndex
});




}
/// @nodoc
class __$ListMemberDtoCopyWithImpl<$Res>
    implements _$ListMemberDtoCopyWith<$Res> {
  __$ListMemberDtoCopyWithImpl(this._self, this._then);

  final _ListMemberDto _self;
  final $Res Function(_ListMemberDto) _then;

/// Create a copy of ListMemberDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? displayName = null,Object? avatarInitials = null,Object? role = null,Object? joinedAt = null,Object? roundRobinIndex = null,}) {
  return _then(_ListMemberDto(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,avatarInitials: null == avatarInitials ? _self.avatarInitials : avatarInitials // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as String,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as String,roundRobinIndex: null == roundRobinIndex ? _self.roundRobinIndex : roundRobinIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
