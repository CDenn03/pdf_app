import 'dart:developer' as developer;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'package:sefer/features/reader/data/book_page_image_repository.dart';
import 'package:sefer/features/reader/presentation/reader_page_cell.dart';

/// The bounded set of page images a turn needs: the current page and its
/// neighbours. Only images it still holds are ever handed out, so a caller
/// never paints one the repository has disposed.
class BookPageImages extends ChangeNotifier {
  BookPageImages({
    required BookPageImageRepository repository,
    required int totalPages,
    required Size Function(int pageNumber) pageSizeOf,
  }) : _repository = repository,
       _totalPages = totalPages,
       _pageSizeOf = pageSizeOf;

  final BookPageImageRepository _repository;
  final int _totalPages;
  final Size Function(int pageNumber) _pageSizeOf;
  final Map<int, ui.Image> _images = {};
  final Map<int, Size> _requested = {};
  bool _disposed = false;

  ui.Image? imageOf(int pageNumber) => _images[pageNumber];

  void prepare({
    required int page,
    required Size viewport,
    required double devicePixelRatio,
  }) {
    final window = {
      for (var p = page - 1; p <= page + 1; p++)
        if (p >= 1 && p <= _totalPages) p,
    };
    _repository.retain(window);
    _images.removeWhere((p, _) => !window.contains(p));
    _requested.removeWhere((p, _) => !window.contains(p));
    for (final p in window) {
      final rect = ReaderPageCell.rectIn(viewport, _pageSizeOf(p), p);
      final size = rect.size * devicePixelRatio;
      if (size.isEmpty || _requested[p] == size) continue;
      _images.remove(p);
      _requested[p] = size;
      _load(p, size);
    }
  }

  Future<void> _load(int pageNumber, Size size) async {
    final image = await _repository.imageFor(pageNumber, size);
    if (_disposed || _requested[pageNumber] != size) return;
    if (image == null) return _logMissing(pageNumber);
    _images[pageNumber] = image;
    notifyListeners();
  }

  void _logMissing(int pageNumber) => developer.log(
    'No image for page $pageNumber; turns fall back to a rotation',
    name: 'sefer.reader',
  );

  @override
  void dispose() {
    _disposed = true;
    _images.clear();
    _repository.dispose();
    super.dispose();
  }
}
