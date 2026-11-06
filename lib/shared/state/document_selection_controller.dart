import 'package:flutter/foundation.dart';

class DocumentSelectionController extends ChangeNotifier {
  final Set<String> _selectedPaths = {};

  Set<String> get selectedPaths => Set.unmodifiable(_selectedPaths);

  bool get isSelecting => _selectedPaths.isNotEmpty;

  bool isSelected(String path) => _selectedPaths.contains(path);

  void select(String path) {
    if (_selectedPaths.add(path)) notifyListeners();
  }

  void toggle(String path) {
    if (!_selectedPaths.remove(path)) _selectedPaths.add(path);
    notifyListeners();
  }

  void selectVisible(Iterable<String> visiblePaths) {
    final before = _selectedPaths.length;
    _selectedPaths.addAll(visiblePaths);
    if (_selectedPaths.length != before) notifyListeners();
  }

  void retainExisting(Iterable<String> existingPaths) {
    final before = _selectedPaths.length;
    _selectedPaths.retainAll(existingPaths.toSet());
    if (_selectedPaths.length != before) notifyListeners();
  }

  void clear() {
    if (_selectedPaths.isEmpty) return;
    _selectedPaths.clear();
    notifyListeners();
  }
}
