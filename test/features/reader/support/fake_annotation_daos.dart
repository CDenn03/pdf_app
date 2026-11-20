import 'dart:async';

import 'package:flutter_test/flutter_test.dart' show Fake;

import 'package:sefer/core/database/annotation_dao.dart';
import 'package:sefer/core/database/note_entry_dao.dart';
import 'package:sefer/core/models/annotation.dart';
import 'package:sefer/core/models/annotation_search.dart';

class FakeAnnotationDao extends Fake implements AnnotationDao {
  FakeAnnotationDao({this.stored = const [], this.noteTexts = const {}});

  final List<Annotation> stored;
  final Map<String, List<String>> noteTexts;
  final List<Completer<List<Annotation>>> pendingRangeReads = [];
  final List<(int, int)> requestedRanges = [];
  bool deferRangeReads = false;

  @override
  Future<List<Annotation>> getAllForPdf(String pdfId) async => stored;

  @override
  Future<List<AnnotationSearchRow>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final rows = <AnnotationSearchRow>[];
    for (final annotation in stored) {
      if (annotation.isDeleted) continue;
      String? matchingNote;
      for (final text in noteTexts[annotation.id] ?? const <String>[]) {
        if (text.toLowerCase().contains(q)) {
          matchingNote = text;
          break;
        }
      }
      final snippet = snippetForAnnotation(
        annotation,
        query,
        noteText: matchingNote,
      );
      if (!snippet.toLowerCase().contains(q)) continue;
      rows.add(
        AnnotationSearchRow(
          annotation: annotation,
          snippet: compactSnippet(snippet),
        ),
      );
    }
    return rows;
  }

  @override
  Future<List<Annotation>> getByPdfAndPageRange(
    String pdfId,
    int startPage,
    int endPage,
  ) {
    requestedRanges.add((startPage, endPage));
    if (deferRangeReads) {
      final read = Completer<List<Annotation>>();
      pendingRangeReads.add(read);
      return read.future;
    }
    return Future.value([
      for (final a in stored)
        if (a.page >= startPage && a.page <= endPage) a,
    ]);
  }
}

class FakeNoteEntryDao extends Fake implements NoteEntryDao {}
