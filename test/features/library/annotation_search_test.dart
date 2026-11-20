import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/models/annotation.dart';
import 'package:sefer/core/models/annotation_search.dart';
import 'package:sefer/core/models/annotation_type.dart';
import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/features/library/domain/annotation_search.dart';
import 'package:sefer/features/library/state/library_entry.dart';

AnnotationSearchRow _row({
  required String id,
  required String pdfId,
  String snippet = 'matched text',
  int page = 1,
}) {
  return AnnotationSearchRow(
    annotation: Annotation(
      id: id,
      pdfId: pdfId,
      page: page,
      type: AnnotationType.highlight,
      selectedText: snippet,
    ),
    snippet: snippet,
  );
}

LibraryEntry _entry({
  required String path,
  required String name,
  Set<String> collectionIds = const {},
  bool favorite = false,
  FileStatus status = FileStatus.ok,
}) {
  return LibraryEntry(
    id: path,
    name: name,
    path: path,
    status: status,
    isFavorite: favorite,
    collectionIds: collectionIds,
  );
}

void main() {
  test('likeQueryPattern escapes LIKE wildcards', () {
    expect(likeQueryPattern('100%'), r'%100\%%');
    expect(likeQueryPattern('a_b'), r'%a\_b%');
  });

  test('snippetForAnnotation prefers selected text then notes', () {
    const annotation = Annotation(
      id: 'n',
      pdfId: '/a.pdf',
      page: 1,
      type: AnnotationType.note,
      selectedText: 'Highlighted token',
      text: 'body token',
    );
    expect(
      snippetForAnnotation(annotation, 'token', noteText: 'note token'),
      'Highlighted token',
    );
    expect(
      snippetForAnnotation(
        annotation.copyWith(selectedText: null, text: null),
        'token',
        noteText: 'note token',
      ),
      'note token',
    );
  });

  test('resolveAnnotationHits joins book names and collection filter', () {
    final rows = [
      _row(id: '1', pdfId: '/design.pdf', snippet: 'tokens', page: 4),
      _row(id: '2', pdfId: '/habits.pdf', snippet: 'tokens', page: 2),
      _row(id: '3', pdfId: '/loose.pdf', snippet: 'tokens'),
    ];
    final entries = [
      _entry(
        path: '/design.pdf',
        name: 'Design Systems.pdf',
        collectionIds: {'c1'},
      ),
      _entry(
        path: '/habits.pdf',
        name: 'Atomic Habits.pdf',
        collectionIds: {'c2'},
      ),
    ];
    const collections = [
      PdfCollection(id: 'c1', name: 'Design'),
      PdfCollection(id: 'c2', name: 'Life'),
    ];

    final all = resolveAnnotationHits(
      rows: rows,
      entries: entries,
      collections: collections,
    );
    expect(all.map((h) => h.bookName), [
      'Design Systems.pdf',
      'Atomic Habits.pdf',
      'loose.pdf',
    ]);
    expect(all.first.collectionNames, ['Design']);

    final filtered = resolveAnnotationHits(
      rows: rows,
      entries: entries,
      collections: collections,
      filter: const SearchInCollection('c1'),
    );
    expect(filtered.map((h) => h.bookPath), ['/design.pdf']);
  });

  test('groupHitsByBook sorts books and pages', () {
    final hits = resolveAnnotationHits(
      rows: [
        _row(id: 'z', pdfId: '/b.pdf', page: 9, snippet: 'x'),
        _row(id: 'a', pdfId: '/a.pdf', page: 3, snippet: 'x'),
        _row(id: 'b', pdfId: '/a.pdf', page: 1, snippet: 'x'),
      ],
      entries: [
        _entry(path: '/b.pdf', name: 'Zebra.pdf'),
        _entry(path: '/a.pdf', name: 'Alpha.pdf'),
      ],
      collections: const [],
    );

    final groups = groupHitsByBook(hits);
    expect(groups.map((g) => g.bookName), ['Alpha.pdf', 'Zebra.pdf']);
    expect(groups.first.hits.map((h) => h.annotation.page), [1, 3]);
  });

  test('favorites filter keeps only starred books', () {
    final hits = resolveAnnotationHits(
      rows: [
        _row(id: '1', pdfId: '/a.pdf'),
        _row(id: '2', pdfId: '/b.pdf'),
      ],
      entries: [
        _entry(path: '/a.pdf', name: 'A.pdf', favorite: true),
        _entry(path: '/b.pdf', name: 'B.pdf'),
      ],
      collections: const [],
      filter: const SearchFavorites(),
    );
    expect(hits.map((h) => h.bookPath), ['/a.pdf']);
  });
}
