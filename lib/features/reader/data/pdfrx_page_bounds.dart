import 'package:flutter/painting.dart';
import 'package:pdfrx/pdfrx.dart';

Rect normalizePageBounds(PdfRect bounds, PdfPage page) {
  final pageSize = Size(page.width, page.height);
  final upright = bounds.toRect(page: page, scaledPageSize: pageSize);
  return Rect.fromLTRB(
    upright.left / pageSize.width,
    upright.top / pageSize.height,
    upright.right / pageSize.width,
    upright.bottom / pageSize.height,
  );
}

PdfRect pageBoundsFromNormalized(Rect normalized, PdfPage page) {
  final pageSize = Size(page.width, page.height);
  return Rect.fromLTRB(
    normalized.left * pageSize.width,
    normalized.top * pageSize.height,
    normalized.right * pageSize.width,
    normalized.bottom * pageSize.height,
  ).toPdfRect(page: page);
}
