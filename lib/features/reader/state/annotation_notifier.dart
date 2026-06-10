import 'dart:developer' as developer;
import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sefer/core/constants.dart';
import 'package:sefer/core/database/annotation_dao.dart';
import 'package:sefer/core/database/note_entry_dao.dart';
import 'package:sefer/core/models/annotation.dart';
import 'package:sefer/core/models/annotation_color.dart';
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/core/models/note_entry.dart';
import 'package:sefer/core/models/relative_rect_model.dart';
import 'package:sefer/core/providers.dart';

/// Manages annotation state for the currently viewed PDF.
///
/// State is page-indexed so overlays for page N only rebuild when page N
/// changes. Use [annotationsForPage] to read a single page's annotations.
///
/// Loads annotations for a window of pages around the current page.
/// In continuous mode callers pass a larger [window] to cover all visible pages.
class AnnotationNotifier
    extends Notifier<Map<int, List<Annotation>>> {
  late final AnnotationDao _dao;
  late final NoteEntryDao _noteEntryDao;

  String _currentPdfId = '';
  final _undoStack = <String>[];
  static const _maxUndoDepth = 20;

  bool get canUndo => _undoStack.isNotEmpty;

  @override
  Map<int, List<Annotation>> build() {
    _dao = ref.read(annotationDaoProvider);
    _noteEntryDao = ref.read(noteEntryDaoProvider);
    return {};
  }

  /// Loads annotations for [page] ± [window] of the given [pdfId].
  Future<void> loadForPage(String pdfId, int page, {int window = 1}) async {
    if (pdfId != _currentPdfId) {
      _undoStack.clear();
      _syncCanUndo();
    }
    _currentPdfId = pdfId;

    final startPage = max(1, page - window);
    final endPage = page + window;

    final list = await _dao.getByPdfAndPageRange(pdfId, startPage, endPage);
    state = _mergeIntoState(state, list, startPage, endPage);
  }

  /// Loads ALL non-deleted annotations for [pdfId] — used by the panel.
  Future<List<Annotation>> loadAllForPdf(String pdfId) =>
      _dao.getAllForPdf(pdfId);

  /// Creates a new highlight annotation from one or more word-snapped rects.
  void addHighlight({
    required List<RelativeRectModel> rects,
    required int page,
    required String pdfId,
    AnnotationColor color = AnnotationColor.yellow,
    String? selectedText,
    String? pdfFingerprint,
  }) {
    _addAnnotation(
      _build(
        pdfId: pdfId,
        page: page,
        type: AnnotationType.highlight,
        rects: rects,
        color: color,
        selectedText: selectedText,
        pdfFingerprint: pdfFingerprint,
      ),
    );
  }

  /// Creates a new note annotation marker on the page edge.
  ///
  /// [edgePosition] encodes the marker position: [RelativeRectModel.left] is
  /// `0.0` for the left edge or `1.0` for the right edge; [RelativeRectModel.top]
  /// is the vertical fraction of the tap (0–1).
  /// The initial note text is stored as the first [NoteEntry].
  Future<void> addNote({
    required RelativeRectModel edgePosition,
    required String initialText,
    required int page,
    required String pdfId,
    AnnotationColor color = AnnotationColor.yellow,
  }) async {
    final annotation = _build(
      pdfId: pdfId,
      page: page,
      type: AnnotationType.note,
      rects: [edgePosition],
      color: color,
    );
    // Add to in-memory state immediately, then persist both the annotation
    // and the initial entry in order — entry has a FK on the annotation row.
    final page0 = annotation.page;
    state = {
      ...state,
      page0: [...(state[page0] ?? []), annotation],
    };
    _undoStack.add(annotation.id);
    if (_undoStack.length > _maxUndoDepth) _undoStack.removeAt(0);
    _syncCanUndo();

    // Persist annotation first, then the note entry so the FK is satisfied.
    await _saveAsync(annotation);
    developer.log(
      'addNote: saved annotation id=${annotation.id} pdfId=${annotation.pdfId} page=${annotation.page}',
      name: 'sefer.annotation',
    );
    await _saveNoteEntry(
      NoteEntry(
        id: uuid.v4(),
        annotationId: annotation.id,
        text: initialText,
        createdAt: DateTime.now(),
      ),
      annotation.id,
    );
  }

  Future<void> _saveNoteEntry(NoteEntry entry, String annotationId) async {
    try {
      await _noteEntryDao.insert(entry);
    } catch (e, s) {
      developer.log(
        'Failed to save note entry for $annotationId',
        name: 'sefer.annotation',
        level: 1000,
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Adds a new timestamped entry to an existing note annotation.
  Future<void> addNoteEntry(String annotationId, String text) async {
    await _noteEntryDao.insert(
      NoteEntry(
        id: uuid.v4(),
        annotationId: annotationId,
        text: text,
        createdAt: DateTime.now(),
      ),
    );
  }

  /// Returns all [NoteEntry]s for [annotationId], oldest first.
  Future<List<NoteEntry>> loadNoteEntries(String annotationId) =>
      _noteEntryDao.getForAnnotation(annotationId);

  /// Creates a new bookmark annotation (no rects).
  void addBookmark({
    required int page,
    required String pdfId,
    String? label,
    AnnotationColor color = AnnotationColor.yellow,
  }) {
    _addAnnotation(
      _build(
        pdfId: pdfId,
        page: page,
        type: AnnotationType.bookmark,
        label: label ?? 'Page $page',
        color: color,
      ),
    );
  }

  /// Soft-deletes an annotation.
  Future<void> removeAnnotation(String id) async {
    state = _removeFromState(state, id);
    _undoStack.remove(id);
    _syncCanUndo();
    await _dao.softDelete(id);
  }

  /// Undoes the most recently added annotation.
  Future<String?> undo() async {
    if (_undoStack.isEmpty) return null;

    final id = _undoStack.removeLast();
    _syncCanUndo();

    Annotation? annotation;
    for (final list in state.values) {
      for (final a in list) {
        if (a.id == id) {
          annotation = a;
          break;
        }
      }
      if (annotation != null) break;
    }
    if (annotation == null) return null;

    state = _removeFromState(state, id);
    await _dao.softDelete(id);

    return switch (annotation.type) {
      AnnotationType.highlight => 'Highlight removed',
      AnnotationType.note => 'Note removed',
      AnnotationType.bookmark => 'Bookmark removed',
    };
  }

  /// Updates an existing note annotation's text.
  void updateNoteText(String id, String newText) {
    _mutateAnnotation(id, (a) => a.copyWith(text: newText));
  }

  /// Updates an existing annotation's color.
  void updateColor(String id, AnnotationColor color) {
    _mutateAnnotation(id, (a) => a.copyWith(color: color));
  }

  /// Returns non-deleted annotations for a single [page].
  List<Annotation> annotationsForPage(int page) =>
      (state[page] ?? []).where((a) => !a.isDeleted).toList();

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Annotation _build({
    required int page,
    required String pdfId,
    required AnnotationType type,
    List<RelativeRectModel> rects = const [],
    String? selectedText,
    String? text,
    String? label,
    AnnotationColor color = AnnotationColor.yellow,
    String? pdfFingerprint,
  }) {
    final now = DateTime.now();
    return Annotation(
      id: uuid.v4(),
      pdfId: pdfId,
      page: page,
      type: type,
      rects: rects,
      selectedText: selectedText,
      text: text,
      label: label,
      color: color,
      pdfFingerprint: pdfFingerprint,
      createdAt: now,
      updatedAt: now,
    );
  }

  void _addAnnotation(Annotation annotation) {
    final page = annotation.page;
    state = {
      ...state,
      page: [...(state[page] ?? []), annotation],
    };
    _undoStack.add(annotation.id);
    if (_undoStack.length > _maxUndoDepth) _undoStack.removeAt(0);
    _syncCanUndo();
    unawaited(_saveAsync(annotation));
  }

  Map<int, List<Annotation>> _removeFromState(
    Map<int, List<Annotation>> current,
    String id,
  ) {
    return {
      for (final entry in current.entries)
        entry.key: entry.value.where((a) => a.id != id).toList(),
    };
  }

  /// Replaces loaded page range while preserving pages outside the window.
  ///
  /// Evicts pages more than 10 pages outside the current range to prevent the
  /// state map growing without bound on long scrolling sessions (#7).
  Map<int, List<Annotation>> _mergeIntoState(
    Map<int, List<Annotation>> current,
    List<Annotation> loaded,
    int startPage,
    int endPage,
  ) {
    final byPage = <int, List<Annotation>>{};
    for (final a in loaded) {
      (byPage[a.page] ??= []).add(a);
    }
    const evictionPadding = 10;
    final keepStart = startPage - evictionPadding;
    final keepEnd = endPage + evictionPadding;
    // Evict pages outside the keep window; update the loaded range.
    return {
      for (final e in current.entries)
        if (e.key >= keepStart && e.key <= keepEnd) e.key: e.value,
      for (var p = startPage; p <= endPage; p++) p: byPage[p] ?? [],
    };
  }

  void _mutateAnnotation(String id, Annotation Function(Annotation) mutate) {
    state = {
      for (final entry in state.entries)
        entry.key: entry.value.map((a) {
          if (a.id != id) return a;
          final updated = mutate(a);
          unawaited(_saveAsync(updated));
          return updated;
        }).toList(),
    };
  }

  void _syncCanUndo() {
    ref.read(canUndoAnnotationProvider.notifier).setValue(canUndo);
  }

  // Declared Future<void> so errors propagate; called with unawaited() to
  // make the fire-and-forget intent explicit and avoid mixed async styles (#23).
  Future<void> _saveAsync(Annotation annotation) async {
    try {
      await _dao.upsert(annotation);
    } catch (e, s) {
      developer.log(
        'Failed to save annotation ${annotation.id}',
        name: 'sefer.annotation',
        level: 1000,
        error: e,
        stackTrace: s,
      );
    }
  }
}
