// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SearchFilter {

 String? get query; String? get listId; String? get listName; DateTime? get dueDateFrom; DateTime? get dueDateTo; TaskSearchStatus? get status; bool? get hasStake;
/// Create a copy of SearchFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SearchFilterCopyWith<SearchFilter> get copyWith => _$SearchFilterCopyWithImpl<SearchFilter>(this as SearchFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SearchFilter&&(identical(other.query, query) || other.query == query)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.listName, listName) || other.listName == listName)&&(identical(other.dueDateFrom, dueDateFrom) || other.dueDateFrom == dueDateFrom)&&(identical(other.dueDateTo, dueDateTo) || other.dueDateTo == dueDateTo)&&(identical(other.status, status) || other.status == status)&&(identical(other.hasStake, hasStake) || other.hasStake == hasStake));
}


@override
int get hashCode => Object.hash(runtimeType,query,listId,listName,dueDateFrom,dueDateTo,status,hasStake);

@override
String toString() {
  return 'SearchFilter(query: $query, listId: $listId, listName: $listName, dueDateFrom: $dueDateFrom, dueDateTo: $dueDateTo, status: $status, hasStake: $hasStake)';
}


}

/// @nodoc
abstract mixin class $SearchFilterCopyWith<$Res>  {
  factory $SearchFilterCopyWith(SearchFilter value, $Res Function(SearchFilter) _then) = _$SearchFilterCopyWithImpl;
@useResult
$Res call({
 String? query, String? listId, String? listName, DateTime? dueDateFrom, DateTime? dueDateTo, TaskSearchStatus? status, bool? hasStake
});




}
/// @nodoc
class _$SearchFilterCopyWithImpl<$Res>
    implements $SearchFilterCopyWith<$Res> {
  _$SearchFilterCopyWithImpl(this._self, this._then);

  final SearchFilter _self;
  final $Res Function(SearchFilter) _then;

/// Create a copy of SearchFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? query = freezed,Object? listId = freezed,Object? listName = freezed,Object? dueDateFrom = freezed,Object? dueDateTo = freezed,Object? status = freezed,Object? hasStake = freezed,}) {
  return _then(_self.copyWith(
query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,listName: freezed == listName ? _self.listName : listName // ignore: cast_nullable_to_non_nullable
as String?,dueDateFrom: freezed == dueDateFrom ? _self.dueDateFrom : dueDateFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,dueDateTo: freezed == dueDateTo ? _self.dueDateTo : dueDateTo // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskSearchStatus?,hasStake: freezed == hasStake ? _self.hasStake : hasStake // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}

}


/// Adds pattern-matching-related methods to [SearchFilter].
extension SearchFilterPatterns on SearchFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SearchFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SearchFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SearchFilter value)  $default,){
final _that = this;
switch (_that) {
case _SearchFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SearchFilter value)?  $default,){
final _that = this;
switch (_that) {
case _SearchFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? query,  String? listId,  String? listName,  DateTime? dueDateFrom,  DateTime? dueDateTo,  TaskSearchStatus? status,  bool? hasStake)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SearchFilter() when $default != null:
return $default(_that.query,_that.listId,_that.listName,_that.dueDateFrom,_that.dueDateTo,_that.status,_that.hasStake);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? query,  String? listId,  String? listName,  DateTime? dueDateFrom,  DateTime? dueDateTo,  TaskSearchStatus? status,  bool? hasStake)  $default,) {final _that = this;
switch (_that) {
case _SearchFilter():
return $default(_that.query,_that.listId,_that.listName,_that.dueDateFrom,_that.dueDateTo,_that.status,_that.hasStake);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? query,  String? listId,  String? listName,  DateTime? dueDateFrom,  DateTime? dueDateTo,  TaskSearchStatus? status,  bool? hasStake)?  $default,) {final _that = this;
switch (_that) {
case _SearchFilter() when $default != null:
return $default(_that.query,_that.listId,_that.listName,_that.dueDateFrom,_that.dueDateTo,_that.status,_that.hasStake);case _:
  return null;

}
}

}

/// @nodoc


class _SearchFilter extends SearchFilter {
  const _SearchFilter({this.query, this.listId, this.listName, this.dueDateFrom, this.dueDateTo, this.status, this.hasStake}): super._();
  

@override final  String? query;
@override final  String? listId;
@override final  String? listName;
@override final  DateTime? dueDateFrom;
@override final  DateTime? dueDateTo;
@override final  TaskSearchStatus? status;
@override final  bool? hasStake;

/// Create a copy of SearchFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SearchFilterCopyWith<_SearchFilter> get copyWith => __$SearchFilterCopyWithImpl<_SearchFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SearchFilter&&(identical(other.query, query) || other.query == query)&&(identical(other.listId, listId) || other.listId == listId)&&(identical(other.listName, listName) || other.listName == listName)&&(identical(other.dueDateFrom, dueDateFrom) || other.dueDateFrom == dueDateFrom)&&(identical(other.dueDateTo, dueDateTo) || other.dueDateTo == dueDateTo)&&(identical(other.status, status) || other.status == status)&&(identical(other.hasStake, hasStake) || other.hasStake == hasStake));
}


@override
int get hashCode => Object.hash(runtimeType,query,listId,listName,dueDateFrom,dueDateTo,status,hasStake);

@override
String toString() {
  return 'SearchFilter(query: $query, listId: $listId, listName: $listName, dueDateFrom: $dueDateFrom, dueDateTo: $dueDateTo, status: $status, hasStake: $hasStake)';
}


}

/// @nodoc
abstract mixin class _$SearchFilterCopyWith<$Res> implements $SearchFilterCopyWith<$Res> {
  factory _$SearchFilterCopyWith(_SearchFilter value, $Res Function(_SearchFilter) _then) = __$SearchFilterCopyWithImpl;
@override @useResult
$Res call({
 String? query, String? listId, String? listName, DateTime? dueDateFrom, DateTime? dueDateTo, TaskSearchStatus? status, bool? hasStake
});




}
/// @nodoc
class __$SearchFilterCopyWithImpl<$Res>
    implements _$SearchFilterCopyWith<$Res> {
  __$SearchFilterCopyWithImpl(this._self, this._then);

  final _SearchFilter _self;
  final $Res Function(_SearchFilter) _then;

/// Create a copy of SearchFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? query = freezed,Object? listId = freezed,Object? listName = freezed,Object? dueDateFrom = freezed,Object? dueDateTo = freezed,Object? status = freezed,Object? hasStake = freezed,}) {
  return _then(_SearchFilter(
query: freezed == query ? _self.query : query // ignore: cast_nullable_to_non_nullable
as String?,listId: freezed == listId ? _self.listId : listId // ignore: cast_nullable_to_non_nullable
as String?,listName: freezed == listName ? _self.listName : listName // ignore: cast_nullable_to_non_nullable
as String?,dueDateFrom: freezed == dueDateFrom ? _self.dueDateFrom : dueDateFrom // ignore: cast_nullable_to_non_nullable
as DateTime?,dueDateTo: freezed == dueDateTo ? _self.dueDateTo : dueDateTo // ignore: cast_nullable_to_non_nullable
as DateTime?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as TaskSearchStatus?,hasStake: freezed == hasStake ? _self.hasStake : hasStake // ignore: cast_nullable_to_non_nullable
as bool?,
  ));
}


}

// dart format on
