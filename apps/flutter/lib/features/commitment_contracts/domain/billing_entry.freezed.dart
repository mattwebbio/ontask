// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'billing_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BillingEntry {

 String get id; String get taskName; DateTime get date; int? get amountCents; String get disbursementStatus;// 'pending' | 'completed' | 'failed' | 'cancelled'
 String? get charityName;
/// Create a copy of BillingEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BillingEntryCopyWith<BillingEntry> get copyWith => _$BillingEntryCopyWithImpl<BillingEntry>(this as BillingEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BillingEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.taskName, taskName) || other.taskName == taskName)&&(identical(other.date, date) || other.date == date)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.disbursementStatus, disbursementStatus) || other.disbursementStatus == disbursementStatus)&&(identical(other.charityName, charityName) || other.charityName == charityName));
}


@override
int get hashCode => Object.hash(runtimeType,id,taskName,date,amountCents,disbursementStatus,charityName);

@override
String toString() {
  return 'BillingEntry(id: $id, taskName: $taskName, date: $date, amountCents: $amountCents, disbursementStatus: $disbursementStatus, charityName: $charityName)';
}


}

/// @nodoc
abstract mixin class $BillingEntryCopyWith<$Res>  {
  factory $BillingEntryCopyWith(BillingEntry value, $Res Function(BillingEntry) _then) = _$BillingEntryCopyWithImpl;
@useResult
$Res call({
 String id, String taskName, DateTime date, int? amountCents, String disbursementStatus, String? charityName
});




}
/// @nodoc
class _$BillingEntryCopyWithImpl<$Res>
    implements $BillingEntryCopyWith<$Res> {
  _$BillingEntryCopyWithImpl(this._self, this._then);

  final BillingEntry _self;
  final $Res Function(BillingEntry) _then;

/// Create a copy of BillingEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? taskName = null,Object? date = null,Object? amountCents = freezed,Object? disbursementStatus = null,Object? charityName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskName: null == taskName ? _self.taskName : taskName // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,amountCents: freezed == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int?,disbursementStatus: null == disbursementStatus ? _self.disbursementStatus : disbursementStatus // ignore: cast_nullable_to_non_nullable
as String,charityName: freezed == charityName ? _self.charityName : charityName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [BillingEntry].
extension BillingEntryPatterns on BillingEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BillingEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BillingEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BillingEntry value)  $default,){
final _that = this;
switch (_that) {
case _BillingEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BillingEntry value)?  $default,){
final _that = this;
switch (_that) {
case _BillingEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String taskName,  DateTime date,  int? amountCents,  String disbursementStatus,  String? charityName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BillingEntry() when $default != null:
return $default(_that.id,_that.taskName,_that.date,_that.amountCents,_that.disbursementStatus,_that.charityName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String taskName,  DateTime date,  int? amountCents,  String disbursementStatus,  String? charityName)  $default,) {final _that = this;
switch (_that) {
case _BillingEntry():
return $default(_that.id,_that.taskName,_that.date,_that.amountCents,_that.disbursementStatus,_that.charityName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String taskName,  DateTime date,  int? amountCents,  String disbursementStatus,  String? charityName)?  $default,) {final _that = this;
switch (_that) {
case _BillingEntry() when $default != null:
return $default(_that.id,_that.taskName,_that.date,_that.amountCents,_that.disbursementStatus,_that.charityName);case _:
  return null;

}
}

}

/// @nodoc


class _BillingEntry implements BillingEntry {
  const _BillingEntry({required this.id, required this.taskName, required this.date, this.amountCents, required this.disbursementStatus, this.charityName});
  

@override final  String id;
@override final  String taskName;
@override final  DateTime date;
@override final  int? amountCents;
@override final  String disbursementStatus;
// 'pending' | 'completed' | 'failed' | 'cancelled'
@override final  String? charityName;

/// Create a copy of BillingEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BillingEntryCopyWith<_BillingEntry> get copyWith => __$BillingEntryCopyWithImpl<_BillingEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BillingEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.taskName, taskName) || other.taskName == taskName)&&(identical(other.date, date) || other.date == date)&&(identical(other.amountCents, amountCents) || other.amountCents == amountCents)&&(identical(other.disbursementStatus, disbursementStatus) || other.disbursementStatus == disbursementStatus)&&(identical(other.charityName, charityName) || other.charityName == charityName));
}


@override
int get hashCode => Object.hash(runtimeType,id,taskName,date,amountCents,disbursementStatus,charityName);

@override
String toString() {
  return 'BillingEntry(id: $id, taskName: $taskName, date: $date, amountCents: $amountCents, disbursementStatus: $disbursementStatus, charityName: $charityName)';
}


}

/// @nodoc
abstract mixin class _$BillingEntryCopyWith<$Res> implements $BillingEntryCopyWith<$Res> {
  factory _$BillingEntryCopyWith(_BillingEntry value, $Res Function(_BillingEntry) _then) = __$BillingEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String taskName, DateTime date, int? amountCents, String disbursementStatus, String? charityName
});




}
/// @nodoc
class __$BillingEntryCopyWithImpl<$Res>
    implements _$BillingEntryCopyWith<$Res> {
  __$BillingEntryCopyWithImpl(this._self, this._then);

  final _BillingEntry _self;
  final $Res Function(_BillingEntry) _then;

/// Create a copy of BillingEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? taskName = null,Object? date = null,Object? amountCents = freezed,Object? disbursementStatus = null,Object? charityName = freezed,}) {
  return _then(_BillingEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,taskName: null == taskName ? _self.taskName : taskName // ignore: cast_nullable_to_non_nullable
as String,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,amountCents: freezed == amountCents ? _self.amountCents : amountCents // ignore: cast_nullable_to_non_nullable
as int?,disbursementStatus: null == disbursementStatus ? _self.disbursementStatus : disbursementStatus // ignore: cast_nullable_to_non_nullable
as String,charityName: freezed == charityName ? _self.charityName : charityName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
