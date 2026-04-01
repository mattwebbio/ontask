// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_invitation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ListInvitation {

 String get invitationId; String get listId; String get listTitle; String get invitedByName; String get inviteeEmail; String get status;// 'pending' | 'accepted' | 'declined'
 DateTime get expiresAt;
/// Create a copy of ListInvitation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListInvitationCopyWith<ListInvitation> get copyWith => _$ListInvitationCopyWithImpl<ListInvitation>(this as ListInvitation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListInvitation&&(identical(other.invitationId, invitationId) || other.invitationId == invitationId)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.listTitle, listTitle) || other.listTitle == listTitle)&&(identical(other.invitedByName, invitedByName) || other.invitedByName == invitedByName)&&(identical(other.inviteeEmail, inviteeEmail) || other.inviteeEmail == inviteeEmail)&&(identical(other.status, status) || other.status == status)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,invitationId,listId,listTitle,invitedByName,inviteeEmail,status,expiresAt);

@override
String toString() {
  return 'ListInvitation(invitationId: $invitationId, listId: $listId, listTitle: $listTitle, invitedByName: $invitedByName, inviteeEmail: $inviteeEmail, status: $status, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class $ListInvitationCopyWith<$Res>  {
  factory $ListInvitationCopyWith(ListInvitation value, $Res Function(ListInvitation) _then) = _$ListInvitationCopyWithImpl;
@useResult
$Res call({
 String invitationId, String listId, String listTitle, String invitedByName, String inviteeEmail, String status, DateTime expiresAt
});




}
/// @nodoc
class _$ListInvitationCopyWithImpl<$Res>
    implements $ListInvitationCopyWith<$Res> {
  _$ListInvitationCopyWithImpl(this._self, this._then);

  final ListInvitation _self;
  final $Res Function(ListInvitation) _then;

/// Create a copy of ListInvitation
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
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ListInvitation].
extension ListInvitationPatterns on ListInvitation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListInvitation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListInvitation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListInvitation value)  $default,){
final _that = this;
switch (_that) {
case _ListInvitation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListInvitation value)?  $default,){
final _that = this;
switch (_that) {
case _ListInvitation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String invitationId,  String listId,  String listTitle,  String invitedByName,  String inviteeEmail,  String status,  DateTime expiresAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListInvitation() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String invitationId,  String listId,  String listTitle,  String invitedByName,  String inviteeEmail,  String status,  DateTime expiresAt)  $default,) {final _that = this;
switch (_that) {
case _ListInvitation():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String invitationId,  String listId,  String listTitle,  String invitedByName,  String inviteeEmail,  String status,  DateTime expiresAt)?  $default,) {final _that = this;
switch (_that) {
case _ListInvitation() when $default != null:
return $default(_that.invitationId,_that.listId,_that.listTitle,_that.invitedByName,_that.inviteeEmail,_that.status,_that.expiresAt);case _:
  return null;

}
}

}

/// @nodoc


class _ListInvitation implements ListInvitation {
  const _ListInvitation({required this.invitationId, required this.listId, required this.listTitle, required this.invitedByName, required this.inviteeEmail, required this.status, required this.expiresAt});
  

@override final  String invitationId;
@override final  String listId;
@override final  String listTitle;
@override final  String invitedByName;
@override final  String inviteeEmail;
@override final  String status;
// 'pending' | 'accepted' | 'declined'
@override final  DateTime expiresAt;

/// Create a copy of ListInvitation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListInvitationCopyWith<_ListInvitation> get copyWith => __$ListInvitationCopyWithImpl<_ListInvitation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListInvitation&&(identical(other.invitationId, invitationId) || other.invitationId == invitationId)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.listTitle, listTitle) || other.listTitle == listTitle)&&(identical(other.invitedByName, invitedByName) || other.invitedByName == invitedByName)&&(identical(other.inviteeEmail, inviteeEmail) || other.inviteeEmail == inviteeEmail)&&(identical(other.status, status) || other.status == status)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt));
}


@override
int get hashCode => Object.hash(runtimeType,invitationId,listId,listTitle,invitedByName,inviteeEmail,status,expiresAt);

@override
String toString() {
  return 'ListInvitation(invitationId: $invitationId, listId: $listId, listTitle: $listTitle, invitedByName: $invitedByName, inviteeEmail: $inviteeEmail, status: $status, expiresAt: $expiresAt)';
}


}

/// @nodoc
abstract mixin class _$ListInvitationCopyWith<$Res> implements $ListInvitationCopyWith<$Res> {
  factory _$ListInvitationCopyWith(_ListInvitation value, $Res Function(_ListInvitation) _then) = __$ListInvitationCopyWithImpl;
@override @useResult
$Res call({
 String invitationId, String listId, String listTitle, String invitedByName, String inviteeEmail, String status, DateTime expiresAt
});




}
/// @nodoc
class __$ListInvitationCopyWithImpl<$Res>
    implements _$ListInvitationCopyWith<$Res> {
  __$ListInvitationCopyWithImpl(this._self, this._then);

  final _ListInvitation _self;
  final $Res Function(_ListInvitation) _then;

/// Create a copy of ListInvitation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? invitationId = null,Object? listId = null,Object? listTitle = null,Object? invitedByName = null,Object? inviteeEmail = null,Object? status = null,Object? expiresAt = null,}) {
  return _then(_ListInvitation(
invitationId: null == invitationId ? _self.invitationId : invitationId // ignore: cast_nullable_to_non_nullable
as String,listId: null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String,listTitle: null == listTitle ? _self.listTitle : listTitle // ignore: cast_nullable_to_non_nullable
as String,invitedByName: null == invitedByName ? _self.invitedByName : invitedByName // ignore: cast_nullable_to_non_nullable
as String,inviteeEmail: null == inviteeEmail ? _self.inviteeEmail : inviteeEmail // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,expiresAt: null == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
