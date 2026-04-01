// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'impact_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CharityDonation {

 String get charityName; int get donatedCents;
/// Create a copy of CharityDonation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CharityDonationCopyWith<CharityDonation> get copyWith => _$CharityDonationCopyWithImpl<CharityDonation>(this as CharityDonation, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CharityDonation&&(identical(other.charityName, charityName) || other.charityName == charityName)&&(identical(other.donatedCents, donatedCents) || other.donatedCents == donatedCents));
}


@override
int get hashCode => Object.hash(runtimeType,charityName,donatedCents);

@override
String toString() {
  return 'CharityDonation(charityName: $charityName, donatedCents: $donatedCents)';
}


}

/// @nodoc
abstract mixin class $CharityDonationCopyWith<$Res>  {
  factory $CharityDonationCopyWith(CharityDonation value, $Res Function(CharityDonation) _then) = _$CharityDonationCopyWithImpl;
@useResult
$Res call({
 String charityName, int donatedCents
});




}
/// @nodoc
class _$CharityDonationCopyWithImpl<$Res>
    implements $CharityDonationCopyWith<$Res> {
  _$CharityDonationCopyWithImpl(this._self, this._then);

  final CharityDonation _self;
  final $Res Function(CharityDonation) _then;

/// Create a copy of CharityDonation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? charityName = null,Object? donatedCents = null,}) {
  return _then(_self.copyWith(
charityName: null == charityName ? _self.charityName : charityName // ignore: cast_nullable_to_non_nullable
as String,donatedCents: null == donatedCents ? _self.donatedCents : donatedCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CharityDonation].
extension CharityDonationPatterns on CharityDonation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CharityDonation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CharityDonation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CharityDonation value)  $default,){
final _that = this;
switch (_that) {
case _CharityDonation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CharityDonation value)?  $default,){
final _that = this;
switch (_that) {
case _CharityDonation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String charityName,  int donatedCents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CharityDonation() when $default != null:
return $default(_that.charityName,_that.donatedCents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String charityName,  int donatedCents)  $default,) {final _that = this;
switch (_that) {
case _CharityDonation():
return $default(_that.charityName,_that.donatedCents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String charityName,  int donatedCents)?  $default,) {final _that = this;
switch (_that) {
case _CharityDonation() when $default != null:
return $default(_that.charityName,_that.donatedCents);case _:
  return null;

}
}

}

/// @nodoc


class _CharityDonation implements CharityDonation {
  const _CharityDonation({required this.charityName, required this.donatedCents});
  

@override final  String charityName;
@override final  int donatedCents;

/// Create a copy of CharityDonation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CharityDonationCopyWith<_CharityDonation> get copyWith => __$CharityDonationCopyWithImpl<_CharityDonation>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CharityDonation&&(identical(other.charityName, charityName) || other.charityName == charityName)&&(identical(other.donatedCents, donatedCents) || other.donatedCents == donatedCents));
}


@override
int get hashCode => Object.hash(runtimeType,charityName,donatedCents);

@override
String toString() {
  return 'CharityDonation(charityName: $charityName, donatedCents: $donatedCents)';
}


}

/// @nodoc
abstract mixin class _$CharityDonationCopyWith<$Res> implements $CharityDonationCopyWith<$Res> {
  factory _$CharityDonationCopyWith(_CharityDonation value, $Res Function(_CharityDonation) _then) = __$CharityDonationCopyWithImpl;
@override @useResult
$Res call({
 String charityName, int donatedCents
});




}
/// @nodoc
class __$CharityDonationCopyWithImpl<$Res>
    implements _$CharityDonationCopyWith<$Res> {
  __$CharityDonationCopyWithImpl(this._self, this._then);

  final _CharityDonation _self;
  final $Res Function(_CharityDonation) _then;

/// Create a copy of CharityDonation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? charityName = null,Object? donatedCents = null,}) {
  return _then(_CharityDonation(
charityName: null == charityName ? _self.charityName : charityName // ignore: cast_nullable_to_non_nullable
as String,donatedCents: null == donatedCents ? _self.donatedCents : donatedCents // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$ImpactSummary {

 int get totalDonatedCents; int get commitmentsKept; int get commitmentsMissed; List<CharityDonation> get charityBreakdown; List<ImpactMilestone> get milestones;
/// Create a copy of ImpactSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImpactSummaryCopyWith<ImpactSummary> get copyWith => _$ImpactSummaryCopyWithImpl<ImpactSummary>(this as ImpactSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImpactSummary&&(identical(other.totalDonatedCents, totalDonatedCents) || other.totalDonatedCents == totalDonatedCents)&&(identical(other.commitmentsKept, commitmentsKept) || other.commitmentsKept == commitmentsKept)&&(identical(other.commitmentsMissed, commitmentsMissed) || other.commitmentsMissed == commitmentsMissed)&&const DeepCollectionEquality().equals(other.charityBreakdown, charityBreakdown)&&const DeepCollectionEquality().equals(other.milestones, milestones));
}


@override
int get hashCode => Object.hash(runtimeType,totalDonatedCents,commitmentsKept,commitmentsMissed,const DeepCollectionEquality().hash(charityBreakdown),const DeepCollectionEquality().hash(milestones));

@override
String toString() {
  return 'ImpactSummary(totalDonatedCents: $totalDonatedCents, commitmentsKept: $commitmentsKept, commitmentsMissed: $commitmentsMissed, charityBreakdown: $charityBreakdown, milestones: $milestones)';
}


}

/// @nodoc
abstract mixin class $ImpactSummaryCopyWith<$Res>  {
  factory $ImpactSummaryCopyWith(ImpactSummary value, $Res Function(ImpactSummary) _then) = _$ImpactSummaryCopyWithImpl;
@useResult
$Res call({
 int totalDonatedCents, int commitmentsKept, int commitmentsMissed, List<CharityDonation> charityBreakdown, List<ImpactMilestone> milestones
});




}
/// @nodoc
class _$ImpactSummaryCopyWithImpl<$Res>
    implements $ImpactSummaryCopyWith<$Res> {
  _$ImpactSummaryCopyWithImpl(this._self, this._then);

  final ImpactSummary _self;
  final $Res Function(ImpactSummary) _then;

/// Create a copy of ImpactSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalDonatedCents = null,Object? commitmentsKept = null,Object? commitmentsMissed = null,Object? charityBreakdown = null,Object? milestones = null,}) {
  return _then(_self.copyWith(
totalDonatedCents: null == totalDonatedCents ? _self.totalDonatedCents : totalDonatedCents // ignore: cast_nullable_to_non_nullable
as int,commitmentsKept: null == commitmentsKept ? _self.commitmentsKept : commitmentsKept // ignore: cast_nullable_to_non_nullable
as int,commitmentsMissed: null == commitmentsMissed ? _self.commitmentsMissed : commitmentsMissed // ignore: cast_nullable_to_non_nullable
as int,charityBreakdown: null == charityBreakdown ? _self.charityBreakdown : charityBreakdown // ignore: cast_nullable_to_non_nullable
as List<CharityDonation>,milestones: null == milestones ? _self.milestones : milestones // ignore: cast_nullable_to_non_nullable
as List<ImpactMilestone>,
  ));
}

}


/// Adds pattern-matching-related methods to [ImpactSummary].
extension ImpactSummaryPatterns on ImpactSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImpactSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImpactSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImpactSummary value)  $default,){
final _that = this;
switch (_that) {
case _ImpactSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImpactSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ImpactSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int totalDonatedCents,  int commitmentsKept,  int commitmentsMissed,  List<CharityDonation> charityBreakdown,  List<ImpactMilestone> milestones)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImpactSummary() when $default != null:
return $default(_that.totalDonatedCents,_that.commitmentsKept,_that.commitmentsMissed,_that.charityBreakdown,_that.milestones);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int totalDonatedCents,  int commitmentsKept,  int commitmentsMissed,  List<CharityDonation> charityBreakdown,  List<ImpactMilestone> milestones)  $default,) {final _that = this;
switch (_that) {
case _ImpactSummary():
return $default(_that.totalDonatedCents,_that.commitmentsKept,_that.commitmentsMissed,_that.charityBreakdown,_that.milestones);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int totalDonatedCents,  int commitmentsKept,  int commitmentsMissed,  List<CharityDonation> charityBreakdown,  List<ImpactMilestone> milestones)?  $default,) {final _that = this;
switch (_that) {
case _ImpactSummary() when $default != null:
return $default(_that.totalDonatedCents,_that.commitmentsKept,_that.commitmentsMissed,_that.charityBreakdown,_that.milestones);case _:
  return null;

}
}

}

/// @nodoc


class _ImpactSummary implements ImpactSummary {
  const _ImpactSummary({required this.totalDonatedCents, required this.commitmentsKept, required this.commitmentsMissed, final  List<CharityDonation> charityBreakdown = const [], final  List<ImpactMilestone> milestones = const []}): _charityBreakdown = charityBreakdown,_milestones = milestones;
  

@override final  int totalDonatedCents;
@override final  int commitmentsKept;
@override final  int commitmentsMissed;
 final  List<CharityDonation> _charityBreakdown;
@override@JsonKey() List<CharityDonation> get charityBreakdown {
  if (_charityBreakdown is EqualUnmodifiableListView) return _charityBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_charityBreakdown);
}

 final  List<ImpactMilestone> _milestones;
@override@JsonKey() List<ImpactMilestone> get milestones {
  if (_milestones is EqualUnmodifiableListView) return _milestones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_milestones);
}


/// Create a copy of ImpactSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImpactSummaryCopyWith<_ImpactSummary> get copyWith => __$ImpactSummaryCopyWithImpl<_ImpactSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImpactSummary&&(identical(other.totalDonatedCents, totalDonatedCents) || other.totalDonatedCents == totalDonatedCents)&&(identical(other.commitmentsKept, commitmentsKept) || other.commitmentsKept == commitmentsKept)&&(identical(other.commitmentsMissed, commitmentsMissed) || other.commitmentsMissed == commitmentsMissed)&&const DeepCollectionEquality().equals(other._charityBreakdown, _charityBreakdown)&&const DeepCollectionEquality().equals(other._milestones, _milestones));
}


@override
int get hashCode => Object.hash(runtimeType,totalDonatedCents,commitmentsKept,commitmentsMissed,const DeepCollectionEquality().hash(_charityBreakdown),const DeepCollectionEquality().hash(_milestones));

@override
String toString() {
  return 'ImpactSummary(totalDonatedCents: $totalDonatedCents, commitmentsKept: $commitmentsKept, commitmentsMissed: $commitmentsMissed, charityBreakdown: $charityBreakdown, milestones: $milestones)';
}


}

/// @nodoc
abstract mixin class _$ImpactSummaryCopyWith<$Res> implements $ImpactSummaryCopyWith<$Res> {
  factory _$ImpactSummaryCopyWith(_ImpactSummary value, $Res Function(_ImpactSummary) _then) = __$ImpactSummaryCopyWithImpl;
@override @useResult
$Res call({
 int totalDonatedCents, int commitmentsKept, int commitmentsMissed, List<CharityDonation> charityBreakdown, List<ImpactMilestone> milestones
});




}
/// @nodoc
class __$ImpactSummaryCopyWithImpl<$Res>
    implements _$ImpactSummaryCopyWith<$Res> {
  __$ImpactSummaryCopyWithImpl(this._self, this._then);

  final _ImpactSummary _self;
  final $Res Function(_ImpactSummary) _then;

/// Create a copy of ImpactSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalDonatedCents = null,Object? commitmentsKept = null,Object? commitmentsMissed = null,Object? charityBreakdown = null,Object? milestones = null,}) {
  return _then(_ImpactSummary(
totalDonatedCents: null == totalDonatedCents ? _self.totalDonatedCents : totalDonatedCents // ignore: cast_nullable_to_non_nullable
as int,commitmentsKept: null == commitmentsKept ? _self.commitmentsKept : commitmentsKept // ignore: cast_nullable_to_non_nullable
as int,commitmentsMissed: null == commitmentsMissed ? _self.commitmentsMissed : commitmentsMissed // ignore: cast_nullable_to_non_nullable
as int,charityBreakdown: null == charityBreakdown ? _self._charityBreakdown : charityBreakdown // ignore: cast_nullable_to_non_nullable
as List<CharityDonation>,milestones: null == milestones ? _self._milestones : milestones // ignore: cast_nullable_to_non_nullable
as List<ImpactMilestone>,
  ));
}


}

// dart format on
