import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/constants.dart';
import 'package:pdf_app/core/database/annotation_dao.dart';
import 'package:pdf_app/core/database/note_entry_dao.dart';
import 'package:pdf_app/core/models/annotation.dart';
import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/core/models/annotation_type.dart';
import 'package:pdf_app/core/models/note_entry.dart';
import 'package:pdf_app/core/models/relative_rect_model.dart';
import 'package:pdf_app/core/providers.dart';

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
    AnnotationColor color = AnnotationColor.yellow,
    String? selectedText,
    String? pdfFingerprint,
  }) {
    _addAnnotation(
      _build(
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
  void addNote({
    required RelativeRectModel edgePosition,
    required String initialText,
    required int page,
    AnnotationColor color = AnnotationColor.yellow,
  }) {
    final annotation = _build(
      page: page,
      type: AnnotationType.note,
      rects: [edgePosition],
      color: color,
    );
    _addAnnotation(annotation);
    final entry = NoteEntry(
      id: uuid.v4(),
      annotationId: annotation.id,
      text: initialText,
      createdAt: DateTime.now(),
    );
    _noteEntryDao.insert(entry).catchError((Object e, StackTrace s) {
      developer.log(
        'Failed to save note entry for ${annotation.id}',
        name: 'pdf_app.annotation',
        level: 1000,
        error: e,
        stackTrace: s,
      );
    });
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
  void addBookmark({required int page, String? label}) {
    _addAnnotation(
      _build(
        page: page,
        type: AnnotationType.bookmark,
        label: label ?? 'Page $page',
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
      pdfId: _currentPdfId,
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
    _saveAsync(annotation);
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
    final updated = Map<int, List<Annotation>>.from(current);
    for (var p = startPage; p <= endPage; p++) {
      updated[p] = byPage[p] ?? [];
    }
    return updated;
  }

  void _mutateAnnotation(String id, Annotation Function(Annotation) mutate) {
    state = {
      for (final entry in state.entries)
        entry.key: entry.value.map((a) {
          if (a.id != id) return a;
          final updated = mutate(a);
          _saveAsync(updated);
          return updated;
        }).toList(),
    };
  }

  void _syncCanUndo() {
    ref.read(canUndoAnnotationProvider.notifier).setValue(canUndo);
  }

  void _saveAsync(Annotation annotation) {
    _dao.upsert(annotation).catchError((Object e, StackTrace s) {
      developer.log(
        'Failed to save annotation ${annotation.id}',
        name: 'pdf_app.annotation',
        level: 1000,
        error: e,
        stackTrace: s,
      );
    });
  }
}
