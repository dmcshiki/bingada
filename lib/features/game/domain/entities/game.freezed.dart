// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'game.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Raffle {

 PrizeId get prizeId; List<UserId> get candidates; RaffleKind get kind; UserId? get winner;/// Who gave the prize up ([RaffleKind.released]).
 UserId? get releasedBy;
/// Create a copy of Raffle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RaffleCopyWith<Raffle> get copyWith => _$RaffleCopyWithImpl<Raffle>(this as Raffle, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Raffle;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Raffle&&(identical(other.prizeId, _this.prizeId) || other.prizeId == _this.prizeId)&&const DeepCollectionEquality().equals(other.candidates, _this.candidates)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.winner, _this.winner) || other.winner == _this.winner)&&(identical(other.releasedBy, _this.releasedBy) || other.releasedBy == _this.releasedBy));
}


@override
int get hashCode {
  final _this = this as Raffle;
  return Object.hash(runtimeType,_this.prizeId,const DeepCollectionEquality().hash(_this.candidates),_this.kind,_this.winner,_this.releasedBy);
}

@override
String toString() {
  final _this = this as Raffle;
  return 'Raffle(prizeId: ${_this.prizeId}, candidates: ${_this.candidates}, kind: ${_this.kind}, winner: ${_this.winner}, releasedBy: ${_this.releasedBy})';
}


}

/// @nodoc
abstract mixin class $RaffleCopyWith<$Res>  {
  factory $RaffleCopyWith(Raffle value, $Res Function(Raffle) _then) = _$RaffleCopyWithImpl;
@useResult
$Res call({
 PrizeId prizeId, List<UserId> candidates, RaffleKind kind, UserId? winner, UserId? releasedBy
});




}
/// @nodoc
class _$RaffleCopyWithImpl<$Res>
    implements $RaffleCopyWith<$Res> {
  _$RaffleCopyWithImpl(this._self, this._then);

  final Raffle _self;
  final $Res Function(Raffle) _then;

/// Create a copy of Raffle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? prizeId = null,Object? candidates = null,Object? kind = null,Object? winner = freezed,Object? releasedBy = freezed,}) {
  return _then(Raffle(
prizeId: null == prizeId ? _self.prizeId : prizeId // ignore: cast_nullable_to_non_nullable
as PrizeId,candidates: null == candidates ? _self.candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<UserId>,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RaffleKind,winner: freezed == winner ? _self.winner : winner // ignore: cast_nullable_to_non_nullable
as UserId?,releasedBy: freezed == releasedBy ? _self.releasedBy : releasedBy // ignore: cast_nullable_to_non_nullable
as UserId?,
  ));
}

}


/// Adds pattern-matching-related methods to [Raffle].
extension RafflePatterns on Raffle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Raffle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Raffle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Raffle value)  $default,){
final _that = this;
switch (_that) {
case _Raffle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Raffle value)?  $default,){
final _that = this;
switch (_that) {
case _Raffle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PrizeId prizeId,  List<UserId> candidates,  RaffleKind kind,  UserId? winner,  UserId? releasedBy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Raffle() when $default != null:
return $default(_that.prizeId,_that.candidates,_that.kind,_that.winner,_that.releasedBy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PrizeId prizeId,  List<UserId> candidates,  RaffleKind kind,  UserId? winner,  UserId? releasedBy)  $default,) {final _that = this;
switch (_that) {
case _Raffle():
return $default(_that.prizeId,_that.candidates,_that.kind,_that.winner,_that.releasedBy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PrizeId prizeId,  List<UserId> candidates,  RaffleKind kind,  UserId? winner,  UserId? releasedBy)?  $default,) {final _that = this;
switch (_that) {
case _Raffle() when $default != null:
return $default(_that.prizeId,_that.candidates,_that.kind,_that.winner,_that.releasedBy);case _:
  return null;

}
}

}

/// @nodoc


class _Raffle implements Raffle {
  const _Raffle({required this.prizeId, required  List<UserId> candidates, required this.kind, this.winner, this.releasedBy}): _candidates = candidates;
  

@override final  PrizeId prizeId;
 final  List<UserId> _candidates;
@override List<UserId> get candidates {
  if (_candidates is EqualUnmodifiableListView) return _candidates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_candidates);
}

@override final  RaffleKind kind;
@override final  UserId? winner;
/// Who gave the prize up ([RaffleKind.released]).
@override final  UserId? releasedBy;

/// Create a copy of Raffle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RaffleCopyWith<_Raffle> get copyWith => __$RaffleCopyWithImpl<_Raffle>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Raffle&&(identical(other.prizeId, prizeId) || other.prizeId == prizeId)&&const DeepCollectionEquality().equals(other.candidates, _candidates)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.winner, winner) || other.winner == winner)&&(identical(other.releasedBy, releasedBy) || other.releasedBy == releasedBy));
}


@override
int get hashCode {
    return Object.hash(runtimeType,prizeId,const DeepCollectionEquality().hash(_candidates),kind,winner,releasedBy);
}

@override
String toString() {
    return 'Raffle(prizeId: $prizeId, candidates: $candidates, kind: $kind, winner: $winner, releasedBy: $releasedBy)';
}


}

/// @nodoc
abstract mixin class _$RaffleCopyWith<$Res> implements $RaffleCopyWith<$Res> {
  factory _$RaffleCopyWith(_Raffle value, $Res Function(_Raffle) _then) = __$RaffleCopyWithImpl;
@override @useResult
$Res call({
 PrizeId prizeId, List<UserId> candidates, RaffleKind kind, UserId? winner, UserId? releasedBy
});




}
/// @nodoc
class __$RaffleCopyWithImpl<$Res>
    implements _$RaffleCopyWith<$Res> {
  __$RaffleCopyWithImpl(this._self, this._then);

  final _Raffle _self;
  final $Res Function(_Raffle) _then;

/// Create a copy of Raffle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? prizeId = null,Object? candidates = null,Object? kind = null,Object? winner = freezed,Object? releasedBy = freezed,}) {
  return _then(_Raffle(
prizeId: null == prizeId ? _self.prizeId : prizeId // ignore: cast_nullable_to_non_nullable
as PrizeId,candidates: null == candidates ? _self._candidates : candidates // ignore: cast_nullable_to_non_nullable
as List<UserId>,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as RaffleKind,winner: freezed == winner ? _self.winner : winner // ignore: cast_nullable_to_non_nullable
as UserId?,releasedBy: freezed == releasedBy ? _self.releasedBy : releasedBy // ignore: cast_nullable_to_non_nullable
as UserId?,
  ));
}


}

/// @nodoc
mixin _$AccessPolicy {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AccessPolicy);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AccessPolicy()';
}


}

/// @nodoc
class $AccessPolicyCopyWith<$Res>  {
$AccessPolicyCopyWith(AccessPolicy _, $Res Function(AccessPolicy) __);
}


/// Adds pattern-matching-related methods to [AccessPolicy].
extension AccessPolicyPatterns on AccessPolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( DomainAccess value)?  domain,TResult Function( SameAsHostAccess value)?  sameAsHost,TResult Function( AllowlistAccess value)?  allowlist,TResult Function( PublicAccess value)?  public,required TResult orElse(),}){
final _that = this;
switch (_that) {
case DomainAccess() when domain != null:
return domain(_that);case SameAsHostAccess() when sameAsHost != null:
return sameAsHost(_that);case AllowlistAccess() when allowlist != null:
return allowlist(_that);case PublicAccess() when public != null:
return public(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( DomainAccess value)  domain,required TResult Function( SameAsHostAccess value)  sameAsHost,required TResult Function( AllowlistAccess value)  allowlist,required TResult Function( PublicAccess value)  public,}){
final _that = this;
switch (_that) {
case DomainAccess():
return domain(_that);case SameAsHostAccess():
return sameAsHost(_that);case AllowlistAccess():
return allowlist(_that);case PublicAccess():
return public(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( DomainAccess value)?  domain,TResult? Function( SameAsHostAccess value)?  sameAsHost,TResult? Function( AllowlistAccess value)?  allowlist,TResult? Function( PublicAccess value)?  public,}){
final _that = this;
switch (_that) {
case DomainAccess() when domain != null:
return domain(_that);case SameAsHostAccess() when sameAsHost != null:
return sameAsHost(_that);case AllowlistAccess() when allowlist != null:
return allowlist(_that);case PublicAccess() when public != null:
return public(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( List<String> domains)?  domain,TResult Function( String hostDomain)?  sameAsHost,TResult Function( List<String> emails)?  allowlist,TResult Function()?  public,required TResult orElse(),}) {final _that = this;
switch (_that) {
case DomainAccess() when domain != null:
return domain(_that.domains);case SameAsHostAccess() when sameAsHost != null:
return sameAsHost(_that.hostDomain);case AllowlistAccess() when allowlist != null:
return allowlist(_that.emails);case PublicAccess() when public != null:
return public();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( List<String> domains)  domain,required TResult Function( String hostDomain)  sameAsHost,required TResult Function( List<String> emails)  allowlist,required TResult Function()  public,}) {final _that = this;
switch (_that) {
case DomainAccess():
return domain(_that.domains);case SameAsHostAccess():
return sameAsHost(_that.hostDomain);case AllowlistAccess():
return allowlist(_that.emails);case PublicAccess():
return public();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( List<String> domains)?  domain,TResult? Function( String hostDomain)?  sameAsHost,TResult? Function( List<String> emails)?  allowlist,TResult? Function()?  public,}) {final _that = this;
switch (_that) {
case DomainAccess() when domain != null:
return domain(_that.domains);case SameAsHostAccess() when sameAsHost != null:
return sameAsHost(_that.hostDomain);case AllowlistAccess() when allowlist != null:
return allowlist(_that.emails);case PublicAccess() when public != null:
return public();case _:
  return null;

}
}

}

/// @nodoc


class DomainAccess implements AccessPolicy {
  const DomainAccess({required  List<String> domains}): _domains = domains;
  

 final  List<String> _domains;
 List<String> get domains {
  if (_domains is EqualUnmodifiableListView) return _domains;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_domains);
}


/// Create a copy of AccessPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DomainAccessCopyWith<DomainAccess> get copyWith => _$DomainAccessCopyWithImpl<DomainAccess>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is DomainAccess&&const DeepCollectionEquality().equals(other.domains, _domains));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_domains));
}

@override
String toString() {
    return 'AccessPolicy.domain(domains: $domains)';
}


}

/// @nodoc
abstract mixin class $DomainAccessCopyWith<$Res> implements $AccessPolicyCopyWith<$Res> {
  factory $DomainAccessCopyWith(DomainAccess value, $Res Function(DomainAccess) _then) = _$DomainAccessCopyWithImpl;
@useResult
$Res call({
 List<String> domains
});




}
/// @nodoc
class _$DomainAccessCopyWithImpl<$Res>
    implements $DomainAccessCopyWith<$Res> {
  _$DomainAccessCopyWithImpl(this._self, this._then);

  final DomainAccess _self;
  final $Res Function(DomainAccess) _then;

/// Create a copy of AccessPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? domains = null,}) {
  return _then(DomainAccess(
domains: null == domains ? _self._domains : domains // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class SameAsHostAccess implements AccessPolicy {
  const SameAsHostAccess({required this.hostDomain});
  

 final  String hostDomain;

/// Create a copy of AccessPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SameAsHostAccessCopyWith<SameAsHostAccess> get copyWith => _$SameAsHostAccessCopyWithImpl<SameAsHostAccess>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SameAsHostAccess&&(identical(other.hostDomain, hostDomain) || other.hostDomain == hostDomain));
}


@override
int get hashCode {
    return Object.hash(runtimeType,hostDomain);
}

@override
String toString() {
    return 'AccessPolicy.sameAsHost(hostDomain: $hostDomain)';
}


}

/// @nodoc
abstract mixin class $SameAsHostAccessCopyWith<$Res> implements $AccessPolicyCopyWith<$Res> {
  factory $SameAsHostAccessCopyWith(SameAsHostAccess value, $Res Function(SameAsHostAccess) _then) = _$SameAsHostAccessCopyWithImpl;
@useResult
$Res call({
 String hostDomain
});




}
/// @nodoc
class _$SameAsHostAccessCopyWithImpl<$Res>
    implements $SameAsHostAccessCopyWith<$Res> {
  _$SameAsHostAccessCopyWithImpl(this._self, this._then);

  final SameAsHostAccess _self;
  final $Res Function(SameAsHostAccess) _then;

/// Create a copy of AccessPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? hostDomain = null,}) {
  return _then(SameAsHostAccess(
hostDomain: null == hostDomain ? _self.hostDomain : hostDomain // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AllowlistAccess implements AccessPolicy {
  const AllowlistAccess({required  List<String> emails}): _emails = emails;
  

 final  List<String> _emails;
 List<String> get emails {
  if (_emails is EqualUnmodifiableListView) return _emails;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_emails);
}


/// Create a copy of AccessPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AllowlistAccessCopyWith<AllowlistAccess> get copyWith => _$AllowlistAccessCopyWithImpl<AllowlistAccess>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AllowlistAccess&&const DeepCollectionEquality().equals(other.emails, _emails));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_emails));
}

@override
String toString() {
    return 'AccessPolicy.allowlist(emails: $emails)';
}


}

/// @nodoc
abstract mixin class $AllowlistAccessCopyWith<$Res> implements $AccessPolicyCopyWith<$Res> {
  factory $AllowlistAccessCopyWith(AllowlistAccess value, $Res Function(AllowlistAccess) _then) = _$AllowlistAccessCopyWithImpl;
@useResult
$Res call({
 List<String> emails
});




}
/// @nodoc
class _$AllowlistAccessCopyWithImpl<$Res>
    implements $AllowlistAccessCopyWith<$Res> {
  _$AllowlistAccessCopyWithImpl(this._self, this._then);

  final AllowlistAccess _self;
  final $Res Function(AllowlistAccess) _then;

/// Create a copy of AccessPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? emails = null,}) {
  return _then(AllowlistAccess(
emails: null == emails ? _self._emails : emails // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc


class PublicAccess implements AccessPolicy {
  const PublicAccess();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is PublicAccess);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AccessPolicy.public()';
}


}




/// @nodoc
mixin _$ClaimPenaltyPolicy {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ClaimPenaltyPolicy);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ClaimPenaltyPolicy()';
}


}

/// @nodoc
class $ClaimPenaltyPolicyCopyWith<$Res>  {
$ClaimPenaltyPolicyCopyWith(ClaimPenaltyPolicy _, $Res Function(ClaimPenaltyPolicy) __);
}


/// Adds pattern-matching-related methods to [ClaimPenaltyPolicy].
extension ClaimPenaltyPolicyPatterns on ClaimPenaltyPolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( NoPenalty value)?  none,TResult Function( SkipDraws value)?  skipDraws,required TResult orElse(),}){
final _that = this;
switch (_that) {
case NoPenalty() when none != null:
return none(_that);case SkipDraws() when skipDraws != null:
return skipDraws(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( NoPenalty value)  none,required TResult Function( SkipDraws value)  skipDraws,}){
final _that = this;
switch (_that) {
case NoPenalty():
return none(_that);case SkipDraws():
return skipDraws(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( NoPenalty value)?  none,TResult? Function( SkipDraws value)?  skipDraws,}){
final _that = this;
switch (_that) {
case NoPenalty() when none != null:
return none(_that);case SkipDraws() when skipDraws != null:
return skipDraws(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  none,TResult Function( int draws)?  skipDraws,required TResult orElse(),}) {final _that = this;
switch (_that) {
case NoPenalty() when none != null:
return none();case SkipDraws() when skipDraws != null:
return skipDraws(_that.draws);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  none,required TResult Function( int draws)  skipDraws,}) {final _that = this;
switch (_that) {
case NoPenalty():
return none();case SkipDraws():
return skipDraws(_that.draws);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  none,TResult? Function( int draws)?  skipDraws,}) {final _that = this;
switch (_that) {
case NoPenalty() when none != null:
return none();case SkipDraws() when skipDraws != null:
return skipDraws(_that.draws);case _:
  return null;

}
}

}

/// @nodoc


class NoPenalty implements ClaimPenaltyPolicy {
  const NoPenalty();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is NoPenalty);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ClaimPenaltyPolicy.none()';
}


}




/// @nodoc


class SkipDraws implements ClaimPenaltyPolicy {
  const SkipDraws({required this.draws});
  

 final  int draws;

/// Create a copy of ClaimPenaltyPolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SkipDrawsCopyWith<SkipDraws> get copyWith => _$SkipDrawsCopyWithImpl<SkipDraws>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SkipDraws&&(identical(other.draws, draws) || other.draws == draws));
}


@override
int get hashCode {
    return Object.hash(runtimeType,draws);
}

@override
String toString() {
    return 'ClaimPenaltyPolicy.skipDraws(draws: $draws)';
}


}

/// @nodoc
abstract mixin class $SkipDrawsCopyWith<$Res> implements $ClaimPenaltyPolicyCopyWith<$Res> {
  factory $SkipDrawsCopyWith(SkipDraws value, $Res Function(SkipDraws) _then) = _$SkipDrawsCopyWithImpl;
@useResult
$Res call({
 int draws
});




}
/// @nodoc
class _$SkipDrawsCopyWithImpl<$Res>
    implements $SkipDrawsCopyWith<$Res> {
  _$SkipDrawsCopyWithImpl(this._self, this._then);

  final SkipDraws _self;
  final $Res Function(SkipDraws) _then;

/// Create a copy of ClaimPenaltyPolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? draws = null,}) {
  return _then(SkipDraws(
draws: null == draws ? _self.draws : draws // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$GameSettings {

 bool get hostPlays; bool get showFailsOnStream; TieBreakRule get tieBreak;/// Tie-break of the underdog prize. Null (old games) = same as [tieBreak].
 TieBreakRule? get underdogTieBreak; ClaimPenaltyPolicy get claimPenalty; OverLimitRule get overLimit;
/// Create a copy of GameSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameSettingsCopyWith<GameSettings> get copyWith => _$GameSettingsCopyWithImpl<GameSettings>(this as GameSettings, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as GameSettings;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GameSettings&&(identical(other.hostPlays, _this.hostPlays) || other.hostPlays == _this.hostPlays)&&(identical(other.showFailsOnStream, _this.showFailsOnStream) || other.showFailsOnStream == _this.showFailsOnStream)&&(identical(other.tieBreak, _this.tieBreak) || other.tieBreak == _this.tieBreak)&&(identical(other.underdogTieBreak, _this.underdogTieBreak) || other.underdogTieBreak == _this.underdogTieBreak)&&(identical(other.claimPenalty, _this.claimPenalty) || other.claimPenalty == _this.claimPenalty)&&(identical(other.overLimit, _this.overLimit) || other.overLimit == _this.overLimit));
}


@override
int get hashCode {
  final _this = this as GameSettings;
  return Object.hash(runtimeType,_this.hostPlays,_this.showFailsOnStream,_this.tieBreak,_this.underdogTieBreak,_this.claimPenalty,_this.overLimit);
}

@override
String toString() {
  final _this = this as GameSettings;
  return 'GameSettings(hostPlays: ${_this.hostPlays}, showFailsOnStream: ${_this.showFailsOnStream}, tieBreak: ${_this.tieBreak}, underdogTieBreak: ${_this.underdogTieBreak}, claimPenalty: ${_this.claimPenalty}, overLimit: ${_this.overLimit})';
}


}

/// @nodoc
abstract mixin class $GameSettingsCopyWith<$Res>  {
  factory $GameSettingsCopyWith(GameSettings value, $Res Function(GameSettings) _then) = _$GameSettingsCopyWithImpl;
@useResult
$Res call({
 bool hostPlays, bool showFailsOnStream, TieBreakRule tieBreak, TieBreakRule? underdogTieBreak, ClaimPenaltyPolicy claimPenalty, OverLimitRule overLimit
});


$ClaimPenaltyPolicyCopyWith<$Res> get claimPenalty;

}
/// @nodoc
class _$GameSettingsCopyWithImpl<$Res>
    implements $GameSettingsCopyWith<$Res> {
  _$GameSettingsCopyWithImpl(this._self, this._then);

  final GameSettings _self;
  final $Res Function(GameSettings) _then;

/// Create a copy of GameSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hostPlays = null,Object? showFailsOnStream = null,Object? tieBreak = null,Object? underdogTieBreak = freezed,Object? claimPenalty = null,Object? overLimit = null,}) {
  return _then(GameSettings(
hostPlays: null == hostPlays ? _self.hostPlays : hostPlays // ignore: cast_nullable_to_non_nullable
as bool,showFailsOnStream: null == showFailsOnStream ? _self.showFailsOnStream : showFailsOnStream // ignore: cast_nullable_to_non_nullable
as bool,tieBreak: null == tieBreak ? _self.tieBreak : tieBreak // ignore: cast_nullable_to_non_nullable
as TieBreakRule,underdogTieBreak: freezed == underdogTieBreak ? _self.underdogTieBreak : underdogTieBreak // ignore: cast_nullable_to_non_nullable
as TieBreakRule?,claimPenalty: null == claimPenalty ? _self.claimPenalty : claimPenalty // ignore: cast_nullable_to_non_nullable
as ClaimPenaltyPolicy,overLimit: null == overLimit ? _self.overLimit : overLimit // ignore: cast_nullable_to_non_nullable
as OverLimitRule,
  ));
}
/// Create a copy of GameSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClaimPenaltyPolicyCopyWith<$Res> get claimPenalty {
  
  return $ClaimPenaltyPolicyCopyWith<$Res>(_self.claimPenalty, (value) {
    return _then(_self.copyWith(claimPenalty: value));
  });
}
}


/// Adds pattern-matching-related methods to [GameSettings].
extension GameSettingsPatterns on GameSettings {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GameSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GameSettings() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GameSettings value)  $default,){
final _that = this;
switch (_that) {
case _GameSettings():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GameSettings value)?  $default,){
final _that = this;
switch (_that) {
case _GameSettings() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool hostPlays,  bool showFailsOnStream,  TieBreakRule tieBreak,  TieBreakRule? underdogTieBreak,  ClaimPenaltyPolicy claimPenalty,  OverLimitRule overLimit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GameSettings() when $default != null:
return $default(_that.hostPlays,_that.showFailsOnStream,_that.tieBreak,_that.underdogTieBreak,_that.claimPenalty,_that.overLimit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool hostPlays,  bool showFailsOnStream,  TieBreakRule tieBreak,  TieBreakRule? underdogTieBreak,  ClaimPenaltyPolicy claimPenalty,  OverLimitRule overLimit)  $default,) {final _that = this;
switch (_that) {
case _GameSettings():
return $default(_that.hostPlays,_that.showFailsOnStream,_that.tieBreak,_that.underdogTieBreak,_that.claimPenalty,_that.overLimit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool hostPlays,  bool showFailsOnStream,  TieBreakRule tieBreak,  TieBreakRule? underdogTieBreak,  ClaimPenaltyPolicy claimPenalty,  OverLimitRule overLimit)?  $default,) {final _that = this;
switch (_that) {
case _GameSettings() when $default != null:
return $default(_that.hostPlays,_that.showFailsOnStream,_that.tieBreak,_that.underdogTieBreak,_that.claimPenalty,_that.overLimit);case _:
  return null;

}
}

}

/// @nodoc


class _GameSettings implements GameSettings {
  const _GameSettings({this.hostPlays = true, this.showFailsOnStream = true, this.tieBreak = TieBreakRule.draw, this.underdogTieBreak, this.claimPenalty = const ClaimPenaltyPolicy.none(), this.overLimit = OverLimitRule.backToGame});
  

@override@JsonKey() final  bool hostPlays;
@override@JsonKey() final  bool showFailsOnStream;
@override@JsonKey() final  TieBreakRule tieBreak;
/// Tie-break of the underdog prize. Null (old games) = same as [tieBreak].
@override final  TieBreakRule? underdogTieBreak;
@override@JsonKey() final  ClaimPenaltyPolicy claimPenalty;
@override@JsonKey() final  OverLimitRule overLimit;

/// Create a copy of GameSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameSettingsCopyWith<_GameSettings> get copyWith => __$GameSettingsCopyWithImpl<_GameSettings>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _GameSettings&&(identical(other.hostPlays, hostPlays) || other.hostPlays == hostPlays)&&(identical(other.showFailsOnStream, showFailsOnStream) || other.showFailsOnStream == showFailsOnStream)&&(identical(other.tieBreak, tieBreak) || other.tieBreak == tieBreak)&&(identical(other.underdogTieBreak, underdogTieBreak) || other.underdogTieBreak == underdogTieBreak)&&(identical(other.claimPenalty, claimPenalty) || other.claimPenalty == claimPenalty)&&(identical(other.overLimit, overLimit) || other.overLimit == overLimit));
}


@override
int get hashCode {
    return Object.hash(runtimeType,hostPlays,showFailsOnStream,tieBreak,underdogTieBreak,claimPenalty,overLimit);
}

@override
String toString() {
    return 'GameSettings(hostPlays: $hostPlays, showFailsOnStream: $showFailsOnStream, tieBreak: $tieBreak, underdogTieBreak: $underdogTieBreak, claimPenalty: $claimPenalty, overLimit: $overLimit)';
}


}

/// @nodoc
abstract mixin class _$GameSettingsCopyWith<$Res> implements $GameSettingsCopyWith<$Res> {
  factory _$GameSettingsCopyWith(_GameSettings value, $Res Function(_GameSettings) _then) = __$GameSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool hostPlays, bool showFailsOnStream, TieBreakRule tieBreak, TieBreakRule? underdogTieBreak, ClaimPenaltyPolicy claimPenalty, OverLimitRule overLimit
});


@override $ClaimPenaltyPolicyCopyWith<$Res> get claimPenalty;

}
/// @nodoc
class __$GameSettingsCopyWithImpl<$Res>
    implements _$GameSettingsCopyWith<$Res> {
  __$GameSettingsCopyWithImpl(this._self, this._then);

  final _GameSettings _self;
  final $Res Function(_GameSettings) _then;

/// Create a copy of GameSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hostPlays = null,Object? showFailsOnStream = null,Object? tieBreak = null,Object? underdogTieBreak = freezed,Object? claimPenalty = null,Object? overLimit = null,}) {
  return _then(_GameSettings(
hostPlays: null == hostPlays ? _self.hostPlays : hostPlays // ignore: cast_nullable_to_non_nullable
as bool,showFailsOnStream: null == showFailsOnStream ? _self.showFailsOnStream : showFailsOnStream // ignore: cast_nullable_to_non_nullable
as bool,tieBreak: null == tieBreak ? _self.tieBreak : tieBreak // ignore: cast_nullable_to_non_nullable
as TieBreakRule,underdogTieBreak: freezed == underdogTieBreak ? _self.underdogTieBreak : underdogTieBreak // ignore: cast_nullable_to_non_nullable
as TieBreakRule?,claimPenalty: null == claimPenalty ? _self.claimPenalty : claimPenalty // ignore: cast_nullable_to_non_nullable
as ClaimPenaltyPolicy,overLimit: null == overLimit ? _self.overLimit : overLimit // ignore: cast_nullable_to_non_nullable
as OverLimitRule,
  ));
}

/// Create a copy of GameSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClaimPenaltyPolicyCopyWith<$Res> get claimPenalty {
  
  return $ClaimPenaltyPolicyCopyWith<$Res>(_self.claimPenalty, (value) {
    return _then(_self.copyWith(claimPenalty: value));
  });
}
}

/// @nodoc
mixin _$Winner {

 PrizeId get prizeId; UserId get uid; int get drawIndex; bool get tieBreak;
/// Create a copy of Winner
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WinnerCopyWith<Winner> get copyWith => _$WinnerCopyWithImpl<Winner>(this as Winner, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Winner;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Winner&&(identical(other.prizeId, _this.prizeId) || other.prizeId == _this.prizeId)&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.drawIndex, _this.drawIndex) || other.drawIndex == _this.drawIndex)&&(identical(other.tieBreak, _this.tieBreak) || other.tieBreak == _this.tieBreak));
}


@override
int get hashCode {
  final _this = this as Winner;
  return Object.hash(runtimeType,_this.prizeId,_this.uid,_this.drawIndex,_this.tieBreak);
}

@override
String toString() {
  final _this = this as Winner;
  return 'Winner(prizeId: ${_this.prizeId}, uid: ${_this.uid}, drawIndex: ${_this.drawIndex}, tieBreak: ${_this.tieBreak})';
}


}

/// @nodoc
abstract mixin class $WinnerCopyWith<$Res>  {
  factory $WinnerCopyWith(Winner value, $Res Function(Winner) _then) = _$WinnerCopyWithImpl;
@useResult
$Res call({
 PrizeId prizeId, UserId uid, int drawIndex, bool tieBreak
});




}
/// @nodoc
class _$WinnerCopyWithImpl<$Res>
    implements $WinnerCopyWith<$Res> {
  _$WinnerCopyWithImpl(this._self, this._then);

  final Winner _self;
  final $Res Function(Winner) _then;

/// Create a copy of Winner
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? prizeId = null,Object? uid = null,Object? drawIndex = null,Object? tieBreak = null,}) {
  return _then(Winner(
prizeId: null == prizeId ? _self.prizeId : prizeId // ignore: cast_nullable_to_non_nullable
as PrizeId,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,drawIndex: null == drawIndex ? _self.drawIndex : drawIndex // ignore: cast_nullable_to_non_nullable
as int,tieBreak: null == tieBreak ? _self.tieBreak : tieBreak // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Winner].
extension WinnerPatterns on Winner {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Winner value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Winner() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Winner value)  $default,){
final _that = this;
switch (_that) {
case _Winner():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Winner value)?  $default,){
final _that = this;
switch (_that) {
case _Winner() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PrizeId prizeId,  UserId uid,  int drawIndex,  bool tieBreak)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Winner() when $default != null:
return $default(_that.prizeId,_that.uid,_that.drawIndex,_that.tieBreak);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PrizeId prizeId,  UserId uid,  int drawIndex,  bool tieBreak)  $default,) {final _that = this;
switch (_that) {
case _Winner():
return $default(_that.prizeId,_that.uid,_that.drawIndex,_that.tieBreak);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PrizeId prizeId,  UserId uid,  int drawIndex,  bool tieBreak)?  $default,) {final _that = this;
switch (_that) {
case _Winner() when $default != null:
return $default(_that.prizeId,_that.uid,_that.drawIndex,_that.tieBreak);case _:
  return null;

}
}

}

/// @nodoc


class _Winner implements Winner {
  const _Winner({required this.prizeId, required this.uid, required this.drawIndex, this.tieBreak = false});
  

@override final  PrizeId prizeId;
@override final  UserId uid;
@override final  int drawIndex;
@override@JsonKey() final  bool tieBreak;

/// Create a copy of Winner
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WinnerCopyWith<_Winner> get copyWith => __$WinnerCopyWithImpl<_Winner>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Winner&&(identical(other.prizeId, prizeId) || other.prizeId == prizeId)&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.drawIndex, drawIndex) || other.drawIndex == drawIndex)&&(identical(other.tieBreak, tieBreak) || other.tieBreak == tieBreak));
}


@override
int get hashCode {
    return Object.hash(runtimeType,prizeId,uid,drawIndex,tieBreak);
}

@override
String toString() {
    return 'Winner(prizeId: $prizeId, uid: $uid, drawIndex: $drawIndex, tieBreak: $tieBreak)';
}


}

/// @nodoc
abstract mixin class _$WinnerCopyWith<$Res> implements $WinnerCopyWith<$Res> {
  factory _$WinnerCopyWith(_Winner value, $Res Function(_Winner) _then) = __$WinnerCopyWithImpl;
@override @useResult
$Res call({
 PrizeId prizeId, UserId uid, int drawIndex, bool tieBreak
});




}
/// @nodoc
class __$WinnerCopyWithImpl<$Res>
    implements _$WinnerCopyWith<$Res> {
  __$WinnerCopyWithImpl(this._self, this._then);

  final _Winner _self;
  final $Res Function(_Winner) _then;

/// Create a copy of Winner
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? prizeId = null,Object? uid = null,Object? drawIndex = null,Object? tieBreak = null,}) {
  return _then(_Winner(
prizeId: null == prizeId ? _self.prizeId : prizeId // ignore: cast_nullable_to_non_nullable
as PrizeId,uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,drawIndex: null == drawIndex ? _self.drawIndex : drawIndex // ignore: cast_nullable_to_non_nullable
as int,tieBreak: null == tieBreak ? _self.tieBreak : tieBreak // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$Game {

 GameId get id; RoomCode get roomCode; UserId get hostUid; String get eventName; GameStatus get status; AccessPolicy get access; CardTemplate get template; List<Prize> get prizes; List<Prize> get endOfGamePrizes; PrizePolicy get prizePolicy; GameSettings get settings;/// Public, created when the game opens (hex).
 String get salt;/// sha256(drawSeed) published at creation (hex).
 String get drawCommit;/// sha256 of the ordered list of cards, published at start (hex).
 String? get cardsHash;/// Revealed only when finished/abandoned (hex).
 String? get drawSeed; int get playerCount; int get maxPlayers; int get currentPrizeIndex; List<ItemId> get draws; List<Winner> get winners; DateTime get createdAt; DateTime? get startedAt; DateTime? get endedAt;/// Last host/player action (draw, claim, confirmation). Drives the
/// automatic end after [idleLimit] without activity.
 DateTime? get lastActivityAt;/// Draw in progress or just decided (see [Raffle]).
 Raffle? get raffle;
/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GameCopyWith<Game> get copyWith => _$GameCopyWithImpl<Game>(this as Game, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Game;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Game&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.roomCode, _this.roomCode) || other.roomCode == _this.roomCode)&&(identical(other.hostUid, _this.hostUid) || other.hostUid == _this.hostUid)&&(identical(other.eventName, _this.eventName) || other.eventName == _this.eventName)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.access, _this.access) || other.access == _this.access)&&(identical(other.template, _this.template) || other.template == _this.template)&&const DeepCollectionEquality().equals(other.prizes, _this.prizes)&&const DeepCollectionEquality().equals(other.endOfGamePrizes, _this.endOfGamePrizes)&&(identical(other.prizePolicy, _this.prizePolicy) || other.prizePolicy == _this.prizePolicy)&&(identical(other.settings, _this.settings) || other.settings == _this.settings)&&(identical(other.salt, _this.salt) || other.salt == _this.salt)&&(identical(other.drawCommit, _this.drawCommit) || other.drawCommit == _this.drawCommit)&&(identical(other.cardsHash, _this.cardsHash) || other.cardsHash == _this.cardsHash)&&(identical(other.drawSeed, _this.drawSeed) || other.drawSeed == _this.drawSeed)&&(identical(other.playerCount, _this.playerCount) || other.playerCount == _this.playerCount)&&(identical(other.maxPlayers, _this.maxPlayers) || other.maxPlayers == _this.maxPlayers)&&(identical(other.currentPrizeIndex, _this.currentPrizeIndex) || other.currentPrizeIndex == _this.currentPrizeIndex)&&const DeepCollectionEquality().equals(other.draws, _this.draws)&&const DeepCollectionEquality().equals(other.winners, _this.winners)&&(identical(other.createdAt, _this.createdAt) || other.createdAt == _this.createdAt)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&(identical(other.lastActivityAt, _this.lastActivityAt) || other.lastActivityAt == _this.lastActivityAt)&&(identical(other.raffle, _this.raffle) || other.raffle == _this.raffle));
}


@override
int get hashCode {
  final _this = this as Game;
  return Object.hashAll([runtimeType,_this.id,_this.roomCode,_this.hostUid,_this.eventName,_this.status,_this.access,_this.template,const DeepCollectionEquality().hash(_this.prizes),const DeepCollectionEquality().hash(_this.endOfGamePrizes),_this.prizePolicy,_this.settings,_this.salt,_this.drawCommit,_this.cardsHash,_this.drawSeed,_this.playerCount,_this.maxPlayers,_this.currentPrizeIndex,const DeepCollectionEquality().hash(_this.draws),const DeepCollectionEquality().hash(_this.winners),_this.createdAt,_this.startedAt,_this.endedAt,_this.lastActivityAt,_this.raffle]);
}

@override
String toString() {
  final _this = this as Game;
  return 'Game(id: ${_this.id}, roomCode: ${_this.roomCode}, hostUid: ${_this.hostUid}, eventName: ${_this.eventName}, status: ${_this.status}, access: ${_this.access}, template: ${_this.template}, prizes: ${_this.prizes}, endOfGamePrizes: ${_this.endOfGamePrizes}, prizePolicy: ${_this.prizePolicy}, settings: ${_this.settings}, salt: ${_this.salt}, drawCommit: ${_this.drawCommit}, cardsHash: ${_this.cardsHash}, drawSeed: ${_this.drawSeed}, playerCount: ${_this.playerCount}, maxPlayers: ${_this.maxPlayers}, currentPrizeIndex: ${_this.currentPrizeIndex}, draws: ${_this.draws}, winners: ${_this.winners}, createdAt: ${_this.createdAt}, startedAt: ${_this.startedAt}, endedAt: ${_this.endedAt}, lastActivityAt: ${_this.lastActivityAt}, raffle: ${_this.raffle})';
}


}

/// @nodoc
abstract mixin class $GameCopyWith<$Res>  {
  factory $GameCopyWith(Game value, $Res Function(Game) _then) = _$GameCopyWithImpl;
@useResult
$Res call({
 GameId id, RoomCode roomCode, UserId hostUid, String eventName, GameStatus status, AccessPolicy access, CardTemplate template, List<Prize> prizes, List<Prize> endOfGamePrizes, PrizePolicy prizePolicy, GameSettings settings, String salt, String drawCommit, String? cardsHash, String? drawSeed, int playerCount, int maxPlayers, int currentPrizeIndex, List<ItemId> draws, List<Winner> winners, DateTime createdAt, DateTime? startedAt, DateTime? endedAt, DateTime? lastActivityAt, Raffle? raffle
});


$AccessPolicyCopyWith<$Res> get access;$CardTemplateCopyWith<$Res> get template;$PrizePolicyCopyWith<$Res> get prizePolicy;$GameSettingsCopyWith<$Res> get settings;$RaffleCopyWith<$Res>? get raffle;

}
/// @nodoc
class _$GameCopyWithImpl<$Res>
    implements $GameCopyWith<$Res> {
  _$GameCopyWithImpl(this._self, this._then);

  final Game _self;
  final $Res Function(Game) _then;

/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? roomCode = null,Object? hostUid = null,Object? eventName = null,Object? status = null,Object? access = null,Object? template = null,Object? prizes = null,Object? endOfGamePrizes = null,Object? prizePolicy = null,Object? settings = null,Object? salt = null,Object? drawCommit = null,Object? cardsHash = freezed,Object? drawSeed = freezed,Object? playerCount = null,Object? maxPlayers = null,Object? currentPrizeIndex = null,Object? draws = null,Object? winners = null,Object? createdAt = null,Object? startedAt = freezed,Object? endedAt = freezed,Object? lastActivityAt = freezed,Object? raffle = freezed,}) {
  return _then(Game(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GameId,roomCode: null == roomCode ? _self.roomCode : roomCode // ignore: cast_nullable_to_non_nullable
as RoomCode,hostUid: null == hostUid ? _self.hostUid : hostUid // ignore: cast_nullable_to_non_nullable
as UserId,eventName: null == eventName ? _self.eventName : eventName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GameStatus,access: null == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as AccessPolicy,template: null == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as CardTemplate,prizes: null == prizes ? _self.prizes : prizes // ignore: cast_nullable_to_non_nullable
as List<Prize>,endOfGamePrizes: null == endOfGamePrizes ? _self.endOfGamePrizes : endOfGamePrizes // ignore: cast_nullable_to_non_nullable
as List<Prize>,prizePolicy: null == prizePolicy ? _self.prizePolicy : prizePolicy // ignore: cast_nullable_to_non_nullable
as PrizePolicy,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as GameSettings,salt: null == salt ? _self.salt : salt // ignore: cast_nullable_to_non_nullable
as String,drawCommit: null == drawCommit ? _self.drawCommit : drawCommit // ignore: cast_nullable_to_non_nullable
as String,cardsHash: freezed == cardsHash ? _self.cardsHash : cardsHash // ignore: cast_nullable_to_non_nullable
as String?,drawSeed: freezed == drawSeed ? _self.drawSeed : drawSeed // ignore: cast_nullable_to_non_nullable
as String?,playerCount: null == playerCount ? _self.playerCount : playerCount // ignore: cast_nullable_to_non_nullable
as int,maxPlayers: null == maxPlayers ? _self.maxPlayers : maxPlayers // ignore: cast_nullable_to_non_nullable
as int,currentPrizeIndex: null == currentPrizeIndex ? _self.currentPrizeIndex : currentPrizeIndex // ignore: cast_nullable_to_non_nullable
as int,draws: null == draws ? _self.draws : draws // ignore: cast_nullable_to_non_nullable
as List<ItemId>,winners: null == winners ? _self.winners : winners // ignore: cast_nullable_to_non_nullable
as List<Winner>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActivityAt: freezed == lastActivityAt ? _self.lastActivityAt : lastActivityAt // ignore: cast_nullable_to_non_nullable
as DateTime?,raffle: freezed == raffle ? _self.raffle : raffle // ignore: cast_nullable_to_non_nullable
as Raffle?,
  ));
}
/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccessPolicyCopyWith<$Res> get access {
  
  return $AccessPolicyCopyWith<$Res>(_self.access, (value) {
    return _then(_self.copyWith(access: value));
  });
}/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardTemplateCopyWith<$Res> get template {
  
  return $CardTemplateCopyWith<$Res>(_self.template, (value) {
    return _then(_self.copyWith(template: value));
  });
}/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrizePolicyCopyWith<$Res> get prizePolicy {
  
  return $PrizePolicyCopyWith<$Res>(_self.prizePolicy, (value) {
    return _then(_self.copyWith(prizePolicy: value));
  });
}/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameSettingsCopyWith<$Res> get settings {
  
  return $GameSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RaffleCopyWith<$Res>? get raffle {
    if (_self.raffle == null) {
    return null;
  }

  return $RaffleCopyWith<$Res>(_self.raffle!, (value) {
    return _then(_self.copyWith(raffle: value));
  });
}
}


/// Adds pattern-matching-related methods to [Game].
extension GamePatterns on Game {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Game value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Game() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Game value)  $default,){
final _that = this;
switch (_that) {
case _Game():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Game value)?  $default,){
final _that = this;
switch (_that) {
case _Game() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( GameId id,  RoomCode roomCode,  UserId hostUid,  String eventName,  GameStatus status,  AccessPolicy access,  CardTemplate template,  List<Prize> prizes,  List<Prize> endOfGamePrizes,  PrizePolicy prizePolicy,  GameSettings settings,  String salt,  String drawCommit,  String? cardsHash,  String? drawSeed,  int playerCount,  int maxPlayers,  int currentPrizeIndex,  List<ItemId> draws,  List<Winner> winners,  DateTime createdAt,  DateTime? startedAt,  DateTime? endedAt,  DateTime? lastActivityAt,  Raffle? raffle)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Game() when $default != null:
return $default(_that.id,_that.roomCode,_that.hostUid,_that.eventName,_that.status,_that.access,_that.template,_that.prizes,_that.endOfGamePrizes,_that.prizePolicy,_that.settings,_that.salt,_that.drawCommit,_that.cardsHash,_that.drawSeed,_that.playerCount,_that.maxPlayers,_that.currentPrizeIndex,_that.draws,_that.winners,_that.createdAt,_that.startedAt,_that.endedAt,_that.lastActivityAt,_that.raffle);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( GameId id,  RoomCode roomCode,  UserId hostUid,  String eventName,  GameStatus status,  AccessPolicy access,  CardTemplate template,  List<Prize> prizes,  List<Prize> endOfGamePrizes,  PrizePolicy prizePolicy,  GameSettings settings,  String salt,  String drawCommit,  String? cardsHash,  String? drawSeed,  int playerCount,  int maxPlayers,  int currentPrizeIndex,  List<ItemId> draws,  List<Winner> winners,  DateTime createdAt,  DateTime? startedAt,  DateTime? endedAt,  DateTime? lastActivityAt,  Raffle? raffle)  $default,) {final _that = this;
switch (_that) {
case _Game():
return $default(_that.id,_that.roomCode,_that.hostUid,_that.eventName,_that.status,_that.access,_that.template,_that.prizes,_that.endOfGamePrizes,_that.prizePolicy,_that.settings,_that.salt,_that.drawCommit,_that.cardsHash,_that.drawSeed,_that.playerCount,_that.maxPlayers,_that.currentPrizeIndex,_that.draws,_that.winners,_that.createdAt,_that.startedAt,_that.endedAt,_that.lastActivityAt,_that.raffle);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( GameId id,  RoomCode roomCode,  UserId hostUid,  String eventName,  GameStatus status,  AccessPolicy access,  CardTemplate template,  List<Prize> prizes,  List<Prize> endOfGamePrizes,  PrizePolicy prizePolicy,  GameSettings settings,  String salt,  String drawCommit,  String? cardsHash,  String? drawSeed,  int playerCount,  int maxPlayers,  int currentPrizeIndex,  List<ItemId> draws,  List<Winner> winners,  DateTime createdAt,  DateTime? startedAt,  DateTime? endedAt,  DateTime? lastActivityAt,  Raffle? raffle)?  $default,) {final _that = this;
switch (_that) {
case _Game() when $default != null:
return $default(_that.id,_that.roomCode,_that.hostUid,_that.eventName,_that.status,_that.access,_that.template,_that.prizes,_that.endOfGamePrizes,_that.prizePolicy,_that.settings,_that.salt,_that.drawCommit,_that.cardsHash,_that.drawSeed,_that.playerCount,_that.maxPlayers,_that.currentPrizeIndex,_that.draws,_that.winners,_that.createdAt,_that.startedAt,_that.endedAt,_that.lastActivityAt,_that.raffle);case _:
  return null;

}
}

}

/// @nodoc


class _Game extends Game {
  const _Game({required this.id, required this.roomCode, required this.hostUid, required this.eventName, this.status = GameStatus.lobby, required this.access, required this.template, required  List<Prize> prizes,  List<Prize> endOfGamePrizes = const <Prize>[], this.prizePolicy = const PrizePolicy(), this.settings = const GameSettings(), required this.salt, required this.drawCommit, this.cardsHash, this.drawSeed, this.playerCount = 0, this.maxPlayers = 60, this.currentPrizeIndex = 0,  List<ItemId> draws = const <ItemId>[],  List<Winner> winners = const <Winner>[], required this.createdAt, this.startedAt, this.endedAt, this.lastActivityAt, this.raffle}): _prizes = prizes,_endOfGamePrizes = endOfGamePrizes,_draws = draws,_winners = winners,super._();
  

@override final  GameId id;
@override final  RoomCode roomCode;
@override final  UserId hostUid;
@override final  String eventName;
@override@JsonKey() final  GameStatus status;
@override final  AccessPolicy access;
@override final  CardTemplate template;
 final  List<Prize> _prizes;
@override List<Prize> get prizes {
  if (_prizes is EqualUnmodifiableListView) return _prizes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_prizes);
}

 final  List<Prize> _endOfGamePrizes;
@override@JsonKey() List<Prize> get endOfGamePrizes {
  if (_endOfGamePrizes is EqualUnmodifiableListView) return _endOfGamePrizes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_endOfGamePrizes);
}

@override@JsonKey() final  PrizePolicy prizePolicy;
@override@JsonKey() final  GameSettings settings;
/// Public, created when the game opens (hex).
@override final  String salt;
/// sha256(drawSeed) published at creation (hex).
@override final  String drawCommit;
/// sha256 of the ordered list of cards, published at start (hex).
@override final  String? cardsHash;
/// Revealed only when finished/abandoned (hex).
@override final  String? drawSeed;
@override@JsonKey() final  int playerCount;
@override@JsonKey() final  int maxPlayers;
@override@JsonKey() final  int currentPrizeIndex;
 final  List<ItemId> _draws;
@override@JsonKey() List<ItemId> get draws {
  if (_draws is EqualUnmodifiableListView) return _draws;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_draws);
}

 final  List<Winner> _winners;
@override@JsonKey() List<Winner> get winners {
  if (_winners is EqualUnmodifiableListView) return _winners;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_winners);
}

@override final  DateTime createdAt;
@override final  DateTime? startedAt;
@override final  DateTime? endedAt;
/// Last host/player action (draw, claim, confirmation). Drives the
/// automatic end after [idleLimit] without activity.
@override final  DateTime? lastActivityAt;
/// Draw in progress or just decided (see [Raffle]).
@override final  Raffle? raffle;

/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GameCopyWith<_Game> get copyWith => __$GameCopyWithImpl<_Game>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Game&&(identical(other.id, id) || other.id == id)&&(identical(other.roomCode, roomCode) || other.roomCode == roomCode)&&(identical(other.hostUid, hostUid) || other.hostUid == hostUid)&&(identical(other.eventName, eventName) || other.eventName == eventName)&&(identical(other.status, status) || other.status == status)&&(identical(other.access, access) || other.access == access)&&(identical(other.template, template) || other.template == template)&&const DeepCollectionEquality().equals(other.prizes, _prizes)&&const DeepCollectionEquality().equals(other.endOfGamePrizes, _endOfGamePrizes)&&(identical(other.prizePolicy, prizePolicy) || other.prizePolicy == prizePolicy)&&(identical(other.settings, settings) || other.settings == settings)&&(identical(other.salt, salt) || other.salt == salt)&&(identical(other.drawCommit, drawCommit) || other.drawCommit == drawCommit)&&(identical(other.cardsHash, cardsHash) || other.cardsHash == cardsHash)&&(identical(other.drawSeed, drawSeed) || other.drawSeed == drawSeed)&&(identical(other.playerCount, playerCount) || other.playerCount == playerCount)&&(identical(other.maxPlayers, maxPlayers) || other.maxPlayers == maxPlayers)&&(identical(other.currentPrizeIndex, currentPrizeIndex) || other.currentPrizeIndex == currentPrizeIndex)&&const DeepCollectionEquality().equals(other.draws, _draws)&&const DeepCollectionEquality().equals(other.winners, _winners)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.lastActivityAt, lastActivityAt) || other.lastActivityAt == lastActivityAt)&&(identical(other.raffle, raffle) || other.raffle == raffle));
}


@override
int get hashCode {
    return Object.hashAll([runtimeType,id,roomCode,hostUid,eventName,status,access,template,const DeepCollectionEquality().hash(_prizes),const DeepCollectionEquality().hash(_endOfGamePrizes),prizePolicy,settings,salt,drawCommit,cardsHash,drawSeed,playerCount,maxPlayers,currentPrizeIndex,const DeepCollectionEquality().hash(_draws),const DeepCollectionEquality().hash(_winners),createdAt,startedAt,endedAt,lastActivityAt,raffle]);
}

@override
String toString() {
    return 'Game(id: $id, roomCode: $roomCode, hostUid: $hostUid, eventName: $eventName, status: $status, access: $access, template: $template, prizes: $prizes, endOfGamePrizes: $endOfGamePrizes, prizePolicy: $prizePolicy, settings: $settings, salt: $salt, drawCommit: $drawCommit, cardsHash: $cardsHash, drawSeed: $drawSeed, playerCount: $playerCount, maxPlayers: $maxPlayers, currentPrizeIndex: $currentPrizeIndex, draws: $draws, winners: $winners, createdAt: $createdAt, startedAt: $startedAt, endedAt: $endedAt, lastActivityAt: $lastActivityAt, raffle: $raffle)';
}


}

/// @nodoc
abstract mixin class _$GameCopyWith<$Res> implements $GameCopyWith<$Res> {
  factory _$GameCopyWith(_Game value, $Res Function(_Game) _then) = __$GameCopyWithImpl;
@override @useResult
$Res call({
 GameId id, RoomCode roomCode, UserId hostUid, String eventName, GameStatus status, AccessPolicy access, CardTemplate template, List<Prize> prizes, List<Prize> endOfGamePrizes, PrizePolicy prizePolicy, GameSettings settings, String salt, String drawCommit, String? cardsHash, String? drawSeed, int playerCount, int maxPlayers, int currentPrizeIndex, List<ItemId> draws, List<Winner> winners, DateTime createdAt, DateTime? startedAt, DateTime? endedAt, DateTime? lastActivityAt, Raffle? raffle
});


@override $AccessPolicyCopyWith<$Res> get access;@override $CardTemplateCopyWith<$Res> get template;@override $PrizePolicyCopyWith<$Res> get prizePolicy;@override $GameSettingsCopyWith<$Res> get settings;@override $RaffleCopyWith<$Res>? get raffle;

}
/// @nodoc
class __$GameCopyWithImpl<$Res>
    implements _$GameCopyWith<$Res> {
  __$GameCopyWithImpl(this._self, this._then);

  final _Game _self;
  final $Res Function(_Game) _then;

/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? roomCode = null,Object? hostUid = null,Object? eventName = null,Object? status = null,Object? access = null,Object? template = null,Object? prizes = null,Object? endOfGamePrizes = null,Object? prizePolicy = null,Object? settings = null,Object? salt = null,Object? drawCommit = null,Object? cardsHash = freezed,Object? drawSeed = freezed,Object? playerCount = null,Object? maxPlayers = null,Object? currentPrizeIndex = null,Object? draws = null,Object? winners = null,Object? createdAt = null,Object? startedAt = freezed,Object? endedAt = freezed,Object? lastActivityAt = freezed,Object? raffle = freezed,}) {
  return _then(_Game(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as GameId,roomCode: null == roomCode ? _self.roomCode : roomCode // ignore: cast_nullable_to_non_nullable
as RoomCode,hostUid: null == hostUid ? _self.hostUid : hostUid // ignore: cast_nullable_to_non_nullable
as UserId,eventName: null == eventName ? _self.eventName : eventName // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as GameStatus,access: null == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as AccessPolicy,template: null == template ? _self.template : template // ignore: cast_nullable_to_non_nullable
as CardTemplate,prizes: null == prizes ? _self._prizes : prizes // ignore: cast_nullable_to_non_nullable
as List<Prize>,endOfGamePrizes: null == endOfGamePrizes ? _self._endOfGamePrizes : endOfGamePrizes // ignore: cast_nullable_to_non_nullable
as List<Prize>,prizePolicy: null == prizePolicy ? _self.prizePolicy : prizePolicy // ignore: cast_nullable_to_non_nullable
as PrizePolicy,settings: null == settings ? _self.settings : settings // ignore: cast_nullable_to_non_nullable
as GameSettings,salt: null == salt ? _self.salt : salt // ignore: cast_nullable_to_non_nullable
as String,drawCommit: null == drawCommit ? _self.drawCommit : drawCommit // ignore: cast_nullable_to_non_nullable
as String,cardsHash: freezed == cardsHash ? _self.cardsHash : cardsHash // ignore: cast_nullable_to_non_nullable
as String?,drawSeed: freezed == drawSeed ? _self.drawSeed : drawSeed // ignore: cast_nullable_to_non_nullable
as String?,playerCount: null == playerCount ? _self.playerCount : playerCount // ignore: cast_nullable_to_non_nullable
as int,maxPlayers: null == maxPlayers ? _self.maxPlayers : maxPlayers // ignore: cast_nullable_to_non_nullable
as int,currentPrizeIndex: null == currentPrizeIndex ? _self.currentPrizeIndex : currentPrizeIndex // ignore: cast_nullable_to_non_nullable
as int,draws: null == draws ? _self._draws : draws // ignore: cast_nullable_to_non_nullable
as List<ItemId>,winners: null == winners ? _self._winners : winners // ignore: cast_nullable_to_non_nullable
as List<Winner>,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,startedAt: freezed == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastActivityAt: freezed == lastActivityAt ? _self.lastActivityAt : lastActivityAt // ignore: cast_nullable_to_non_nullable
as DateTime?,raffle: freezed == raffle ? _self.raffle : raffle // ignore: cast_nullable_to_non_nullable
as Raffle?,
  ));
}

/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AccessPolicyCopyWith<$Res> get access {
  
  return $AccessPolicyCopyWith<$Res>(_self.access, (value) {
    return _then(_self.copyWith(access: value));
  });
}/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CardTemplateCopyWith<$Res> get template {
  
  return $CardTemplateCopyWith<$Res>(_self.template, (value) {
    return _then(_self.copyWith(template: value));
  });
}/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PrizePolicyCopyWith<$Res> get prizePolicy {
  
  return $PrizePolicyCopyWith<$Res>(_self.prizePolicy, (value) {
    return _then(_self.copyWith(prizePolicy: value));
  });
}/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GameSettingsCopyWith<$Res> get settings {
  
  return $GameSettingsCopyWith<$Res>(_self.settings, (value) {
    return _then(_self.copyWith(settings: value));
  });
}/// Create a copy of Game
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RaffleCopyWith<$Res>? get raffle {
    if (_self.raffle == null) {
    return null;
  }

  return $RaffleCopyWith<$Res>(_self.raffle!, (value) {
    return _then(_self.copyWith(raffle: value));
  });
}
}

// dart format on
