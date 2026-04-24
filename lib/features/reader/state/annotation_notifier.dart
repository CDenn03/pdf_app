import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pdf_app/core/constants.dart';
import 'package:pdf_app/core/database/annotation_dao.dart';
import 'package:pdf_app/core/models/annotation.dart';
import 'package:pdf_app/core/models/annotation_type.dart';
import 'package:pdf_app/core/models/relative_rect_model.dart';
import 'package:pdf_app/core/utils/debounce.dart';

/// Manages annotation state for the currently viewed PDF.
///
/// Only loads annotations for `currentPage ± 1` — never the full document set.
/// All writes are debounced by 300ms per architecture spec.
class AnnotationNotifier extends StateNotifier<List<Annotation>> {
  final AnnotationDao _dao;
  final Debounce _debounce;

  String _currentPdfId = '';

  AnnotationNotifier({required AnnotationDao dao, required Debounce debounce})
    : _dao = dao,
      _debounce = debounce,
      super([]);

  /// Loads annotations for [page] ± 1 of the given [pdfId].
  ///
  /// Only renders annotations for currentPage ± 1 per architecture spec.
  Future<void> loadForPage(String pdfId, int page) async {
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

  /// Creates a new highlight annotation with a debounced save.
  void addHighlight({required RelativeRectModel rect, required int page}) {
    _addAnnotation(
      _buildAnnotation(page: page, type: AnnotationType.highlight, rect: rect),
    );
  }

  /// Creates a new note annotation with a debounced save.
  void addNote({
    required RelativeRectModel rect,
    required String text,
    required int page,
  }) {
    _addAnnotation(
      _buildAnnotation(
        page: page,
        type: AnnotationType.note,
        rect: rect,
        text: text,
      ),
    );
  }

  /// Creates a new bookmark annotation (no rect) with a debounced save.
  void addBookmark({required int page}) {
    _addAnnotation(_buildAnnotation(page: page, type: AnnotationType.bookmark));
  }

  /// Soft-deletes an annotation. Never hard-deletes per architecture spec.
  Future<void> removeAnnotation(String id) async {
    state = state.where((a) => a.id != id).toList();
    await _dao.softDelete(id);
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

  /// Returns annotations filtered to a specific [page].
  List<Annotation> annotationsForPage(int page) {
    return state.where((a) => a.page == page && !a.isDeleted).toList();
  }

  Annotation _buildAnnotation({
    required int page,
    required AnnotationType type,
    RelativeRectModel? rect,
    String? text,
  }) => Annotation(
    id: uuid.v4(),
    pdfId: _currentPdfId,
    page: page,
    type: type,
    rect: rect,
    text: text,
  );

  void _addAnnotation(Annotation annotation) {
    state = [...state, annotation];
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

  @override
  void dispose() {
    _debounce.dispose();
    super.dispose();
  }
}
