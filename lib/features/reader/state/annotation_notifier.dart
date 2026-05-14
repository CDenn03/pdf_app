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
import 'package:pdf_app/core/utils/debounce.dart';

/// Manages annotation state for the currently viewed PDF.
///
/// Only loads annotations for `currentPage ± 1` — never the full document set.
/// All writes are debounced by 300ms per architecture spec.
///
/// Maintains an undo stack of recently added annotation IDs so the user
/// can reverse accidental highlights or notes without opening the panel.
class AnnotationNotifier extends Notifier<List<Annotation>> {
  late final AnnotationDao _dao;
  late final Debounce _debounce;

  String _currentPdfId = '';
  final _undoStack = <String>[];
  static const _maxUndoDepth = 20;

  bool get canUndo => _undoStack.isNotEmpty;

  @override
  List<Annotation> build() {
    _dao = ref.read(annotationDaoProvider);
    _debounce = Debounce();
    ref.onDispose(_debounce.dispose);
    return [];
  }

  /// Loads annotations for [page] ± 1 of the given [pdfId].
  Future<void> loadForPage(String pdfId, int page) async {
    if (pdfId != _currentPdfId) {
      _undoStack.clear();
    }
    _currentPdfId = pdfId;

    final startPage = max(1, page - 1);
    final endPage = page + 1;

    final annotations = await _dao.getByPdfAndPageRange(
      pdfId,
      startPage,
      endPage,
    );
    state = annotations;
  }

  /// Loads ALL non-deleted annotations for [pdfId] — used by the panel.
  Future<List<Annotation>> loadAllForPdf(String pdfId) async {
    return _dao.getAllForPdf(pdfId);
  }

  /// Creates a new highlight annotation with a debounced save.
  void addHighlight({
    required RelativeRectModel rect,
    required int page,
    AnnotationColor color = AnnotationColor.yellow,
  }) {
    _addAnnotation(
      _buildAnnotation(
        page: page,
        type: AnnotationType.highlight,
        rect: rect,
        color: color,
      ),
    );
  }

  /// Creates a new note annotation with a debounced save.
  void addNote({
    required RelativeRectModel rect,
    required String text,
    required int page,
    AnnotationColor color = AnnotationColor.yellow,
  }) {
    _addAnnotation(
      _buildAnnotation(
        page: page,
        type: AnnotationType.note,
        rect: rect,
        text: text,
        color: color,
      ),
    );
  }

  /// Creates a new bookmark annotation (no rect) with a debounced save.
  ///
  /// [label] is an optional user-defined name shown in the annotations panel.
  /// Defaults to "Page N" if not provided.
  void addBookmark({required int page, String? label}) {
    _addAnnotation(
      _buildAnnotation(
        page: page,
        type: AnnotationType.bookmark,
        label: label ?? 'Page $page',
      ),
    );
  }

  /// Soft-deletes an annotation. Never hard-deletes per architecture spec.
  Future<void> removeAnnotation(String id) async {
    state = state.where((a) => a.id != id).toList();
    _undoStack.remove(id);
    await _dao.softDelete(id);
  }

  /// Undoes the most recently added annotation by soft-deleting it.
  ///
  /// Returns a description of what was undone, or null if nothing to undo.
  Future<String?> undo() async {
    if (_undoStack.isEmpty) return null;

    final id = _undoStack.removeLast();

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

  /// Updates an existing annotation's text (for notes).
  void updateNoteText(String id, String newText) {
    state = state.map((a) {
      if (a.id == id) {
        final updated = a.copyWith(text: newText);
        _debouncedSave(updated);
        return updated;
      }
      return a;
    }).toList();
  }

  /// Updates an existing annotation's color.
  void updateColor(String id, AnnotationColor color) {
    state = state.map((a) {
      if (a.id == id) {
        final updated = a.copyWith(color: color);
        _debouncedSave(updated);
        return updated;
      }
      return a;
    }).toList();
  }

  /// Returns annotations filtered to a specific [page].
  List<Annotation> annotationsForPage(int page) =>
      state.where((a) => a.page == page && !a.isDeleted).toList();

  Annotation _buildAnnotation({
    required int page,
    required AnnotationType type,
    RelativeRectModel? rect,
    String? text,
    String? label,
    AnnotationColor color = AnnotationColor.yellow,
  }) => Annotation(
    id: uuid.v4(),
    pdfId: _currentPdfId,
    page: page,
    type: type,
    rect: rect,
    text: text,
    label: label,
    color: color,
  );

  void _addAnnotation(Annotation annotation) {
    state = [...state, annotation];
    _undoStack.add(annotation.id);
    if (_undoStack.length > _maxUndoDepth) _undoStack.removeAt(0);
    _debouncedSave(annotation);
  }

  void _debouncedSave(Annotation annotation) {
    _debounce.run(() async {
      try {
        await _dao.upsert(annotation);
      } catch (e, s) {
        developer.log(
          'Failed to save annotation ${annotation.id}',
          name: 'pdf_app.annotation',
          level: 1000,
          error: e,
          stackTrace: s,
        );
      }
    });
  }
}
