import 'package:flutter/widgets.dart';

import 'package:sefer/features/reader/presentation/reader_document_controller.dart';
import 'package:sefer/features/reader/state/annotation_notifier.dart';
import 'package:sefer/features/reader/state/open_document_rename_coordinator.dart';
import 'package:sefer/features/reader/state/reader_notifier.dart';

class ReaderRenameHost implements OpenDocumentRenameHost {
  ReaderRenameHost({
    required this.readCurrentPage,
    required this.readerNotifier,
    required this.annotationNotifier,
    required this.documentController,
    required this.onCancelSearch,
    required this.onViewportSuspendedChanged,
  });

  final int Function() readCurrentPage;
  final ReaderNotifier readerNotifier;
  final AnnotationNotifier annotationNotifier;
  final ReaderDocumentController documentController;
  final VoidCallback onCancelSearch;
  final ValueChanged<bool> onViewportSuspendedChanged;

  @override
  int get currentPage => readCurrentPage();

  @override
  Future<void> flushProgress() => readerNotifier.flushProgress();

  @override
  Future<void> flushAnnotations() => annotationNotifier.flushWrites();

  @override
  void cancelSearch() => onCancelSearch();

  @override
  Future<void> suspendViewport() async {
    onViewportSuspendedChanged(true);
    documentController.releaseAuxiliaryDocument();
    await WidgetsBinding.instance.endOfFrame;
  }

  @override
  void resumeViewport() => onViewportSuspendedChanged(false);
}
