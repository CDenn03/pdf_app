import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sefer/core/models/file_status.dart';
import 'package:sefer/core/services/library_persistence_service.dart';
import 'package:sefer/features/library/state/library_entry.dart';

LibraryEntry _entry({
  required String id,
  required String path,
  bool favorite = false,
  Set<String> collectionIds = const {},
}) => LibraryEntry(
  id: id,
  name: path.split('/').last,
  path: path,
  status: FileStatus.ok,
  isFavorite: favorite,
  collectionIds: collectionIds,
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('round-trips entries', () async {
    final service = LibraryPersistenceService();
    final entries = [
      _entry(id: '1', path: '/a.pdf', favorite: true),
      _entry(id: '2', path: '/b.pdf', collectionIds: {'col-1', 'col-2'}),
    ];

    // saveEntries is debounced; invoke _write directly via a zero-delay pump.
    await service.saveEntries(entries);
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final loaded = await service.loadEntries();
    expect(loaded, hasLength(2));
    expect(loaded.first.isFavorite, isTrue);
    expect(loaded.last.collectionIds, {'col-1', 'col-2'});
  });

  test('migrates a legacy collectionId into collectionIds', () async {
    SharedPreferences.setMockInitialValues({
      'library_entries_v1':
          '[{"id":"1","name":"a.pdf","path":"/a.pdf",'
          '"collectionId":"legacy"}]',
    });

    final loaded = await LibraryPersistenceService().loadEntries();

    expect(loaded.single.collectionIds, {'legacy'});
  });

  test('returns empty list on corrupt JSON', () async {
    SharedPreferences.setMockInitialValues({
      'library_entries_v1': 'NOT VALID JSON}}}',
    });

    final service = LibraryPersistenceService();
    final loaded = await service.loadEntries();
    expect(loaded, isEmpty);
  });
}
