// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'annotation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AnnotationImpl _$$AnnotationImplFromJson(Map<String, dynamic> json) =>
    _$AnnotationImpl(
      id: json['id'] as String,
      pdfId: json['pdfId'] as String,
      page: (json['page'] as num).toInt(),
      type: $enumDecode(_$AnnotationTypeEnumMap, json['type']),
      rect: json['rect'] == null
          ? null
          : RelativeRectModel.fromJson(json['rect'] as Map<String, dynamic>),
      text: json['text'] as String?,
      isDeleted: json['isDeleted'] as bool? ?? false,
    );

Map<String, dynamic> _$$AnnotationImplToJson(_$AnnotationImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'pdfId': instance.pdfId,
      'page': instance.page,
      'type': _$AnnotationTypeEnumMap[instance.type]!,
      'rect': instance.rect,
      'text': instance.text,
      'isDeleted': instance.isDeleted,
    };

const _$AnnotationTypeEnumMap = {
  AnnotationType.highlight: 'highlight',
  AnnotationType.note: 'note',
  AnnotationType.bookmark: 'bookmark',
};
