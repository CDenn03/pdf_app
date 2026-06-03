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
  rects:
      (json['rects'] as List<dynamic>?)
          ?.map((e) => RelativeRectModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  selectedText: json['selectedText'] as String?,
  text: json['text'] as String?,
  label: json['label'] as String?,
  color:
      $enumDecodeNullable(_$AnnotationColorEnumMap, json['color']) ??
      AnnotationColor.yellow,
  isDeleted: json['isDeleted'] as bool? ?? false,
  pdfFingerprint: json['pdfFingerprint'] as String?,
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
      'rects': instance.rects,
      'selectedText': instance.selectedText,
      'text': instance.text,
      'label': instance.label,
      'color': _$AnnotationColorEnumMap[instance.color]!,
      'isDeleted': instance.isDeleted,
      'pdfFingerprint': instance.pdfFingerprint,
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
