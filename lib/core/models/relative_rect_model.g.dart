// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'relative_rect_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RelativeRectModel _$RelativeRectModelFromJson(Map<String, dynamic> json) =>
    _RelativeRectModel(
      top: (json['top'] as num).toDouble(),
      left: (json['left'] as num).toDouble(),
      bottom: (json['bottom'] as num).toDouble(),
      right: (json['right'] as num).toDouble(),
    );

Map<String, dynamic> _$RelativeRectModelToJson(_RelativeRectModel instance) =>
    <String, dynamic>{
      'top': instance.top,
      'left': instance.left,
      'bottom': instance.bottom,
      'right': instance.right,
    };
