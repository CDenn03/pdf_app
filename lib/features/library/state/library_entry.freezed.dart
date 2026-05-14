// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'library_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$LibraryEntry {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get path => throw _privateConstructorUsedError;
  FileStatus get status => throw _privateConstructorUsedError;
  DateTime? get lastOpenedAt => throw _privateConstructorUsedError;
  String? get collectionId => throw _privateConstructorUsedError;

  /// Create a copy of LibraryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LibraryEntryCopyWith<LibraryEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LibraryEntryCopyWith<$Res> {
  factory $LibraryEntryCopyWith(
    LibraryEntry value,
    $Res Function(LibraryEntry) then,
  ) = _$LibraryEntryCopyWithImpl<$Res, LibraryEntry>;
  @useResult
  $Res call({
    String id,
    String name,
    String path,
    FileStatus status,
    DateTime? lastOpenedAt,
    String? collectionId,
  });
}

/// @nodoc
class _$LibraryEntryCopyWithImpl<$Res, $Val extends LibraryEntry>
    implements $LibraryEntryCopyWith<$Res> {
  _$LibraryEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LibraryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? path = null,
    Object? status = null,
    Object? lastOpenedAt = freezed,
    Object? collectionId = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            path: null == path
                ? _value.path
                : path // ignore: cast_nullable_to_non_nullable
                      as String,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as FileStatus,
            lastOpenedAt: freezed == lastOpenedAt
                ? _value.lastOpenedAt
                : lastOpenedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            collectionId: freezed == collectionId
                ? _value.collectionId
                : collectionId // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LibraryEntryImplCopyWith<$Res>
    implements $LibraryEntryCopyWith<$Res> {
  factory _$$LibraryEntryImplCopyWith(
    _$LibraryEntryImpl value,
    $Res Function(_$LibraryEntryImpl) then,
  ) = __$$LibraryEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String path,
    FileStatus status,
    DateTime? lastOpenedAt,
    String? collectionId,
  });
}

/// @nodoc
class __$$LibraryEntryImplCopyWithImpl<$Res>
    extends _$LibraryEntryCopyWithImpl<$Res, _$LibraryEntryImpl>
    implements _$$LibraryEntryImplCopyWith<$Res> {
  __$$LibraryEntryImplCopyWithImpl(
    _$LibraryEntryImpl _value,
    $Res Function(_$LibraryEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LibraryEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? path = null,
    Object? status = null,
    Object? lastOpenedAt = freezed,
    Object? collectionId = freezed,
  }) {
    return _then(
      _$LibraryEntryImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        path: null == path
            ? _value.path
            : path // ignore: cast_nullable_to_non_nullable
                  as String,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as FileStatus,
        lastOpenedAt: freezed == lastOpenedAt
            ? _value.lastOpenedAt
            : lastOpenedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        collectionId: freezed == collectionId
            ? _value.collectionId
            : collectionId // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$LibraryEntryImpl implements _LibraryEntry {
  const _$LibraryEntryImpl({
    required this.id,
    required this.name,
    required this.path,
    required this.status,
    this.lastOpenedAt,
    this.collectionId,
  });

  @override
  final String id;
  @override
  final String name;
  @override
  final String path;
  @override
  final FileStatus status;
  @override
  final DateTime? lastOpenedAt;
  @override
  final String? collectionId;

  @override
  String toString() {
    return 'LibraryEntry(id: $id, name: $name, path: $path, status: $status, lastOpenedAt: $lastOpenedAt, collectionId: $collectionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LibraryEntryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastOpenedAt, lastOpenedAt) ||
                other.lastOpenedAt == lastOpenedAt) &&
            (identical(other.collectionId, collectionId) ||
                other.collectionId == collectionId));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    path,
    status,
    lastOpenedAt,
    collectionId,
  );

  /// Create a copy of LibraryEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LibraryEntryImplCopyWith<_$LibraryEntryImpl> get copyWith =>
      __$$LibraryEntryImplCopyWithImpl<_$LibraryEntryImpl>(this, _$identity);
}

abstract class _LibraryEntry implements LibraryEntry {
  const factory _LibraryEntry({
    required final String id,
    required final String name,
    required final String path,
    required final FileStatus status,
    final DateTime? lastOpenedAt,
    final String? collectionId,
  }) = _$LibraryEntryImpl;

  @override
  String get id;
  @override
  String get name;
  @override
  String get path;
  @override
  FileStatus get status;
  @override
  DateTime? get lastOpenedAt;
  @override
  String? get collectionId;

  /// Create a copy of LibraryEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LibraryEntryImplCopyWith<_$LibraryEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
