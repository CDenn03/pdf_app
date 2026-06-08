import 'dart:async';

import 'package:flutter/foundation.dart';

/// Owns the top/bottom bar visibility and auto-hide timer logic (#24).
///
/// Callers must call [dispose] when the page is removed from the tree.
class ReaderBarController {
  ReaderBarController({required this.onStateChanged});

  final VoidCallback onStateChanged;

  bool barsVisible = true;
  Timer? _autoHideTimer;

  void toggle({required bool annotating}) {
    if (annotating) return;
    barsVisible = !barsVisible;
    onStateChanged();
    if (barsVisible) {
      scheduleAutoHide();
    } else {
      _autoHideTimer?.cancel();
    }
  }

  void show({required bool annotating}) {
    if (annotating) return;
    barsVisible = true;
    onStateChanged();
    scheduleAutoHide();
  }

  void hide() {
    _autoHideTimer?.cancel();
    barsVisible = false;
    onStateChanged();
  }

  void scheduleAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 4), hide);
  }

  void dispose() {
    _autoHideTimer?.cancel();
  }
}
