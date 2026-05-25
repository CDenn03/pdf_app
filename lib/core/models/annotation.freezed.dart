// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'annotation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Annotation {

 String get id; String get pdfId; int get page; AnnotationType get type; RelativeRectModel? get rect; String? get selectedText; int? get textRunStart; int? get textRunEnd; String? get text; String? get label; AnnotationColor get color; bool get isDeleted; int get coordinateVersion; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnnotationCopyWith<Annotation> get copyWith => _$AnnotationCopyWithImpl<Annotation>(this as Annotation, _$identity);

  /// Serializes this Annotation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Annotation&&(identical(other.id, id) || other.id == id)&&(identical(other.pdfId, pdfId) || other.pdfId == pdfId)&&(identical(other.page, page) || other.page == page)&&(identical(other.type, type) || other.type == type)&&(identical(other.rect, rect) || other.rect == rect)&&(identical(other.selectedText, selectedText) || other.selectedText == selectedText)&&(identical(other.textRunStart, textRunStart) || other.textRunStart == textRunStart)&&(identical(other.textRunEnd, textRunEnd) || other.textRunEnd == textRunEnd)&&(identical(other.text, text) || other.text == text)&&(identical(other.label, label) || other.label == label)&&(identical(other.color, color) || other.color == color)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.coordinateVersion, coordinateVersion) || other.coordinateVersion == coordinateVersion)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pdfId,page,type,rect,selectedText,textRunStart,textRunEnd,text,label,color,isDeleted,coordinateVersion,createdAt,updatedAt);

@override
String toString() {
  return 'Annotation(id: $id, pdfId: $pdfId, page: $page, type: $type, rect: $rect, selectedText: $selectedText, textRunStart: $textRunStart, textRunEnd: $textRunEnd, text: $text, label: $label, color: $color, isDeleted: $isDeleted, coordinateVersion: $coordinateVersion, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $AnnotationCopyWith<$Res>  {
  factory $AnnotationCopyWith(Annotation value, $Res Function(Annotation) _then) = _$AnnotationCopyWithImpl;
@useResult
$Res call({
 String id, String pdfId, int page, AnnotationType type, RelativeRectModel? rect, String? selectedText, int? textRunStart, int? textRunEnd, String? text, String? label, AnnotationColor color, bool isDeleted, int coordinateVersion, DateTime? createdAt, DateTime? updatedAt
});


$RelativeRectModelCopyWith<$Res>? get rect;

}
/// @nodoc
class _$AnnotationCopyWithImpl<$Res>
    implements $AnnotationCopyWith<$Res> {
  _$AnnotationCopyWithImpl(this._self, this._then);

  final Annotation _self;
  final $Res Function(Annotation) _then;

/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? pdfId = null,Object? page = null,Object? type = null,Object? rect = freezed,Object? selectedText = freezed,Object? textRunStart = freezed,Object? textRunEnd = freezed,Object? text = freezed,Object? label = freezed,Object? color = null,Object? isDeleted = null,Object? coordinateVersion = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pdfId: null == pdfId ? _self.pdfId : pdfId // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AnnotationType,rect: freezed == rect ? _self.rect : rect // ignore: cast_nullable_to_non_nullable
as RelativeRectModel?,selectedText: freezed == selectedText ? _self.selectedText : selectedText // ignore: cast_nullable_to_non_nullable
as String?,textRunStart: freezed == textRunStart ? _self.textRunStart : textRunStart // ignore: cast_nullable_to_non_nullable
as int?,textRunEnd: freezed == textRunEnd ? _self.textRunEnd : textRunEnd // ignore: cast_nullable_to_non_nullable
as int?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as AnnotationColor,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,coordinateVersion: null == coordinateVersion ? _self.coordinateVersion : coordinateVersion // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RelativeRectModelCopyWith<$Res>? get rect {
    if (_self.rect == null) {
    return null;
  }

  return $RelativeRectModelCopyWith<$Res>(_self.rect!, (value) {
    return _then(_self.copyWith(rect: value));
  });
}
}


/// Adds pattern-matching-related methods to [Annotation].
extension AnnotationPatterns on Annotation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Annotation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Annotation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Annotation value)  $default,){
final _that = this;
switch (_that) {
case _Annotation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Annotation value)?  $default,){
final _that = this;
switch (_that) {
case _Annotation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String pdfId,  int page,  AnnotationType type,  RelativeRectModel? rect,  String? selectedText,  int? textRunStart,  int? textRunEnd,  String? text,  String? label,  AnnotationColor color,  bool isDeleted,  int coordinateVersion,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Annotation() when $default != null:
return $default(_that.id,_that.pdfId,_that.page,_that.type,_that.rect,_that.selectedText,_that.textRunStart,_that.textRunEnd,_that.text,_that.label,_that.color,_that.isDeleted,_that.coordinateVersion,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String pdfId,  int page,  AnnotationType type,  RelativeRectModel? rect,  String? selectedText,  int? textRunStart,  int? textRunEnd,  String? text,  String? label,  AnnotationColor color,  bool isDeleted,  int coordinateVersion,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Annotation():
return $default(_that.id,_that.pdfId,_that.page,_that.type,_that.rect,_that.selectedText,_that.textRunStart,_that.textRunEnd,_that.text,_that.label,_that.color,_that.isDeleted,_that.coordinateVersion,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String pdfId,  int page,  AnnotationType type,  RelativeRectModel? rect,  String? selectedText,  int? textRunStart,  int? textRunEnd,  String? text,  String? label,  AnnotationColor color,  bool isDeleted,  int coordinateVersion,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Annotation() when $default != null:
return $default(_that.id,_that.pdfId,_that.page,_that.type,_that.rect,_that.selectedText,_that.textRunStart,_that.textRunEnd,_that.text,_that.label,_that.color,_that.isDeleted,_that.coordinateVersion,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Annotation implements Annotation {
  const _Annotation({required this.id, required this.pdfId, required this.page, required this.type, this.rect, this.selectedText, this.textRunStart, this.textRunEnd, this.text, this.label, this.color = AnnotationColor.yellow, this.isDeleted = false, this.coordinateVersion = 2, this.createdAt, this.updatedAt});
  factory _Annotation.fromJson(Map<String, dynamic> json) => _$AnnotationFromJson(json);

@override final  String id;
@override final  String pdfId;
@override final  int page;
@override final  AnnotationType type;
@override final  RelativeRectModel? rect;
@override final  String? selectedText;
@override final  int? textRunStart;
@override final  int? textRunEnd;
@override final  String? text;
@override final  String? label;
@override@JsonKey() final  AnnotationColor color;
@override@JsonKey() final  bool isDeleted;
@override@JsonKey() final  int coordinateVersion;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnnotationCopyWith<_Annotation> get copyWith => __$AnnotationCopyWithImpl<_Annotation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnnotationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Annotation&&(identical(other.id, id) || other.id == id)&&(identical(other.pdfId, pdfId) || other.pdfId == pdfId)&&(identical(other.page, page) || other.page == page)&&(identical(other.type, type) || other.type == type)&&(identical(other.rect, rect) || other.rect == rect)&&(identical(other.selectedText, selectedText) || other.selectedText == selectedText)&&(identical(other.textRunStart, textRunStart) || other.textRunStart == textRunStart)&&(identical(other.textRunEnd, textRunEnd) || other.textRunEnd == textRunEnd)&&(identical(other.text, text) || other.text == text)&&(identical(other.label, label) || other.label == label)&&(identical(other.color, color) || other.color == color)&&(identical(other.isDeleted, isDeleted) || other.isDeleted == isDeleted)&&(identical(other.coordinateVersion, coordinateVersion) || other.coordinateVersion == coordinateVersion)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,pdfId,page,type,rect,selectedText,textRunStart,textRunEnd,text,label,color,isDeleted,coordinateVersion,createdAt,updatedAt);

@override
String toString() {
  return 'Annotation(id: $id, pdfId: $pdfId, page: $page, type: $type, rect: $rect, selectedText: $selectedText, textRunStart: $textRunStart, textRunEnd: $textRunEnd, text: $text, label: $label, color: $color, isDeleted: $isDeleted, coordinateVersion: $coordinateVersion, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$AnnotationCopyWith<$Res> implements $AnnotationCopyWith<$Res> {
  factory _$AnnotationCopyWith(_Annotation value, $Res Function(_Annotation) _then) = __$AnnotationCopyWithImpl;
@override @useResult
$Res call({
 String id, String pdfId, int page, AnnotationType type, RelativeRectModel? rect, String? selectedText, int? textRunStart, int? textRunEnd, String? text, String? label, AnnotationColor color, bool isDeleted, int coordinateVersion, DateTime? createdAt, DateTime? updatedAt
});


@override $RelativeRectModelCopyWith<$Res>? get rect;

}
/// @nodoc
class __$AnnotationCopyWithImpl<$Res>
    implements _$AnnotationCopyWith<$Res> {
  __$AnnotationCopyWithImpl(this._self, this._then);

  final _Annotation _self;
  final $Res Function(_Annotation) _then;

/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? pdfId = null,Object? page = null,Object? type = null,Object? rect = freezed,Object? selectedText = freezed,Object? textRunStart = freezed,Object? textRunEnd = freezed,Object? text = freezed,Object? label = freezed,Object? color = null,Object? isDeleted = null,Object? coordinateVersion = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Annotation(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,pdfId: null == pdfId ? _self.pdfId : pdfId // ignore: cast_nullable_to_non_nullable
as String,page: null == page ? _self.page : page // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as AnnotationType,rect: freezed == rect ? _self.rect : rect // ignore: cast_nullable_to_non_nullable
as RelativeRectModel?,selectedText: freezed == selectedText ? _self.selectedText : selectedText // ignore: cast_nullable_to_non_nullable
as String?,textRunStart: freezed == textRunStart ? _self.textRunStart : textRunStart // ignore: cast_nullable_to_non_nullable
as int?,textRunEnd: freezed == textRunEnd ? _self.textRunEnd : textRunEnd // ignore: cast_nullable_to_non_nullable
as int?,text: freezed == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String?,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String?,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as AnnotationColor,isDeleted: null == isDeleted ? _self.isDeleted : isDeleted // ignore: cast_nullable_to_non_nullable
as bool,coordinateVersion: null == coordinateVersion ? _self.coordinateVersion : coordinateVersion // ignore: cast_nullable_to_non_nullable
as int,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Annotation
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RelativeRectModelCopyWith<$Res>? get rect {
    if (_self.rect == null) {
    return null;
  }

  return $RelativeRectModelCopyWith<$Res>(_self.rect!, (value) {
    return _then(_self.copyWith(rect: value));
  });
}
}

// dart format on
