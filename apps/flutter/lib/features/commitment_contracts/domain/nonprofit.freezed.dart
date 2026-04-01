// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nonprofit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Nonprofit {

 String get id; String get name; String? get description; String? get logoUrl; List<String> get categories;
/// Create a copy of Nonprofit
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NonprofitCopyWith<Nonprofit> get copyWith => _$NonprofitCopyWithImpl<Nonprofit>(this as Nonprofit, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Nonprofit&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&const DeepCollectionEquality().equals(other.categories, categories));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,logoUrl,const DeepCollectionEquality().hash(categories));

@override
String toString() {
  return 'Nonprofit(id: $id, name: $name, description: $description, logoUrl: $logoUrl, categories: $categories)';
}


}

/// @nodoc
abstract mixin class $NonprofitCopyWith<$Res>  {
  factory $NonprofitCopyWith(Nonprofit value, $Res Function(Nonprofit) _then) = _$NonprofitCopyWithImpl;
@useResult
$Res call({
 String id, String name, String? description, String? logoUrl, List<String> categories
});




}
/// @nodoc
class _$NonprofitCopyWithImpl<$Res>
    implements $NonprofitCopyWith<$Res> {
  _$NonprofitCopyWithImpl(this._self, this._then);

  final Nonprofit _self;
  final $Res Function(Nonprofit) _then;

/// Create a copy of Nonprofit
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? logoUrl = freezed,Object? categories = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Nonprofit].
extension NonprofitPatterns on Nonprofit {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Nonprofit value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Nonprofit() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Nonprofit value)  $default,){
final _that = this;
switch (_that) {
case _Nonprofit():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Nonprofit value)?  $default,){
final _that = this;
switch (_that) {
case _Nonprofit() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String? logoUrl,  List<String> categories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Nonprofit() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.logoUrl,_that.categories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String? description,  String? logoUrl,  List<String> categories)  $default,) {final _that = this;
switch (_that) {
case _Nonprofit():
return $default(_that.id,_that.name,_that.description,_that.logoUrl,_that.categories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String? description,  String? logoUrl,  List<String> categories)?  $default,) {final _that = this;
switch (_that) {
case _Nonprofit() when $default != null:
return $default(_that.id,_that.name,_that.description,_that.logoUrl,_that.categories);case _:
  return null;

}
}

}

/// @nodoc


class _Nonprofit implements Nonprofit {
  const _Nonprofit({required this.id, required this.name, this.description, this.logoUrl, final  List<String> categories = const []}): _categories = categories;
  

@override final  String id;
@override final  String name;
@override final  String? description;
@override final  String? logoUrl;
 final  List<String> _categories;
@override@JsonKey() List<String> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}


/// Create a copy of Nonprofit
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NonprofitCopyWith<_Nonprofit> get copyWith => __$NonprofitCopyWithImpl<_Nonprofit>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Nonprofit&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.description, description) || other.description == description)&&(identical(other.logoUrl, logoUrl) || other.logoUrl == logoUrl)&&const DeepCollectionEquality().equals(other._categories, _categories));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,description,logoUrl,const DeepCollectionEquality().hash(_categories));

@override
String toString() {
  return 'Nonprofit(id: $id, name: $name, description: $description, logoUrl: $logoUrl, categories: $categories)';
}


}

/// @nodoc
abstract mixin class _$NonprofitCopyWith<$Res> implements $NonprofitCopyWith<$Res> {
  factory _$NonprofitCopyWith(_Nonprofit value, $Res Function(_Nonprofit) _then) = __$NonprofitCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String? description, String? logoUrl, List<String> categories
});




}
/// @nodoc
class __$NonprofitCopyWithImpl<$Res>
    implements _$NonprofitCopyWith<$Res> {
  __$NonprofitCopyWithImpl(this._self, this._then);

  final _Nonprofit _self;
  final $Res Function(_Nonprofit) _then;

/// Create a copy of Nonprofit
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? description = freezed,Object? logoUrl = freezed,Object? categories = null,}) {
  return _then(_Nonprofit(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,logoUrl: freezed == logoUrl ? _self.logoUrl : logoUrl // ignore: cast_nullable_to_non_nullable
as String?,categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
