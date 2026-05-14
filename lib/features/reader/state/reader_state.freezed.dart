// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reader_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ReaderState {
  String get pdfId => throw _privateConstructorUsedError;
  int get currentPage => throw _privateConstructorUsedError;
  int get totalPages => throw _privateConstructorUsedError;
  bool get isLoaded => throw _privateConstructorUsedError;

  /// The page to jump to on document load (restored from persistence).
  int get resumePage => throw _privateConstructorUsedError;

  /// Create a copy of ReaderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReaderStateCopyWith<ReaderState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReaderStateCopyWith<$Res> {
  factory $ReaderStateCopyWith(
    ReaderState value,
    $Res Function(ReaderState) then,
  ) = _$ReaderStateCopyWithImpl<$Res, ReaderState>;
  @useResult
  $Res call({
    String pdfId,
    int currentPage,
    int totalPages,
    bool isLoaded,
    int resumePage,
  });
}

/// @nodoc
class _$ReaderStateCopyWithImpl<$Res, $Val extends ReaderState>
    implements $ReaderStateCopyWith<$Res> {
  _$ReaderStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReaderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pdfId = null,
    Object? currentPage = null,
    Object? totalPages = null,
    Object? isLoaded = null,
    Object? resumePage = null,
  }) {
    return _then(
      _value.copyWith(
            pdfId: null == pdfId
                ? _value.pdfId
                : pdfId // ignore: cast_nullable_to_non_nullable
                      as String,
            currentPage: null == currentPage
                ? _value.currentPage
                : currentPage // ignore: cast_nullable_to_non_nullable
                      as int,
            totalPages: null == totalPages
                ? _value.totalPages
                : totalPages // ignore: cast_nullable_to_non_nullable
                      as int,
            isLoaded: null == isLoaded
                ? _value.isLoaded
                : isLoaded // ignore: cast_nullable_to_non_nullable
                      as bool,
            resumePage: null == resumePage
                ? _value.resumePage
                : resumePage // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReaderStateImplCopyWith<$Res>
    implements $ReaderStateCopyWith<$Res> {
  factory _$$ReaderStateImplCopyWith(
    _$ReaderStateImpl value,
    $Res Function(_$ReaderStateImpl) then,
  ) = __$$ReaderStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String pdfId,
    int currentPage,
    int totalPages,
    bool isLoaded,
    int resumePage,
  });
}

/// @nodoc
class __$$ReaderStateImplCopyWithImpl<$Res>
    extends _$ReaderStateCopyWithImpl<$Res, _$ReaderStateImpl>
    implements _$$ReaderStateImplCopyWith<$Res> {
  __$$ReaderStateImplCopyWithImpl(
    _$ReaderStateImpl _value,
    $Res Function(_$ReaderStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReaderState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pdfId = null,
    Object? currentPage = null,
    Object? totalPages = null,
    Object? isLoaded = null,
    Object? resumePage = null,
  }) {
    return _then(
      _$ReaderStateImpl(
        pdfId: null == pdfId
            ? _value.pdfId
            : pdfId // ignore: cast_nullable_to_non_nullable
                  as String,
        currentPage: null == currentPage
            ? _value.currentPage
            : currentPage // ignore: cast_nullable_to_non_nullable
                  as int,
        totalPages: null == totalPages
            ? _value.totalPages
            : totalPages // ignore: cast_nullable_to_non_nullable
                  as int,
        isLoaded: null == isLoaded
            ? _value.isLoaded
            : isLoaded // ignore: cast_nullable_to_non_nullable
                  as bool,
        resumePage: null == resumePage
            ? _value.resumePage
            : resumePage // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ReaderStateImpl implements _ReaderState {
  const _$ReaderStateImpl({
    this.pdfId = '',
    this.currentPage = 1,
    this.totalPages = 1,
    this.isLoaded = false,
    this.resumePage = 1,
  });

  @override
  @JsonKey()
  final String pdfId;
  @override
  @JsonKey()
  final int currentPage;
  @override
  @JsonKey()
  final int totalPages;
  @override
  @JsonKey()
  final bool isLoaded;

  /// The page to jump to on document load (restored from persistence).
  @override
  @JsonKey()
  final int resumePage;

  @override
  String toString() {
    return 'ReaderState(pdfId: $pdfId, currentPage: $currentPage, totalPages: $totalPages, isLoaded: $isLoaded, resumePage: $resumePage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReaderStateImpl &&
            (identical(other.pdfId, pdfId) || other.pdfId == pdfId) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.totalPages, totalPages) ||
                other.totalPages == totalPages) &&
            (identical(other.isLoaded, isLoaded) ||
                other.isLoaded == isLoaded) &&
            (identical(other.resumePage, resumePage) ||
                other.resumePage == resumePage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    pdfId,
    currentPage,
    totalPages,
    isLoaded,
    resumePage,
  );

  /// Create a copy of ReaderState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReaderStateImplCopyWith<_$ReaderStateImpl> get copyWith =>
      __$$ReaderStateImplCopyWithImpl<_$ReaderStateImpl>(this, _$identity);
}

abstract class _ReaderState implements ReaderState {
  const factory _ReaderState({
    final String pdfId,
    final int currentPage,
    final int totalPages,
    final bool isLoaded,
    final int resumePage,
  }) = _$ReaderStateImpl;

  @override
  String get pdfId;
  @override
  int get currentPage;
  @override
  int get totalPages;
  @override
  bool get isLoaded;

  /// The page to jump to on document load (restored from persistence).
  @override
  int get resumePage;

  /// Create a copy of ReaderState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReaderStateImplCopyWith<_$ReaderStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
