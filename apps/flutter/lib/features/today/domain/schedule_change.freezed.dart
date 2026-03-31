// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'schedule_change.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ScheduleChangeItem {

 String get taskId; String get taskTitle; ScheduleChangeType get changeType; DateTime? get oldTime; DateTime? get newTime;
/// Create a copy of ScheduleChangeItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleChangeItemCopyWith<ScheduleChangeItem> get copyWith => _$ScheduleChangeItemCopyWithImpl<ScheduleChangeItem>(this as ScheduleChangeItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduleChangeItem&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.taskTitle, taskTitle) || other.taskTitle == taskTitle)&&(identical(other.changeType, changeType) || other.changeType == changeType)&&(identical(other.oldTime, oldTime) || other.oldTime == oldTime)&&(identical(other.newTime, newTime) || other.newTime == newTime));
}


@override
int get hashCode => Object.hash(runtimeType,taskId,taskTitle,changeType,oldTime,newTime);

@override
String toString() {
  return 'ScheduleChangeItem(taskId: $taskId, taskTitle: $taskTitle, changeType: $changeType, oldTime: $oldTime, newTime: $newTime)';
}


}

/// @nodoc
abstract mixin class $ScheduleChangeItemCopyWith<$Res>  {
  factory $ScheduleChangeItemCopyWith(ScheduleChangeItem value, $Res Function(ScheduleChangeItem) _then) = _$ScheduleChangeItemCopyWithImpl;
@useResult
$Res call({
 String taskId, String taskTitle, ScheduleChangeType changeType, DateTime? oldTime, DateTime? newTime
});




}
/// @nodoc
class _$ScheduleChangeItemCopyWithImpl<$Res>
    implements $ScheduleChangeItemCopyWith<$Res> {
  _$ScheduleChangeItemCopyWithImpl(this._self, this._then);

  final ScheduleChangeItem _self;
  final $Res Function(ScheduleChangeItem) _then;

/// Create a copy of ScheduleChangeItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? taskId = null,Object? taskTitle = null,Object? changeType = null,Object? oldTime = freezed,Object? newTime = freezed,}) {
  return _then(_self.copyWith(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,taskTitle: null == taskTitle ? _self.taskTitle : taskTitle // ignore: cast_nullable_to_non_nullable
as String,changeType: null == changeType ? _self.changeType : changeType // ignore: cast_nullable_to_non_nullable
as ScheduleChangeType,oldTime: freezed == oldTime ? _self.oldTime : oldTime // ignore: cast_nullable_to_non_nullable
as DateTime?,newTime: freezed == newTime ? _self.newTime : newTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduleChangeItem].
extension ScheduleChangeItemPatterns on ScheduleChangeItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduleChangeItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduleChangeItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduleChangeItem value)  $default,){
final _that = this;
switch (_that) {
case _ScheduleChangeItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduleChangeItem value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduleChangeItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String taskId,  String taskTitle,  ScheduleChangeType changeType,  DateTime? oldTime,  DateTime? newTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduleChangeItem() when $default != null:
return $default(_that.taskId,_that.taskTitle,_that.changeType,_that.oldTime,_that.newTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String taskId,  String taskTitle,  ScheduleChangeType changeType,  DateTime? oldTime,  DateTime? newTime)  $default,) {final _that = this;
switch (_that) {
case _ScheduleChangeItem():
return $default(_that.taskId,_that.taskTitle,_that.changeType,_that.oldTime,_that.newTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String taskId,  String taskTitle,  ScheduleChangeType changeType,  DateTime? oldTime,  DateTime? newTime)?  $default,) {final _that = this;
switch (_that) {
case _ScheduleChangeItem() when $default != null:
return $default(_that.taskId,_that.taskTitle,_that.changeType,_that.oldTime,_that.newTime);case _:
  return null;

}
}

}

/// @nodoc


class _ScheduleChangeItem implements ScheduleChangeItem {
  const _ScheduleChangeItem({required this.taskId, required this.taskTitle, required this.changeType, required this.oldTime, required this.newTime});
  

@override final  String taskId;
@override final  String taskTitle;
@override final  ScheduleChangeType changeType;
@override final  DateTime? oldTime;
@override final  DateTime? newTime;

/// Create a copy of ScheduleChangeItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduleChangeItemCopyWith<_ScheduleChangeItem> get copyWith => __$ScheduleChangeItemCopyWithImpl<_ScheduleChangeItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduleChangeItem&&(identical(other.taskId, taskId) || other.taskId == taskId)&&(identical(other.taskTitle, taskTitle) || other.taskTitle == taskTitle)&&(identical(other.changeType, changeType) || other.changeType == changeType)&&(identical(other.oldTime, oldTime) || other.oldTime == oldTime)&&(identical(other.newTime, newTime) || other.newTime == newTime));
}


@override
int get hashCode => Object.hash(runtimeType,taskId,taskTitle,changeType,oldTime,newTime);

@override
String toString() {
  return 'ScheduleChangeItem(taskId: $taskId, taskTitle: $taskTitle, changeType: $changeType, oldTime: $oldTime, newTime: $newTime)';
}


}

/// @nodoc
abstract mixin class _$ScheduleChangeItemCopyWith<$Res> implements $ScheduleChangeItemCopyWith<$Res> {
  factory _$ScheduleChangeItemCopyWith(_ScheduleChangeItem value, $Res Function(_ScheduleChangeItem) _then) = __$ScheduleChangeItemCopyWithImpl;
@override @useResult
$Res call({
 String taskId, String taskTitle, ScheduleChangeType changeType, DateTime? oldTime, DateTime? newTime
});




}
/// @nodoc
class __$ScheduleChangeItemCopyWithImpl<$Res>
    implements _$ScheduleChangeItemCopyWith<$Res> {
  __$ScheduleChangeItemCopyWithImpl(this._self, this._then);

  final _ScheduleChangeItem _self;
  final $Res Function(_ScheduleChangeItem) _then;

/// Create a copy of ScheduleChangeItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? taskId = null,Object? taskTitle = null,Object? changeType = null,Object? oldTime = freezed,Object? newTime = freezed,}) {
  return _then(_ScheduleChangeItem(
taskId: null == taskId ? _self.taskId : taskId // ignore: cast_nullable_to_non_nullable
as String,taskTitle: null == taskTitle ? _self.taskTitle : taskTitle // ignore: cast_nullable_to_non_nullable
as String,changeType: null == changeType ? _self.changeType : changeType // ignore: cast_nullable_to_non_nullable
as ScheduleChangeType,oldTime: freezed == oldTime ? _self.oldTime : oldTime // ignore: cast_nullable_to_non_nullable
as DateTime?,newTime: freezed == newTime ? _self.newTime : newTime // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$ScheduleChanges {

 bool get hasMeaningfulChanges; int get changeCount; List<ScheduleChangeItem> get changes;
/// Create a copy of ScheduleChanges
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ScheduleChangesCopyWith<ScheduleChanges> get copyWith => _$ScheduleChangesCopyWithImpl<ScheduleChanges>(this as ScheduleChanges, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ScheduleChanges&&(identical(other.hasMeaningfulChanges, hasMeaningfulChanges) || other.hasMeaningfulChanges == hasMeaningfulChanges)&&(identical(other.changeCount, changeCount) || other.changeCount == changeCount)&&const DeepCollectionEquality().equals(other.changes, changes));
}


@override
int get hashCode => Object.hash(runtimeType,hasMeaningfulChanges,changeCount,const DeepCollectionEquality().hash(changes));

@override
String toString() {
  return 'ScheduleChanges(hasMeaningfulChanges: $hasMeaningfulChanges, changeCount: $changeCount, changes: $changes)';
}


}

/// @nodoc
abstract mixin class $ScheduleChangesCopyWith<$Res>  {
  factory $ScheduleChangesCopyWith(ScheduleChanges value, $Res Function(ScheduleChanges) _then) = _$ScheduleChangesCopyWithImpl;
@useResult
$Res call({
 bool hasMeaningfulChanges, int changeCount, List<ScheduleChangeItem> changes
});




}
/// @nodoc
class _$ScheduleChangesCopyWithImpl<$Res>
    implements $ScheduleChangesCopyWith<$Res> {
  _$ScheduleChangesCopyWithImpl(this._self, this._then);

  final ScheduleChanges _self;
  final $Res Function(ScheduleChanges) _then;

/// Create a copy of ScheduleChanges
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hasMeaningfulChanges = null,Object? changeCount = null,Object? changes = null,}) {
  return _then(_self.copyWith(
hasMeaningfulChanges: null == hasMeaningfulChanges ? _self.hasMeaningfulChanges : hasMeaningfulChanges // ignore: cast_nullable_to_non_nullable
as bool,changeCount: null == changeCount ? _self.changeCount : changeCount // ignore: cast_nullable_to_non_nullable
as int,changes: null == changes ? _self.changes : changes // ignore: cast_nullable_to_non_nullable
as List<ScheduleChangeItem>,
  ));
}

}


/// Adds pattern-matching-related methods to [ScheduleChanges].
extension ScheduleChangesPatterns on ScheduleChanges {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ScheduleChanges value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ScheduleChanges() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ScheduleChanges value)  $default,){
final _that = this;
switch (_that) {
case _ScheduleChanges():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ScheduleChanges value)?  $default,){
final _that = this;
switch (_that) {
case _ScheduleChanges() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool hasMeaningfulChanges,  int changeCount,  List<ScheduleChangeItem> changes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ScheduleChanges() when $default != null:
return $default(_that.hasMeaningfulChanges,_that.changeCount,_that.changes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool hasMeaningfulChanges,  int changeCount,  List<ScheduleChangeItem> changes)  $default,) {final _that = this;
switch (_that) {
case _ScheduleChanges():
return $default(_that.hasMeaningfulChanges,_that.changeCount,_that.changes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool hasMeaningfulChanges,  int changeCount,  List<ScheduleChangeItem> changes)?  $default,) {final _that = this;
switch (_that) {
case _ScheduleChanges() when $default != null:
return $default(_that.hasMeaningfulChanges,_that.changeCount,_that.changes);case _:
  return null;

}
}

}

/// @nodoc


class _ScheduleChanges implements ScheduleChanges {
  const _ScheduleChanges({required this.hasMeaningfulChanges, required this.changeCount, required final  List<ScheduleChangeItem> changes}): _changes = changes;
  

@override final  bool hasMeaningfulChanges;
@override final  int changeCount;
 final  List<ScheduleChangeItem> _changes;
@override List<ScheduleChangeItem> get changes {
  if (_changes is EqualUnmodifiableListView) return _changes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_changes);
}


/// Create a copy of ScheduleChanges
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ScheduleChangesCopyWith<_ScheduleChanges> get copyWith => __$ScheduleChangesCopyWithImpl<_ScheduleChanges>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ScheduleChanges&&(identical(other.hasMeaningfulChanges, hasMeaningfulChanges) || other.hasMeaningfulChanges == hasMeaningfulChanges)&&(identical(other.changeCount, changeCount) || other.changeCount == changeCount)&&const DeepCollectionEquality().equals(other._changes, _changes));
}


@override
int get hashCode => Object.hash(runtimeType,hasMeaningfulChanges,changeCount,const DeepCollectionEquality().hash(_changes));

@override
String toString() {
  return 'ScheduleChanges(hasMeaningfulChanges: $hasMeaningfulChanges, changeCount: $changeCount, changes: $changes)';
}


}

/// @nodoc
abstract mixin class _$ScheduleChangesCopyWith<$Res> implements $ScheduleChangesCopyWith<$Res> {
  factory _$ScheduleChangesCopyWith(_ScheduleChanges value, $Res Function(_ScheduleChanges) _then) = __$ScheduleChangesCopyWithImpl;
@override @useResult
$Res call({
 bool hasMeaningfulChanges, int changeCount, List<ScheduleChangeItem> changes
});




}
/// @nodoc
class __$ScheduleChangesCopyWithImpl<$Res>
    implements _$ScheduleChangesCopyWith<$Res> {
  __$ScheduleChangesCopyWithImpl(this._self, this._then);

  final _ScheduleChanges _self;
  final $Res Function(_ScheduleChanges) _then;

/// Create a copy of ScheduleChanges
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hasMeaningfulChanges = null,Object? changeCount = null,Object? changes = null,}) {
  return _then(_ScheduleChanges(
hasMeaningfulChanges: null == hasMeaningfulChanges ? _self.hasMeaningfulChanges : hasMeaningfulChanges // ignore: cast_nullable_to_non_nullable
as bool,changeCount: null == changeCount ? _self.changeCount : changeCount // ignore: cast_nullable_to_non_nullable
as int,changes: null == changes ? _self._changes : changes // ignore: cast_nullable_to_non_nullable
as List<ScheduleChangeItem>,
  ));
}


}

// dart format on
