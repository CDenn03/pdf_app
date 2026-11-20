import 'package:path/path.dart' as p;

import 'package:sefer/core/models/annotation.dart';
import 'package:sefer/core/models/annotation_search.dart';
import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/features/library/state/library_entry.dart';

/// How library search narrows books and annotation hits.
sealed class LibrarySearchFilter {
  const LibrarySearchFilter();
}

class SearchAllBooks extends LibrarySearchFilter {
  const SearchAllBooks();
}

class SearchFavorites extends LibrarySearchFilter {
  const SearchFavorites();
}

class SearchInCollection extends LibrarySearchFilter {
  const SearchInCollection(this.collectionId);

  final String collectionId;

  @override
  bool operator ==(Object other) =>
      other is SearchInCollection && other.collectionId == collectionId;

  @override
  int get hashCode => collectionId.hashCode;
}

/// An annotation search result joined with the book it belongs to.
class AnnotationSearchHit {
  const AnnotationSearchHit({
    required this.annotation,
    required this.snippet,
    required this.bookName,
    required this.bookPath,
    this.unavailable = false,
    this.collectionNames = const [],
  });

  final Annotation annotation;
  final String snippet;
  final String bookName;
  final String bookPath;
  final bool unavailable;
  final List<String> collectionNames;
}

/// Hits for one book, ordered by page.
class AnnotationBookGroup {
  const AnnotationBookGroup({
    required this.bookName,
    required this.bookPath,
    required this.hits,
  });

  final String bookName;
  final String bookPath;
  final List<AnnotationSearchHit> hits;
}

Iterable<LibraryEntry> applyLibrarySearchFilter(
  Iterable<LibraryEntry> entries,
  LibrarySearchFilter filter,
) => switch (filter) {
  SearchAllBooks() => entries,
  SearchFavorites() => entries.where((e) => e.isFavorite),
  SearchInCollection(:final collectionId) => entries.where(
    (e) => e.collectionIds.contains(collectionId),
  ),
};

List<AnnotationSearchHit> resolveAnnotationHits({
  required List<AnnotationSearchRow> rows,
  required List<LibraryEntry> entries,
  required List<PdfCollection> collections,
  LibrarySearchFilter filter = const SearchAllBooks(),
}) {
  final byPath = {for (final entry in entries) entry.path: entry};
  final allowedPaths = switch (filter) {
    SearchAllBooks() => null,
    _ => applyLibrarySearchFilter(entries, filter).map((e) => e.path).toSet(),
  };

  final hits = <AnnotationSearchHit>[];
  for (final row in rows) {
    final path = row.annotation.pdfId;
    if (allowedPaths != null && !allowedPaths.contains(path)) continue;
    final entry = byPath[path];
    hits.add(
      AnnotationSearchHit(
        annotation: row.annotation,
        snippet: compactSnippet(row.snippet),
        bookName: entry?.name ?? p.basename(path),
        bookPath: path,
        unavailable: entry != null && entry.status != FileStatus.ok,
        collectionNames: [
          for (final collection in collections)
            if (entry?.collectionIds.contains(collection.id) ?? false)
              collection.name,
        ],
      ),
    );
  }
  return hits;
}

List<AnnotationBookGroup> groupHitsByBook(List<AnnotationSearchHit> hits) {
  final grouped = <String, List<AnnotationSearchHit>>{};
  for (final hit in hits) {
    (grouped[hit.bookPath] ??= []).add(hit);
  }
  final paths = grouped.keys.toList()
    ..sort((a, b) {
      final nameA = grouped[a]!.first.bookName.toLowerCase();
      final nameB = grouped[b]!.first.bookName.toLowerCase();
      return nameA.compareTo(nameB);
    });
  return [
    for (final path in paths)
      AnnotationBookGroup(
        bookName: grouped[path]!.first.bookName,
        bookPath: path,
        hits: [...grouped[path]!]
          ..sort((a, b) => a.annotation.page.compareTo(b.annotation.page)),
      ),
  ];
}
