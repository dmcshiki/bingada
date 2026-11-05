// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'card_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ColumnSource {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ColumnSource);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'ColumnSource()';
}


}

/// @nodoc
class $ColumnSourceCopyWith<$Res>  {
$ColumnSourceCopyWith(ColumnSource _, $Res Function(ColumnSource) __);
}


/// Adds pattern-matching-related methods to [ColumnSource].
extension ColumnSourcePatterns on ColumnSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( RangeSource value)?  range,TResult Function( ItemsSource value)?  items,required TResult orElse(),}){
final _that = this;
switch (_that) {
case RangeSource() when range != null:
return range(_that);case ItemsSource() when items != null:
return items(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( RangeSource value)  range,required TResult Function( ItemsSource value)  items,}){
final _that = this;
switch (_that) {
case RangeSource():
return range(_that);case ItemsSource():
return items(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( RangeSource value)?  range,TResult? Function( ItemsSource value)?  items,}){
final _that = this;
switch (_that) {
case RangeSource() when range != null:
return range(_that);case ItemsSource() when items != null:
return items(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( int from,  int to)?  range,TResult Function( List<String> items)?  items,required TResult orElse(),}) {final _that = this;
switch (_that) {
case RangeSource() when range != null:
return range(_that.from,_that.to);case ItemsSource() when items != null:
return items(_that.items);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( int from,  int to)  range,required TResult Function( List<String> items)  items,}) {final _that = this;
switch (_that) {
case RangeSource():
return range(_that.from,_that.to);case ItemsSource():
return items(_that.items);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( int from,  int to)?  range,TResult? Function( List<String> items)?  items,}) {final _that = this;
switch (_that) {
case RangeSource() when range != null:
return range(_that.from,_that.to);case ItemsSource() when items != null:
return items(_that.items);case _:
  return null;

}
}

}

/// @nodoc


class RangeSource implements ColumnSource {
  const RangeSource({required this.from, required this.to});
  

 final  int from;
 final  int to;

/// Create a copy of ColumnSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RangeSourceCopyWith<RangeSource> get copyWith => _$RangeSourceCopyWithImpl<RangeSource>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is RangeSource&&(identical(other.from, from) || other.from == from)&&(identical(other.to, to) || other.to == to));
}


@override
int get hashCode {
    return Object.hash(runtimeType,from,to);
}

@override
String toString() {
    return 'ColumnSource.range(from: $from, to: $to)';
}


}

/// @nodoc
abstract mixin class $RangeSourceCopyWith<$Res> implements $ColumnSourceCopyWith<$Res> {
  factory $RangeSourceCopyWith(RangeSource value, $Res Function(RangeSource) _then) = _$RangeSourceCopyWithImpl;
@useResult
$Res call({
 int from, int to
});




}
/// @nodoc
class _$RangeSourceCopyWithImpl<$Res>
    implements $RangeSourceCopyWith<$Res> {
  _$RangeSourceCopyWithImpl(this._self, this._then);

  final RangeSource _self;
  final $Res Function(RangeSource) _then;

/// Create a copy of ColumnSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? from = null,Object? to = null,}) {
  return _then(RangeSource(
from: null == from ? _self.from : from // ignore: cast_nullable_to_non_nullable
as int,to: null == to ? _self.to : to // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class ItemsSource implements ColumnSource {
  const ItemsSource({required  List<String> items}): _items = items;
  

 final  List<String> _items;
 List<String> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}


/// Create a copy of ColumnSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ItemsSourceCopyWith<ItemsSource> get copyWith => _$ItemsSourceCopyWithImpl<ItemsSource>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ItemsSource&&const DeepCollectionEquality().equals(other.items, _items));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items));
}

@override
String toString() {
    return 'ColumnSource.items(items: $items)';
}


}

/// @nodoc
abstract mixin class $ItemsSourceCopyWith<$Res> implements $ColumnSourceCopyWith<$Res> {
  factory $ItemsSourceCopyWith(ItemsSource value, $Res Function(ItemsSource) _then) = _$ItemsSourceCopyWithImpl;
@useResult
$Res call({
 List<String> items
});




}
/// @nodoc
class _$ItemsSourceCopyWithImpl<$Res>
    implements $ItemsSourceCopyWith<$Res> {
  _$ItemsSourceCopyWithImpl(this._self, this._then);

  final ItemsSource _self;
  final $Res Function(ItemsSource) _then;

/// Create a copy of ColumnSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,}) {
  return _then(ItemsSource(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

/// @nodoc
mixin _$FreeCell {

 bool get enabled; String get label; String? get imageUrl;
/// Create a copy of FreeCell
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FreeCellCopyWith<FreeCell> get copyWith => _$FreeCellCopyWithImpl<FreeCell>(this as FreeCell, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FreeCell;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FreeCell&&(identical(other.enabled, _this.enabled) || other.enabled == _this.enabled)&&(identical(other.label, _this.label) || other.label == _this.label)&&(identical(other.imageUrl, _this.imageUrl) || other.imageUrl == _this.imageUrl));
}


@override
int get hashCode {
  final _this = this as FreeCell;
  return Object.hash(runtimeType,_this.enabled,_this.label,_this.imageUrl);
}

@override
String toString() {
  final _this = this as FreeCell;
  return 'FreeCell(enabled: ${_this.enabled}, label: ${_this.label}, imageUrl: ${_this.imageUrl})';
}


}

/// @nodoc
abstract mixin class $FreeCellCopyWith<$Res>  {
  factory $FreeCellCopyWith(FreeCell value, $Res Function(FreeCell) _then) = _$FreeCellCopyWithImpl;
@useResult
$Res call({
 bool enabled, String label, String? imageUrl
});




}
/// @nodoc
class _$FreeCellCopyWithImpl<$Res>
    implements $FreeCellCopyWith<$Res> {
  _$FreeCellCopyWithImpl(this._self, this._then);

  final FreeCell _self;
  final $Res Function(FreeCell) _then;

/// Create a copy of FreeCell
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? label = null,Object? imageUrl = freezed,}) {
  return _then(FreeCell(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [FreeCell].
extension FreeCellPatterns on FreeCell {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FreeCell value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FreeCell() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FreeCell value)  $default,){
final _that = this;
switch (_that) {
case _FreeCell():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FreeCell value)?  $default,){
final _that = this;
switch (_that) {
case _FreeCell() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  String label,  String? imageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FreeCell() when $default != null:
return $default(_that.enabled,_that.label,_that.imageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  String label,  String? imageUrl)  $default,) {final _that = this;
switch (_that) {
case _FreeCell():
return $default(_that.enabled,_that.label,_that.imageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  String label,  String? imageUrl)?  $default,) {final _that = this;
switch (_that) {
case _FreeCell() when $default != null:
return $default(_that.enabled,_that.label,_that.imageUrl);case _:
  return null;

}
}

}

/// @nodoc


class _FreeCell implements FreeCell {
  const _FreeCell({this.enabled = true, this.label = '★', this.imageUrl});
  

@override@JsonKey() final  bool enabled;
@override@JsonKey() final  String label;
@override final  String? imageUrl;

/// Create a copy of FreeCell
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FreeCellCopyWith<_FreeCell> get copyWith => __$FreeCellCopyWithImpl<_FreeCell>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FreeCell&&(identical(other.enabled, enabled) || other.enabled == enabled)&&(identical(other.label, label) || other.label == label)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,enabled,label,imageUrl);
}

@override
String toString() {
    return 'FreeCell(enabled: $enabled, label: $label, imageUrl: $imageUrl)';
}


}

/// @nodoc
abstract mixin class _$FreeCellCopyWith<$Res> implements $FreeCellCopyWith<$Res> {
  factory _$FreeCellCopyWith(_FreeCell value, $Res Function(_FreeCell) _then) = __$FreeCellCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, String label, String? imageUrl
});




}
/// @nodoc
class __$FreeCellCopyWithImpl<$Res>
    implements _$FreeCellCopyWith<$Res> {
  __$FreeCellCopyWithImpl(this._self, this._then);

  final _FreeCell _self;
  final $Res Function(_FreeCell) _then;

/// Create a copy of FreeCell
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? label = null,Object? imageUrl = freezed,}) {
  return _then(_FreeCell(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$PoolItem {

 ItemId get id; int get column; String get label;
/// Create a copy of PoolItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PoolItemCopyWith<PoolItem> get copyWith => _$PoolItemCopyWithImpl<PoolItem>(this as PoolItem, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PoolItem;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PoolItem&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.column, _this.column) || other.column == _this.column)&&(identical(other.label, _this.label) || other.label == _this.label));
}


@override
int get hashCode {
  final _this = this as PoolItem;
  return Object.hash(runtimeType,_this.id,_this.column,_this.label);
}

@override
String toString() {
  final _this = this as PoolItem;
  return 'PoolItem(id: ${_this.id}, column: ${_this.column}, label: ${_this.label})';
}


}

/// @nodoc
abstract mixin class $PoolItemCopyWith<$Res>  {
  factory $PoolItemCopyWith(PoolItem value, $Res Function(PoolItem) _then) = _$PoolItemCopyWithImpl;
@useResult
$Res call({
 ItemId id, int column, String label
});




}
/// @nodoc
class _$PoolItemCopyWithImpl<$Res>
    implements $PoolItemCopyWith<$Res> {
  _$PoolItemCopyWithImpl(this._self, this._then);

  final PoolItem _self;
  final $Res Function(PoolItem) _then;

/// Create a copy of PoolItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? column = null,Object? label = null,}) {
  return _then(PoolItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ItemId,column: null == column ? _self.column : column // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [PoolItem].
extension PoolItemPatterns on PoolItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PoolItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PoolItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PoolItem value)  $default,){
final _that = this;
switch (_that) {
case _PoolItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PoolItem value)?  $default,){
final _that = this;
switch (_that) {
case _PoolItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ItemId id,  int column,  String label)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PoolItem() when $default != null:
return $default(_that.id,_that.column,_that.label);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ItemId id,  int column,  String label)  $default,) {final _that = this;
switch (_that) {
case _PoolItem():
return $default(_that.id,_that.column,_that.label);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ItemId id,  int column,  String label)?  $default,) {final _that = this;
switch (_that) {
case _PoolItem() when $default != null:
return $default(_that.id,_that.column,_that.label);case _:
  return null;

}
}

}

/// @nodoc


class _PoolItem implements PoolItem {
  const _PoolItem({required this.id, required this.column, required this.label});
  

@override final  ItemId id;
@override final  int column;
@override final  String label;

/// Create a copy of PoolItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PoolItemCopyWith<_PoolItem> get copyWith => __$PoolItemCopyWithImpl<_PoolItem>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PoolItem&&(identical(other.id, id) || other.id == id)&&(identical(other.column, column) || other.column == column)&&(identical(other.label, label) || other.label == label));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,column,label);
}

@override
String toString() {
    return 'PoolItem(id: $id, column: $column, label: $label)';
}


}

/// @nodoc
abstract mixin class _$PoolItemCopyWith<$Res> implements $PoolItemCopyWith<$Res> {
  factory _$PoolItemCopyWith(_PoolItem value, $Res Function(_PoolItem) _then) = __$PoolItemCopyWithImpl;
@override @useResult
$Res call({
 ItemId id, int column, String label
});




}
/// @nodoc
class __$PoolItemCopyWithImpl<$Res>
    implements _$PoolItemCopyWith<$Res> {
  __$PoolItemCopyWithImpl(this._self, this._then);

  final _PoolItem _self;
  final $Res Function(_PoolItem) _then;

/// Create a copy of PoolItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? column = null,Object? label = null,}) {
  return _then(_PoolItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as ItemId,column: null == column ? _self.column : column // ignore: cast_nullable_to_non_nullable
as int,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$CardTemplate {

 String get name; int get rows; int get cols; List<String> get headers; List<String> get colors; FreeCell get free; List<ColumnSource> get columns;
/// Create a copy of CardTemplate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CardTemplateCopyWith<CardTemplate> get copyWith => _$CardTemplateCopyWithImpl<CardTemplate>(this as CardTemplate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CardTemplate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CardTemplate&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.rows, _this.rows) || other.rows == _this.rows)&&(identical(other.cols, _this.cols) || other.cols == _this.cols)&&const DeepCollectionEquality().equals(other.headers, _this.headers)&&const DeepCollectionEquality().equals(other.colors, _this.colors)&&(identical(other.free, _this.free) || other.free == _this.free)&&const DeepCollectionEquality().equals(other.columns, _this.columns));
}


@override
int get hashCode {
  final _this = this as CardTemplate;
  return Object.hash(runtimeType,_this.name,_this.rows,_this.cols,const DeepCollectionEquality().hash(_this.headers),const DeepCollectionEquality().hash(_this.colors),_this.free,const DeepCollectionEquality().hash(_this.columns));
}

@override
String toString() {
  final _this = this as CardTemplate;
  return 'CardTemplate(name: ${_this.name}, rows: ${_this.rows}, cols: ${_this.cols}, headers: ${_this.headers}, colors: ${_this.colors}, free: ${_this.free}, columns: ${_this.columns})';
}


}

/// @nodoc
abstract mixin class $CardTemplateCopyWith<$Res>  {
  factory $CardTemplateCopyWith(CardTemplate value, $Res Function(CardTemplate) _then) = _$CardTemplateCopyWithImpl;
@useResult
$Res call({
 String name, int rows, int cols, List<String> headers, List<String> colors, FreeCell free, List<ColumnSource> columns
});


$FreeCellCopyWith<$Res> get free;

}
/// @nodoc
class _$CardTemplateCopyWithImpl<$Res>
    implements $CardTemplateCopyWith<$Res> {
  _$CardTemplateCopyWithImpl(this._self, this._then);

  final CardTemplate _self;
  final $Res Function(CardTemplate) _then;

/// Create a copy of CardTemplate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? rows = null,Object? cols = null,Object? headers = null,Object? colors = null,Object? free = null,Object? columns = null,}) {
  return _then(CardTemplate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as int,cols: null == cols ? _self.cols : cols // ignore: cast_nullable_to_non_nullable
as int,headers: null == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as List<String>,colors: null == colors ? _self.colors : colors // ignore: cast_nullable_to_non_nullable
as List<String>,free: null == free ? _self.free : free // ignore: cast_nullable_to_non_nullable
as FreeCell,columns: null == columns ? _self.columns : columns // ignore: cast_nullable_to_non_nullable
as List<ColumnSource>,
  ));
}
/// Create a copy of CardTemplate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FreeCellCopyWith<$Res> get free {
  
  return $FreeCellCopyWith<$Res>(_self.free, (value) {
    return _then(_self.copyWith(free: value));
  });
}
}


/// Adds pattern-matching-related methods to [CardTemplate].
extension CardTemplatePatterns on CardTemplate {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CardTemplate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CardTemplate() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CardTemplate value)  $default,){
final _that = this;
switch (_that) {
case _CardTemplate():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CardTemplate value)?  $default,){
final _that = this;
switch (_that) {
case _CardTemplate() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int rows,  int cols,  List<String> headers,  List<String> colors,  FreeCell free,  List<ColumnSource> columns)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CardTemplate() when $default != null:
return $default(_that.name,_that.rows,_that.cols,_that.headers,_that.colors,_that.free,_that.columns);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int rows,  int cols,  List<String> headers,  List<String> colors,  FreeCell free,  List<ColumnSource> columns)  $default,) {final _that = this;
switch (_that) {
case _CardTemplate():
return $default(_that.name,_that.rows,_that.cols,_that.headers,_that.colors,_that.free,_that.columns);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int rows,  int cols,  List<String> headers,  List<String> colors,  FreeCell free,  List<ColumnSource> columns)?  $default,) {final _that = this;
switch (_that) {
case _CardTemplate() when $default != null:
return $default(_that.name,_that.rows,_that.cols,_that.headers,_that.colors,_that.free,_that.columns);case _:
  return null;

}
}

}

/// @nodoc


class _CardTemplate extends CardTemplate {
  const _CardTemplate({required this.name, this.rows = 5, this.cols = 5, required  List<String> headers, required  List<String> colors, this.free = const FreeCell(), required  List<ColumnSource> columns}): _headers = headers,_colors = colors,_columns = columns,super._();
  

@override final  String name;
@override@JsonKey() final  int rows;
@override@JsonKey() final  int cols;
 final  List<String> _headers;
@override List<String> get headers {
  if (_headers is EqualUnmodifiableListView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_headers);
}

 final  List<String> _colors;
@override List<String> get colors {
  if (_colors is EqualUnmodifiableListView) return _colors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_colors);
}

@override@JsonKey() final  FreeCell free;
 final  List<ColumnSource> _columns;
@override List<ColumnSource> get columns {
  if (_columns is EqualUnmodifiableListView) return _columns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_columns);
}


/// Create a copy of CardTemplate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CardTemplateCopyWith<_CardTemplate> get copyWith => __$CardTemplateCopyWithImpl<_CardTemplate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CardTemplate&&(identical(other.name, name) || other.name == name)&&(identical(other.rows, rows) || other.rows == rows)&&(identical(other.cols, cols) || other.cols == cols)&&const DeepCollectionEquality().equals(other.headers, _headers)&&const DeepCollectionEquality().equals(other.colors, _colors)&&(identical(other.free, free) || other.free == free)&&const DeepCollectionEquality().equals(other.columns, _columns));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,rows,cols,const DeepCollectionEquality().hash(_headers),const DeepCollectionEquality().hash(_colors),free,const DeepCollectionEquality().hash(_columns));
}

@override
String toString() {
    return 'CardTemplate(name: $name, rows: $rows, cols: $cols, headers: $headers, colors: $colors, free: $free, columns: $columns)';
}


}

/// @nodoc
abstract mixin class _$CardTemplateCopyWith<$Res> implements $CardTemplateCopyWith<$Res> {
  factory _$CardTemplateCopyWith(_CardTemplate value, $Res Function(_CardTemplate) _then) = __$CardTemplateCopyWithImpl;
@override @useResult
$Res call({
 String name, int rows, int cols, List<String> headers, List<String> colors, FreeCell free, List<ColumnSource> columns
});


@override $FreeCellCopyWith<$Res> get free;

}
/// @nodoc
class __$CardTemplateCopyWithImpl<$Res>
    implements _$CardTemplateCopyWith<$Res> {
  __$CardTemplateCopyWithImpl(this._self, this._then);

  final _CardTemplate _self;
  final $Res Function(_CardTemplate) _then;

/// Create a copy of CardTemplate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? rows = null,Object? cols = null,Object? headers = null,Object? colors = null,Object? free = null,Object? columns = null,}) {
  return _then(_CardTemplate(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as int,cols: null == cols ? _self.cols : cols // ignore: cast_nullable_to_non_nullable
as int,headers: null == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as List<String>,colors: null == colors ? _self._colors : colors // ignore: cast_nullable_to_non_nullable
as List<String>,free: null == free ? _self.free : free // ignore: cast_nullable_to_non_nullable
as FreeCell,columns: null == columns ? _self._columns : columns // ignore: cast_nullable_to_non_nullable
as List<ColumnSource>,
  ));
}

/// Create a copy of CardTemplate
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FreeCellCopyWith<$Res> get free {
  
  return $FreeCellCopyWith<$Res>(_self.free, (value) {
    return _then(_self.copyWith(free: value));
  });
}
}

// dart format on
