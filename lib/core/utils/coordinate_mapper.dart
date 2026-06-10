import 'dart:ui';

import 'package:sefer/core/models/relative_rect_model.dart';

/// Converts a [RelativeRectModel] (0.0–1.0 normalized) to an absolute [Rect]
/// based on the rendered PDF page size.
///
/// [pageSize] MUST be the rendered PDF page size obtained from
/// `PdfViewerController.getPageSize()`, NOT the screen or viewport size.
Rect toAbsolute(RelativeRectModel rel, Size pageSize) {
  return Rect.fromLTRB(
    rel.left * pageSize.width,
    rel.top * pageSize.height,
    rel.right * pageSize.width,
    rel.bottom * pageSize.height,
  );
}

/// Converts an absolute [Rect] to a [RelativeRectModel] by normalizing
/// against the rendered PDF page size.
///
/// Used when converting gesture screen coordinates back to normalized storage
/// coordinates.
RelativeRectModel toRelative(Rect absoluteRect, Size pageSize) {
  // ASSUMPTION: pageSize width and height are always > 0 when this is called.
  return RelativeRectModel(
    left: absoluteRect.left / pageSize.width,
    top: absoluteRect.top / pageSize.height,
    right: absoluteRect.right / pageSize.width,
    bottom: absoluteRect.bottom / pageSize.height,
  );
}
