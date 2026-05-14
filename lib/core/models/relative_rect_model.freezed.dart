// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'relative_rect_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RelativeRectModel {

 double get top; double get left; double get bottom; double get right;
/// Create a copy of RelativeRectModel
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RelativeRectModelCopyWith<RelativeRectModel> get copyWith => _$RelativeRectModelCopyWithImpl<RelativeRectModel>(this as RelativeRectModel, _$identity);

  /// Serializes this RelativeRectModel to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RelativeRectModel&&(identical(other.top, top) || other.top == top)&&(identical(other.left, left) || other.left == left)&&(identical(other.bottom, bottom) || other.bottom == bottom)&&(identical(other.right, right) || other.right == right));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,top,left,bottom,right);

@override
String toString() {
  return 'RelativeRectModel(top: $top, left: $left, bottom: $bottom, right: $right)';
}


}

/// @nodoc
abstract mixin class $RelativeRectModelCopyWith<$Res>  {
  factory $RelativeRectModelCopyWith(RelativeRectModel value, $Res Function(RelativeRectModel) _then) = _$RelativeRectModelCopyWithImpl;
@useResult
$Res call({
 double top, double left, double bottom, double right
});




}
/// @nodoc
class _$RelativeRectModelCopyWithImpl<$Res>
    implements $RelativeRectModelCopyWith<$Res> {
  _$RelativeRectModelCopyWithImpl(this._self, this._then);

  final RelativeRectModel _self;
  final $Res Function(RelativeRectModel) _then;

/// Create a copy of RelativeRectModel
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? top = null,Object? left = null,Object? bottom = null,Object? right = null,}) {
  return _then(_self.copyWith(
top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double,left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as double,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [RelativeRectModel].
extension RelativeRectModelPatterns on RelativeRectModel {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RelativeRectModel value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RelativeRectModel() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RelativeRectModel value)  $default,){
final _that = this;
switch (_that) {
case _RelativeRectModel():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RelativeRectModel value)?  $default,){
final _that = this;
switch (_that) {
case _RelativeRectModel() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double top,  double left,  double bottom,  double right)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RelativeRectModel() when $default != null:
return $default(_that.top,_that.left,_that.bottom,_that.right);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double top,  double left,  double bottom,  double right)  $default,) {final _that = this;
switch (_that) {
case _RelativeRectModel():
return $default(_that.top,_that.left,_that.bottom,_that.right);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double top,  double left,  double bottom,  double right)?  $default,) {final _that = this;
switch (_that) {
case _RelativeRectModel() when $default != null:
return $default(_that.top,_that.left,_that.bottom,_that.right);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RelativeRectModel implements RelativeRectModel {
  const _RelativeRectModel({required this.top, required this.left, required this.bottom, required this.right});
  factory _RelativeRectModel.fromJson(Map<String, dynamic> json) => _$RelativeRectModelFromJson(json);

@override final  double top;
@override final  double left;
@override final  double bottom;
@override final  double right;

/// Create a copy of RelativeRectModel
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RelativeRectModelCopyWith<_RelativeRectModel> get copyWith => __$RelativeRectModelCopyWithImpl<_RelativeRectModel>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RelativeRectModelToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RelativeRectModel&&(identical(other.top, top) || other.top == top)&&(identical(other.left, left) || other.left == left)&&(identical(other.bottom, bottom) || other.bottom == bottom)&&(identical(other.right, right) || other.right == right));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,top,left,bottom,right);

@override
String toString() {
  return 'RelativeRectModel(top: $top, left: $left, bottom: $bottom, right: $right)';
}


}

/// @nodoc
abstract mixin class _$RelativeRectModelCopyWith<$Res> implements $RelativeRectModelCopyWith<$Res> {
  factory _$RelativeRectModelCopyWith(_RelativeRectModel value, $Res Function(_RelativeRectModel) _then) = __$RelativeRectModelCopyWithImpl;
@override @useResult
$Res call({
 double top, double left, double bottom, double right
});




}
/// @nodoc
class __$RelativeRectModelCopyWithImpl<$Res>
    implements _$RelativeRectModelCopyWith<$Res> {
  __$RelativeRectModelCopyWithImpl(this._self, this._then);

  final _RelativeRectModel _self;
  final $Res Function(_RelativeRectModel) _then;

/// Create a copy of RelativeRectModel
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? top = null,Object? left = null,Object? bottom = null,Object? right = null,}) {
  return _then(_RelativeRectModel(
top: null == top ? _self.top : top // ignore: cast_nullable_to_non_nullable
as double,left: null == left ? _self.left : left // ignore: cast_nullable_to_non_nullable
as double,bottom: null == bottom ? _self.bottom : bottom // ignore: cast_nullable_to_non_nullable
as double,right: null == right ? _self.right : right // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

// dart format on
