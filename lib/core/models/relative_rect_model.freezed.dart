// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'relative_rect_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RelativeRectModel _$RelativeRectModelFromJson(Map<String, dynamic> json) {
  return _RelativeRectModel.fromJson(json);
}

/// @nodoc
mixin _$RelativeRectModel {
  double get top => throw _privateConstructorUsedError;
  double get left => throw _privateConstructorUsedError;
  double get bottom => throw _privateConstructorUsedError;
  double get right => throw _privateConstructorUsedError;

  /// Serializes this RelativeRectModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RelativeRectModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RelativeRectModelCopyWith<RelativeRectModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RelativeRectModelCopyWith<$Res> {
  factory $RelativeRectModelCopyWith(
    RelativeRectModel value,
    $Res Function(RelativeRectModel) then,
  ) = _$RelativeRectModelCopyWithImpl<$Res, RelativeRectModel>;
  @useResult
  $Res call({double top, double left, double bottom, double right});
}

/// @nodoc
class _$RelativeRectModelCopyWithImpl<$Res, $Val extends RelativeRectModel>
    implements $RelativeRectModelCopyWith<$Res> {
  _$RelativeRectModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RelativeRectModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? top = null,
    Object? left = null,
    Object? bottom = null,
    Object? right = null,
  }) {
    return _then(
      _value.copyWith(
            top: null == top
                ? _value.top
                : top // ignore: cast_nullable_to_non_nullable
                      as double,
            left: null == left
                ? _value.left
                : left // ignore: cast_nullable_to_non_nullable
                      as double,
            bottom: null == bottom
                ? _value.bottom
                : bottom // ignore: cast_nullable_to_non_nullable
                      as double,
            right: null == right
                ? _value.right
                : right // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RelativeRectModelImplCopyWith<$Res>
    implements $RelativeRectModelCopyWith<$Res> {
  factory _$$RelativeRectModelImplCopyWith(
    _$RelativeRectModelImpl value,
    $Res Function(_$RelativeRectModelImpl) then,
  ) = __$$RelativeRectModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double top, double left, double bottom, double right});
}

/// @nodoc
class __$$RelativeRectModelImplCopyWithImpl<$Res>
    extends _$RelativeRectModelCopyWithImpl<$Res, _$RelativeRectModelImpl>
    implements _$$RelativeRectModelImplCopyWith<$Res> {
  __$$RelativeRectModelImplCopyWithImpl(
    _$RelativeRectModelImpl _value,
    $Res Function(_$RelativeRectModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RelativeRectModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? top = null,
    Object? left = null,
    Object? bottom = null,
    Object? right = null,
  }) {
    return _then(
      _$RelativeRectModelImpl(
        top: null == top
            ? _value.top
            : top // ignore: cast_nullable_to_non_nullable
                  as double,
        left: null == left
            ? _value.left
            : left // ignore: cast_nullable_to_non_nullable
                  as double,
        bottom: null == bottom
            ? _value.bottom
            : bottom // ignore: cast_nullable_to_non_nullable
                  as double,
        right: null == right
            ? _value.right
            : right // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RelativeRectModelImpl implements _RelativeRectModel {
  const _$RelativeRectModelImpl({
    required this.top,
    required this.left,
    required this.bottom,
    required this.right,
  });

  factory _$RelativeRectModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$RelativeRectModelImplFromJson(json);

  @override
  final double top;
  @override
  final double left;
  @override
  final double bottom;
  @override
  final double right;

  @override
  String toString() {
    return 'RelativeRectModel(top: $top, left: $left, bottom: $bottom, right: $right)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RelativeRectModelImpl &&
            (identical(other.top, top) || other.top == top) &&
            (identical(other.left, left) || other.left == left) &&
            (identical(other.bottom, bottom) || other.bottom == bottom) &&
            (identical(other.right, right) || other.right == right));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, top, left, bottom, right);

  /// Create a copy of RelativeRectModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RelativeRectModelImplCopyWith<_$RelativeRectModelImpl> get copyWith =>
      __$$RelativeRectModelImplCopyWithImpl<_$RelativeRectModelImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RelativeRectModelImplToJson(this);
  }
}

abstract class _RelativeRectModel implements RelativeRectModel {
  const factory _RelativeRectModel({
    required final double top,
    required final double left,
    required final double bottom,
    required final double right,
  }) = _$RelativeRectModelImpl;

  factory _RelativeRectModel.fromJson(Map<String, dynamic> json) =
      _$RelativeRectModelImpl.fromJson;

  @override
  double get top;
  @override
  double get left;
  @override
  double get bottom;
  @override
  double get right;

  /// Create a copy of RelativeRectModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RelativeRectModelImplCopyWith<_$RelativeRectModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
