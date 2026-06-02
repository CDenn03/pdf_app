// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LibraryEntry {

 String get id; String get name; String get path; FileStatus get status; DateTime? get lastOpenedAt; String? get collectionId; bool get isFavorite;
/// Create a copy of LibraryEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LibraryEntryCopyWith<LibraryEntry> get copyWith => _$LibraryEntryCopyWithImpl<LibraryEntry>(this as LibraryEntry, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LibraryEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastOpenedAt, lastOpenedAt) || other.lastOpenedAt == lastOpenedAt)&&(identical(other.collectionId, collectionId) || other.collectionId == collectionId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,path,status,lastOpenedAt,collectionId,isFavorite);

@override
String toString() {
  return 'LibraryEntry(id: $id, name: $name, path: $path, status: $status, lastOpenedAt: $lastOpenedAt, collectionId: $collectionId, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class $LibraryEntryCopyWith<$Res>  {
  factory $LibraryEntryCopyWith(LibraryEntry value, $Res Function(LibraryEntry) _then) = _$LibraryEntryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String path, FileStatus status, DateTime? lastOpenedAt, String? collectionId, bool isFavorite
});




}
/// @nodoc
class _$LibraryEntryCopyWithImpl<$Res>
    implements $LibraryEntryCopyWith<$Res> {
  _$LibraryEntryCopyWithImpl(this._self, this._then);

  final LibraryEntry _self;
  final $Res Function(LibraryEntry) _then;

/// Create a copy of LibraryEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? path = null,Object? status = null,Object? lastOpenedAt = freezed,Object? collectionId = freezed,Object? isFavorite = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FileStatus,lastOpenedAt: freezed == lastOpenedAt ? _self.lastOpenedAt : lastOpenedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,collectionId: freezed == collectionId ? _self.collectionId : collectionId // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [LibraryEntry].
extension LibraryEntryPatterns on LibraryEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LibraryEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LibraryEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LibraryEntry value)  $default,){
final _that = this;
switch (_that) {
case _LibraryEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LibraryEntry value)?  $default,){
final _that = this;
switch (_that) {
case _LibraryEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String path,  FileStatus status,  DateTime? lastOpenedAt,  String? collectionId,  bool isFavorite)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LibraryEntry() when $default != null:
return $default(_that.id,_that.name,_that.path,_that.status,_that.lastOpenedAt,_that.collectionId,_that.isFavorite);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String path,  FileStatus status,  DateTime? lastOpenedAt,  String? collectionId,  bool isFavorite)  $default,) {final _that = this;
switch (_that) {
case _LibraryEntry():
return $default(_that.id,_that.name,_that.path,_that.status,_that.lastOpenedAt,_that.collectionId,_that.isFavorite);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String path,  FileStatus status,  DateTime? lastOpenedAt,  String? collectionId,  bool isFavorite)?  $default,) {final _that = this;
switch (_that) {
case _LibraryEntry() when $default != null:
return $default(_that.id,_that.name,_that.path,_that.status,_that.lastOpenedAt,_that.collectionId,_that.isFavorite);case _:
  return null;

}
}

}

/// @nodoc


class _LibraryEntry implements LibraryEntry {
  const _LibraryEntry({required this.id, required this.name, required this.path, required this.status, this.lastOpenedAt, this.collectionId, this.isFavorite = false});
  

@override final  String id;
@override final  String name;
@override final  String path;
@override final  FileStatus status;
@override final  DateTime? lastOpenedAt;
@override final  String? collectionId;
@override@JsonKey() final  bool isFavorite;

/// Create a copy of LibraryEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LibraryEntryCopyWith<_LibraryEntry> get copyWith => __$LibraryEntryCopyWithImpl<_LibraryEntry>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LibraryEntry&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.path, path) || other.path == path)&&(identical(other.status, status) || other.status == status)&&(identical(other.lastOpenedAt, lastOpenedAt) || other.lastOpenedAt == lastOpenedAt)&&(identical(other.collectionId, collectionId) || other.collectionId == collectionId)&&(identical(other.isFavorite, isFavorite) || other.isFavorite == isFavorite));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,path,status,lastOpenedAt,collectionId,isFavorite);

@override
String toString() {
  return 'LibraryEntry(id: $id, name: $name, path: $path, status: $status, lastOpenedAt: $lastOpenedAt, collectionId: $collectionId, isFavorite: $isFavorite)';
}


}

/// @nodoc
abstract mixin class _$LibraryEntryCopyWith<$Res> implements $LibraryEntryCopyWith<$Res> {
  factory _$LibraryEntryCopyWith(_LibraryEntry value, $Res Function(_LibraryEntry) _then) = __$LibraryEntryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String path, FileStatus status, DateTime? lastOpenedAt, String? collectionId, bool isFavorite
});




}
/// @nodoc
class __$LibraryEntryCopyWithImpl<$Res>
    implements _$LibraryEntryCopyWith<$Res> {
  __$LibraryEntryCopyWithImpl(this._self, this._then);

  final _LibraryEntry _self;
  final $Res Function(_LibraryEntry) _then;

/// Create a copy of LibraryEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? path = null,Object? status = null,Object? lastOpenedAt = freezed,Object? collectionId = freezed,Object? isFavorite = null,}) {
  return _then(_LibraryEntry(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as FileStatus,lastOpenedAt: freezed == lastOpenedAt ? _self.lastOpenedAt : lastOpenedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,collectionId: freezed == collectionId ? _self.collectionId : collectionId // ignore: cast_nullable_to_non_nullable
as String?,isFavorite: null == isFavorite ? _self.isFavorite : isFavorite // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
