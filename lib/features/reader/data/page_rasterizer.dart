import 'dart:ui' as ui;

class PageRenderCancellation {
  final List<void Function()> _listeners = [];
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in _listeners) {
      listener();
    }
    _listeners.clear();
  }

  void whenCancelled(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }
}

abstract interface class PageRasterizer {
  Future<ui.Image?> render(
    int pageNumber,
    ui.Size pixelSize, {
    required PageRenderCancellation cancellation,
  });
}
