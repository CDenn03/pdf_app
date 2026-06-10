import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/core/models/annotation.dart';
import 'package:sefer/features/reader/state/annotation_notifier.dart';
import 'package:sefer/features/reader/state/reader_notifier.dart';
import 'package:sefer/features/reader/state/reader_state.dart';

// Re-export core providers (includes activeAnnotationColorProvider,
// canUndoAnnotationProvider, appSettingsServiceProvider, etc.)
export 'package:sefer/core/providers.dart';

/// Provider for reader state (page, zoom, pdf info).
///
/// autoDispose ensures state and the annotation map are released when the
/// reader screen is popped, preventing memory accumulation across sessions (#6).
final readerNotifierProvider =
    NotifierProvider.autoDispose<ReaderNotifier, ReaderState>(
  ReaderNotifier.new,
);

/// Provider for annotation state, page-indexed.
/// Use [AnnotationNotifier.annotationsForPage] to read a single page.
final annotationNotifierProvider =
    NotifierProvider.autoDispose<AnnotationNotifier, Map<int, List<Annotation>>>(
  AnnotationNotifier.new,
);
