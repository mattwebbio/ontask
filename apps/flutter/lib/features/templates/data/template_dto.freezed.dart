// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'template_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TemplateDto {

 String get id; String get userId; String get title; String get sourceType; String? get templateData; String get createdAt; String? get updatedAt;
/// Create a copy of TemplateDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TemplateDtoCopyWith<TemplateDto> get copyWith => _$TemplateDtoCopyWithImpl<TemplateDto>(this as TemplateDto, _$identity);

  /// Serializes this TemplateDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TemplateDto&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.title, title) || other.title == title)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.templateData, templateData) || other.templateData == templateData)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,title,sourceType,templateData,createdAt,updatedAt);

@override
String toString() {
  return 'TemplateDto(id: $id, userId: $userId, title: $title, sourceType: $sourceType, templateData: $templateData, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TemplateDtoCopyWith<$Res>  {
  factory $TemplateDtoCopyWith(TemplateDto value, $Res Function(TemplateDto) _then) = _$TemplateDtoCopyWithImpl;
@useResult
$Res call({
 String id, String userId, String title, String sourceType, String? templateData, String createdAt, String? updatedAt
});




}
/// @nodoc
class _$TemplateDtoCopyWithImpl<$Res>
    implements $TemplateDtoCopyWith<$Res> {
  _$TemplateDtoCopyWithImpl(this._self, this._then);

  final TemplateDto _self;
  final $Res Function(TemplateDto) _then;

/// Create a copy of TemplateDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? title = null,Object? sourceType = null,Object? templateData = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String,templateData: freezed == templateData ? _self.templateData : templateData // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [TemplateDto].
extension TemplateDtoPatterns on TemplateDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TemplateDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TemplateDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TemplateDto value)  $default,){
final _that = this;
switch (_that) {
case _TemplateDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TemplateDto value)?  $default,){
final _that = this;
switch (_that) {
case _TemplateDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String userId,  String title,  String sourceType,  String? templateData,  String createdAt,  String? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TemplateDto() when $default != null:
return $default(_that.id,_that.userId,_that.title,_that.sourceType,_that.templateData,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String userId,  String title,  String sourceType,  String? templateData,  String createdAt,  String? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _TemplateDto():
return $default(_that.id,_that.userId,_that.title,_that.sourceType,_that.templateData,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String userId,  String title,  String sourceType,  String? templateData,  String createdAt,  String? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _TemplateDto() when $default != null:
return $default(_that.id,_that.userId,_that.title,_that.sourceType,_that.templateData,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TemplateDto extends TemplateDto {
  const _TemplateDto({required this.id, required this.userId, required this.title, required this.sourceType, this.templateData, required this.createdAt, this.updatedAt}): super._();
  factory _TemplateDto.fromJson(Map<String, dynamic> json) => _$TemplateDtoFromJson(json);

@override final  String id;
@override final  String userId;
@override final  String title;
@override final  String sourceType;
@override final  String? templateData;
@override final  String createdAt;
@override final  String? updatedAt;

/// Create a copy of TemplateDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TemplateDtoCopyWith<_TemplateDto> get copyWith => __$TemplateDtoCopyWithImpl<_TemplateDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TemplateDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TemplateDto&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.title, title) || other.title == title)&&(identical(other.sourceType, sourceType) || other.sourceType == sourceType)&&(identical(other.templateData, templateData) || other.templateData == templateData)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,title,sourceType,templateData,createdAt,updatedAt);

@override
String toString() {
  return 'TemplateDto(id: $id, userId: $userId, title: $title, sourceType: $sourceType, templateData: $templateData, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TemplateDtoCopyWith<$Res> implements $TemplateDtoCopyWith<$Res> {
  factory _$TemplateDtoCopyWith(_TemplateDto value, $Res Function(_TemplateDto) _then) = __$TemplateDtoCopyWithImpl;
@override @useResult
$Res call({
 String id, String userId, String title, String sourceType, String? templateData, String createdAt, String? updatedAt
});




}
/// @nodoc
class __$TemplateDtoCopyWithImpl<$Res>
    implements _$TemplateDtoCopyWith<$Res> {
  __$TemplateDtoCopyWithImpl(this._self, this._then);

  final _TemplateDto _self;
  final $Res Function(_TemplateDto) _then;

/// Create a copy of TemplateDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? title = null,Object? sourceType = null,Object? templateData = freezed,Object? createdAt = null,Object? updatedAt = freezed,}) {
  return _then(_TemplateDto(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,sourceType: null == sourceType ? _self.sourceType : sourceType // ignore: cast_nullable_to_non_nullable
as String,templateData: freezed == templateData ? _self.templateData : templateData // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
