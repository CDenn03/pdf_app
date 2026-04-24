// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'annotation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Annotation _$AnnotationFromJson(Map<String, dynamic> json) {
  return _Annotation.fromJson(json);
}

/// @nodoc
mixin _$Annotation {
  String get id => throw _privateConstructorUsedError; // UUID
  String get pdfId => throw _privateConstructorUsedError;
  int get page => throw _privateConstructorUsedError;
  AnnotationType get type => throw _privateConstructorUsedError;
  RelativeRectModel? get rect =>
      throw _privateConstructorUsedError; // Nullable for bookmarks
  String? get text =>
      throw _privateConstructorUsedError; // Nullable for highlights and bookmarks
  bool get isDeleted => throw _privateConstructorUsedError;

  /// Serializes this Annotation to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Annotation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnnotationCopyWith<Annotation> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnnotationCopyWith<$Res> {
  factory $AnnotationCopyWith(
    Annotation value,
    $Res Function(Annotation) then,
  ) = _$AnnotationCopyWithImpl<$Res, Annotation>;
  @useResult
  $Res call({
    String id,
    String pdfId,
    int page,
    AnnotationType type,
    RelativeRectModel? rect,
    String? text,
    bool isDeleted,
  });

  $RelativeRectModelCopyWith<$Res>? get rect;
}

/// @nodoc
class _$AnnotationCopyWithImpl<$Res, $Val extends Annotation>
    implements $AnnotationCopyWith<$Res> {
  _$AnnotationCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Annotation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pdfId = null,
    Object? page = null,
    Object? type = null,
    Object? rect = freezed,
    Object? text = freezed,
    Object? isDeleted = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            pdfId: null == pdfId
                ? _value.pdfId
                : pdfId // ignore: cast_nullable_to_non_nullable
                      as String,
            page: null == page
                ? _value.page
                : page // ignore: cast_nullable_to_non_nullable
                      as int,
            type: null == type
                ? _value.type
                : type // ignore: cast_nullable_to_non_nullable
                      as AnnotationType,
            rect: freezed == rect
                ? _value.rect
                : rect // ignore: cast_nullable_to_non_nullable
                      as RelativeRectModel?,
            text: freezed == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String?,
            isDeleted: null == isDeleted
                ? _value.isDeleted
                : isDeleted // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }

  /// Create a copy of Annotation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $RelativeRectModelCopyWith<$Res>? get rect {
    if (_value.rect == null) {
      return null;
    }

    return $RelativeRectModelCopyWith<$Res>(_value.rect!, (value) {
      return _then(_value.copyWith(rect: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AnnotationImplCopyWith<$Res>
    implements $AnnotationCopyWith<$Res> {
  factory _$$AnnotationImplCopyWith(
    _$AnnotationImpl value,
    $Res Function(_$AnnotationImpl) then,
  ) = __$$AnnotationImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String pdfId,
    int page,
    AnnotationType type,
    RelativeRectModel? rect,
    String? text,
    bool isDeleted,
  });

  @override
  $RelativeRectModelCopyWith<$Res>? get rect;
}

/// @nodoc
class __$$AnnotationImplCopyWithImpl<$Res>
    extends _$AnnotationCopyWithImpl<$Res, _$AnnotationImpl>
    implements _$$AnnotationImplCopyWith<$Res> {
  __$$AnnotationImplCopyWithImpl(
    _$AnnotationImpl _value,
    $Res Function(_$AnnotationImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Annotation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? pdfId = null,
    Object? page = null,
    Object? type = null,
    Object? rect = freezed,
    Object? text = freezed,
    Object? isDeleted = null,
  }) {
    return _then(
      _$AnnotationImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        pdfId: null == pdfId
            ? _value.pdfId
            : pdfId // ignore: cast_nullable_to_non_nullable
                  as String,
        page: null == page
            ? _value.page
            : page // ignore: cast_nullable_to_non_nullable
                  as int,
        type: null == type
            ? _value.type
            : type // ignore: cast_nullable_to_non_nullable
                  as AnnotationType,
        rect: freezed == rect
            ? _value.rect
            : rect // ignore: cast_nullable_to_non_nullable
                  as RelativeRectModel?,
        text: freezed == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String?,
        isDeleted: null == isDeleted
            ? _value.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AnnotationImpl implements _Annotation {
  const _$AnnotationImpl({
    required this.id,
    required this.pdfId,
    required this.page,
    required this.type,
    this.rect,
    this.text,
    this.isDeleted = false,
  });

  factory _$AnnotationImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnnotationImplFromJson(json);

  @override
  final String id;
  // UUID
  @override
  final String pdfId;
  @override
  final int page;
  @override
  final AnnotationType type;
  @override
  final RelativeRectModel? rect;
  // Nullable for bookmarks
  @override
  final String? text;
  // Nullable for highlights and bookmarks
  @override
  @JsonKey()
  final bool isDeleted;

  @override
  String toString() {
    return 'Annotation(id: $id, pdfId: $pdfId, page: $page, type: $type, rect: $rect, text: $text, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnnotationImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.pdfId, pdfId) || other.pdfId == pdfId) &&
            (identical(other.page, page) || other.page == page) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.rect, rect) || other.rect == rect) &&
            (identical(other.text, text) || other.text == text) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, pdfId, page, type, rect, text, isDeleted);

  /// Create a copy of Annotation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnnotationImplCopyWith<_$AnnotationImpl> get copyWith =>
      __$$AnnotationImplCopyWithImpl<_$AnnotationImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnnotationImplToJson(this);
  }
}

abstract class _Annotation implements Annotation {
  const factory _Annotation({
    required final String id,
    required final String pdfId,
    required final int page,
    required final AnnotationType type,
    final RelativeRectModel? rect,
    final String? text,
    final bool isDeleted,
  }) = _$AnnotationImpl;

  factory _Annotation.fromJson(Map<String, dynamic> json) =
      _$AnnotationImpl.fromJson;

  @override
  String get id; // UUID
  @override
  String get pdfId;
  @override
  int get page;
  @override
  AnnotationType get type;
  @override
  RelativeRectModel? get rect; // Nullable for bookmarks
  @override
  String? get text; // Nullable for highlights and bookmarks
  @override
  bool get isDeleted;

  /// Create a copy of Annotation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnnotationImplCopyWith<_$AnnotationImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
