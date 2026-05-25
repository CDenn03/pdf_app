import 'package:freezed_annotation/freezed_annotation.dart';

import 'annotation_color.dart';
import 'annotation_type.dart';
import 'relative_rect_model.dart';

part 'annotation.freezed.dart';
part 'annotation.g.dart';

/// An annotation created by the user on a PDF page.
///
/// Supports highlights, notes, and bookmarks. [rect] is nullable because
/// bookmarks have no spatial extent. [text] is nullable because highlights
/// and bookmarks carry no note content.
///
/// [selectedText] stores the verbatim text the user highlighted, providing
/// text-anchoring so annotations survive zoom and rendering changes.
///
/// [coordinateVersion] marks which coordinate system the [rect] was captured
/// in: 1 = legacy (screen pixels / PDF points — unreliable), 2 = normalized
/// to rendered page size (correct). Pre-v4-migration data is always version 1.
///
/// Soft-deleted annotations are retained in the database with [isDeleted] set
/// to true.
@freezed
abstract class Annotation with _$Annotation {
  const factory Annotation({
    required String id,
    required String pdfId,
    required int page,
    required AnnotationType type,
    RelativeRectModel? rect,
    String? selectedText,
    int? textRunStart,
    int? textRunEnd,
    String? text,
    String? label,
    @Default(AnnotationColor.yellow) AnnotationColor color,
    @Default(false) bool isDeleted,
    @Default(2) int coordinateVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Annotation;

  factory Annotation.fromJson(Map<String, dynamic> json) =>
      _$AnnotationFromJson(json);
}
