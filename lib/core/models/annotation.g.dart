// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annotation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Annotation _$AnnotationFromJson(Map<String, dynamic> json) => _Annotation(
  id: json['id'] as String,
  pdfId: json['pdfId'] as String,
  page: (json['page'] as num).toInt(),
  type: $enumDecode(_$AnnotationTypeEnumMap, json['type']),
  rect: json['rect'] == null
      ? null
      : RelativeRectModel.fromJson(json['rect'] as Map<String, dynamic>),
  selectedText: json['selectedText'] as String?,
  textRunStart: (json['textRunStart'] as num?)?.toInt(),
  textRunEnd: (json['textRunEnd'] as num?)?.toInt(),
  text: json['text'] as String?,
  label: json['label'] as String?,
  color:
      $enumDecodeNullable(_$AnnotationColorEnumMap, json['color']) ??
      AnnotationColor.yellow,
  isDeleted: json['isDeleted'] as bool? ?? false,
  coordinateVersion: (json['coordinateVersion'] as num?)?.toInt() ?? 2,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$AnnotationToJson(_Annotation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pdfId': instance.pdfId,
      'page': instance.page,
      'type': _$AnnotationTypeEnumMap[instance.type]!,
      'rect': instance.rect,
      'selectedText': instance.selectedText,
      'textRunStart': instance.textRunStart,
      'textRunEnd': instance.textRunEnd,
      'text': instance.text,
      'label': instance.label,
      'color': _$AnnotationColorEnumMap[instance.color]!,
      'isDeleted': instance.isDeleted,
      'coordinateVersion': instance.coordinateVersion,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$AnnotationTypeEnumMap = {
  AnnotationType.highlight: 'highlight',
  AnnotationType.note: 'note',
  AnnotationType.bookmark: 'bookmark',
};

const _$AnnotationColorEnumMap = {
  AnnotationColor.yellow: 'yellow',
  AnnotationColor.green: 'green',
  AnnotationColor.blue: 'blue',
  AnnotationColor.pink: 'pink',
};
