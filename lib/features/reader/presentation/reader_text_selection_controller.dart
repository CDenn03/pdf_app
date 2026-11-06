import 'package:flutter/foundation.dart';

import 'package:sefer/features/reader/domain/reader_text_selection.dart';

/// The single text selection of the paged reader: at most one page at a time.
class ReaderTextSelectionController extends ChangeNotifier {
  int? _pageNumber;
  ReaderTextSelection? _selection;

  /// True while a selection or handle drag is under the finger, so the page
  /// gallery must not scroll.
  final ValueNotifier<bool> dragging = ValueNotifier(false);

  ReaderTextSelection? selectionOn(int pageNumber) =>
      _pageNumber == pageNumber ? _selection : null;

  void select(int pageNumber, ReaderTextSelection selection) {
    if (_pageNumber == pageNumber && _selection == selection) return;
    _pageNumber = pageNumber;
    _selection = selection;
    notifyListeners();
  }

  /// Returns whether there was a selection to clear.
  bool clear() {
    final hadSelection = _selection != null;
    _pageNumber = null;
    _selection = null;
    dragging.value = false;
    if (hadSelection) notifyListeners();
    return hadSelection;
  }

  @override
  void dispose() {
    dragging.dispose();
    super.dispose();
  }
}
