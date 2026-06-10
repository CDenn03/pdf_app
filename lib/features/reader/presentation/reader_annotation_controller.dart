import 'package:flutter/foundation.dart';

import 'package:sefer/features/reader/presentation/annotation_toolbar.dart';

/// Owns annotation mode state and active tool selection (#24).
class ReaderAnnotationController {
  ReaderAnnotationController({
    required this.onEnter,
    required this.onExit,
    required this.onStateChanged,
  });

  final VoidCallback onEnter;
  final VoidCallback onExit;
  final VoidCallback onStateChanged;

  bool annotating = false;
  AnnotationTool activeTool = AnnotationTool.highlight;

  void enter() {
    annotating = true;
    activeTool = AnnotationTool.highlight;
    onStateChanged();
    onEnter();
  }

  void exit() {
    annotating = false;
    onStateChanged();
    onExit();
  }

  void setTool(AnnotationTool tool) {
    activeTool = tool;
    onStateChanged();
  }
}
