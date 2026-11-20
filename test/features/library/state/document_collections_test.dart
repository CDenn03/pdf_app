import 'package:flutter_test/flutter_test.dart';

import 'package:sefer/core/models/collection.dart';
import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/features/library/state/document_collections.dart';
import 'package:sefer/features/library/state/library_entry.dart';

const _papers = PdfCollection(id: 'c1', name: 'Papers');
const _novels = PdfCollection(id: 'c2', name: 'Novels');
const _collections = [_papers, _novels];

LibraryEntry _entry({
  String path = '/docs/a.pdf',
  Set<String> collectionIds = const {},
}) {
  return LibraryEntry(
    id: 'e1',
    name: 'a.pdf',
    path: path,
    status: FileStatus.ok,
    collectionIds: collectionIds,
  );
}

void main() {
  test('collectionsForIds keeps the catalogue order', () {
    expect(collectionsForIds(ids: {'c2', 'c1'}, collections: _collections), [
      _papers,
      _novels,
    ]);
  });

  test('collectionsForPath is empty when the file is not in the library', () {
    expect(
      collectionsForPath(
        path: '/docs/missing.pdf',
        entries: [
          _entry(collectionIds: {'c1'}),
        ],
        collections: _collections,
      ),
      isEmpty,
    );
  });

  test('singleSelectionMembershipLabel lists names for one selected file', () {
    expect(
      singleSelectionMembershipLabel(
        selectedPaths: {'/docs/a.pdf'},
        entries: [
          _entry(collectionIds: {'c1', 'c2'}),
        ],
        collections: _collections,
      ),
      'In Papers · Novels',
    );
  });

  test('singleSelectionMembershipLabel is null for a multi selection', () {
    expect(
      singleSelectionMembershipLabel(
        selectedPaths: {'/docs/a.pdf', '/docs/b.pdf'},
        entries: [
          _entry(collectionIds: {'c1'}),
        ],
        collections: _collections,
      ),
      isNull,
    );
  });

  test('singleSelectionMembershipLabel is null when the file has none', () {
    expect(
      singleSelectionMembershipLabel(
        selectedPaths: {'/docs/a.pdf'},
        entries: [_entry()],
        collections: _collections,
      ),
      isNull,
    );
  });
}
