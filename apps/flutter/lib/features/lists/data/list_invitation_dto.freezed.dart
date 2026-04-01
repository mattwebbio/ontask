// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_invitation_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ListInvitationDto {

 String get invitationId; String get listId; String get listTitle; String get invitedByName; String get inviteeEmail; String get status; String get expiresAt;
/// Create a copy of ListInvitationDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListInvitationDtoCopyWith<ListInvitationDto> get copyWith => _$ListInvitationDtoCopyWithImpl<ListInvitationDto>(this as ListInvitationDto, _$identity);

  /// Serializes this ListInvitationDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListInvitationDto&&(identical(other.invitationId, invitationId) || other.invitationId == invitationId)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.listTitle, listTitle) || other.listTitle == listTitle)&&(identical(other.invitedByName, invitedByName) || other.invitedByName == invitedByName)&&(identical(other.inviteeEmail, inviteeEmail) || other.inviteeEmail == inviteeEmail)&&(identical(other.status, status) || other.status == status)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,invitationId,listId,listTitle,invitedByName,inviteeEmail,status,expiresAt);

@override
String toString() {
  return 'ListInvitationDto(invitationId: $invitationId, listId: $listId, listTitle: $listTitle, invitedByName: $invitedByName, inviteeEmail: $inviteeEmail, status: $status, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $ListInvitationDtoCopyWith<$Res>  {
  factory $ListInvitationDtoCopyWith(ListInvitationDto value, $Res Function(ListInvitationDto) _then) = _$ListInvitationDtoCopyWithImpl;
@useResult
$Res call({
 String invitationId, String listId, String listTitle, String invitedByName, String inviteeEmail, String status, String expiresAt
});




}
/// @nodoc
class _$ListInvitationDtoCopyWithImpl<$Res>
    implements $ListInvitationDtoCopyWith<$Res> {
  _$ListInvitationDtoCopyWithImpl(this._self, this._then);

  final ListInvitationDto _self;
  final $Res Function(ListInvitationDto) _then;

/// Create a copy of ListInvitationDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? invitationId = null,Object? listId = null,Object? listTitle = null,Object? invitedByName = null,Object? inviteeEmail = null,Object? status = null,Object? expiresAt = null,}) {
  return _then(_self.copyWith(
invitationId: null == invitationId ? _self.invitationId : invitationId // ignore: cast_nullable_to_non_nullable
as String,listId: null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String,listTitle: null == listTitle ? _self.listTitle : listTitle // ignore: cast_nullable_to_non_nullable
as String,invitedByName: null == invitedByName ? _self.invitedByName : invitedByName // ignore: cast_nullable_to_non_nullable
as String,inviteeEmail: null == inviteeEmail ? _self.inviteeEmail : inviteeEmail // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ListInvitationDto].
extension ListInvitationDtoPatterns on ListInvitationDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListInvitationDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListInvitationDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListInvitationDto value)  $default,){
final _that = this;
switch (_that) {
case _ListInvitationDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListInvitationDto value)?  $default,){
final _that = this;
switch (_that) {
case _ListInvitationDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String invitationId,  String listId,  String listTitle,  String invitedByName,  String inviteeEmail,  String status,  String expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListInvitationDto() when $default != null:
return $default(_that.invitationId,_that.listId,_that.listTitle,_that.invitedByName,_that.inviteeEmail,_that.status,_that.expiresAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String invitationId,  String listId,  String listTitle,  String invitedByName,  String inviteeEmail,  String status,  String expiresAt)  $default,) {final _that = this;
switch (_that) {
case _ListInvitationDto():
return $default(_that.invitationId,_that.listId,_that.listTitle,_that.invitedByName,_that.inviteeEmail,_that.status,_that.expiresAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String invitationId,  String listId,  String listTitle,  String invitedByName,  String inviteeEmail,  String status,  String expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _ListInvitationDto() when $default != null:
return $default(_that.invitationId,_that.listId,_that.listTitle,_that.invitedByName,_that.inviteeEmail,_that.status,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListInvitationDto extends ListInvitationDto {
  const _ListInvitationDto({required this.invitationId, required this.listId, required this.listTitle, required this.invitedByName, required this.inviteeEmail, required this.status, required this.expiresAt}): super._();
  factory _ListInvitationDto.fromJson(Map<String, dynamic> json) => _$ListInvitationDtoFromJson(json);

@override final  String invitationId;
@override final  String listId;
@override final  String listTitle;
@override final  String invitedByName;
@override final  String inviteeEmail;
@override final  String status;
@override final  String expiresAt;

/// Create a copy of ListInvitationDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListInvitationDtoCopyWith<_ListInvitationDto> get copyWith => __$ListInvitationDtoCopyWithImpl<_ListInvitationDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListInvitationDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListInvitationDto&&(identical(other.invitationId, invitationId) || other.invitationId == invitationId)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.listTitle, listTitle) || other.listTitle == listTitle)&&(identical(other.invitedByName, invitedByName) || other.invitedByName == invitedByName)&&(identical(other.inviteeEmail, inviteeEmail) || other.inviteeEmail == inviteeEmail)&&(identical(other.status, status) || other.status == status)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,invitationId,listId,listTitle,invitedByName,inviteeEmail,status,expiresAt);

@override
String toString() {
  return 'ListInvitationDto(invitationId: $invitationId, listId: $listId, listTitle: $listTitle, invitedByName: $invitedByName, inviteeEmail: $inviteeEmail, status: $status, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$ListInvitationDtoCopyWith<$Res> implements $ListInvitationDtoCopyWith<$Res> {
  factory _$ListInvitationDtoCopyWith(_ListInvitationDto value, $Res Function(_ListInvitationDto) _then) = __$ListInvitationDtoCopyWithImpl;
@override @useResult
$Res call({
 String invitationId, String listId, String listTitle, String invitedByName, String inviteeEmail, String status, String expiresAt
});




}
/// @nodoc
class __$ListInvitationDtoCopyWithImpl<$Res>
    implements _$ListInvitationDtoCopyWith<$Res> {
  __$ListInvitationDtoCopyWithImpl(this._self, this._then);

  final _ListInvitationDto _self;
  final $Res Function(_ListInvitationDto) _then;

/// Create a copy of ListInvitationDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? invitationId = null,Object? listId = null,Object? listTitle = null,Object? invitedByName = null,Object? inviteeEmail = null,Object? status = null,Object? expiresAt = null,}) {
  return _then(_ListInvitationDto(
invitationId: null == invitationId ? _self.invitationId : invitationId // ignore: cast_nullable_to_non_nullable
as String,listId: null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String,listTitle: null == listTitle ? _self.listTitle : listTitle // ignore: cast_nullable_to_non_nullable
as String,invitedByName: null == invitedByName ? _self.invitedByName : invitedByName // ignore: cast_nullable_to_non_nullable
as String,inviteeEmail: null == inviteeEmail ? _self.inviteeEmail : inviteeEmail // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
