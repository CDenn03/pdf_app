import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/models/annotation.dart';
import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/features/reader/state/annotation_notifier.dart';
import 'package:pdf_app/features/reader/state/reader_notifier.dart';
import 'package:pdf_app/features/reader/state/reader_state.dart';

// Re-export core providers so existing imports of this file keep working.
export 'package:pdf_app/core/providers.dart';

// --- Simple value providers ---

/// The currently selected annotation color. Persists within a session.
final activeAnnotationColorProvider =
    NotifierProvider<_ValueNotifier<AnnotationColor>, AnnotationColor>(
      () => _ValueNotifier(AnnotationColor.yellow),
    );

/// Whether there is an annotation that can be undone.
final canUndoAnnotationProvider = NotifierProvider<_ValueNotifier<bool>, bool>(
  () => _ValueNotifier(false),
);

// --- Notifier providers ---

/// Provider for reader state (page, zoom, pdf info).
/// Separate from annotation state to prevent rebuild storms.
final readerNotifierProvider = NotifierProvider<ReaderNotifier, ReaderState>(
  ReaderNotifier.new,
);

/// Provider for annotation state.
/// Only loads annotations for currentPage ± 1.
final annotationNotifierProvider =
    NotifierProvider<AnnotationNotifier, List<Annotation>>(
      AnnotationNotifier.new,
    );

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

/// A minimal [Notifier] that holds a single mutable value.
///
/// Replaces [StateProvider] which was removed in Riverpod 3.
class _ValueNotifier<T> extends Notifier<T> {
  _ValueNotifier(this._initial);

  final T _initial;

  @override
  T build() => _initial;

  // ignore: use_setters_to_change_properties
  void setValue(T value) => state = value;
}
