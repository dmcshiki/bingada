// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'claim.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Claim {

 ClaimId get id; UserId get uid; PrizeId get prizeId;/// `draws.length` at the moment of the claim.
 int get drawIndex;/// Row-major indexes the player had stamped when claiming (marks are
/// local until a claim; the snapshot is what the host verifies).
 List<int> get markedCells; ClaimStatus get status; ClaimVerdict? get verdict; List<PatternMatch> get matched;/// Prize offered while awaiting a choice when it differs from [prizeId]
/// (a prize passed on from a tie).
 PrizeId? get offerPrizeId;/// Legacy answer (keep = give up the offer, swap = give up the held one).
 ClaimChoice? get choice;/// Player answer: the prize they give up (the offer or one they hold).
 PrizeId? get releasePrizeId;/// Tie while the player is at the limit: they are asked first whether
/// they join the draw ([ClaimChoice.join]) or skip it.
 bool get tieOptIn; DateTime get createdAt;
/// Create a copy of Claim
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClaimCopyWith<Claim> get copyWith => _$ClaimCopyWithImpl<Claim>(this as Claim, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Claim;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Claim&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.prizeId, _this.prizeId) || other.prizeId == _this.prizeId)&&(identical(other.drawIndex, _this.drawIndex) || other.drawIndex == _this.drawIndex)&&const DeepCollectionEquality().equals(other.markedCells, _this.markedCells)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.verdict, _this.verdict) || other.verdict == _this.verdict)&&const DeepCollectionEquality().equals(other.matched, _this.matched)&&(identical(other.offerPrizeId, _this.offerPrizeId) || other.offerPrizeId == _this.offerPrizeId)&&(identical(other.choice, _this.choice) || other.choice == _this.choice)&&(identical(other.releasePrizeId, _this.releasePrizeId) || other.releasePrizeId == _this.releasePrizeId)&&(identical(other.tieOptIn, _this.tieOptIn) || other.tieOptIn == _this.tieOptIn)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt));
}


@override
int get hashCode {
  final _this = this as Claim;
  return Object.hash(runtimeType,_this.id,_this.uid,_this.prizeId,_this.drawIndex,const DeepCollectionEquality().hash(_this.markedCells),_this.status,_this.verdict,const DeepCollectionEquality().hash(_this.matched),_this.offerPrizeId,_this.choice,_this.releasePrizeId,_this.tieOptIn,_this.createdAt);
}

@override
String toString() {
  final _this = this as Claim;
  return 'Claim(id: ${_this.id}, uid: ${_this.uid}, prizeId: ${_this.prizeId}, drawIndex: ${_this.drawIndex}, markedCells: ${_this.markedCells}, status: ${_this.status}, verdict: ${_this.verdict}, matched: ${_this.matched}, offerPrizeId: ${_this.offerPrizeId}, choice: ${_this.choice}, releasePrizeId: ${_this.releasePrizeId}, tieOptIn: ${_this.tieOptIn}, createdAt: ${_this.createdAt})';
}


}

/// @nodoc
abstract mixin class $ClaimCopyWith<$Res>  {
  factory $ClaimCopyWith(Claim value, $Res Function(Claim) _then) = _$ClaimCopyWithImpl;
@useResult
$Res call({
 ClaimId id, UserId uid, PrizeId prizeId, int drawIndex, List<int> markedCells, ClaimStatus status, ClaimVerdict? verdict, List<PatternMatch> matched, PrizeId? offerPrizeId, ClaimChoice? choice, PrizeId? releasePrizeId, bool tieOptIn, DateTime createdAt
});




}
/// @nodoc
class _$ClaimCopyWithImpl<$Res>
    implements $ClaimCopyWith<$Res> {
  _$ClaimCopyWithImpl(this._self, this._then);

  final Claim _self;
  final $Res Function(Claim) _then;

/// Create a copy of Claim
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? uid = null,Object? prizeId = null,Object? drawIndex = null,Object? markedCells = null,Object? status = null,Object? verdict = freezed,Object? matched = null,Object? offerPrizeId = freezed,Object? choice = freezed,Object? releasePrizeId = freezed,Object? tieOptIn = null,Object? createdAt = null,}) {
  return _then(Claim(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ClaimId,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,prizeId: null == prizeId ? _self.prizeId : prizeId // ignore: cast_nullable_to_non_nullable
as PrizeId,drawIndex: null == drawIndex ? _self.drawIndex : drawIndex // ignore: cast_nullable_to_non_nullable
as int,markedCells: null == markedCells ? _self.markedCells : markedCells // ignore: cast_nullable_to_non_nullable
as List<int>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ClaimStatus,verdict: freezed == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as ClaimVerdict?,matched: null == matched ? _self.matched : matched // ignore: cast_nullable_to_non_nullable
as List<PatternMatch>,offerPrizeId: freezed == offerPrizeId ? _self.offerPrizeId : offerPrizeId // ignore: cast_nullable_to_non_nullable
as PrizeId?,choice: freezed == choice ? _self.choice : choice // ignore: cast_nullable_to_non_nullable
as ClaimChoice?,releasePrizeId: freezed == releasePrizeId ? _self.releasePrizeId : releasePrizeId // ignore: cast_nullable_to_non_nullable
as PrizeId?,tieOptIn: null == tieOptIn ? _self.tieOptIn : tieOptIn // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Claim].
extension ClaimPatterns on Claim {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Claim value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Claim() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Claim value)  $default,){
final _that = this;
switch (_that) {
case _Claim():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Claim value)?  $default,){
final _that = this;
switch (_that) {
case _Claim() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ClaimId id,  UserId uid,  PrizeId prizeId,  int drawIndex,  List<int> markedCells,  ClaimStatus status,  ClaimVerdict? verdict,  List<PatternMatch> matched,  PrizeId? offerPrizeId,  ClaimChoice? choice,  PrizeId? releasePrizeId,  bool tieOptIn,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Claim() when $default != null:
return $default(_that.id,_that.uid,_that.prizeId,_that.drawIndex,_that.markedCells,_that.status,_that.verdict,_that.matched,_that.offerPrizeId,_that.choice,_that.releasePrizeId,_that.tieOptIn,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ClaimId id,  UserId uid,  PrizeId prizeId,  int drawIndex,  List<int> markedCells,  ClaimStatus status,  ClaimVerdict? verdict,  List<PatternMatch> matched,  PrizeId? offerPrizeId,  ClaimChoice? choice,  PrizeId? releasePrizeId,  bool tieOptIn,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _Claim():
return $default(_that.id,_that.uid,_that.prizeId,_that.drawIndex,_that.markedCells,_that.status,_that.verdict,_that.matched,_that.offerPrizeId,_that.choice,_that.releasePrizeId,_that.tieOptIn,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ClaimId id,  UserId uid,  PrizeId prizeId,  int drawIndex,  List<int> markedCells,  ClaimStatus status,  ClaimVerdict? verdict,  List<PatternMatch> matched,  PrizeId? offerPrizeId,  ClaimChoice? choice,  PrizeId? releasePrizeId,  bool tieOptIn,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Claim() when $default != null:
return $default(_that.id,_that.uid,_that.prizeId,_that.drawIndex,_that.markedCells,_that.status,_that.verdict,_that.matched,_that.offerPrizeId,_that.choice,_that.releasePrizeId,_that.tieOptIn,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _Claim implements Claim {
  const _Claim({required this.id, required this.uid, required this.prizeId, required this.drawIndex,  List<int> markedCells = const <int>[], this.status = ClaimStatus.pending, this.verdict,  List<PatternMatch> matched = const <PatternMatch>[], this.offerPrizeId, this.choice, this.releasePrizeId, this.tieOptIn = false, required this.createdAt}): _markedCells = markedCells,_matched = matched;
  

@override final  ClaimId id;
@override final  UserId uid;
@override final  PrizeId prizeId;
/// `draws.length` at the moment of the claim.
@override final  int drawIndex;
/// Row-major indexes the player had stamped when claiming (marks are
/// local until a claim; the snapshot is what the host verifies).
 final  List<int> _markedCells;
/// Row-major indexes the player had stamped when claiming (marks are
/// local until a claim; the snapshot is what the host verifies).
@override@JsonKey() List<int> get markedCells {
  if (_markedCells is EqualUnmodifiableListView) return _markedCells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_markedCells);
}

@override@JsonKey() final  ClaimStatus status;
@override final  ClaimVerdict? verdict;
 final  List<PatternMatch> _matched;
@override@JsonKey() List<PatternMatch> get matched {
  if (_matched is EqualUnmodifiableListView) return _matched;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_matched);
}

/// Prize offered while awaiting a choice when it differs from [prizeId]
/// (a prize passed on from a tie).
@override final  PrizeId? offerPrizeId;
/// Legacy answer (keep = give up the offer, swap = give up the held one).
@override final  ClaimChoice? choice;
/// Player answer: the prize they give up (the offer or one they hold).
@override final  PrizeId? releasePrizeId;
/// Tie while the player is at the limit: they are asked first whether
/// they join the draw ([ClaimChoice.join]) or skip it.
@override@JsonKey() final  bool tieOptIn;
@override final  DateTime createdAt;

/// Create a copy of Claim
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClaimCopyWith<_Claim> get copyWith => __$ClaimCopyWithImpl<_Claim>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Claim&&(identical(other.id, id) || other.id == id)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.prizeId, prizeId) || other.prizeId == prizeId)&&(identical(other.drawIndex, drawIndex) || other.drawIndex == drawIndex)&&const DeepCollectionEquality().equals(other.markedCells, _markedCells)&&(identical(other.status, status) || other.status == status)&&(identical(other.verdict, verdict) || other.verdict == verdict)&&const DeepCollectionEquality().equals(other.matched, _matched)&&(identical(other.offerPrizeId, offerPrizeId) || other.offerPrizeId == offerPrizeId)&&(identical(other.choice, choice) || other.choice == choice)&&(identical(other.releasePrizeId, releasePrizeId) || other.releasePrizeId == releasePrizeId)&&(identical(other.tieOptIn, tieOptIn) || other.tieOptIn == tieOptIn)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,uid,prizeId,drawIndex,const DeepCollectionEquality().hash(_markedCells),status,verdict,const DeepCollectionEquality().hash(_matched),offerPrizeId,choice,releasePrizeId,tieOptIn,createdAt);
}

@override
String toString() {
    return 'Claim(id: $id, uid: $uid, prizeId: $prizeId, drawIndex: $drawIndex, markedCells: $markedCells, status: $status, verdict: $verdict, matched: $matched, offerPrizeId: $offerPrizeId, choice: $choice, releasePrizeId: $releasePrizeId, tieOptIn: $tieOptIn, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$ClaimCopyWith<$Res> implements $ClaimCopyWith<$Res> {
  factory _$ClaimCopyWith(_Claim value, $Res Function(_Claim) _then) = __$ClaimCopyWithImpl;
@override @useResult
$Res call({
 ClaimId id, UserId uid, PrizeId prizeId, int drawIndex, List<int> markedCells, ClaimStatus status, ClaimVerdict? verdict, List<PatternMatch> matched, PrizeId? offerPrizeId, ClaimChoice? choice, PrizeId? releasePrizeId, bool tieOptIn, DateTime createdAt
});




}
/// @nodoc
class __$ClaimCopyWithImpl<$Res>
    implements _$ClaimCopyWith<$Res> {
  __$ClaimCopyWithImpl(this._self, this._then);

  final _Claim _self;
  final $Res Function(_Claim) _then;

/// Create a copy of Claim
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? uid = null,Object? prizeId = null,Object? drawIndex = null,Object? markedCells = null,Object? status = null,Object? verdict = freezed,Object? matched = null,Object? offerPrizeId = freezed,Object? choice = freezed,Object? releasePrizeId = freezed,Object? tieOptIn = null,Object? createdAt = null,}) {
  return _then(_Claim(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ClaimId,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,prizeId: null == prizeId ? _self.prizeId : prizeId // ignore: cast_nullable_to_non_nullable
as PrizeId,drawIndex: null == drawIndex ? _self.drawIndex : drawIndex // ignore: cast_nullable_to_non_nullable
as int,markedCells: null == markedCells ? _self._markedCells : markedCells // ignore: cast_nullable_to_non_nullable
as List<int>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as ClaimStatus,verdict: freezed == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as ClaimVerdict?,matched: null == matched ? _self._matched : matched // ignore: cast_nullable_to_non_nullable
as List<PatternMatch>,offerPrizeId: freezed == offerPrizeId ? _self.offerPrizeId : offerPrizeId // ignore: cast_nullable_to_non_nullable
as PrizeId?,choice: freezed == choice ? _self.choice : choice // ignore: cast_nullable_to_non_nullable
as ClaimChoice?,releasePrizeId: freezed == releasePrizeId ? _self.releasePrizeId : releasePrizeId // ignore: cast_nullable_to_non_nullable
as PrizeId?,tieOptIn: null == tieOptIn ? _self.tieOptIn : tieOptIn // ignore: cast_nullable_to_non_nullable
as bool,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$ClaimResult {

 ClaimVerdict get verdict; List<PatternMatch> get matched;/// Card items marked/required but not drawn (for "comeu bola" UI).
 List<ItemId> get notDrawn;/// Human-readable reason for the UI.
 String get reason;
/// Create a copy of ClaimResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClaimResultCopyWith<ClaimResult> get copyWith => _$ClaimResultCopyWithImpl<ClaimResult>(this as ClaimResult, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ClaimResult;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClaimResult&&(identical(other.verdict, _this.verdict) || other.verdict == _this.verdict)&&const DeepCollectionEquality().equals(other.matched, _this.matched)&&const DeepCollectionEquality().equals(other.notDrawn, _this.notDrawn)&&(identical(other.reason, _this.reason) || other.reason == _this.reason));
}


@override
int get hashCode {
  final _this = this as ClaimResult;
  return Object.hash(runtimeType,_this.verdict,const DeepCollectionEquality().hash(_this.matched),const DeepCollectionEquality().hash(_this.notDrawn),_this.reason);
}

@override
String toString() {
  final _this = this as ClaimResult;
  return 'ClaimResult(verdict: ${_this.verdict}, matched: ${_this.matched}, notDrawn: ${_this.notDrawn}, reason: ${_this.reason})';
}


}

/// @nodoc
abstract mixin class $ClaimResultCopyWith<$Res>  {
  factory $ClaimResultCopyWith(ClaimResult value, $Res Function(ClaimResult) _then) = _$ClaimResultCopyWithImpl;
@useResult
$Res call({
 ClaimVerdict verdict, List<PatternMatch> matched, List<ItemId> notDrawn, String reason
});




}
/// @nodoc
class _$ClaimResultCopyWithImpl<$Res>
    implements $ClaimResultCopyWith<$Res> {
  _$ClaimResultCopyWithImpl(this._self, this._then);

  final ClaimResult _self;
  final $Res Function(ClaimResult) _then;

/// Create a copy of ClaimResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? verdict = null,Object? matched = null,Object? notDrawn = null,Object? reason = null,}) {
  return _then(ClaimResult(
verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as ClaimVerdict,matched: null == matched ? _self.matched : matched // ignore: cast_nullable_to_non_nullable
as List<PatternMatch>,notDrawn: null == notDrawn ? _self.notDrawn : notDrawn // ignore: cast_nullable_to_non_nullable
as List<ItemId>,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ClaimResult].
extension ClaimResultPatterns on ClaimResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClaimResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClaimResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClaimResult value)  $default,){
final _that = this;
switch (_that) {
case _ClaimResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClaimResult value)?  $default,){
final _that = this;
switch (_that) {
case _ClaimResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ClaimVerdict verdict,  List<PatternMatch> matched,  List<ItemId> notDrawn,  String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClaimResult() when $default != null:
return $default(_that.verdict,_that.matched,_that.notDrawn,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ClaimVerdict verdict,  List<PatternMatch> matched,  List<ItemId> notDrawn,  String reason)  $default,) {final _that = this;
switch (_that) {
case _ClaimResult():
return $default(_that.verdict,_that.matched,_that.notDrawn,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ClaimVerdict verdict,  List<PatternMatch> matched,  List<ItemId> notDrawn,  String reason)?  $default,) {final _that = this;
switch (_that) {
case _ClaimResult() when $default != null:
return $default(_that.verdict,_that.matched,_that.notDrawn,_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class _ClaimResult implements ClaimResult {
  const _ClaimResult({required this.verdict,  List<PatternMatch> matched = const <PatternMatch>[],  List<ItemId> notDrawn = const <ItemId>[], this.reason = ''}): _matched = matched,_notDrawn = notDrawn;
  

@override final  ClaimVerdict verdict;
 final  List<PatternMatch> _matched;
@override@JsonKey() List<PatternMatch> get matched {
  if (_matched is EqualUnmodifiableListView) return _matched;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_matched);
}

/// Card items marked/required but not drawn (for "comeu bola" UI).
 final  List<ItemId> _notDrawn;
/// Card items marked/required but not drawn (for "comeu bola" UI).
@override@JsonKey() List<ItemId> get notDrawn {
  if (_notDrawn is EqualUnmodifiableListView) return _notDrawn;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_notDrawn);
}

/// Human-readable reason for the UI.
@override@JsonKey() final  String reason;

/// Create a copy of ClaimResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClaimResultCopyWith<_ClaimResult> get copyWith => __$ClaimResultCopyWithImpl<_ClaimResult>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClaimResult&&(identical(other.verdict, verdict) || other.verdict == verdict)&&const DeepCollectionEquality().equals(other.matched, _matched)&&const DeepCollectionEquality().equals(other.notDrawn, _notDrawn)&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,verdict,const DeepCollectionEquality().hash(_matched),const DeepCollectionEquality().hash(_notDrawn),reason);
}

@override
String toString() {
    return 'ClaimResult(verdict: $verdict, matched: $matched, notDrawn: $notDrawn, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$ClaimResultCopyWith<$Res> implements $ClaimResultCopyWith<$Res> {
  factory _$ClaimResultCopyWith(_ClaimResult value, $Res Function(_ClaimResult) _then) = __$ClaimResultCopyWithImpl;
@override @useResult
$Res call({
 ClaimVerdict verdict, List<PatternMatch> matched, List<ItemId> notDrawn, String reason
});




}
/// @nodoc
class __$ClaimResultCopyWithImpl<$Res>
    implements _$ClaimResultCopyWith<$Res> {
  __$ClaimResultCopyWithImpl(this._self, this._then);

  final _ClaimResult _self;
  final $Res Function(_ClaimResult) _then;

/// Create a copy of ClaimResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? verdict = null,Object? matched = null,Object? notDrawn = null,Object? reason = null,}) {
  return _then(_ClaimResult(
verdict: null == verdict ? _self.verdict : verdict // ignore: cast_nullable_to_non_nullable
as ClaimVerdict,matched: null == matched ? _self._matched : matched // ignore: cast_nullable_to_non_nullable
as List<PatternMatch>,notDrawn: null == notDrawn ? _self._notDrawn : notDrawn // ignore: cast_nullable_to_non_nullable
as List<ItemId>,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
