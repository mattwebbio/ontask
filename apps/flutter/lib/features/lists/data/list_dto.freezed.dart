// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'list_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ListDto {

 String get id; String get title; String? get defaultDueDate; int get position; String? get archivedAt; String get createdAt; String get updatedAt;@JsonKey(defaultValue: false) bool get isShared;@JsonKey(defaultValue: 1) int get memberCount;@JsonKey(defaultValue: <String>[]) List<String> get memberAvatarInitials;@JsonKey(defaultValue: null) String? get assignmentStrategy;
/// Create a copy of ListDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ListDtoCopyWith<ListDto> get copyWith => _$ListDtoCopyWithImpl<ListDto>(this as ListDto, _$identity);

  /// Serializes this ListDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ListDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.defaultDueDate, defaultDueDate) || other.defaultDueDate == defaultDueDate)&&(identical(other.position, position) || other.position == position)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isShared, isShared) || other.isShared == isShared)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&const DeepCollectionEquality().equals(other.memberAvatarInitials, memberAvatarInitials)&&(identical(other.assignmentStrategy, assignmentStrategy) || other.assignmentStrategy == assignmentStrategy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,defaultDueDate,position,archivedAt,createdAt,updatedAt,isShared,memberCount,const DeepCollectionEquality().hash(memberAvatarInitials),assignmentStrategy);

@override
String toString() {
  return 'ListDto(id: $id, title: $title, defaultDueDate: $defaultDueDate, position: $position, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, isShared: $isShared, memberCount: $memberCount, memberAvatarInitials: $memberAvatarInitials, assignmentStrategy: $assignmentStrategy)';
}


}

/// @nodoc
abstract mixin class $ListDtoCopyWith<$Res>  {
  factory $ListDtoCopyWith(ListDto value, $Res Function(ListDto) _then) = _$ListDtoCopyWithImpl;
@useResult
$Res call({
 String id, String title, String? defaultDueDate, int position, String? archivedAt, String createdAt, String updatedAt,@JsonKey(defaultValue: false) bool isShared,@JsonKey(defaultValue: 1) int memberCount,@JsonKey(defaultValue: <String>[]) List<String> memberAvatarInitials,@JsonKey(defaultValue: null) String? assignmentStrategy
});




}
/// @nodoc
class _$ListDtoCopyWithImpl<$Res>
    implements $ListDtoCopyWith<$Res> {
  _$ListDtoCopyWithImpl(this._self, this._then);

  final ListDto _self;
  final $Res Function(ListDto) _then;

/// Create a copy of ListDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? defaultDueDate = freezed,Object? position = null,Object? archivedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isShared = null,Object? memberCount = null,Object? memberAvatarInitials = null,Object? assignmentStrategy = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,defaultDueDate: freezed == defaultDueDate ? _self.defaultDueDate : defaultDueDate // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,isShared: null == isShared ? _self.isShared : isShared // ignore: cast_nullable_to_non_nullable
as bool,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,memberAvatarInitials: null == memberAvatarInitials ? _self.memberAvatarInitials : memberAvatarInitials // ignore: cast_nullable_to_non_nullable
as List<String>,assignmentStrategy: freezed == assignmentStrategy ? _self.assignmentStrategy : assignmentStrategy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [ListDto].
extension ListDtoPatterns on ListDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ListDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ListDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ListDto value)  $default,){
final _that = this;
switch (_that) {
case _ListDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ListDto value)?  $default,){
final _that = this;
switch (_that) {
case _ListDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String? defaultDueDate,  int position,  String? archivedAt,  String createdAt,  String updatedAt, @JsonKey(defaultValue: false)  bool isShared, @JsonKey(defaultValue: 1)  int memberCount, @JsonKey(defaultValue: <String>[])  List<String> memberAvatarInitials, @JsonKey(defaultValue: null)  String? assignmentStrategy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ListDto() when $default != null:
return $default(_that.id,_that.title,_that.defaultDueDate,_that.position,_that.archivedAt,_that.createdAt,_that.updatedAt,_that.isShared,_that.memberCount,_that.memberAvatarInitials,_that.assignmentStrategy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String? defaultDueDate,  int position,  String? archivedAt,  String createdAt,  String updatedAt, @JsonKey(defaultValue: false)  bool isShared, @JsonKey(defaultValue: 1)  int memberCount, @JsonKey(defaultValue: <String>[])  List<String> memberAvatarInitials, @JsonKey(defaultValue: null)  String? assignmentStrategy)  $default,) {final _that = this;
switch (_that) {
case _ListDto():
return $default(_that.id,_that.title,_that.defaultDueDate,_that.position,_that.archivedAt,_that.createdAt,_that.updatedAt,_that.isShared,_that.memberCount,_that.memberAvatarInitials,_that.assignmentStrategy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String? defaultDueDate,  int position,  String? archivedAt,  String createdAt,  String updatedAt, @JsonKey(defaultValue: false)  bool isShared, @JsonKey(defaultValue: 1)  int memberCount, @JsonKey(defaultValue: <String>[])  List<String> memberAvatarInitials, @JsonKey(defaultValue: null)  String? assignmentStrategy)?  $default,) {final _that = this;
switch (_that) {
case _ListDto() when $default != null:
return $default(_that.id,_that.title,_that.defaultDueDate,_that.position,_that.archivedAt,_that.createdAt,_that.updatedAt,_that.isShared,_that.memberCount,_that.memberAvatarInitials,_that.assignmentStrategy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ListDto extends ListDto {
  const _ListDto({required this.id, required this.title, this.defaultDueDate, required this.position, this.archivedAt, required this.createdAt, required this.updatedAt, @JsonKey(defaultValue: false) this.isShared = false, @JsonKey(defaultValue: 1) this.memberCount = 1, @JsonKey(defaultValue: <String>[]) final  List<String> memberAvatarInitials = const <String>[], @JsonKey(defaultValue: null) this.assignmentStrategy}): _memberAvatarInitials = memberAvatarInitials,super._();
  factory _ListDto.fromJson(Map<String, dynamic> json) => _$ListDtoFromJson(json);

@override final  String id;
@override final  String title;
@override final  String? defaultDueDate;
@override final  int position;
@override final  String? archivedAt;
@override final  String createdAt;
@override final  String updatedAt;
@override@JsonKey(defaultValue: false) final  bool isShared;
@override@JsonKey(defaultValue: 1) final  int memberCount;
 final  List<String> _memberAvatarInitials;
@override@JsonKey(defaultValue: <String>[]) List<String> get memberAvatarInitials {
  if (_memberAvatarInitials is EqualUnmodifiableListView) return _memberAvatarInitials;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_memberAvatarInitials);
}

@override@JsonKey(defaultValue: null) final  String? assignmentStrategy;

/// Create a copy of ListDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ListDtoCopyWith<_ListDto> get copyWith => __$ListDtoCopyWithImpl<_ListDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ListDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ListDto&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.defaultDueDate, defaultDueDate) || other.defaultDueDate == defaultDueDate)&&(identical(other.position, position) || other.position == position)&&(identical(other.archivedAt, archivedAt) || other.archivedAt == archivedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.isShared, isShared) || other.isShared == isShared)&&(identical(other.memberCount, memberCount) || other.memberCount == memberCount)&&const DeepCollectionEquality().equals(other._memberAvatarInitials, _memberAvatarInitials)&&(identical(other.assignmentStrategy, assignmentStrategy) || other.assignmentStrategy == assignmentStrategy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,title,defaultDueDate,position,archivedAt,createdAt,updatedAt,isShared,memberCount,const DeepCollectionEquality().hash(_memberAvatarInitials),assignmentStrategy);

@override
String toString() {
  return 'ListDto(id: $id, title: $title, defaultDueDate: $defaultDueDate, position: $position, archivedAt: $archivedAt, createdAt: $createdAt, updatedAt: $updatedAt, isShared: $isShared, memberCount: $memberCount, memberAvatarInitials: $memberAvatarInitials, assignmentStrategy: $assignmentStrategy)';
}


}

/// @nodoc
abstract mixin class _$ListDtoCopyWith<$Res> implements $ListDtoCopyWith<$Res> {
  factory _$ListDtoCopyWith(_ListDto value, $Res Function(_ListDto) _then) = __$ListDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String? defaultDueDate, int position, String? archivedAt, String createdAt, String updatedAt,@JsonKey(defaultValue: false) bool isShared,@JsonKey(defaultValue: 1) int memberCount,@JsonKey(defaultValue: <String>[]) List<String> memberAvatarInitials,@JsonKey(defaultValue: null) String? assignmentStrategy
});




}
/// @nodoc
class __$ListDtoCopyWithImpl<$Res>
    implements _$ListDtoCopyWith<$Res> {
  __$ListDtoCopyWithImpl(this._self, this._then);

  final _ListDto _self;
  final $Res Function(_ListDto) _then;

/// Create a copy of ListDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? defaultDueDate = freezed,Object? position = null,Object? archivedAt = freezed,Object? createdAt = null,Object? updatedAt = null,Object? isShared = null,Object? memberCount = null,Object? memberAvatarInitials = null,Object? assignmentStrategy = freezed,}) {
  return _then(_ListDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,defaultDueDate: freezed == defaultDueDate ? _self.defaultDueDate : defaultDueDate // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,archivedAt: freezed == archivedAt ? _self.archivedAt : archivedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,isShared: null == isShared ? _self.isShared : isShared // ignore: cast_nullable_to_non_nullable
as bool,memberCount: null == memberCount ? _self.memberCount : memberCount // ignore: cast_nullable_to_non_nullable
as int,memberAvatarInitials: null == memberAvatarInitials ? _self._memberAvatarInitials : memberAvatarInitials // ignore: cast_nullable_to_non_nullable
as List<String>,assignmentStrategy: freezed == assignmentStrategy ? _self.assignmentStrategy : assignmentStrategy // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
