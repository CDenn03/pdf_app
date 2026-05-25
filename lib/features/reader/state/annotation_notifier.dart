import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/constants.dart';
import 'package:pdf_app/core/database/annotation_dao.dart';
import 'package:pdf_app/core/models/annotation.dart';
import 'package:pdf_app/core/models/annotation_color.dart';
import 'package:pdf_app/core/models/annotation_type.dart';
import 'package:pdf_app/core/models/relative_rect_model.dart';
import 'package:pdf_app/core/providers.dart';

/// Manages annotation state for the currently viewed PDF.
///
/// Loads annotations for a window of pages around the current page.
/// In continuous mode callers pass a larger [window] to cover all visible pages.
///
/// Writes are immediate — no debounce — so rapid additions are never dropped.
/// The undo stack is capped at [_maxUndoDepth].
class AnnotationNotifier extends Notifier<List<Annotation>> {
  late final AnnotationDao _dao;

  String _currentPdfId = '';
  final _undoStack = <String>[];
  static const _maxUndoDepth = 20;

  bool get canUndo => _undoStack.isNotEmpty;

  @override
  List<Annotation> build() {
    _dao = ref.read(annotationDaoProvider);
    return [];
  }

  /// Loads annotations for [page] ± [window] of the given [pdfId].
  ///
  /// Pass [window] = 3 in continuous mode so all visible pages are covered.
  Future<void> loadForPage(String pdfId, int page, {int window = 1}) async {
    if (pdfId != _currentPdfId) {
      _undoStack.clear();
      _syncCanUndo();
    }
    _currentPdfId = pdfId;

    final startPage = max(1, page - window);
    final endPage = page + window;

    final annotations = await _dao.getByPdfAndPageRange(pdfId, startPage, endPage);
    state = annotations;
  }

  /// Loads ALL non-deleted annotations for [pdfId] — used by the panel.
  Future<List<Annotation>> loadAllForPdf(String pdfId) async {
    return _dao.getAllForPdf(pdfId);
  }

  /// Creates a new highlight annotation.
  ///
  /// [selectedText] is the verbatim text extracted from the PDF at the
  /// highlighted region, used for text-anchoring across zoom changes.
  void addHighlight({
    required RelativeRectModel rect,
    required int page,
    AnnotationColor color = AnnotationColor.yellow,
    String? selectedText,
  }) {
    _addAnnotation(
      _buildAnnotation(
        page: page,
        type: AnnotationType.highlight,
        rect: rect,
        color: color,
        selectedText: selectedText,
      ),
    );
  }

  /// Creates a new note annotation.
  void addNote({
    required RelativeRectModel rect,
    required String text,
    required int page,
    AnnotationColor color = AnnotationColor.yellow,
    String? selectedText,
  }) {
    _addAnnotation(
      _buildAnnotation(
        page: page,
        type: AnnotationType.note,
        rect: rect,
        text: text,
        color: color,
        selectedText: selectedText,
      ),
    );
  }

  /// Creates a new bookmark annotation (no rect).
  void addBookmark({required int page, String? label}) {
    _addAnnotation(
      _buildAnnotation(
        page: page,
        type: AnnotationType.bookmark,
        label: label ?? 'Page $page',
      ),
    );
  }

  /// Soft-deletes an annotation.
  Future<void> removeAnnotation(String id) async {
    state = state.where((a) => a.id != id).toList();
    _undoStack.remove(id);
    _syncCanUndo();
    await _dao.softDelete(id);
  }

  /// Undoes the most recently added annotation.
  ///
  /// Returns a human-readable description of what was undone, or null if
  /// there is nothing to undo.
  Future<String?> undo() async {
    if (_undoStack.isEmpty) return null;

    final id = _undoStack.removeLast();
    _syncCanUndo();

    final annotation = state.firstWhere(
      (a) => a.id == id,
      orElse: () => const Annotation(
        id: '',
        pdfId: '',
        page: 0,
        type: AnnotationType.highlight,
      ),
    );
    if (annotation.id.isEmpty) return null;

    state = state.where((a) => a.id != id).toList();
    await _dao.softDelete(id);

    return switch (annotation.type) {
      AnnotationType.highlight => 'Highlight removed',
      AnnotationType.note => 'Note removed',
      AnnotationType.bookmark => 'Bookmark removed',
    };
  }

  /// Updates an existing note annotation's text.
  void updateNoteText(String id, String newText) {
    state = state.map((a) {
      if (a.id != id) return a;
      final updated = a.copyWith(text: newText);
      _saveAsync(updated);
      return updated;
    }).toList();
  }

  /// Updates an existing annotation's color.
  void updateColor(String id, AnnotationColor color) {
    state = state.map((a) {
      if (a.id != id) return a;
      final updated = a.copyWith(color: color);
      _saveAsync(updated);
      return updated;
    }).toList();
  }

  /// Returns annotations filtered to a specific [page], excluding deleted ones.
  List<Annotation> annotationsForPage(int page) =>
      state.where((a) => a.page == page && !a.isDeleted).toList();

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  Annotation _buildAnnotation({
    required int page,
    required AnnotationType type,
    RelativeRectModel? rect,
    String? selectedText,
    String? text,
    String? label,
    AnnotationColor color = AnnotationColor.yellow,
  }) {
    final now = DateTime.now();
    return Annotation(
      id: uuid.v4(),
      pdfId: _currentPdfId,
      page: page,
      type: type,
      rect: rect,
      selectedText: selectedText,
      text: text,
      label: label,
      color: color,
      coordinateVersion: 2,
      createdAt: now,
      updatedAt: now,
    );
  }

  void _addAnnotation(Annotation annotation) {
    state = [...state, annotation];
    _undoStack.add(annotation.id);
    if (_undoStack.length > _maxUndoDepth) _undoStack.removeAt(0);
    _syncCanUndo();
    _saveAsync(annotation);
  }

  /// Pushes the current [canUndo] state into [canUndoAnnotationProvider] so
  /// the toolbar undo button reflects reality.
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
