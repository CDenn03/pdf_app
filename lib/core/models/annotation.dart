import 'package:freezed_annotation/freezed_annotation.dart';

import 'annotation_type.dart';
import 'relative_rect_model.dart';

part 'annotation.freezed.dart';
part 'annotation.g.dart';

/// An annotation created by the user on a PDF page.
///
/// Supports highlights, notes, and bookmarks. Rect is nullable because
/// bookmarks have no spatial extent. Text is nullable because highlights
/// and bookmarks carry no text content. Soft-deleted annotations are
/// retained in the database with [isDeleted] set to true.
@freezed
class Annotation with _$Annotation {
  const factory Annotation({
    required String id,
    required String pdfId,
    required int page,
    required AnnotationType type,
    RelativeRectModel? rect,
    String? text,
    @Default(false) bool isDeleted,
  }) = _Annotation;

  factory Annotation.fromJson(Map<String, dynamic> json) =>
      _$AnnotationFromJson(json);
}
