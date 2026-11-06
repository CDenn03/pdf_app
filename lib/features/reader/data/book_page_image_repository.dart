import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:sefer/features/reader/data/page_rasterizer.dart';

class BookPageImageRepository {
  BookPageImageRepository({
    required PageRasterizer rasterizer,
    this.maxTextureDimension = 2048,
  }) : _rasterizer = rasterizer;

  final PageRasterizer _rasterizer;
  final double maxTextureDimension;
  final Map<int, _PageRender> _renders = {};
  bool _disposed = false;

  Future<ui.Image?> imageFor(int pageNumber, ui.Size pixelSize) {
    if (_disposed) return Future.value();
    final target = _clamped(pixelSize);
    final existing = _renders[pageNumber];
    if (existing != null && existing.size != target) {
      existing.discard();
      _renders.remove(pageNumber);
    }
    final render = _renders[pageNumber] ??= _start(pageNumber, target);
    return render.result;
  }

  void retain(Set<int> pages) {
    final obsolete = _renders.keys.where((page) => !pages.contains(page));
    for (final page in obsolete.toList()) {
      _renders.remove(page)?.discard();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _discardAll();
  }

  ui.Size _clamped(ui.Size size) {
    final longest = math.max(size.width, size.height);
    final scale = longest > maxTextureDimension
        ? maxTextureDimension / longest
        : 1.0;
    return ui.Size(
      math.max(1, (size.width * scale).roundToDouble()),
      math.max(1, (size.height * scale).roundToDouble()),
    );
  }

  void _discardAll() {
    for (final render in _renders.values) {
      render.discard();
    }
    _renders.clear();
  }

  _PageRender _start(int pageNumber, ui.Size size) {
    final render = _PageRender(size);
    render.result = _run(pageNumber, size, render);
    return render;
  }

  Future<ui.Image?> _run(
    int pageNumber,
    ui.Size size,
    _PageRender render,
  ) async {
    try {
      final image = await _rasterizer.render(
        pageNumber,
        size,
        cancellation: render.cancellation,
      );
      if (image == null) {
        _forget(pageNumber, render);
        return null;
      }
      if (render.discarded) {
        image.dispose();
        return null;
      }
      render.image = image;
      return image;
    } catch (error, stackTrace) {
      _forget(pageNumber, render);
      if (!render.discarded) {
        developer.log(
          'Page $pageNumber render failed',
          name: 'sefer.reader',
          level: 1000,
          error: error,
          stackTrace: stackTrace,
        );
      }
      return null;
    }
  }

  void _forget(int pageNumber, _PageRender render) {
    if (identical(_renders[pageNumber], render)) _renders.remove(pageNumber);
  }
}

class _PageRender {
  _PageRender(this.size);

  final ui.Size size;
  final PageRenderCancellation cancellation = PageRenderCancellation();
  late final Future<ui.Image?> result;
  ui.Image? image;
  bool discarded = false;

  void discard() {
    discarded = true;
    cancellation.cancel();
    image?.dispose();
    image = null;
  }
}
