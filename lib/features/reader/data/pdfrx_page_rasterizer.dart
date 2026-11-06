import 'dart:ui' as ui;

import 'package:pdfrx/pdfrx.dart';

import 'package:sefer/features/reader/data/page_rasterizer.dart';

class PdfrxPageRasterizer implements PageRasterizer {
  PdfrxPageRasterizer({required PdfDocument document}) : _document = document;

  final PdfDocument _document;

  @override
  Future<ui.Image?> render(
    int pageNumber,
    ui.Size pixelSize, {
    required PageRenderCancellation cancellation,
  }) async {
    final page = _document.pages[pageNumber - 1];
    final token = page.createCancellationToken();
    cancellation.whenCancelled(token.cancel);
    final raster = await page.render(
      fullWidth: pixelSize.width,
      fullHeight: pixelSize.height,
      cancellationToken: token,
    );
    if (raster == null) return null;
    try {
      return await raster.createImage();
    } finally {
      raster.dispose();
    }
  }
}
