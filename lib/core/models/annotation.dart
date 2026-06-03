import 'package:freezed_annotation/freezed_annotation.dart';

import 'annotation_color.dart';
import 'annotation_type.dart';
import 'relative_rect_model.dart';

part 'annotation.freezed.dart';
part 'annotation.g.dart';

/// An annotation created by the user on a PDF page.
///
/// [rects] holds one [RelativeRectModel] per word for highlights, a single
/// icon-position rect for notes, and is empty for bookmarks.
///
/// [pdfFingerprint] is the SHA-256 hex digest of the PDF file bytes, used to
/// detect mismatched document revisions when annotations are loaded.
@freezed
abstract class Annotation with _$Annotation {
  const factory Annotation({
    required String id,
    required String pdfId,
    required int page,
    required AnnotationType type,
    @Default([]) List<RelativeRectModel> rects,
    String? selectedText,
    String? text,
    String? label,
    @Default(AnnotationColor.yellow) AnnotationColor color,
    @Default(false) bool isDeleted,
    String? pdfFingerprint,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Annotation;

  factory Annotation.fromJson(Map<String, dynamic> json) =>
      _$AnnotationFromJson(json);
}
