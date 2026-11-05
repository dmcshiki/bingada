// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bingo_card.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BingoCard {

 UserId get owner; List<ItemId?> get cells; int get algoVersion;
/// Create a copy of BingoCard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BingoCardCopyWith<BingoCard> get copyWith => _$BingoCardCopyWithImpl<BingoCard>(this as BingoCard, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as BingoCard;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BingoCard&&(identical(other.owner, _this.owner) || other.owner == _this.owner)&&const DeepCollectionEquality().equals(other.cells, _this.cells)&&(identical(other.algoVersion, _this.algoVersion) || other.algoVersion == _this.algoVersion));
}


@override
int get hashCode {
  final _this = this as BingoCard;
  return Object.hash(runtimeType,_this.owner,const DeepCollectionEquality().hash(_this.cells),_this.algoVersion);
}

@override
String toString() {
  final _this = this as BingoCard;
  return 'BingoCard(owner: ${_this.owner}, cells: ${_this.cells}, algoVersion: ${_this.algoVersion})';
}


}

/// @nodoc
abstract mixin class $BingoCardCopyWith<$Res>  {
  factory $BingoCardCopyWith(BingoCard value, $Res Function(BingoCard) _then) = _$BingoCardCopyWithImpl;
@useResult
$Res call({
 UserId owner, List<ItemId?> cells, int algoVersion
});




}
/// @nodoc
class _$BingoCardCopyWithImpl<$Res>
    implements $BingoCardCopyWith<$Res> {
  _$BingoCardCopyWithImpl(this._self, this._then);

  final BingoCard _self;
  final $Res Function(BingoCard) _then;

/// Create a copy of BingoCard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? owner = null,Object? cells = null,Object? algoVersion = null,}) {
  return _then(BingoCard(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as UserId,cells: null == cells ? _self.cells : cells // ignore: cast_nullable_to_non_nullable
as List<ItemId?>,algoVersion: null == algoVersion ? _self.algoVersion : algoVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [BingoCard].
extension BingoCardPatterns on BingoCard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BingoCard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BingoCard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BingoCard value)  $default,){
final _that = this;
switch (_that) {
case _BingoCard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BingoCard value)?  $default,){
final _that = this;
switch (_that) {
case _BingoCard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserId owner,  List<ItemId?> cells,  int algoVersion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BingoCard() when $default != null:
return $default(_that.owner,_that.cells,_that.algoVersion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserId owner,  List<ItemId?> cells,  int algoVersion)  $default,) {final _that = this;
switch (_that) {
case _BingoCard():
return $default(_that.owner,_that.cells,_that.algoVersion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserId owner,  List<ItemId?> cells,  int algoVersion)?  $default,) {final _that = this;
switch (_that) {
case _BingoCard() when $default != null:
return $default(_that.owner,_that.cells,_that.algoVersion);case _:
  return null;

}
}

}

/// @nodoc


class _BingoCard implements BingoCard {
  const _BingoCard({required this.owner, required  List<ItemId?> cells, this.algoVersion = 2}): _cells = cells;
  

@override final  UserId owner;
 final  List<ItemId?> _cells;
@override List<ItemId?> get cells {
  if (_cells is EqualUnmodifiableListView) return _cells;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cells);
}

@override@JsonKey() final  int algoVersion;

/// Create a copy of BingoCard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BingoCardCopyWith<_BingoCard> get copyWith => __$BingoCardCopyWithImpl<_BingoCard>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BingoCard&&(identical(other.owner, owner) || other.owner == owner)&&const DeepCollectionEquality().equals(other.cells, _cells)&&(identical(other.algoVersion, algoVersion) || other.algoVersion == algoVersion));
}


@override
int get hashCode {
    return Object.hash(runtimeType,owner,const DeepCollectionEquality().hash(_cells),algoVersion);
}

@override
String toString() {
    return 'BingoCard(owner: $owner, cells: $cells, algoVersion: $algoVersion)';
}


}

/// @nodoc
abstract mixin class _$BingoCardCopyWith<$Res> implements $BingoCardCopyWith<$Res> {
  factory _$BingoCardCopyWith(_BingoCard value, $Res Function(_BingoCard) _then) = __$BingoCardCopyWithImpl;
@override @useResult
$Res call({
 UserId owner, List<ItemId?> cells, int algoVersion
});




}
/// @nodoc
class __$BingoCardCopyWithImpl<$Res>
    implements _$BingoCardCopyWith<$Res> {
  __$BingoCardCopyWithImpl(this._self, this._then);

  final _BingoCard _self;
  final $Res Function(_BingoCard) _then;

/// Create a copy of BingoCard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? owner = null,Object? cells = null,Object? algoVersion = null,}) {
  return _then(_BingoCard(
owner: null == owner ? _self.owner : owner // ignore: cast_nullable_to_non_nullable
as UserId,cells: null == cells ? _self._cells : cells // ignore: cast_nullable_to_non_nullable
as List<ItemId?>,algoVersion: null == algoVersion ? _self.algoVersion : algoVersion // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$Player {

 UserId get uid; String get displayName; String? get photoUrl; DateTime get joinedAt;
/// Create a copy of Player
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlayerCopyWith<Player> get copyWith => _$PlayerCopyWithImpl<Player>(this as Player, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Player;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Player&&(identical(other.uid, _this.uid) || other.uid == _this.uid)&&(identical(other.displayName, _this.displayName) || other.displayName == _this.displayName)&&(identical(other.photoUrl, _this.photoUrl) || other.photoUrl == _this.photoUrl)&&(identical(other.joinedAt, _this.joinedAt) || other.joinedAt == _this.joinedAt));
}


@override
int get hashCode {
  final _this = this as Player;
  return Object.hash(runtimeType,_this.uid,_this.displayName,_this.photoUrl,_this.joinedAt);
}

@override
String toString() {
  final _this = this as Player;
  return 'Player(uid: ${_this.uid}, displayName: ${_this.displayName}, photoUrl: ${_this.photoUrl}, joinedAt: ${_this.joinedAt})';
}


}

/// @nodoc
abstract mixin class $PlayerCopyWith<$Res>  {
  factory $PlayerCopyWith(Player value, $Res Function(Player) _then) = _$PlayerCopyWithImpl;
@useResult
$Res call({
 UserId uid, String displayName, String? photoUrl, DateTime joinedAt
});




}
/// @nodoc
class _$PlayerCopyWithImpl<$Res>
    implements $PlayerCopyWith<$Res> {
  _$PlayerCopyWithImpl(this._self, this._then);

  final Player _self;
  final $Res Function(Player) _then;

/// Create a copy of Player
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? uid = null,Object? displayName = null,Object? photoUrl = freezed,Object? joinedAt = null,}) {
  return _then(Player(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [Player].
extension PlayerPatterns on Player {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Player value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Player() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Player value)  $default,){
final _that = this;
switch (_that) {
case _Player():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Player value)?  $default,){
final _that = this;
switch (_that) {
case _Player() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( UserId uid,  String displayName,  String? photoUrl,  DateTime joinedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Player() when $default != null:
return $default(_that.uid,_that.displayName,_that.photoUrl,_that.joinedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( UserId uid,  String displayName,  String? photoUrl,  DateTime joinedAt)  $default,) {final _that = this;
switch (_that) {
case _Player():
return $default(_that.uid,_that.displayName,_that.photoUrl,_that.joinedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( UserId uid,  String displayName,  String? photoUrl,  DateTime joinedAt)?  $default,) {final _that = this;
switch (_that) {
case _Player() when $default != null:
return $default(_that.uid,_that.displayName,_that.photoUrl,_that.joinedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Player implements Player {
  const _Player({required this.uid, required this.displayName, this.photoUrl, required this.joinedAt});
  

@override final  UserId uid;
@override final  String displayName;
@override final  String? photoUrl;
@override final  DateTime joinedAt;

/// Create a copy of Player
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlayerCopyWith<_Player> get copyWith => __$PlayerCopyWithImpl<_Player>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Player&&(identical(other.uid, uid) || other.uid == uid)&&(identical(other.displayName, displayName) || other.displayName == displayName)&&(identical(other.photoUrl, photoUrl) || other.photoUrl == photoUrl)&&(identical(other.joinedAt, joinedAt) || other.joinedAt == joinedAt));
}


@override
int get hashCode {
    return Object.hash(runtimeType,uid,displayName,photoUrl,joinedAt);
}

@override
String toString() {
    return 'Player(uid: $uid, displayName: $displayName, photoUrl: $photoUrl, joinedAt: $joinedAt)';
}


}

/// @nodoc
abstract mixin class _$PlayerCopyWith<$Res> implements $PlayerCopyWith<$Res> {
  factory _$PlayerCopyWith(_Player value, $Res Function(_Player) _then) = __$PlayerCopyWithImpl;
@override @useResult
$Res call({
 UserId uid, String displayName, String? photoUrl, DateTime joinedAt
});




}
/// @nodoc
class __$PlayerCopyWithImpl<$Res>
    implements _$PlayerCopyWith<$Res> {
  __$PlayerCopyWithImpl(this._self, this._then);

  final _Player _self;
  final $Res Function(_Player) _then;

/// Create a copy of Player
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? uid = null,Object? displayName = null,Object? photoUrl = freezed,Object? joinedAt = null,}) {
  return _then(_Player(
uid: null == uid ? _self.uid : uid // ignore: cast_nullable_to_non_nullable
as UserId,displayName: null == displayName ? _self.displayName : displayName // ignore: cast_nullable_to_non_nullable
as String,photoUrl: freezed == photoUrl ? _self.photoUrl : photoUrl // ignore: cast_nullable_to_non_nullable
as String?,joinedAt: null == joinedAt ? _self.joinedAt : joinedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
