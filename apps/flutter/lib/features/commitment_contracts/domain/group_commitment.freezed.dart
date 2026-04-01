// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'group_commitment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$GroupCommitmentMember {

 String get userId; int? get stakeAmountCents; bool get approved; bool get poolModeOptIn;
/// Create a copy of GroupCommitmentMember
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupCommitmentMemberCopyWith<GroupCommitmentMember> get copyWith => _$GroupCommitmentMemberCopyWithImpl<GroupCommitmentMember>(this as GroupCommitmentMember, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupCommitmentMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.stakeAmountCents, stakeAmountCents) || other.stakeAmountCents == stakeAmountCents)&&(identical(other.approved, approved) || other.approved == approved)&&(identical(other.poolModeOptIn, poolModeOptIn) || other.poolModeOptIn == poolModeOptIn));
}


@override
int get hashCode => Object.hash(runtimeType,userId,stakeAmountCents,approved,poolModeOptIn);

@override
String toString() {
  return 'GroupCommitmentMember(userId: $userId, stakeAmountCents: $stakeAmountCents, approved: $approved, poolModeOptIn: $poolModeOptIn)';
}


}

/// @nodoc
abstract mixin class $GroupCommitmentMemberCopyWith<$Res>  {
  factory $GroupCommitmentMemberCopyWith(GroupCommitmentMember value, $Res Function(GroupCommitmentMember) _then) = _$GroupCommitmentMemberCopyWithImpl;
@useResult
$Res call({
 String userId, int? stakeAmountCents, bool approved, bool poolModeOptIn
});




}
/// @nodoc
class _$GroupCommitmentMemberCopyWithImpl<$Res>
    implements $GroupCommitmentMemberCopyWith<$Res> {
  _$GroupCommitmentMemberCopyWithImpl(this._self, this._then);

  final GroupCommitmentMember _self;
  final $Res Function(GroupCommitmentMember) _then;

/// Create a copy of GroupCommitmentMember
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? userId = null,Object? stakeAmountCents = freezed,Object? approved = null,Object? poolModeOptIn = null,}) {
  return _then(_self.copyWith(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,stakeAmountCents: freezed == stakeAmountCents ? _self.stakeAmountCents : stakeAmountCents // ignore: cast_nullable_to_non_nullable
as int?,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,poolModeOptIn: null == poolModeOptIn ? _self.poolModeOptIn : poolModeOptIn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupCommitmentMember].
extension GroupCommitmentMemberPatterns on GroupCommitmentMember {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupCommitmentMember value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupCommitmentMember() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupCommitmentMember value)  $default,){
final _that = this;
switch (_that) {
case _GroupCommitmentMember():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupCommitmentMember value)?  $default,){
final _that = this;
switch (_that) {
case _GroupCommitmentMember() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String userId,  int? stakeAmountCents,  bool approved,  bool poolModeOptIn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupCommitmentMember() when $default != null:
return $default(_that.userId,_that.stakeAmountCents,_that.approved,_that.poolModeOptIn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String userId,  int? stakeAmountCents,  bool approved,  bool poolModeOptIn)  $default,) {final _that = this;
switch (_that) {
case _GroupCommitmentMember():
return $default(_that.userId,_that.stakeAmountCents,_that.approved,_that.poolModeOptIn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String userId,  int? stakeAmountCents,  bool approved,  bool poolModeOptIn)?  $default,) {final _that = this;
switch (_that) {
case _GroupCommitmentMember() when $default != null:
return $default(_that.userId,_that.stakeAmountCents,_that.approved,_that.poolModeOptIn);case _:
  return null;

}
}

}

/// @nodoc


class _GroupCommitmentMember implements GroupCommitmentMember {
  const _GroupCommitmentMember({required this.userId, this.stakeAmountCents, this.approved = false, this.poolModeOptIn = false});
  

@override final  String userId;
@override final  int? stakeAmountCents;
@override@JsonKey() final  bool approved;
@override@JsonKey() final  bool poolModeOptIn;

/// Create a copy of GroupCommitmentMember
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupCommitmentMemberCopyWith<_GroupCommitmentMember> get copyWith => __$GroupCommitmentMemberCopyWithImpl<_GroupCommitmentMember>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupCommitmentMember&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.stakeAmountCents, stakeAmountCents) || other.stakeAmountCents == stakeAmountCents)&&(identical(other.approved, approved) || other.approved == approved)&&(identical(other.poolModeOptIn, poolModeOptIn) || other.poolModeOptIn == poolModeOptIn));
}


@override
int get hashCode => Object.hash(runtimeType,userId,stakeAmountCents,approved,poolModeOptIn);

@override
String toString() {
  return 'GroupCommitmentMember(userId: $userId, stakeAmountCents: $stakeAmountCents, approved: $approved, poolModeOptIn: $poolModeOptIn)';
}


}

/// @nodoc
abstract mixin class _$GroupCommitmentMemberCopyWith<$Res> implements $GroupCommitmentMemberCopyWith<$Res> {
  factory _$GroupCommitmentMemberCopyWith(_GroupCommitmentMember value, $Res Function(_GroupCommitmentMember) _then) = __$GroupCommitmentMemberCopyWithImpl;
@override @useResult
$Res call({
 String userId, int? stakeAmountCents, bool approved, bool poolModeOptIn
});




}
/// @nodoc
class __$GroupCommitmentMemberCopyWithImpl<$Res>
    implements _$GroupCommitmentMemberCopyWith<$Res> {
  __$GroupCommitmentMemberCopyWithImpl(this._self, this._then);

  final _GroupCommitmentMember _self;
  final $Res Function(_GroupCommitmentMember) _then;

/// Create a copy of GroupCommitmentMember
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? userId = null,Object? stakeAmountCents = freezed,Object? approved = null,Object? poolModeOptIn = null,}) {
  return _then(_GroupCommitmentMember(
userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,stakeAmountCents: freezed == stakeAmountCents ? _self.stakeAmountCents : stakeAmountCents // ignore: cast_nullable_to_non_nullable
as int?,approved: null == approved ? _self.approved : approved // ignore: cast_nullable_to_non_nullable
as bool,poolModeOptIn: null == poolModeOptIn ? _self.poolModeOptIn : poolModeOptIn // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$GroupCommitment {

 String get id; String get listId; String get taskId; String get proposedByUserId; String get status;// 'pending' | 'active' | 'cancelled'
 List<GroupCommitmentMember> get members; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of GroupCommitment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupCommitmentCopyWith<GroupCommitment> get copyWith => _$GroupCommitmentCopyWithImpl<GroupCommitment>(this as GroupCommitment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupCommitment&&(identical(other.id, id) || other.id == id)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.proposedByUserId, proposedByUserId) || other.proposedByUserId == proposedByUserId)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.members, members)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,listId,taskId,proposedByUserId,status,const DeepCollectionEquality().hash(members),createdAt,updatedAt);

@override
String toString() {
  return 'GroupCommitment(id: $id, listId: $listId, taskId: $taskId, proposedByUserId: $proposedByUserId, status: $status, members: $members, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $GroupCommitmentCopyWith<$Res>  {
  factory $GroupCommitmentCopyWith(GroupCommitment value, $Res Function(GroupCommitment) _then) = _$GroupCommitmentCopyWithImpl;
@useResult
$Res call({
 String id, String listId, String taskId, String proposedByUserId, String status, List<GroupCommitmentMember> members, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$GroupCommitmentCopyWithImpl<$Res>
    implements $GroupCommitmentCopyWith<$Res> {
  _$GroupCommitmentCopyWithImpl(this._self, this._then);

  final GroupCommitment _self;
  final $Res Function(GroupCommitment) _then;

/// Create a copy of GroupCommitment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? listId = null,Object? taskId = null,Object? proposedByUserId = null,Object? status = null,Object? members = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,listId: null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,proposedByUserId: null == proposedByUserId ? _self.proposedByUserId : proposedByUserId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<GroupCommitmentMember>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupCommitment].
extension GroupCommitmentPatterns on GroupCommitment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupCommitment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupCommitment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupCommitment value)  $default,){
final _that = this;
switch (_that) {
case _GroupCommitment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupCommitment value)?  $default,){
final _that = this;
switch (_that) {
case _GroupCommitment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String listId,  String taskId,  String proposedByUserId,  String status,  List<GroupCommitmentMember> members,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupCommitment() when $default != null:
return $default(_that.id,_that.listId,_that.taskId,_that.proposedByUserId,_that.status,_that.members,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String listId,  String taskId,  String proposedByUserId,  String status,  List<GroupCommitmentMember> members,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _GroupCommitment():
return $default(_that.id,_that.listId,_that.taskId,_that.proposedByUserId,_that.status,_that.members,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String listId,  String taskId,  String proposedByUserId,  String status,  List<GroupCommitmentMember> members,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _GroupCommitment() when $default != null:
return $default(_that.id,_that.listId,_that.taskId,_that.proposedByUserId,_that.status,_that.members,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _GroupCommitment extends GroupCommitment {
  const _GroupCommitment({required this.id, required this.listId, required this.taskId, required this.proposedByUserId, required this.status, final  List<GroupCommitmentMember> members = const <GroupCommitmentMember>[], required this.createdAt, required this.updatedAt}): _members = members,super._();
  

@override final  String id;
@override final  String listId;
@override final  String taskId;
@override final  String proposedByUserId;
@override final  String status;
// 'pending' | 'active' | 'cancelled'
 final  List<GroupCommitmentMember> _members;
// 'pending' | 'active' | 'cancelled'
@override@JsonKey() List<GroupCommitmentMember> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of GroupCommitment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupCommitmentCopyWith<_GroupCommitment> get copyWith => __$GroupCommitmentCopyWithImpl<_GroupCommitment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupCommitment&&(identical(other.id, id) || other.id == id)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.proposedByUserId, proposedByUserId) || other.proposedByUserId == proposedByUserId)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._members, _members)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,listId,taskId,proposedByUserId,status,const DeepCollectionEquality().hash(_members),createdAt,updatedAt);

@override
String toString() {
  return 'GroupCommitment(id: $id, listId: $listId, taskId: $taskId, proposedByUserId: $proposedByUserId, status: $status, members: $members, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$GroupCommitmentCopyWith<$Res> implements $GroupCommitmentCopyWith<$Res> {
  factory _$GroupCommitmentCopyWith(_GroupCommitment value, $Res Function(_GroupCommitment) _then) = __$GroupCommitmentCopyWithImpl;
@override @useResult
$Res call({
 String id, String listId, String taskId, String proposedByUserId, String status, List<GroupCommitmentMember> members, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$GroupCommitmentCopyWithImpl<$Res>
    implements _$GroupCommitmentCopyWith<$Res> {
  __$GroupCommitmentCopyWithImpl(this._self, this._then);

  final _GroupCommitment _self;
  final $Res Function(_GroupCommitment) _then;

/// Create a copy of GroupCommitment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? listId = null,Object? taskId = null,Object? proposedByUserId = null,Object? status = null,Object? members = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_GroupCommitment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,listId: null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String,taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,proposedByUserId: null == proposedByUserId ? _self.proposedByUserId : proposedByUserId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<GroupCommitmentMember>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
