// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prize.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PatternMatch {

 PatternKind get kind; int get index;
/// Create a copy of PatternMatch
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PatternMatchCopyWith<PatternMatch> get copyWith => _$PatternMatchCopyWithImpl<PatternMatch>(this as PatternMatch, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PatternMatch;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PatternMatch&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.index, _this.index) || other.index == _this.index));
}


@override
int get hashCode {
  final _this = this as PatternMatch;
  return Object.hash(runtimeType,_this.kind,_this.index);
}

@override
String toString() {
  final _this = this as PatternMatch;
  return 'PatternMatch(kind: ${_this.kind}, index: ${_this.index})';
}


}

/// @nodoc
abstract mixin class $PatternMatchCopyWith<$Res>  {
  factory $PatternMatchCopyWith(PatternMatch value, $Res Function(PatternMatch) _then) = _$PatternMatchCopyWithImpl;
@useResult
$Res call({
 PatternKind kind, int index
});




}
/// @nodoc
class _$PatternMatchCopyWithImpl<$Res>
    implements $PatternMatchCopyWith<$Res> {
  _$PatternMatchCopyWithImpl(this._self, this._then);

  final PatternMatch _self;
  final $Res Function(PatternMatch) _then;

/// Create a copy of PatternMatch
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? index = null,}) {
  return _then(PatternMatch(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PatternKind,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PatternMatch].
extension PatternMatchPatterns on PatternMatch {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PatternMatch value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PatternMatch() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PatternMatch value)  $default,){
final _that = this;
switch (_that) {
case _PatternMatch():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PatternMatch value)?  $default,){
final _that = this;
switch (_that) {
case _PatternMatch() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PatternKind kind,  int index)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PatternMatch() when $default != null:
return $default(_that.kind,_that.index);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PatternKind kind,  int index)  $default,) {final _that = this;
switch (_that) {
case _PatternMatch():
return $default(_that.kind,_that.index);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PatternKind kind,  int index)?  $default,) {final _that = this;
switch (_that) {
case _PatternMatch() when $default != null:
return $default(_that.kind,_that.index);case _:
  return null;

}
}

}

/// @nodoc


class _PatternMatch implements PatternMatch {
  const _PatternMatch({required this.kind, this.index = 0});
  

@override final  PatternKind kind;
@override@JsonKey() final  int index;

/// Create a copy of PatternMatch
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PatternMatchCopyWith<_PatternMatch> get copyWith => __$PatternMatchCopyWithImpl<_PatternMatch>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PatternMatch&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.index, index) || other.index == index));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,index);
}

@override
String toString() {
    return 'PatternMatch(kind: $kind, index: $index)';
}


}

/// @nodoc
abstract mixin class _$PatternMatchCopyWith<$Res> implements $PatternMatchCopyWith<$Res> {
  factory _$PatternMatchCopyWith(_PatternMatch value, $Res Function(_PatternMatch) _then) = __$PatternMatchCopyWithImpl;
@override @useResult
$Res call({
 PatternKind kind, int index
});




}
/// @nodoc
class __$PatternMatchCopyWithImpl<$Res>
    implements _$PatternMatchCopyWith<$Res> {
  __$PatternMatchCopyWithImpl(this._self, this._then);

  final _PatternMatch _self;
  final $Res Function(_PatternMatch) _then;

/// Create a copy of PatternMatch
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? index = null,}) {
  return _then(_PatternMatch(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PatternKind,index: null == index ? _self.index : index // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$Prize {

 PrizeId get id; String get label; PatternKind get pattern; int get winners;/// Sequential order (1-based). `null` for end-of-game prizes (underdog).
 int? get order;/// Row-major mask for [PatternKind.custom].
 List<bool>? get customMask; String? get customName;
/// Create a copy of Prize
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrizeCopyWith<Prize> get copyWith => _$PrizeCopyWithImpl<Prize>(this as Prize, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Prize;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Prize&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.pattern, _this.pattern) || other.pattern == _this.pattern)&&(identical(other.winners, _this.winners) || other.winners == _this.winners)&&(identical(other.order, _this.order) || other.order == _this.order)&&const DeepCollectionEquality().equals(other.customMask, _this.customMask)&&(identical(other.customName, _this.customName) || other.customName == _this.customName));
}


@override
int get hashCode {
  final _this = this as Prize;
  return Object.hash(runtimeType,_this.id,_this.label,_this.pattern,_this.winners,_this.order,const DeepCollectionEquality().hash(_this.customMask),_this.customName);
}

@override
String toString() {
  final _this = this as Prize;
  return 'Prize(id: ${_this.id}, label: ${_this.label}, pattern: ${_this.pattern}, winners: ${_this.winners}, order: ${_this.order}, customMask: ${_this.customMask}, customName: ${_this.customName})';
}


}

/// @nodoc
abstract mixin class $PrizeCopyWith<$Res>  {
  factory $PrizeCopyWith(Prize value, $Res Function(Prize) _then) = _$PrizeCopyWithImpl;
@useResult
$Res call({
 PrizeId id, String label, PatternKind pattern, int winners, int? order, List<bool>? customMask, String? customName
});




}
/// @nodoc
class _$PrizeCopyWithImpl<$Res>
    implements $PrizeCopyWith<$Res> {
  _$PrizeCopyWithImpl(this._self, this._then);

  final Prize _self;
  final $Res Function(Prize) _then;

/// Create a copy of Prize
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? label = null,Object? pattern = null,Object? winners = null,Object? order = freezed,Object? customMask = freezed,Object? customName = freezed,}) {
  return _then(Prize(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PrizeId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as PatternKind,winners: null == winners ? _self.winners : winners // ignore: cast_nullable_to_non_nullable
as int,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int?,customMask: freezed == customMask ? _self.customMask : customMask // ignore: cast_nullable_to_non_nullable
as List<bool>?,customName: freezed == customName ? _self.customName : customName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Prize].
extension PrizePatterns on Prize {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Prize value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Prize() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Prize value)  $default,){
final _that = this;
switch (_that) {
case _Prize():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Prize value)?  $default,){
final _that = this;
switch (_that) {
case _Prize() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PrizeId id,  String label,  PatternKind pattern,  int winners,  int? order,  List<bool>? customMask,  String? customName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Prize() when $default != null:
return $default(_that.id,_that.label,_that.pattern,_that.winners,_that.order,_that.customMask,_that.customName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PrizeId id,  String label,  PatternKind pattern,  int winners,  int? order,  List<bool>? customMask,  String? customName)  $default,) {final _that = this;
switch (_that) {
case _Prize():
return $default(_that.id,_that.label,_that.pattern,_that.winners,_that.order,_that.customMask,_that.customName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PrizeId id,  String label,  PatternKind pattern,  int winners,  int? order,  List<bool>? customMask,  String? customName)?  $default,) {final _that = this;
switch (_that) {
case _Prize() when $default != null:
return $default(_that.id,_that.label,_that.pattern,_that.winners,_that.order,_that.customMask,_that.customName);case _:
  return null;

}
}

}

/// @nodoc


class _Prize implements Prize {
  const _Prize({required this.id, required this.label, required this.pattern, this.winners = 1, this.order,  List<bool>? customMask, this.customName}): _customMask = customMask;
  

@override final  PrizeId id;
@override final  String label;
@override final  PatternKind pattern;
@override@JsonKey() final  int winners;
/// Sequential order (1-based). `null` for end-of-game prizes (underdog).
@override final  int? order;
/// Row-major mask for [PatternKind.custom].
 final  List<bool>? _customMask;
/// Row-major mask for [PatternKind.custom].
@override List<bool>? get customMask {
  final value = _customMask;
  if (value == null) return null;
  if (_customMask is EqualUnmodifiableListView) return _customMask;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  String? customName;

/// Create a copy of Prize
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrizeCopyWith<_Prize> get copyWith => __$PrizeCopyWithImpl<_Prize>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Prize&&(identical(other.id, id) || other.id == id)&&(identical(other.label, label) || other.label == label)&&(identical(other.pattern, pattern) || other.pattern == pattern)&&(identical(other.winners, winners) || other.winners == winners)&&(identical(other.order, order) || other.order == order)&&const DeepCollectionEquality().equals(other.customMask, _customMask)&&(identical(other.customName, customName) || other.customName == customName));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,label,pattern,winners,order,const DeepCollectionEquality().hash(_customMask),customName);
}

@override
String toString() {
    return 'Prize(id: $id, label: $label, pattern: $pattern, winners: $winners, order: $order, customMask: $customMask, customName: $customName)';
}


}

/// @nodoc
abstract mixin class _$PrizeCopyWith<$Res> implements $PrizeCopyWith<$Res> {
  factory _$PrizeCopyWith(_Prize value, $Res Function(_Prize) _then) = __$PrizeCopyWithImpl;
@override @useResult
$Res call({
 PrizeId id, String label, PatternKind pattern, int winners, int? order, List<bool>? customMask, String? customName
});




}
/// @nodoc
class __$PrizeCopyWithImpl<$Res>
    implements _$PrizeCopyWith<$Res> {
  __$PrizeCopyWithImpl(this._self, this._then);

  final _Prize _self;
  final $Res Function(_Prize) _then;

/// Create a copy of Prize
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? label = null,Object? pattern = null,Object? winners = null,Object? order = freezed,Object? customMask = freezed,Object? customName = freezed,}) {
  return _then(_Prize(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as PrizeId,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,pattern: null == pattern ? _self.pattern : pattern // ignore: cast_nullable_to_non_nullable
as PatternKind,winners: null == winners ? _self.winners : winners // ignore: cast_nullable_to_non_nullable
as int,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int?,customMask: freezed == customMask ? _self._customMask : customMask // ignore: cast_nullable_to_non_nullable
as List<bool>?,customName: freezed == customName ? _self.customName : customName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PrizePolicy {

/// `null` = unlimited.
 int? get maxPerPlayer;/// winner of key → may compete for these prizes.
 Map<PrizeId, List<PrizeId>> get allow;
/// Create a copy of PrizePolicy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PrizePolicyCopyWith<PrizePolicy> get copyWith => _$PrizePolicyCopyWithImpl<PrizePolicy>(this as PrizePolicy, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PrizePolicy;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PrizePolicy&&(identical(other.maxPerPlayer, _this.maxPerPlayer) || other.maxPerPlayer == _this.maxPerPlayer)&&const DeepCollectionEquality().equals(other.allow, _this.allow));
}


@override
int get hashCode {
  final _this = this as PrizePolicy;
  return Object.hash(runtimeType,_this.maxPerPlayer,const DeepCollectionEquality().hash(_this.allow));
}

@override
String toString() {
  final _this = this as PrizePolicy;
  return 'PrizePolicy(maxPerPlayer: ${_this.maxPerPlayer}, allow: ${_this.allow})';
}


}

/// @nodoc
abstract mixin class $PrizePolicyCopyWith<$Res>  {
  factory $PrizePolicyCopyWith(PrizePolicy value, $Res Function(PrizePolicy) _then) = _$PrizePolicyCopyWithImpl;
@useResult
$Res call({
 int? maxPerPlayer, Map<PrizeId, List<PrizeId>> allow
});




}
/// @nodoc
class _$PrizePolicyCopyWithImpl<$Res>
    implements $PrizePolicyCopyWith<$Res> {
  _$PrizePolicyCopyWithImpl(this._self, this._then);

  final PrizePolicy _self;
  final $Res Function(PrizePolicy) _then;

/// Create a copy of PrizePolicy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? maxPerPlayer = freezed,Object? allow = null,}) {
  return _then(PrizePolicy(
maxPerPlayer: freezed == maxPerPlayer ? _self.maxPerPlayer : maxPerPlayer // ignore: cast_nullable_to_non_nullable
as int?,allow: null == allow ? _self.allow : allow // ignore: cast_nullable_to_non_nullable
as Map<PrizeId, List<PrizeId>>,
  ));
}

}


/// Adds pattern-matching-related methods to [PrizePolicy].
extension PrizePolicyPatterns on PrizePolicy {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PrizePolicy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PrizePolicy() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PrizePolicy value)  $default,){
final _that = this;
switch (_that) {
case _PrizePolicy():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PrizePolicy value)?  $default,){
final _that = this;
switch (_that) {
case _PrizePolicy() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int? maxPerPlayer,  Map<PrizeId, List<PrizeId>> allow)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PrizePolicy() when $default != null:
return $default(_that.maxPerPlayer,_that.allow);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int? maxPerPlayer,  Map<PrizeId, List<PrizeId>> allow)  $default,) {final _that = this;
switch (_that) {
case _PrizePolicy():
return $default(_that.maxPerPlayer,_that.allow);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int? maxPerPlayer,  Map<PrizeId, List<PrizeId>> allow)?  $default,) {final _that = this;
switch (_that) {
case _PrizePolicy() when $default != null:
return $default(_that.maxPerPlayer,_that.allow);case _:
  return null;

}
}

}

/// @nodoc


class _PrizePolicy implements PrizePolicy {
  const _PrizePolicy({this.maxPerPlayer = 1,  Map<PrizeId, List<PrizeId>> allow = const <PrizeId, List<PrizeId>>{}}): _allow = allow;
  

/// `null` = unlimited.
@override@JsonKey() final  int? maxPerPlayer;
/// winner of key → may compete for these prizes.
 final  Map<PrizeId, List<PrizeId>> _allow;
/// winner of key → may compete for these prizes.
@override@JsonKey() Map<PrizeId, List<PrizeId>> get allow {
  if (_allow is EqualUnmodifiableMapView) return _allow;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_allow);
}


/// Create a copy of PrizePolicy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PrizePolicyCopyWith<_PrizePolicy> get copyWith => __$PrizePolicyCopyWithImpl<_PrizePolicy>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PrizePolicy&&(identical(other.maxPerPlayer, maxPerPlayer) || other.maxPerPlayer == maxPerPlayer)&&const DeepCollectionEquality().equals(other.allow, _allow));
}


@override
int get hashCode {
    return Object.hash(runtimeType,maxPerPlayer,const DeepCollectionEquality().hash(_allow));
}

@override
String toString() {
    return 'PrizePolicy(maxPerPlayer: $maxPerPlayer, allow: $allow)';
}


}

/// @nodoc
abstract mixin class _$PrizePolicyCopyWith<$Res> implements $PrizePolicyCopyWith<$Res> {
  factory _$PrizePolicyCopyWith(_PrizePolicy value, $Res Function(_PrizePolicy) _then) = __$PrizePolicyCopyWithImpl;
@override @useResult
$Res call({
 int? maxPerPlayer, Map<PrizeId, List<PrizeId>> allow
});




}
/// @nodoc
class __$PrizePolicyCopyWithImpl<$Res>
    implements _$PrizePolicyCopyWith<$Res> {
  __$PrizePolicyCopyWithImpl(this._self, this._then);

  final _PrizePolicy _self;
  final $Res Function(_PrizePolicy) _then;

/// Create a copy of PrizePolicy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? maxPerPlayer = freezed,Object? allow = null,}) {
  return _then(_PrizePolicy(
maxPerPlayer: freezed == maxPerPlayer ? _self.maxPerPlayer : maxPerPlayer // ignore: cast_nullable_to_non_nullable
as int?,allow: null == allow ? _self._allow : allow // ignore: cast_nullable_to_non_nullable
as Map<PrizeId, List<PrizeId>>,
  ));
}


}

// dart format on
