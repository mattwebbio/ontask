// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'section_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SectionDto {

 String get id; String get listId; String? get parentSectionId; String get title; String? get defaultDueDate; int get position; String get createdAt; String get updatedAt;@JsonKey(defaultValue: null) String? get proofRequirement;
/// Create a copy of SectionDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SectionDtoCopyWith<SectionDto> get copyWith => _$SectionDtoCopyWithImpl<SectionDto>(this as SectionDto, _$identity);

  /// Serializes this SectionDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SectionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.parentSectionId, parentSectionId) || other.parentSectionId == parentSectionId)&&(identical(other.title, title) || other.title == title)&&(identical(other.defaultDueDate, defaultDueDate) || other.defaultDueDate == defaultDueDate)&&(identical(other.position, position) || other.position == position)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.proofRequirement, proofRequirement) || other.proofRequirement == proofRequirement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,listId,parentSectionId,title,defaultDueDate,position,createdAt,updatedAt,proofRequirement);

@override
String toString() {
  return 'SectionDto(id: $id, listId: $listId, parentSectionId: $parentSectionId, title: $title, defaultDueDate: $defaultDueDate, position: $position, createdAt: $createdAt, updatedAt: $updatedAt, proofRequirement: $proofRequirement)';
}


}

/// @nodoc
abstract mixin class $SectionDtoCopyWith<$Res>  {
  factory $SectionDtoCopyWith(SectionDto value, $Res Function(SectionDto) _then) = _$SectionDtoCopyWithImpl;
@useResult
$Res call({
 String id, String listId, String? parentSectionId, String title, String? defaultDueDate, int position, String createdAt, String updatedAt,@JsonKey(defaultValue: null) String? proofRequirement
});




}
/// @nodoc
class _$SectionDtoCopyWithImpl<$Res>
    implements $SectionDtoCopyWith<$Res> {
  _$SectionDtoCopyWithImpl(this._self, this._then);

  final SectionDto _self;
  final $Res Function(SectionDto) _then;

/// Create a copy of SectionDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? listId = null,Object? parentSectionId = freezed,Object? title = null,Object? defaultDueDate = freezed,Object? position = null,Object? createdAt = null,Object? updatedAt = null,Object? proofRequirement = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,listId: null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String,parentSectionId: freezed == parentSectionId ? _self.parentSectionId : parentSectionId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,defaultDueDate: freezed == defaultDueDate ? _self.defaultDueDate : defaultDueDate // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,proofRequirement: freezed == proofRequirement ? _self.proofRequirement : proofRequirement // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SectionDto].
extension SectionDtoPatterns on SectionDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SectionDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SectionDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SectionDto value)  $default,){
final _that = this;
switch (_that) {
case _SectionDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SectionDto value)?  $default,){
final _that = this;
switch (_that) {
case _SectionDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String listId,  String? parentSectionId,  String title,  String? defaultDueDate,  int position,  String createdAt,  String updatedAt, @JsonKey(defaultValue: null)  String? proofRequirement)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SectionDto() when $default != null:
return $default(_that.id,_that.listId,_that.parentSectionId,_that.title,_that.defaultDueDate,_that.position,_that.createdAt,_that.updatedAt,_that.proofRequirement);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String listId,  String? parentSectionId,  String title,  String? defaultDueDate,  int position,  String createdAt,  String updatedAt, @JsonKey(defaultValue: null)  String? proofRequirement)  $default,) {final _that = this;
switch (_that) {
case _SectionDto():
return $default(_that.id,_that.listId,_that.parentSectionId,_that.title,_that.defaultDueDate,_that.position,_that.createdAt,_that.updatedAt,_that.proofRequirement);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String listId,  String? parentSectionId,  String title,  String? defaultDueDate,  int position,  String createdAt,  String updatedAt, @JsonKey(defaultValue: null)  String? proofRequirement)?  $default,) {final _that = this;
switch (_that) {
case _SectionDto() when $default != null:
return $default(_that.id,_that.listId,_that.parentSectionId,_that.title,_that.defaultDueDate,_that.position,_that.createdAt,_that.updatedAt,_that.proofRequirement);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SectionDto extends SectionDto {
  const _SectionDto({required this.id, required this.listId, this.parentSectionId, required this.title, this.defaultDueDate, required this.position, required this.createdAt, required this.updatedAt, @JsonKey(defaultValue: null) this.proofRequirement}): super._();
  factory _SectionDto.fromJson(Map<String, dynamic> json) => _$SectionDtoFromJson(json);

@override final  String id;
@override final  String listId;
@override final  String? parentSectionId;
@override final  String title;
@override final  String? defaultDueDate;
@override final  int position;
@override final  String createdAt;
@override final  String updatedAt;
@override@JsonKey(defaultValue: null) final  String? proofRequirement;

/// Create a copy of SectionDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SectionDtoCopyWith<_SectionDto> get copyWith => __$SectionDtoCopyWithImpl<_SectionDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SectionDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SectionDto&&(identical(other.id, id) || other.id == id)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.parentSectionId, parentSectionId) || other.parentSectionId == parentSectionId)&&(identical(other.title, title) || other.title == title)&&(identical(other.defaultDueDate, defaultDueDate) || other.defaultDueDate == defaultDueDate)&&(identical(other.position, position) || other.position == position)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.proofRequirement, proofRequirement) || other.proofRequirement == proofRequirement));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,listId,parentSectionId,title,defaultDueDate,position,createdAt,updatedAt,proofRequirement);

@override
String toString() {
  return 'SectionDto(id: $id, listId: $listId, parentSectionId: $parentSectionId, title: $title, defaultDueDate: $defaultDueDate, position: $position, createdAt: $createdAt, updatedAt: $updatedAt, proofRequirement: $proofRequirement)';
}


}

/// @nodoc
abstract mixin class _$SectionDtoCopyWith<$Res> implements $SectionDtoCopyWith<$Res> {
  factory _$SectionDtoCopyWith(_SectionDto value, $Res Function(_SectionDto) _then) = __$SectionDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String listId, String? parentSectionId, String title, String? defaultDueDate, int position, String createdAt, String updatedAt,@JsonKey(defaultValue: null) String? proofRequirement
});




}
/// @nodoc
class __$SectionDtoCopyWithImpl<$Res>
    implements _$SectionDtoCopyWith<$Res> {
  __$SectionDtoCopyWithImpl(this._self, this._then);

  final _SectionDto _self;
  final $Res Function(_SectionDto) _then;

/// Create a copy of SectionDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? listId = null,Object? parentSectionId = freezed,Object? title = null,Object? defaultDueDate = freezed,Object? position = null,Object? createdAt = null,Object? updatedAt = null,Object? proofRequirement = freezed,}) {
  return _then(_SectionDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,listId: null == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String,parentSectionId: freezed == parentSectionId ? _self.parentSectionId : parentSectionId // ignore: cast_nullable_to_non_nullable
as String?,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,defaultDueDate: freezed == defaultDueDate ? _self.defaultDueDate : defaultDueDate // ignore: cast_nullable_to_non_nullable
as String?,position: null == position ? _self.position : position // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String,proofRequirement: freezed == proofRequirement ? _self.proofRequirement : proofRequirement // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
