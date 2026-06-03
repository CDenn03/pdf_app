import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/models/annotation.dart';
import 'package:pdf_app/features/reader/state/annotation_notifier.dart';
import 'package:pdf_app/features/reader/state/reader_notifier.dart';
import 'package:pdf_app/features/reader/state/reader_state.dart';

// Re-export core providers (includes activeAnnotationColorProvider,
// canUndoAnnotationProvider, appSettingsServiceProvider, etc.)
export 'package:pdf_app/core/providers.dart';

/// Provider for reader state (page, zoom, pdf info).
final readerNotifierProvider = NotifierProvider<ReaderNotifier, ReaderState>(
  ReaderNotifier.new,
);

/// Provider for annotation state, page-indexed.
/// Use [AnnotationNotifier.annotationsForPage] to read a single page.
final annotationNotifierProvider =
    NotifierProvider<AnnotationNotifier, Map<int, List<Annotation>>>(
      AnnotationNotifier.new,
    );
